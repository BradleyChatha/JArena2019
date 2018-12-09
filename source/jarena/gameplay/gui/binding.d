/// Contains the facilities for data binding.
module jarena.gameplay.gui.binding;

private
{
    import std.traits, std.typecons;
    import jarena.core, jarena.graphics, jarena.gameplay, jarena.maths, jarena.data;

    alias NO_TARGET = DataBinding;
}

/// A flag used for certain `DataConverters` functions.
alias NegativeAsNaN = Flag!"NegativeAsNaN";

/++
 + A UDA to be attached to any struct meant to be used as a DataBinding.
 +
 + The UDA itself functionally serves no purpose right now.
 +
 + It's worth noting that binding objects must also serve as valid serialisable objects for
 + the basic `Serialiser` the engine provides. That means things like `Nullable`, and the `@Name` enum,
 + all work fine. The DataBinder actually uses `@Name` for several important things.
 + ++/
struct DataBinding {}

/++
 + Attach this UDA to any `UIBase` class to attach a certain binding to a certain property.
 +
 + Notes:
 +  This is the only way to specify what bindings to use for member properties of an object.
 +
 +  This is only used for parsing an `ArchiveObject` into the attached object.
 +
 + Params:
 +  B       = The binding to apply.
 +  target  = If left to it's default value, then the class itself is the target for the binding.
 +            Otherwise, provide an alias to a property of the class (or a function that acts as a setter), to
 +            use that as the target.
 + ++/
struct UsesBinding(B, alias target = NO_TARGET)
{
    ///
    alias Target = target;
    
    ///
    alias BindT  = B;
}

/++
 + Attach this UDA to any `UIBase` class to disable certain binding fields for a specific member.
 +
 + Example:
 +  The `BasicButton` class uses a `baseColour` property to control it's colour, rather than going
 +  off the colour of `BasicButton.shape`. However, users can still modify the colour of `BasicButton.shape`
 +  when parsing an ArchiveObject, which won't work and will be percieved as a bug.
 +
 +  To get around this, `BasicButton` disables the `RectangleShapeBinding.colour` field from being applied to
 +  it's `BasicButton.shape` field.
 +
 +  If the user attempts to modify it using an ArchiveObject then an exception is thrown using the given `Reason_`.
 +
 + Notes:
 +  Due to limitations in the language, only one member field alias can be used, so `TargetField_` must be passed
 +  as a string rather than an alias.
 +
 +  This is only used for parsing an `ArchiveObject` into a `UIBase` object. This will not prevent the user
 +  from directly changing the value in code.
 +
 + Params:
 +  BindingField_ = An alias to the field in the binding type to disable.
 +  TargetField_  = The name of the accessor/field inside of the attached object to disable the binding field for.
 +  Reason_       = The message to give the thrown exception on why this field was disabled.
 + ++/
struct DisableBinding(alias BindingField_, string TargetField_, string Reason_)
{
    static assert(isInstanceOf!(Nullable, typeof(BindingField_)), "Only Nullable types are supported right now.");

    ///
    alias BindingField = BindingField_;

    ///
    alias TargetField  = TargetField_;

    ///
    alias Reason       = Reason_;
}

/++
 + A UDA that is used within an `@DataBinding` struct to specify that the field this UDA is
 + attached to is a direct data binding for a certain named property.
 +
 + "Direct binding" means that no conversion needs to be performed to bind the field into 
 +  a base object.
 +
 + As an example, take the following code
 +
 + ```
 + @DataBinding
 + struct MyBinding
 + {
 +      @BindingFor("someNamedProperty")
 +      string name;
 + }
 + ```
 +
 + Given the example call of `DataBinder.copyValues(MyBaseObject, MyBindingInstance)`, the value of
 + `MyBindingInstance.name` would be copied to (or in the case of setter functions, passed to as the first argument)
 + the property `MyBaseObject.someNamedProperty`.
 + ++/
struct BindingFor
{
    /++
     + The name of the property to bind to.
     + ++/
    string varName;
}

/++
 + A UDA that is used within an `@DataBinding` struct to specify that the field this UDA is attached
 + to is a conversion data binding for a certain named property.
 +
 + "Conversion binding" means that a conversion function must be called to translate the value from the binding
 + object before it can be given to the base object.
 +
 + Notes:
 +  See `BindingFor` for an explanation of how `varName` works.
 +
 +  The `DataConverters` class holds several useful conversion functions.
 +
 +  See the `UIBaseBinding` struct as an example of how this UDA is used.
 +
 + Params:
 +  T   = The type that the conversion function will output. This type must be compatible (not neccessarily the same)
 +        as the type of the property that will be bound to.
 +  MyT = The type of the binding field.
 + ++/
