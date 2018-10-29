module jarena.data.serialisation.serialiser;

private
{
    import std.stdio;
    import std.traits, std.format, std.range, std.typecons, std.algorithm, std.exception;
    import jarena.data.serialisation.archive;
}

alias UseArrayBaseType = Flag!"useBaseType";

//version = SERIALISER_DEBUG_OUTPUT;

/++
 + This UDA should be attached to any field that is used as an attribute.
 +
 + For binary based archives, this likely has no real meaning.
 + For text based archives, this will likely determine how the value is formatted.
 +
 + Example:
 +  For example, with the SDLang archive (`ArchiveSDL`), the following struct.
 +
 +  ```
 +  struct Foo
 +  {
 +      int bar;
 +      
 +      @Attribute
 +      string type;
 +  }
 +  ```
 +
 +  Would produce the following SDLang file.
 +
 +  Foo type="SomeType" {
 +      bar 200
 +  }
 + ++/
struct Attribute {}

/++
 + This UDA should be attached to a single field that represents the main value of a struct.
 +
 + For binary based archives, this likely has no real meaning.
 + For text based archives, this will likely determine how the value is formatted.
 +
 + Example:
 +  For example, with the SDLang archive (`ArchiveSDL`), the following struct.
 +
 +  ```
 +  struct Foo
 +  {
 +      int bar;
 +      
 +      @MainValue
 +      string type;
 +  }
 +  ```
 +
 +  Would produce the following SDLang file.
 +
 +  Foo "SomeType" {
 +      bar 200
 +  }
 + ++/
struct MainValue {}

/++
 + This UDA is to give a custom name to a type/field.
 +
 + Example:
 +  For example, with the SDLang archive (`ArchiveSDL`), the following struct.
 +
 +  ```
 +  @Name("FooBar")
 +  struct Foo
 +  {
 +      int bar;
 +      
 +      @Name("Not_a_type")
 +      string type;
 +  }
 +  ```
 +
 +  Would produce the following SDLang file.
 +
 +  FooBar {
 +      bar 200
 +      Not_a_type "SomeType"
 +  }
 + ++/
struct Name
{
    string name;
}

/++
 + This UDA is used to specify certain settings for a type/field.
 +
 + Notes:
 +  If @Setting is applied to the struct (as in the type itself, instead of a field) then the setting
 +  is applied to all of the struct's field as well.
 +
 + Example:
 +  Example of applying it to the entire struct.
 +
 +  ```
 +  @Setting(Serialiser.Settings.ArrayAsObject)
 +  struct Foo
 +  {
 +      // Gets applied to this as well
 +      int[] yall;
 +  }
 +  ```
 +
 +  Example of applying it to a single field.
 +
 +  ```
 +  struct Foo
 +  {
 +      int[] bar; // Not affected
 +      
 +      @Setting(Serialiser.Settings.ArrayAsObject)
 +      string[] types;
 +  }
 +  ```
 + ++/
struct Setting
{
    Serialiser.Settings settings;
}

/++
 + This UDA only functions when placed on a struct field, or an array of structs.
 +
 + This UDA tells the serialiser that $(B all) settingss being applied to the attached field
 + should also be passed down onto all of the struct's fields.
 +
 + This is similar to placing an `@Setting` onto the struct type itself, but sometimes
 + this may not be possible. For example, the `Vector` struct from DLSL might need some
 + setting tweaks for it to be serialised the way you want, but you can't modify that code at all
 + so this UDA is the best that you can do.
 + 
 + TODO: Example.
 + ++/
struct InheritSettings {}

/// This UDA marks a field that should be ignored by the serialiser.
struct Ignore {}

/++
 + Retrieves the name to use for the given field, for use in serialisation.
 +
 + Rules:
 +  The rules for how the name is retrieved are a bit _convoluted_ so they're documented here.
 +
 +  For non-structs and non-array types: The return value of `F.stringof` is used.
 +
 +  For struct types: If the struct has an @Name UDA, then that is used.
 +                    If not, the name of the return value of `F.stringof` is used.
 +
 +  For array types: If `UseBase` is set to `UseBase.yes`, then the return value of `getFieldName!(ElementType!F)` is used.
 +                   If not, the return value of `F.stringof` is used.
 +
 +  For when `F` is an alias to a struct's field: The rule for the field's data type will be used, but with one change,
 +                                                the `F.stringof` value will instead return the name of the field, instead of the type.
 + ++/
