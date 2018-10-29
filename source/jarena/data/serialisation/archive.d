/// Contains everything regarding archives.
module jarena.data.serialisation.archive;

private
{
    import std.algorithm    : countUntil;
    import std.exception    : enforce;
    import std.format       : format;
    import std.variant      : Algebraic, This;
    import std.traits       : isNumeric, allSameType;
}

/// An `Algebraic` which determines the types of data that archives can work with.
alias ArchiveValue = Algebraic!
(
    bool,  typeof(null), ubyte[], This[], // Special
    byte,  short,        int,     long,   // Signed
    ubyte, ushort,       uint,    ulong,  // Unsigned
    string,                               // Text
    float, double                         // Floating point
);

/++
 + The base class for an archive.
 +
 + Details:
 +  An archive can be seen as a serialiser/deserialiser for `ArchiveObject`s.
 +
 +  Essentially, this class is used to provide the ability to write and read objects into/from a certain format,
 +  e.g. SDLang, XML, $(I ini) maybe(if you try hard enough), and custom binary formats.
 +
 +  The reason that archives exists is primarily so only one serialiser/deserialiser for more complex types (structs/classes) has to be
 +  written, as `ArchiveObject` is flexible enough to represent mostly everything you'd need to, it is then up to the `Archive` to provide
 +  the actual format to store it in.
 +
 +  For example, the serialiser/deserialiser provided by default could be used to serialise/deserialise to SDLang, XML, binary, etc. without any
 +  extra effort, since all of those details are left up to the `Archive`, all the serialiser has to do is modify the archive's `Archive.root` to
 +  what it wants.
 + ++/
abstract class Archive
{
    public abstract
    {
        /++
         + Saves the data in `Archive.root` into memory.
         +
         + Notes:
         +  Since not all archives may use text, but instead binary, no assumptions can be made so
         +  the return type is a ubyte[].
         +
         +  See the helper function `saveToMemoryText` for an easy way to get this data as text.
         +
         + Returns:
         +  The data a byte array.
         + ++/
        const(ubyte[]) saveToMemory();

        /++
         + Loads the given data and modifies `Archive.root` to represent this data.
         +
         + Params:
         +  data = The data to load.
         + ++/
        void loadFromMemory(const ubyte[] data);

        /++
         + The root of the archive's data.
         +
         + Notes:
         +  When saving, this is the object that is used as the root of tha data.
         +
         +  When loading, this is the object that is the root of the data.
         +
         + Returns:
         +  The root of the archive's data.
         + ++/
        @property
        ArchiveObject root();
    }

    // ####################################
    // # HELPER FUNCS. CAN BE OVERRIDDEN. #
    // ####################################
    public
    {
        /++
         + A helpful alternative to `saveToMemory`, where the data
         + is casted to a `const(char[])`, then passed to `std.utf.validate`,
         + before being returned.
         +
         + Returns:
         +  The archive's data, validated as valid UTF-8 text.
         + ++/
        const(char[]) saveToMemoryText()
        {
            import std.utf : validate;
            auto data = cast(const(char[]))this.saveToMemory();
            data.validate();

            return data;
        }

        /++
         + Saves the archive's data to a file.
         +
         + Params:
         +  path = The path to save to.
         + ++/
        void saveToFile(in char[] path)
        {
            import std.file : write;

            write(path, this.saveToMemory());
        }

        /++
         + Loads the archive's data from a file.
         +
         + Params:
         +  path = The path to load from.
         + ++/
        void loadFromFile(in char[] path)
        {
            import std.file : read;

            return this.loadFromMemory(cast(ubyte[])read(path));
        }
    }
}

/++
 + This class contains the data about an object in the archive.
 +
 + Design:
 +  This class is modeled after sdlang-d, which feels mostly natural and comfortable to work with.
 +
 +  This class should be able to represent most kinds of objects, but will undoubtably be unsuitable for some.
 +
 + Values:
 +  These are `ArchiveValues` that are directly attached to the object.
 +
 + Attributes:
 +  These are named `ArchiveValues` that describe certain features of the object(e.g 'IsHidden=true', 'IsDirectory=false').
 +  (You can of course, use your own meaning for these).
 +
 + Children:
 +  These are `ArchiveObjects` that are children of the current object.
 +
 +  For example, there's the `Archive.root` object which is the root of all of the archive's data,
 +  and then children would be used to describe more complex objects from the root.
 +
 + Issues:
 +  There is currently no tracking of parentship of objects, so it's possible to have circular
 +  references.
 + ++/
