/// Contains an archive for SDLang.
module jarena.data.serialisation.sdlang;

private
{
    import std.algorithm, std.format, std.exception, std.traits, std.utf;
    import sdlang;
    import jarena.data.serialisation.archive;
}

/// An `Archive` for SDLang.
class ArchiveSDL : Archive
{
    private
    {
        ArchiveObject _root;
    }

    public
    {
        void loadFromTag(Tag tag)
        {
            this._root = this.tagToObject(tag);
        }
    }

    public override
    {
        const(ubyte[]) saveToMemory()
        {
            return cast(const(ubyte[]))this.objectToTag(this.root).toSDLDocument();
        }

        void loadFromMemory(const ubyte[] data)
        {
            auto text = cast(string)data.idup;
            validate(text);

            auto tag = parseSource(text);
            this._root = this.tagToObject(tag);
        }

        @property
        ArchiveObject root()
        {
            if(this._root is null)
                this._root = new ArchiveObject();

            return this._root;
        }
    }

    // ###########
    // # UTILITY #
    // ###########
    private
    {
        ArchiveObject tagToObject(Tag tag)
        {
            auto object = new ArchiveObject(tag.getFullName().toString);

            foreach(value; tag.values)
                object.addValues(this.sdlToArchive(value));

            foreach(attrib; tag.attributes)
                object.setAttribute(attrib.name, this.sdlToArchive(attrib.value)[0]);

            foreach(child; tag.all.tags)
                object.addChild(this.tagToObject(child));

            return object;
        }

        ArchiveValue[] sdlToArchive(Value value)
        {
            ArchiveValue[] data;

            static foreach(type; Value.AllowedTypes)
            {
                if(value.type == typeid(type))
                {
                    static if(
                              (isNumeric!type && !is(type == real)) 
                           || is(type == ubyte[]) 
                           || is(type == bool) 
                           || is(type == typeof(null)) 
                           || is(type == string))
                        data ~= ArchiveValue(value.get!type);
                    else static if(is(type == Value[]))
                    {
                        foreach(v; value.get!(Value[]))
                            data ~= sdlToArchive(v);
                    }
                    else enforce(false, "Unsupported type: " ~ type.stringof);
                }
            }

            return data;
        }

        Tag objectToTag(ArchiveObject object)
        {
            Tag tag = new Tag();
            tag.name = object.name;

            foreach(value; object.values)
                tag.add(this.archiveToSdl(value));

            foreach(attrib; object.attributes)
            {
                auto values = this.archiveToSdl(attrib.value);
                
                enforce(values.length == 1, "Attributes cannot be arrays.");
                tag.add(new Attribute(attrib.name, values[0]));
            }

            foreach(child; object.children)
                tag.add(this.objectToTag(child));

            return tag;
        }

        Value[] archiveToSdl(ArchiveValue value)
        {
            Value[] data;

            static foreach(type; ArchiveValue.AllowedTypes)
            {
                if(value.type == typeid(type))
                {
                    static if(isNumeric!type && !isFloatingPoint!type)
                        data ~= Value(value.coerce!long);
                    else static if(isNumeric!type && isFloatingPoint!type)
                        data ~= Value(value.coerce!double);
                    else static if(is(type == ubyte[]) || is(type == bool) || is(type == typeof(null)) || is(type == string))
                        data ~= Value(value.get!type);
                    else static if(is(type == ArchiveValue[]))
                    {
                        foreach(v; value.get!(ArchiveValue[]))
                            data ~= archiveToSdl(v);
                    }
                    else static assert(false, "Unsupported type: " ~ type.stringof);
                }
            }

            return data;
        }
    }
}