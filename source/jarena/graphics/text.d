module jarena.graphics.text;

private
{
    import std.experimental.logger;
    import derelict.sfml2.graphics, derelict.sfml2.system;
    import jarena.core, jarena.graphics, jarena.gameplay;
}

///
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

        @trusted
        this(Font font, vec2 position, uint charSize, Colour colour)
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
        @trusted
        this(Font font, const(dchar[]) text, vec2 position = vec2(0), uint charSize = 14, Colour colour = Colour.black)
        {
            this(font, position, charSize, colour);
            this.unicodeText = text;
        }

        ///
        @trusted
        this(Font font, const(char[]) text, vec2 position = vec2(0), uint charSize = 14, Colour colour = Colour.black)
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
        float outlineThickness() nothrow const
        {
            return sfText_getOutlineThickness(this.handle);
        }

        ///
        @property @trusted @nogc
        void outlineThickness(float thicc) nothrow
        {
            sfText_setOutlineThickness(this.handle, thicc);
        }

        /// Returns: The size of the text on screen.
        @property @trusted @nogc
        const(vec2) screenSize() nothrow const
        {
            auto rect = sfText_getLocalBounds(this.handle);
            return vec2(rect.width, rect.height);
        }

        ///
        @property @trusted @nogc
        const(Colour) colour() nothrow const
        {
            return sfText_getColor(this.handle).to!Colour;
        }

        ///
        @property @trusted @nogc
        void colour(Colour col) nothrow
        {
            sfText_setColor(this.handle, col.toSF!sfColor);
        }

        ///
        @property @trusted @nogc
        const(Colour) outlineColour() nothrow const
        {
            return sfText_getOutlineColor(this.handle).to!Colour;
        }

        ///
        @property @trusted @nogc
        void outlineColour(Colour col) nothrow
        {
            sfText_setOutlineColor(this.handle, col.toSF!sfColor);
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
            this._asciiBuffer.length = 0;

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
            this._unicodeBuffer.length = 0;

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

/++
 + A simple object that does nothing other than draw text.
 +
 + This class is `alias this`ed to it's `Text`, to make it work exactly like a normal sprite.
 + ++/
class TextObject : DrawableObject
{
    alias text this;

    private
    {
        Text _text;
    }

    public
    {
        /++
         + Creates a new TextObject using a pre-made `Text`.
         +
         + Params:
         +  text = The Text to use.
         +  position = The position to set the text at.
         +  yLevel = The yLevel to use
         + ++/
        @safe
        this(Text text, int yLevel = 0)
        {
            assert(text !is null);
            this._text = text;
            this.yLevel = yLevel;
        }

        /++
         + A shortcut to create a new `Text` and assign it to this object.
         + ++/
        @safe
        this(Font font, 
             dstring uniText, 
             vec2 position = vec2(0), 
             uint charSize = 14, 
             Colour colour = Colour.black, 
             int yLevel = 0)
        {
            this(new Text(font, uniText, position, charSize, colour), yLevel);
        }

        /// The text for this TextOBject.
        @property
        Text text()
        {
            assert(this._text !is null, "The text hasn't been created yet.");
            return this._text;
        }
    }

    public override
    {
        ///
        void onUnregister(PostOffice office){}
        
        ///
        void onUpdate(Window window, GameTime deltaTime){}

        ///
        void onRegister(PostOffice office){}

        ///
        void onRender(Window window)
        {
            window.renderer.drawText(this.text);
        }
    }
}