class ArchiveObject
{
    /// Describes an attribute.
    struct Attribute
    {
        /// The name of the attribute.
        string name;

        /// The value of the attribute.
        ArchiveValue value;
    }

    // #####################################
    // # CTOR, PUBLIC VARS, AND PROPERTIES # 
    // #####################################
    public final
    {
        /// The name of this object.
        string          name;

        /// The attributes of this object.
        Attribute[]     attributes;

        /// The values of this object.
        ArchiveValue[]  values;
        
        /// The children of this object.
        ArchiveObject[] children;

        /++
         + Params:
         +  name = The name of this object.
         + ++/
        this(string name = null)
        {
            this.name = name;
        }
    }

    // ##############################
    // # CAN BE OVERIDDEN IF NEEDED #
    // ##############################
    public
    {
        /++
         + Sets/Creates an attribute's value.
         +
         + Params:
         +  name   = The name of the attribute.
         +  attrib = The value of the attribute.
         + ++/
        void setAttribute(string name, ArchiveValue attrib)
        {
            auto index = this.attributes.countUntil!"a.name == b"(name);

            if(index == -1)
                this.attributes ~= Attribute(name, attrib);
            else
                this.attributes[index].value = attrib;
        }

        /++
         + Adds a value to this object.
         + 
         + Params:
         +  value = The value to add.
         + ++/
        void addValue(ArchiveValue value)
        {
            this.values ~= value;
        }

        /++
         + Adds a child to this object, it's `ArchiveObject.name` can be used
         + to retrieve it from `ArchiveObject.getChild`.
         +
         + Notes:
         +  While multiple children with the same name can be added,
         +  only the first one with the given `ArchiveObject.name` will be used
         +  via `ArchiveObject.getChild`.
         +
         + Params:
         +  child = The object to add as a child.
         + ++/
        void addChild(ArchiveObject child)
        {
            assert(child !is null, "The child cannot be null");
            this.children ~= child;
        }

        /++
         + Gets an attribute by name.
         +
         + Params:
         +  name     = The name of the attribute.
         +  default_ = The value to return if no attribute with `name` exists.
         +
         + Returns:
         +  Either the attribute called `name`, or `default_`.
         + ++/
        ArchiveValue getAttribute(string name, lazy ArchiveValue default_ = ArchiveValue.init)
        {
            auto index = this.attributes.countUntil!"a.name == b"(name);
            return (index == -1) ? default_ : this.attributes[index].value;
        }

        /++
         + Gets a value by it's index.
         +
         + Params:
         +  index    = The index of the value to get.
         +  default_ = The value to return if the index is out of bounds.
         +
         + Returns:
         +  Either the value at `index`, or `default_` if `index` is out of bounds.
         + ++/
        ArchiveValue getValue(size_t index, lazy ArchiveValue default_ = ArchiveValue.init)
        {
            return (index >= this.values.length) ? default_ : this.values[index];
        }

        /++
         + Gets an child by name.
         +
         + Notes:
         +  While multiple children with the same name can be added,
         +  only the first one with the given `ArchiveObject.name` will be used
         +  via `ArchiveObject.getChild`.
         +
         + Params:
         +  name     = The name of the child.
         +  default_ = The value to return if no child with `name` exists.
         +
         + Returns:
         +  Either the child called `name`, or `default_`.
         + ++/
        ArchiveObject getChild(string name, lazy ArchiveObject default_ = null)
        {
            auto index = this.children.countUntil!"a.name == b"(name);
            return (index == -1) ? default_ : this.children[index];
        }
    }