struct ConverterBindingFor(T, MyTT)
{
    ///
    alias MyT = MyTT;
    
    ///
    alias ValueT = T;

    /// The name of the property to bind to.
    string varName;

    /// The conversion function.
    ValueT function(MyT) converter;
}

/// A binding that is used for all classes that inherit from `UIBase`.
@DataBinding
struct UIBaseBinding
{
    @BindingFor("name")
    Nullable!string name;

    @BindingFor("isVisible")
    Nullable!bool isVisible;

    @ConverterBindingFor!(RectangleF, float[4])("margin", &DataConverters.staticArrayToRect!float)
    Nullable!(float[4]) margin;

    @ConverterBindingFor!(vec2, float[2])("size", &DataConverters.staticArrayToVect!(float, 2, NegativeAsNaN.yes))
    Nullable!(float[2]) size;
    
    @ConverterBindingFor!(HorizontalAlignment, string)("horizAlignment", &DataConverters.stringToEnum!HorizontalAlignment)
    Nullable!string horizAlignment;

    @ConverterBindingFor!(VerticalAlignment, string)("vertAlignment", &DataConverters.stringToEnum!VerticalAlignment)
    Nullable!string vertAlignment;
}

/// A binding that is used for the `RectangleShape` class, which is commonly used as a primitive part of UI objects.
@DataBinding
struct RectangleShapeBinding
{
    @BindingFor("borderSize")
    Nullable!uint borderSize;

    @ConverterBindingFor!(Colour, string)("borderColour", &DataConverters.stringToColour)
    Nullable!string borderColour;

    @ConverterBindingFor!(Colour, string)("colour", &DataConverters.stringToColour)
    Nullable!string colour;
}

@DataBinding
struct TextBinding
{
    @BindingFor("charSize")
    Nullable!uint charSize;

    @ConverterBindingFor!(Colour, string)("colour", &DataConverters.stringToColour)
    Nullable!string colour;

    @BindingFor("text")
    Nullable!string text;

    @ConverterBindingFor!(Font, string)("font", &DataConverters.stringToFont)
    Nullable!string font;
}

template ColourBinding(string varName)
{
    @DataBinding
    struct ColourBinding
    {
        @ConverterBindingFor!(Colour, string)(varName, &DataConverters.stringToColour)
        mixin("Nullable!string "~varName~";");
    }
}

/++
 + This class provides the functionality of the data binding system.
 +
 + Please refer to the individual functions, as there is too much to document in this description.
 + ++/
static abstract class DataBinder
{
    private static
    {
        alias ParserFunc = UIBase delegate(UIBase, ArchiveObject);
        alias MakerFunc  = UIBase delegate();

        struct BindingInfo
        {
            ParserFunc parser;
            MakerFunc  factory;
        }

        ArchiveObject[string] _templates; // Key is template name.
        BindingInfo[string]   _classInfo; // Key is whatever getFieldName returns for each class.
    }