static string getFieldName(alias F, UseArrayBaseType UseBase = UseArrayBaseType.yes)()
{
    static if(hasUDA!(F, Name)
           &&  (isType!F
             || !isArray!(typeof(F))
             || !UseBase
               )
             )
        return getUDAs!(F, Name)[0].name;
    else
    {
        static if(!isType!F 
               && isArray!(typeof(F))
               && is(ElementType!(typeof(F)) == struct)
               && UseBase)
            return getFieldName!(ElementType!(typeof(F)));
        // else static if(is(typeof(F) == struct))
        // {
        //     alias Type = typeof(F);
        //     return getFieldName!Type;
        // }
        else
            return F.stringof;
    }
}

/++
 + A painless way to get the `Serialiser.Settings` for a type/field.
 +
 + Returns:
 +  The `Serialiser.Settings` specified by the @Settings UDA for `F`.
 +  Or `Serialiser.Settings.None` if no settings are specified.
 + ++/
static Serialiser.Settings getSettings(alias F)()
{
    static if(hasUDA!(F, Setting))
        return getUDAs!(F, Setting)[0].settings;
    else
        return Serialiser.Settings.None;
}

/++
 + The default serialiser provided by the engine.
 +
 + This serialiser is more oriented towards creating data oriented for text-based archives,
 + rather than an optimised format that would be better for binary archives. Both can be used
 + of course.
 + ++/
final static class Serialiser
{
    /++
     + See the UDA called `Settings`.
     + ++/
    enum Settings : ubyte
    {
        /// Apply no settings.
        None = 0,

        /++
         + Tells the serialiser that the array field it is attached to, or all array
         + fields in the attached struct should be serialised as a child object.
         +
         + Notes:
         +  This only works on arrays of struct types for now.
         +
         +  If there are two arrays in the struct that contain the same type
         +  then this settings $(B must) be used for correct serialisation.
         +
         + Example:
         +  Take the given struct.
         +
         +  ```
         +  struct Point{int x; int y;}
         +  struct Foo
         +  {
         +      Point[] pointA = [Point(60, 60), Point(120, 120)];
         +
         +      @Setting(Serialiser.Settings.ArrayAsObject)
         +      Point[] pointB = [Point(60, 60), Point(200, 200)];
         +  }
         +  ```
         +
         +  Using the SDLang archive, this would generate.
         +
         +  ```
         +  Foo {
         +      // The ones embedded inside this scope are from 'pointA'
         +      Point {
         +         x 60
         +         y 60
         +      }
         +
         +      Point {
         +          x 120
         +          y 120
         +      }
         +
         +      pointB {
         +          Point {
         +              x 60
         +              y 60
         +          }
         +
         +          Point {
         +              x 200
         +              y 200
         +          }
         +      }
         +  }
         +  ```
         + ++/
        ArrayAsObject = 1 << 0
    }

    public static final
    {
        /++
         + Serialises the given value, using the provided parent.
         +
         + Non-Struct & Non-Array types:
         +  By default, these types of data are stored as child objects to the parent, holding a single
         +  value. For example the field `string name` would become an ArchiveObject called name, holding
         +  a single string value.
         +
         +  A single field can be marked as @MainValue to become the value of the `parent` object.
         +
         +  While binary archives may support multiple values under an object, text-based ones may only
         +  allow a single value, which i s what @MainValue will be used for. Everything else
         +  must be an attribute or child object.
         +
         +  Multiple fields can be marked as @Attribute to be used as an attribute. For example,
         +  the field `@Attribute string name` would be added to the parent as an attribute called 'name',
         +  holding a string value.
         +
         +  Multiple fields can be given the @Name UDA, and the @Setting UDA. Please see their own documentation.
         +
         + Struct types:
         +  Struct types by default create a new child object inside the `parent` to store their data.
         +  Each field in the struct follows the same rules as are being described.
         +
         +  @Setting and @Name can be attached to structs.
         +
         + Array types (for non-structs):
         +  By default, these types of arrays will be stored as a child object in the parent, where all of the
         +  array's values are given to the child object.
         +
         +  This type of array can be used as the @MainValue for a struct.
         +
         +  @Setting and @Name (more in the 'Array types (shared)' section) are of course supported as well.
         +
         + Array types (for structs):
         +  By default, these types of arrays will write out all of the struct child objects directly into the parent.
         +  However, the settings `Serialiser.Settings.ArrayAsObject` can be used to store these children into a seperate
         +  child object. Please refer to it's documentation.
         +
         +  @Setting and @Name are supported.
         +
         + Array types (shared):
         +  The names chosen when serialising arrays (and other types in general) is a bit complicated, so please refer to the documentation for
         +  `getFieldName`.
         +
         + Nullable:
         +  If the value is currently null, then nothing about it is serialised.
         +
         + Params:
         +  data    = The data to serialise.
         +  parent  = The parent to serialise the data into.
         + ++/
        void serialise(T)(T data, ArchiveObject parent)
        {
            doSerialise!(T, T, T, Settings.None)(data, parent);
        }

        /++
         + Deserialises the given type using `root` as the root of the data.
         +
         + Nullable:
         +  If there is no data for the nullable object, then it is nullafied regardless
         +  of what value it initialises to.
         + ++/
        T deserialise(T)(ArchiveObject root)
        {
            T toReturn = T.init;

            doDeserialise!(T, T, T, Settings.None)(toReturn, root);

            return toReturn;
        }
    }

