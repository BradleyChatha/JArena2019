module jarena.graphics.text;

private
{
    import std.experimental.logger;
    import derelict.sfml2.graphics, derelict.sfml2.system;
    import jarena.core, jarena.graphics;
}

class Font
{
    private
    {
        sfFont* _handle;
    }

    public
    {
        ///
        @trusted
        this(string fontPath)
        {
            import std.string : toStringz;
            import std.exception : enforce;
            
            tracef("Loading font from path: '%s'", fontPath);
            
            this._handle = sfFont_createFromFile(fontPath.toStringz);
            enforce(this._handle !is null, new Exception("Unable to load font"));
        }

        ~this()
        {
            if(this._handle !is null)
            {
                sfFont_destroy(this.handle);
                this._handle = null;
            }
        }

        ///
        @property @safe @nogc
        inout(sfFont*) handle() nothrow inout
        {
            assert(this._handle !is null);
            return this._handle;
        }
    }
}

///
class Text
{
    private
    {
        Font _font;
        sfText* _handle;

        dchar[] _unicodeBuffer;
        char[]  _asciiBuffer;

        this(Font font, vec2 position, uint charSize, uvec4b colour)
        {
            assert(font !is null);
            this._font = font;
            this._handle = sfText_create();
            assert(this._handle !is null);

            sfText_setFont(this.handle, font.handle);
            this.charSize = charSize;
            this.colour = colour;
            this.position = position;
        }
    }

    public
    {
        ///
        this(Font font, const(dchar[]) text, vec2 position = vec2(0), uint charSize = 14, uvec4b colour = jarena.core.colour(0, 0, 0, 255))
        {
            this(font, position, charSize, colour);
            this.unicodeText = text;
        }

        ///
        this(Font font, const(char[]) text, vec2 postion = vec2(0), uint charSize = 14, uvec4b colour = jarena.core.colour(0, 0, 0, 255))
        {
            this(font, position, charSize, colour);
            this.asciiText = text;
        }

        ~this()
        {
            if(this._handle !is null)
            {
                sfText_destroy(this.handle);
                this._handle = null;
            }
        }

        ///
        @property @trusted @nogc
        const(vec2) position() nothrow const
        {
            return sfText_getPosition(this.handle).to!vec2;
        }

        ///
        @property @trusted @nogc
        void position(vec2 pos) nothrow
        {
            sfText_setPosition(this.handle, pos.toSF!sfVector2f);
        }
        
        ///
        @property @trusted @nogc
        uint charSize() nothrow const
        {
            return sfText_getCharacterSize(this.handle);
        }

        ///
        @property @trusted @nogc
        void charSize(uint size) nothrow
        {
            sfText_setCharacterSize(this.handle, size);
        }

        ///
        @property @trusted @nogc
        const(uvec4b) colour() nothrow const
        {
            return sfText_getColor(this.handle).to!uvec4b;
        }

        ///
        @property @trusted @nogc
        void colour(uvec4b col) nothrow
        {
            sfText_setColor(this.handle, col.toSF!sfColor);
        }

        ///
        @property @safe @nogc
        const(dchar[]) unicodeText() nothrow const
        {
            return this._unicodeBuffer;
        }

        ///
        @property @trusted
        void unicodeText(const(dchar[]) text) nothrow
        {
            this._unicodeBuffer.length = text.length + 1;
            this._unicodeBuffer[0..$-1] = text[];
            this._unicodeBuffer[$-1] = '\0';
            sfText_setUnicodeString(this.handle, this._unicodeBuffer.ptr); // This *does* copy the data... right?
        }        

        ///
        @property @safe @nogc
        const(char[]) asciiText() nothrow const
        {
            return this._asciiBuffer;
        }

        ///
        @property @trusted
        void asciiText(const(char[]) text) nothrow
        {
            this._asciiBuffer.length = text.length + 1;
            this._asciiBuffer[0..$-1] = text[];
            this._asciiBuffer[$-1] = '\0';
            sfText_setString(this.handle, this._asciiBuffer.ptr); // This *does* copy the data... right?
        }        

        ///
        @property @safe @nogc
        inout(sfText*) handle() nothrow inout
        {
            assert(this._handle !is null);
            return this._handle;
        }
    }
}