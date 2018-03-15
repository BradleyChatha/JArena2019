module jarena.data.serialise;

private
{
    import std.traits;
    import sdlang;
    import jarena.data.loaders, jarena.core;
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
    import std.format : format;
    import std.conv   : to;
    import codebuilder;
    auto code = new CodeBuilder();

    size_t nameCounter = 0;
    string genTempName()
    {
        import std.conv : to;
        return "var" ~ nameCounter++.to!string;
    }

    foreach(fieldName; FieldNameTuple!ThisType)
    {
        mixin("alias FieldAlias = ThisType.%s;".format(fieldName));
        alias FieldType     = typeof(FieldAlias);
        enum  FieldTypeName = fullyQualifiedName!FieldType;
        enum  FieldTagName  = getFieldName!FieldAlias.name;        

        // For builtin types, use expectTagValue, since it already supports them all.
        static if(isBuiltinType!FieldType)
        {
            code.putf("this.%s = tag.expectTagValue!(%s)(\"%s\");",
                      fieldName, FieldTypeName, FieldTagName);
        }
        else static if(is(FieldType == struct) && hasUDA!(FieldType, Serialisable))
        {
            // For @Serialisable structs, call their fromSdlTag function.
            static assert(hasMember!(FieldType, "fromSdlTag"),
                          format("The @Serialisable type '%s' doesn't have a function called 'fromSdlTag', please use `mixin SerialisableInterface;`",
                                 FieldType.stringof)
                         );
                         
            code.putf("this.%s = (%s).init;",
                      fieldName, FieldTypeName);

            code.putf("this.%s.fromSdlTag(tag.expectTag(\"%s\"));",
                      fieldName, FieldTagName);
        }
        else static if(isVector!FieldType)
        {
            // For vectors, check that the tag has N amount of values, and then read them into the vector.
            enum N = FieldType.dimension;
            alias VectT = Signed!(FieldType.valueType);
            auto varName = genTempName();
            code.putf("Tag %s = tag.expectTag(\"%s\");", varName, FieldTagName);
            code.putf("enforce(%s.values.length == %s, \"Expected %s values for tag %s for type '%s'\");",
                      varName, N, N, FieldTagName, FieldTypeName);
                      
            code.putf("foreach(i; 0..%s)", N);
            code.putScope((_)
            {
                code.putf("this.%s.data[i] = %s.values[i].get!%s;",
                          fieldName, varName, VectT.stringof);
            });
        }
        else
            static assert(false, format("Don't know how to serialise member '%s' of type '%s'", fieldName, FieldType.stringof));
    }        
    
    return code.data.idup.to!string;
}

private static Name getFieldName(alias F)()
{
    static if(hasUDA!(F, Name))
        return getUDAs!(F, Name)[0];
    else
        return Name(F.stringof);
}