    // #################
    // # SERIALISATION #
    // #################
    private static final
    {
        void doSerialise(T, alias MainSymbol, alias Symbol, Settings InheritedSettings)(T data, ArchiveObject parent)
        if(ArchiveValue.allowed!T && !hasUDA!(Symbol, Attribute))
        {
            debug mixin(serialiseDebug("Value"));

            static if(hasUDA!(Symbol, MainValue))
                parent.addValueAs!T(data);
            else
            {
                auto obj = new ArchiveObject(getFieldName!Symbol);
                obj.addValueAs!T(data);
                parent.addChild(obj);
            }
        }

        void doSerialise(T, alias MainSymbol, alias Symbol, Settings InheritedSettings)(T data, ArchiveObject parent)
        if(ArchiveValue.allowed!T && hasUDA!(Symbol, Attribute))
        {
            debug mixin(serialiseDebug("Attribute"));

            parent.setAttributeAs!T(getFieldName!Symbol, data);
        }

        void doSerialise(T, alias MainSymbol, alias Symbol, Settings InheritedSettings)(T data, ArchiveObject parent)
        if(isArray!T && !isSomeString!T)
        {
            debug mixin(serialiseDebug("Array"));
            
            enum settings = getSettings!MainSymbol | getSettings!Symbol | InheritedSettings;
            
            static if(ArchiveValue.allowed!(ElementType!T))
            {
                static assert(!(settings & Settings.ArrayAsObject), "The settings 'ArrayAsObject' can only be applied to arrays of structs.");

                static if(!hasUDA!(Symbol, MainValue))
                {
                    auto obj = new ArchiveObject(getFieldName!Symbol);
                    parent.addChild(obj);
                }
                else
                    auto obj = parent;

                foreach(value; data)
                    obj.addValueAs!(ElementType!T)(value);
            }
            else static if(is(ElementType!T == struct))
            {
                static assert(!hasUDA!(Symbol, MainValue), "Arrays of structs cannot be the main value, they can only be children.");

                static if(settings & Settings.ArrayAsObject)
                {
                    auto obj = new ArchiveObject(getFieldName!(Symbol, UseArrayBaseType.no));
                    parent.addChild(obj);
                }
                else
                    auto obj = parent;

                static if(hasUDA!(Symbol, InheritSettings))
                    enum ToInherit = InheritedSettings | getSettings!Symbol;
                else
                    enum ToInherit = InheritedSettings;

                foreach(value; data)
                    doSerialise!(ElementType!T, MainSymbol, Symbol, cast(Settings)InheritedSettings)(value, obj);
            }
            else static assert(false, "Unsupported type: " ~ T.stringof);
        }

        void doSerialise(T, alias MainSymbol, alias Symbol, Settings InheritedSettings)(T data, ArchiveObject parent)
        if(is(T == enum))
        {
            import std.conv : to;

            static if(hasUDA!(Symbol, Attribute))
                parent.setAttributeAs!string(getFieldName!Symbol, data.to!string);
            else
            {
                auto obj = new ArchiveObject(getFieldName!Symbol);
                obj.addValueAs!string(data.to!string);
                parent.addChild(obj);
            }
        }

        void doSerialise(T, alias MainSymbol, alias Symbol, Settings InheritedSettings)(T data, ArchiveObject parent)
        if(is(T == struct))
        {
            debug mixin(serialiseDebug("Struct"));

            auto obj = new ArchiveObject(getFieldName!Symbol);
            parent.addChild(obj);
            
            static assert(getSymbolsByUDA!(T, MainValue).length < 2, "There can only be one field marked with @MainValue");

            foreach(fieldName; FieldNameTuple!T)
            {
                static if(isPublic!(T, fieldName)
                       && !hasUDA!(mixin("T."~fieldName), Ignore))
                {
                    mixin("alias FieldAlias = T.%s;".format(fieldName));

                    static if(isInstanceOf!(Nullable, typeof(FieldAlias)))
                        alias FieldType = Unqual!(ReturnType!(FieldAlias.get));
                    else
                        alias FieldType = typeof(FieldAlias);

                    static if(hasUDA!(Symbol, InheritSettings))
                        enum ToInherit = InheritedSettings | getSettings!Symbol;
                    else
                        enum ToInherit = InheritedSettings;
                        
                    auto func = () => doSerialise!(FieldType, MainSymbol, FieldAlias, cast(Settings)ToInherit)(mixin("data."~fieldName), obj);
                    static if(isInstanceOf!(Nullable, typeof(FieldAlias)))
                    {
                        if(mixin("!data."~fieldName~".isNull"))
                            func();
                    }
                    else
                        func();
                }
            }
        }
    }

