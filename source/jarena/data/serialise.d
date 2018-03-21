module jarena.data.serialise;

private
{
    import std.traits;
    import std.format   : format;
    import std.conv     : to;
    import std.typecons : Nullable;
    
    import sdlang;
    import jarena.data.loaders, jarena.core;
    import codebuilder;
}

/++
 + [Optional]
 + Can be used to set a custom name for a variable or struct.
 +
 + SDLang:
 +  For SDLang serialisation, the name is used as the tag name.
 +
 +  e.g. A struct named 'myStruct' might be serialised like
 +  ```
 +  myStruct {
 +     someVar "abcdef"
 +  }
 +  ```
 + ++/
struct Name
{
    string name;
}

/++
 + [Mandatory]
 +  Must be placed on any structs that support serialisation.
 + ++/
struct Serialisable
{}

/++
 + Creates functions used for serialisation.
 + ++/
mixin template SerialisableInterface()
{
    import std.traits : hasUDA;
    import sdlang : Tag;
    
    alias ThisType = typeof(this);
    static assert(hasUDA!(ThisType, Serialisable), "Please attach an @Serialisable to the type: " ~ ThisType.stringof);

    /++
     + Updates the data in this struct based on the data in the given `tag`.
     + ++/
    void fromSdlTag(Tag tag)
    {
        import std.exception : enforce;
        
        pragma(msg, "For Type: " ~ ThisType.stringof);
        pragma(msg, fromSdlTagGenerator!ThisType);
        mixin(fromSdlTagGenerator!ThisType);
    }    
}

// Needs to be public so the mixin template can work.
// But shouldn't be used outside of this module.
string fromSdlTagGenerator(ThisType)()
{
    auto code = new CodeBuilder();

    size_t nameCounter = 0;

    foreach(fieldName; FieldNameTuple!ThisType)
    {
        mixin("alias FieldAlias = ThisType.%s;".format(fieldName));
        alias FieldType     = typeof(FieldAlias);
        enum  FieldTypeName = fullyQualifiedName!FieldType;
        enum  FieldTagName  = getFieldName!FieldAlias.name;

        
        static if(is(typeof({code.generateSDL!(FieldAlias, FieldType, FieldTypeName, FieldTagName, fieldName)(nameCounter);})))
            code.generateSDL!(FieldAlias, FieldType, FieldTypeName, FieldTagName, "this." ~ fieldName)(nameCounter);
        else
            static assert(false, format("No Seraliser for field '%s' of type '%s'", fieldName, FieldType.stringof));
    }        
    
    return code.data.idup.to!string;
}

private enum isNullable(T) = isInstanceOf!(Nullable, T);

private static Name getFieldName(alias F)()
{
    static if(hasUDA!(F, Name))
        return getUDAs!(F, Name)[0];
    else
        return Name(F.stringof);
}

private string genTempName(ref size_t nameCounter)
{
    import std.conv : to;
    return "var" ~ nameCounter++.to!string;
}

// SDLang specific functions
// Anytime a new type needs to have a generator for it to be serialised, just make
// a new 'generateSDL' function, and change it's contract.
private static
{
    // For builtin types, use expectTagValue, since it already supports them all.
    void generateSDL(alias FieldAlias, FieldType, string FieldTypeName, string FieldTagName, string FieldMemberName)
                    (CodeBuilder code, ref size_t nameCounter)
    if(isBuiltinType!FieldType && !isNullable!FieldType)
    {
        code.put("// Builtin Type");
        code.putf("%s = tag.expectTagValue!(%s)(\"%s\");",
                  FieldMemberName, FieldTypeName, FieldTagName);
    }

    // For @Serialisable structs, call their fromSdlTag function.
    void generateSDL(alias FieldAlias, FieldType, string FieldTypeName, string FieldTagName, string FieldMemberName)
                    (CodeBuilder code, ref size_t nameCounter)
    if(is(FieldType == struct) && hasUDA!(FieldType, Serialisable) && !isNullableFieldType)
    {        
        static assert(hasMember!(FieldType, "fromSdlTag"),
                      format("The @Serialisable type '%s' doesn't have a function called 'fromSdlTag', please use `mixin SerialisableInterface;`",
                             FieldType.stringof)
                     );

        code.put("// @Serialisable struct");
        code.putf("%s = (%s).init;", FieldMemberName, FieldTypeName);
        code.putf("%s.fromSdlTag(tag.expectTag(\"%s\"));",TagName);
    }

    // For vectors, check that the tag has N amount of values, and then read them into the vector.
    void generateSDL(alias FieldAlias, FieldType, string FieldTypeName, string FieldTagName, string FieldMemberName)
                    (CodeBuilder code, ref size_t nameCounter)
    if(isVector!FieldType && !isNullable!FieldType)
    {
        enum N = FieldType.dimension;
        alias VectT = Signed!(FieldType.valueType);
        auto varName = genTempName(nameCounter);

        code.put("// Vector type");
        code.putf("Tag %s = tag.expectTag(\"%s\");", varName, FieldTagName);
        code.putf("enforce(%s.values.length == %s, \"Expected %s values for tag '%s' for type '%s'\");",
                  varName, N, N, FieldTagName, FieldTypeName);
                      
        code.putf("foreach(i; 0..%s)", N);
        code.putScope((_)
        {
            code.putf("%s.data[i] = %s.values[i].get!%s;",
                      FieldMemberName, varName, VectT.stringof);
        });
    }

    // For nullables, check to see whether the tag exists.
    // If yes, load it in.
    // If no, set it to `.init` which is by default null for a nullable.
    void generateSDL(alias FieldAlias, FieldType, string FieldTypeName, string FieldTagName, string FieldMemberName)
                    (CodeBuilder code, ref size_t nameCounter)
    if(isNullable!FieldType)
    {
        alias NullableInnerType = TemplateArgsOf!(FieldType)[0];
        auto tagName = genTempName(nameCounter);
        
        code.putf("// Nullable of %s", NullableInnerType.stringof);
        code.putf("auto %s = tag.getTag(\"%s\");", tagName, FieldTagName);
        code.putf("if(%s is null) %s.nullify;", tagName, FieldMemberName);
        code.put("else");
        code.putScope((_)
        {
            code.putf("%s = (%s).init;", FieldMemberName, fullyQualifiedName!NullableInnerType);
            code.generateSDL!(FieldAlias, 
                              NullableInnerType, 
                              fullyQualifiedName!NullableInnerType,
                              FieldTagName,
                              FieldMemberName)
                              (nameCounter);
        });
    }
}