    public static
    {
        /++
         + Registers the given class with the data binding system.
         +
         + Notes:
         +  The information for the class is stored with the return value of `getFieldName` as the key.
         +  Please refer to it's documentation, as it's used in several other places.
         +
         +  Once a class has been registered, then `parseUIObject` and `parseUIObjectGeneric` will be configured
         +  to parse any `ArchiveObject`s of it correctly (given they're formatting correctly).
         +
         + How_It_Works:
         +  All `@UsesBinding` UDAs are gathered for `C`, as well as for all of it's base classes (so the UDAs are inherited).
         +
         +  When parsing an ArchiveObject (we'll refer to as 'root'), several steps happen.
         +
         +  First, it goes over every `@UsesBinding` UDA. If there is a specific target to the binding, then
         +  it's `getFieldName` value is retrieved which is then used to get a child object of the root with the same name.
         +  That object (assuming it exists) is then used as the root until the binding has been parsed (then it goes back to the original root).
         +
         +  After it's determined the root for the target, it will call `Serialiser.deserialise` for the type specifed by the current
         +  `@UsesBinding` UDA, with the determined root as the parameter given to it.
         +
         +  Afterwards, it will then make a call to `DataBinder.copyValues`, with the base object being the target, and the
         +  binding object being the binding that was just parsed.
         +
         +  This is then repeated for all `@UsesBinding` UDAs, and the end result is that all of the bindings have been read in,
         +  and the values have been copied over.
         +
         +  Finally, `parseUIObject` is called on the original root, to read in all of the children.
         +
         + Params:
         +  C = The class to register.
         + ++/
        void registerClass(C : UIBase)()
        {
            assert((getFieldName!C in DataBinder._classInfo) is null, 
                   "This class (or one sharing the same name) has been registered already: " ~ getFieldName!C);

            BindingInfo info;
            info.parser     = DataBinder.generateParserFor!C;
            info.factory    = DataBinder.generateFactoryFor!C;
            
            DataBinder._classInfo[getFieldName!C] = info;
        }

        /++
         + Parses the given `obj` as a specific class.
         +
         + Notes:
         +  If `C` hasn't been registered yet, `null` is returned.
         +
         +  The function `enforceAllChildrenUsed` will be used on the obj, and all of it's children.
         +  This will prevent a user from writing a typo or leaving some old features in the original
         +  archive that `obj` came from.
         +
         + Params:
         +  obj = The object to parse.
         + 
         + Returns:
         +  Either `null`, or the parsed object.
         + ++/
        C parseUIObject(C : UIBase)(ArchiveObject obj)
        {
            auto ptr = (getFieldName!C in DataBinder._classInfo);
            if(ptr is null)
                return null;

            return cast(C)ptr.parser(ptr.factory(), obj, null);
        }

        /++
         + A more generic, but probably more useful version of `parseUIObject`.
         +
         + How_It_Works:
         +  It will go over all of the child objects, and for any object that has the same name
         +  as a registered class (the same name from `getFieldName`), then it will proceed to
         +  parse in that object (And all of it's children).
         +
         + Returns:
         +  The parsed in objects.
         + ++/
        UIBase[] parseUIObjectGeneric(ArchiveObject obj)
        {
            UIBase[] values;
            foreach(child; obj.children)
            {
                import std.stdio;
                writeln(child.name, " ", DataBinder._classInfo.byKey);

                auto ptr = (child.name in DataBinder._classInfo);
                if(ptr is null)
                    continue;
                
                values ~= ptr.parser(ptr.factory(), child);
            }

            return values;
        }

        /++
         + Copies the values from a binding into a base object.
         +
         + Direct_Binding:
         +  With direct bindings (See `@BindingFor`) the assignment is simply
         +  `base.someProperty = binding.someValue`. Of course, the 'someProperty' variable
         +  is the `varName` field defined in `@BindingFor`.
         +
         +  There is special support for when 'someProperty' is a `Property` object.
         +
         + Conversion_Binding:
         +  With conversion bindings (See `@ConverterBindingFor`) the assignment is almost the same as with Direct Bindings,
         +  except that `binding.someValue` is first passed to the converter function specified in the `ConverterBindingFor` UDA,
         +  and the result of that convert function is then assigned to the base object's property.
         + ++/
        void copyValues(BaseT, BindingT)(auto ref BaseT base, auto ref BindingT binding)
        {
            static assert(hasUDA!(BindingT, DataBinding), 
                BindingT.stringof~" requires the @DataBinding UDA before it can be used as a binding. "
               ~"While there is no practical reason for this as of now, it does make it clear what the purpose of the type is."
            );

            static foreach(symbol; getSymbolsByUDA!(BindingT, BindingFor))
            {{
                enum UDAs = getUDAs!(symbol, BindingFor);
                static assert(UDAs.length == 1, "Only *one* @BindingFor may be attached to "~symbol.stringof);
                // TODO: Fix for properties
                //alias SetterSymbol = getSymbolByName!(BaseT, UDAs[0].varName); // This is here just to check the symbol exists.
                const SymbolName = __traits(identifier, symbol);

                static if(isInstanceOf!(Property, BaseT))
                    const BaseAccessor = "value."~UDAs[0].varName;
                else
                    const BaseAccessor = UDAs[0].varName;

                static if(isInstanceOf!(Nullable, typeof(mixin("BindingT."~SymbolName))))
                {
                    const SetterCode =
                        "if(!binding."~SymbolName~".isNull)"
                       ~"   base."~BaseAccessor~" = binding."~SymbolName;
                }
                else
                    const SetterCode = "base."~BaseAccessor~" = binding."~SymbolName;

                static assert(is(typeof(mixin(SetterCode)))
                           || is(typeof({mixin(SetterCode~";");})),
                           "Cannot use setter "~BaseT.stringof~"."~BaseAccessor~" with binding value "~BindingT.stringof~"."~SymbolName
                );

                mixin(SetterCode~";");
            }}

            // Search for converter bindings
            foreach(symbolName; __traits(allMembers, BindingT))
            {
                foreach(attrib; __traits(getAttributes, getSymbolByName!(BindingT, symbolName)))
                {
                    static if(isInstanceOf!(ConverterBindingFor, typeof(attrib)))
                    {
                        static if(isInstanceOf!(Nullable, mixin("typeof(BindingT."~symbolName~")")))
                            if(mixin("binding."~symbolName~".isNull"))
                                continue;

                        static if(isInstanceOf!(Property, BaseT))
                            const Accessor = "value."~attrib.varName;
                        else
                            const Accessor = attrib.varName;

                        // TODO: Fix for properties
                        //alias SetterSymbol = getSymbolByName!(BaseT, attrib.varName); // This is here just to check the symbol exists.
                        const SetterCode   = "base."~Accessor~" = value";

                        auto value = attrib.converter(mixin("binding."~symbolName));
                        
                        static assert(is(typeof(mixin(SetterCode))),
                            "Unable to use "~BaseT.stringof~"."~attrib.varName~" as a setter for the converted value of "~BindingT.stringof~"."~symbolName
                        );

                        mixin(SetterCode~";");
                    }
                }
            }
        }
        ///
        unittest
        {
            import jarena.maths, jarena.gameplay;
            import fluent.asserts;

            @DataBinding
            static struct CBinding
            {
                @BindingFor("muhName")
                string name;
                
                @ConverterBindingFor!(RectangleI, int[4])("rect", &DataConverters.staticArrayToRect!int)
                int[4] rect;
            }

            static class C
            {
                private string _name;
                Property!RectangleI rect;

                this()
                {
                    this.rect = new Property!RectangleI();
                }

                public void muhName(string str)
                {
                    this._name = str;
                }

                public string muhName()
                {
                    return this._name;
                }
            }

            auto c = new C();
            auto b = CBinding("Hello!", [1, 2, 3, 4]);

            DataBinder.copyValues(c, b);

            c.muhName.should.equal("Hello!");
            c.rect.value.should.equal(RectangleI(1, 2, 3, 4));
        }

        /++
         + Registers a template.
         +
         + Format:
         +  The given `obj`'s name will be used as the templates name.
         +
         +  The `obj` must have a single child, which will be the same object one would
         +  pass to `parseUIObject`.
         +
         + Params:
         +  obj = The object that serves as the template.
         + ++/
        void addTemplate(ArchiveObject obj)
        {
            assert(obj !is null);
            enforceAndLogf((obj.name in DataBinder._templates) is null, "The template '%s' already exists.", obj.name);
            enforceAndLogf(obj.children.length == 1, "The template '%s' requires having *only* one child in it's root.", obj.name);

            DataBinder._templates[obj.name] = obj.children[0];
        }

        /++
         + Creates a new instance of a registered template.
         +
         + Params:
         +  C         = The class to cast the result to.
         +  override_ = An object (formatted the same as an object passed to `parseUIObject`) which will
         +              override the values of the template.
         +
         + Returns:
         +  Either the new instance of the template, or `null` if the cast to `C` fails.
         + ++/
        C factoryTemplate(C : UIBase = UIBase)(ArchiveObject override_ = null)
        {
            enforceAndLogf(DataBinder.canFindTemplate(override_.name), "Template '%s' could not be created as it doesn't exist.", override_.name);
            enforceAndLogf((DataBinder._templates[override_.name].name in DataBinder._templates) is null,
                "Template '%s' could not be created as it is a template of non-existant control '%s'."
               ~" Do note that currently, creating a template of a template is not supported, if that is the current case.",
               override_.name, DataBinder._templates[override_.name].name
            );

            auto info = DataBinder._classInfo[DataBinder._templates[override_.name].name];
            auto obj  = info.factory();
            info.parser(obj, DataBinder._templates[override_.name]); // Template
            if(override_ !is null)
                info.parser(obj, override_); // Override
            return cast(C)obj;
        }

        /// ditto
        C factoryTemplate(C : UIBase = UIBase)(string templateName)
        {
            return factoryTemplate!C(new ArchiveObject(templateName));
        }

        /// Returns: Whether a template called `templateName` exists.
        bool canFindTemplate(string templateName)
        {
            return (templateName in DataBinder._templates) !is null;
        }
    }

    // ###################
    // # GENERATION CODE #
    // ###################
    private static
    {
        MakerFunc generateFactoryFor(C : UIBase)()
        {
            return () {
                return new C();
            };
        }

        ParserFunc generateParserFor(C : UIBase)()
        {
            import std.meta      : Filter;
            import std.algorithm : endsWith;
            return (UIBase val, ArchiveObject obj)
            {
                auto value = cast(C)val;
                assert(value !is null);
                ArchiveObject[] usedForRoot;

                static foreach(base; AliasSeq!(C, BaseClassesTuple!C))
                static foreach(attrib; __traits(getAttributes, base))
                {{
                    static if(isInstanceOf!(UsesBinding, attrib))
                    {
                        static assert(hasUDA!(attrib.BindT, DataBinding), 
                            attrib.BindT.stringof~" requires the @DataBinding UDA before it can be used as a binding. "
                           ~"While there is no practical reason for this as of now, it does make it clear what the purpose of the type is."
                        );

                        static if(is(attrib.Target == NO_TARGET))
                        {
                            const ValueAccessor = "value";
                            const ObjAccessor   = "obj";
                            const Condition     = "true";
                        }
                        else
                        {
                            const ValueAccessor = "value."~__traits(identifier, attrib.Target);
                            const ObjAccessor   = "obj.expectChild(\""~getFieldName!(attrib.Target)~"\")";
                            const Condition     = "obj.getChild(\""~getFieldName!(attrib.Target)~"\") !is null";
                        }

                        if(mixin(Condition))
                        {
                            UsedObjectsT used;
                            auto root             = mixin(ObjAccessor);
                            auto oldName          = root.name;
                            root.name             = getFieldName!(attrib.BindT);
                            scope(exit) root.name = oldName;
                            usedForRoot          ~= root;
                            attrib.BindT binding  = Serialiser.deserialise!(attrib.BindT)(root, used);

                            // Check for disabled bindings.
                            static foreach(attribDisabled; __traits(getAttributes, base))
                            {{
                                static if(isInstanceOf!(DisableBinding, attribDisabled) 
                                       && attribDisabled.TargetField == __traits(identifier, attrib.Target))
                                {
                                    enforceAndLogf(
                                        mixin("binding."~__traits(identifier, attribDisabled.BindingField)~".isNull"),
                                        attribDisabled.Reason
                                    );
                                }
                            }}

                            DataBinder.copyValues(mixin(ValueAccessor), binding);

                            // If there was a specific target, then we should make sure that all of it's objects were used.
                            static if(!is(attrib.Target == NO_TARGET))
                                enforceAllChildrenUsed(used);
                            else // Otherwise merge it into the used objects for this object.
                            {
                                auto ptr = (obj in used);
                                if(ptr !is null)
                                {
                                    foreach(usedChild; *ptr)
                                        usedForRoot ~= usedChild;
                                }
                            }
                        }
                    }
                }}

                // Look for children that are actually other UI elements/templates
                foreach(child; obj.children)
                {
                    if(DataBinder.canFindTemplate(child.name))
                    {
                        value.addChild(DataBinder.factoryTemplate(child));
                        usedForRoot ~= child;
                    }
                    else
                    {
                        auto ptr = (child.name in DataBinder._classInfo);
                        if(ptr is null)
                            continue;

                        usedForRoot ~= child;
                        value.addChild(ptr.parser(ptr.factory(), child));
                    }
                }

                enforceAllChildrenUsed([obj: usedForRoot]);

                return value;
            };
        }
    }
}

/++
 + A collection of useful data converters.
 + ++/
static abstract class DataConverters
{
    public static
    {
        ///
        Rectangle!T staticArrayToRect(T)(T[4] values)
        {
            return Rectangle!T(values[0], values[1], values[2], values[3]);
        }

        ///
        Vector!(T, N) staticArrayToVect(T, size_t N, NegativeAsNaN DoNaN = NegativeAsNaN.no)(T[N] values)
        {
            typeof(return) vect;
            static if(DoNaN && isFloatingPoint!T)
                foreach(i; 0..N)
                {
                    auto val = values[i];
                    if(val < 0) val = T.nan;
                    vect.components[i] = val;
                }
            else
                vect.components = values;

            return vect;
        }

        ///
        E stringToEnum(E)(string value)
        {
            import std.conv : to;
            return value.to!E;
        }

        ///
        Colour stringToColour(string value)
        {
            // See if it's in the Colours class.
            auto ptr = (value in Colours.colours);
            if(ptr !is null)
                return *ptr;

            // Otherwise try to parse it with the Colour struct
            return Colour.fromString(value);
        }

        ///
        string toString(T)(T value)
        {
            import std.conv : to;
            return value.to!string;
        }

        ///
        Font stringToFont(string value)
        {
            return Systems.assets.get!Font(value);
        }
    }
}