    // ###################
    // # DESERIALISATION #
    // ###################
    private static final
    {
        void doDeserialise(T, alias MainSymbol, alias Symbol, Settings InheritedSettings)(ref T data, ArchiveObject obj)
        if(ArchiveValue.allowed!T && !hasUDA!(Symbol, Attribute))
        {
            static if(hasUDA!(Symbol, MainValue))
                data = obj.expectValueAs!T(0);
            else
                data = obj.expectChild(getFieldName!Symbol).expectValueAs!T(0);
        }

        void doDeserialise(T, alias MainSymbol, alias Symbol, Settings InheritedSettings)(ref T data, ArchiveObject obj)
        if(ArchiveValue.allowed!T && hasUDA!(Symbol, Attribute))
        {
            data = obj.expectAttributeAs!T(getFieldName!Symbol);
        }

        void doDeserialise(T, alias MainSymbol, alias Symbol, Settings InheritedSettings)(ref T data, ArchiveObject parent)
        if(isArray!T && !isSomeString!T)
        {            
            enum settings = getSettings!MainSymbol | getSettings!Symbol | InheritedSettings;
            
            static if(ArchiveValue.allowed!(ElementType!T))
            {
                static if(!hasUDA!(Symbol, MainValue))
                    auto obj = parent.expectChild(getFieldName!Symbol);
                else
                    auto obj = parent;

                static if(isDynamicArray!T)
                {
                    foreach(value; obj.values)
                        data ~= value.coerce!(typeof(data[0]));
                }
                else static if(isStaticArray!T)
                {
                    enforce(obj.values.length == data.length, "Expected %s values, got %s.".format(data.length, obj.values.length));

                    foreach(i, value; obj.values)
                        data[i] = value.coerce!(typeof(data[0]));
                }
                else static assert(false, "NSAUasiogoo");
            }
            else static if(is(ElementType!T == struct))
            {
                static if(settings & Settings.ArrayAsObject)
                    auto obj = parent.expectChild(getFieldName!(Symbol, UseArrayBaseType.no));
                else
                    auto obj = parent;

                static if(hasUDA!(Symbol, InheritSettings))
                    enum ToInherit = InheritedSettings | getSettings!Symbol;
                else
                    enum ToInherit = InheritedSettings;

                foreach(child; obj.children.filter!(c => c.name == getFieldName!Symbol))
                {
                    data ~= typeof(data[0]).init;
                    doDeserialise!(ElementType!T, MainSymbol, Symbol, cast(Settings)InheritedSettings)(data[$-1], child);
                }
            }
            else static assert(false, "Unsupported type: " ~ T.stringof);
        }

        void doDeserialise(T, alias MainSymbol, alias Symbol, Settings InheritedSettings)(ref T data, ArchiveObject obj)
        if(is(T == enum))
        {
            import std.conv : to;

            static if(hasUDA!(Symbol, Attribute))
                data = obj.expectAttributeAs!string(getFieldName!Symbol).to!T;
            else
                data = obj.expectChild(getFieldName!Symbol).getValueAs!string(0).to!T;
        }

        void doDeserialise(T, alias MainSymbol, alias Symbol, Settings InheritedSettings)(ref T data, ArchiveObject obj)
        if(is(T == struct))
        {
            ArchiveObject structObj = (obj.name == getFieldName!Symbol) ? obj
                                                                        : obj.expectChild(getFieldName!Symbol);

            foreach(fieldName; FieldNameTuple!T)
            {
                static if(isPublic!(T, fieldName)
                       && !hasUDA!(mixin("T."~fieldName), Ignore))
                {
                    mixin("alias FieldAlias = T.%s;".format(fieldName));

                    static if(isInstanceOf!(Nullable, typeof(FieldAlias)))
                    {
                        alias FieldType = Unqual!(ReturnType!(FieldAlias.get));
                        enum FieldRef = "tempValue";
                    }
                    else
                    {
                        alias FieldType = typeof(FieldAlias);
                        enum FieldRef = "data."~fieldName;
                    }

                    static if(hasUDA!(Symbol, InheritSettings))
                        enum ToInherit = InheritedSettings | getSettings!Symbol;
                    else
                        enum ToInherit = InheritedSettings;
                    
                    try
                    {
                        // We can't pass the nullable itself by ref, so we have to store it in a temp value first
                        static if(isInstanceOf!(Nullable, typeof(FieldAlias)))
                            FieldType tempValue;

                        doDeserialise!(FieldType, MainSymbol, FieldAlias, cast(Settings)ToInherit)(mixin(FieldRef), structObj);
                        
                        static if(isInstanceOf!(Nullable, typeof(FieldAlias)))
                            mixin("data."~fieldName~" = tempValue;");
                    }
                    catch(Exception ex)
                    {
                        static if(isInstanceOf!(Nullable, typeof(FieldAlias)))
                            mixin("data."~fieldName~".nullify();");
                        else
                            throw ex;
                    }
                }
            }
        }
    }
}