    // ####################
    // # HELPER FUNCTIONS #
    // ####################
    public final
    {
        /++
         + Helper function to add multiple `ArchiveValue`s.
         + ++/
        void addValues(ArchiveValue[] values)
        {
            foreach(value; values)
                this.addValue(value);
        }

        /++
         + Helper function to set an attribute without having to create an `ArchiveValue`.
         + ++/
        void setAttributeAs(T)(string name, T attrib)
        if(ArchiveValue.allowed!T && !is(T == ArchiveValue))
        {
            this.setAttribute(name, ArchiveValue(attrib));
        }

        /++
         + Helper function to add a Value without having to create an `ArchiveValue`.
         + ++/
        void addValueAs(T)(T value)
        if(ArchiveValue.allowed!T && !is(T == ArchiveValue))
        {
            this.addValue(ArchiveValue(value));
        }

        /++
         + Helper function to get an attribute/value as a certain type.
         +
         + Notes:
         +  Other than making it easier to transform the `ArchiveValue` into the given type,
         +  this function performs an extra step.
         +
         +  Imagine if the value has a type of `ubyte`, but you want it as a `uint`.
         +
         +  Doing `getAttribute("blah").get!uint` would actually give you an error.
         +
         +  This function will automatically use the `coerce` function to make sure you'll
         +  get a `uint` even if the type stored is a `ubyte`.
         + ++/
        T getAttributeAs(T)(string name, lazy T default_ = T.init)
        {
            return this.convertFromValue!T(this.getAttribute(name, ArchiveValue.init), default_);
        }

        /// ditto
        T getValueAs(T)(size_t index, lazy T default_ = T.init)
        {
            return this.convertFromValue!T(this.getValue(index, ArchiveValue.init), default_);
        }

        /++
         + Helper function to get a child, or throw an exception if the child doesn't exist.
         +
         + Params:
         +  name = The name of the child to get.
         +
         + Returns:
         +  The child.
         + ++/
        ArchiveObject expectChild(string name)
        {
            auto obj = this.getChild(name, null);
            enforce(obj !is null, "The object '" ~ name ~ "' doesn't exist.");

            return obj;
        }

        /++
         + Helper function to get a attribute, or throw an exception if the attribute doesn't exist.
         +
         + Params:
         +  name = The name of the attribute to get.
         +
         + Returns:
         +  The attribute.
         + ++/
        ArchiveValue expectAttribute(string name)
        {
            auto attrib = this.getAttribute(name, ArchiveValue.init);
            enforce(attrib != ArchiveValue.init, "The attribute '" ~ name ~ "' doesn't exist.");

            return attrib;
        }

        /// ditto
        T expectAttributeAs(T)(string name)
        {
            return this.convertFromValue!T(this.expectAttribute(name), T.init);
        }

        /++
         + Helper function to get a value, or throw an exception if the value doesn't exist.
         +
         + Params:
         +  index = The index of the value to get.
         +
         + Returns:
         +  The value.
         + ++/
        ArchiveValue expectValue(size_t index)
        {
            auto value = this.getValue(index, ArchiveValue.init);
            enforce(value != ArchiveValue.init, "The value at index %s doesn't exist. Value count = %s".format(index, this.values.length));

            return value;
        }

        /// ditto
        T expectValueAs(T)(size_t index)
        {
            return this.convertFromValue!T(this.expectValue(index), T.init);
        }
    }

    // ######################
    // # OPERATOR OVERLOADS #
    // ######################
    public final
    {
        /// An operator version of `ArchiveObject.expectChild`.
        ArchiveObject opIndex(string childName)
        {
            return this.expectChild(childName);
        }
        ///
        unittest
        {
            auto obj = new ArchiveObject();
            obj.addChild(new ArchiveObject("Foo"));

            obj["Foo"].addValueAs!int(69);
            assert(obj["Foo"].getValueAs!int(0) == 69);
        }

        /// An operator version of `ArchiveObject.expectChild` that takes multiple child names.
        ArchiveObject opIndex(Names...)(Names childNames)
        if(Names.length > 0 && is(Names[0] : const(char)[]) && allSameType!Names)
        {
            auto obj = this;
            foreach(name; childNames)
                obj = obj[name];

            return obj;
        }
        ///
        unittest
        {
            auto obj = new ArchiveObject();
            obj.addChild(new ArchiveObject("Foo"));
            obj["Foo"].addChild(new ArchiveObject("Bar"));
            obj["Foo", "Bar"].addChild(new ArchiveObject("Baz"));
            obj["Foo", "Bar", "Baz"].addValueAs!int(69);

            assert(obj["Foo", "Bar", "Baz"].getValueAs!int(0) == 69);
        }
    }

    private
    {
        T convertFromValue(T)(ArchiveValue value, T default_)
        {
            static if(isNumeric!T)
                return (value == ArchiveValue.init) ? default_ : value.coerce!T;
            else
                return (value == ArchiveValue.init) ? default_ : value.get!T; 
        }
    }
}