// Nullable test
unittest
{
    import jarena.data.serialisation.sdlang;

    struct A
    {
        Nullable!int a;
        int b;
        Nullable!int c;
    }

    A a;
    a.a.nullify;
    a.b = 200;
    a.c = 400;

    auto archive = new ArchiveSDL();
    Serialiser.serialise(a, archive.root);

    assert(archive.root.expectChild("A").getChild("a") is null);
    assert(archive.root.expectChild("A").expectChild("b").expectValueAs!int(0) == 200);
    assert(archive.root.expectChild("A").expectChild("c").expectValueAs!int(0) == 400);

    A b = Serialiser.deserialise!A(archive.root);
    assert(a == b);
}

// Enum test
unittest
{
    import jarena.data.serialisation.sdlang;
    import fluent.asserts;

    enum E
    {
        A,
        B,
        C
    }

    struct A
    {
        @Attribute
        E a;
        E b;
        E c;
    }

    A a;
    a.a = E.C;
    a.b = E.A;
    a.c = E.B;

    auto archive = new ArchiveSDL();
    Serialiser.serialise(a, archive.root);

    archive.root.expectChild("A").expectAttributeAs!string("a").should.equal("C");
    archive.root.expectChild("A").expectChild("b").expectValueAs!string(0).should.equal("A");
    archive.root.expectChild("A").expectChild("c").expectValueAs!string(0).should.equal("B");

    A b = Serialiser.deserialise!A(archive.root);
    a.should.equal(b);
}

// Best I can do at least...
private enum isPublic(T, string field) = is(typeof({T t = T.init; auto b = mixin("t."~field);}));

private string serialiseDebug(string name)
{
    version(SERIALISER_DEBUG_OUTPUT)
    {
        return format(`writefln("Func:%%-15s | T:%%-15s | MainSymbol:%%-15s | Symbol:%%-15s | data:%%-15s | parent:%%-15s",
                                "%s", T.stringof, MainSymbol.stringof, Symbol.stringof, data, parent.name);`, name);
    }
    else
        return "";
}