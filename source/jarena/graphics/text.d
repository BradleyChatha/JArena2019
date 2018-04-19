/++
 + Contains clases related to rendering text.
 + ++/
module jarena.graphics.text;

private
{
    import std.experimental.logger;
    import jarena.core, jarena.graphics, jarena.gameplay;
}

/++
 + Contains a font.
 +
 + Notes:
 +  It is $(B heavily) recommended that you properly reuse fonts, as each object
 +  can generate a lot of objects needed to help with rendering text.
 +  The more reuse, the less wasted GPU memory and RAM.
 +
 + Issues:
 +  Currently only a single texture atlas, which also has a fixed size, is generated
 +  per character size, so a size that is too large will mean that there isn't enough space
 +  in a single atlas to store the font, and since there's no support for multiple atlases (yet)
 +  it will cause either crashes or rendering issues.
 +
 +  Currently, only the first 128 characters (ASCII) (including invisible ones...) are generated
 +  for each character size, anything beyond that won't render/will crash the program.
 + ++/
class Font
{
    import derelict.freetype;

    private
    {
        // To make the code more clear
        alias CharSize = uint;
        alias CharCode = ulong;

        struct Glyph
        {
            RectangleI area; // Area in the texture atlas.
            ivec2 bearing;
            ivec2 advance;
        }
        
        struct CharSet
        {
            Glyph[CharCode] glyphs;
            MutableTexture  texture;
        }

        FT_Library        _ft;
        FT_Face           _font;
        CharSet[CharSize] _sets;

        // Generates the entire ASCII character set for a certain character size.
        void generateForSize(CharSize size)
        {
            import opengl;

            // TODO: Support for more than ASCII.
            assert((size in this._sets) is null, "Bug, this shouldn't have been called.");

            // FreeType gives us bitmaps, so we need to tell OpenGL that everything is 1 byte away from eachother.
            glPixelStorei(GL_UNPACK_ALIGNMENT, 1);


            FT_Set_Pixel_Sizes(this._font, 0, size);
            CharSet set;
            set.texture = new MutableTexture(uvec2(1024, 1024));
            foreach(code; 0..128)
            {
                // Load the glyph.
                auto errCode = FT_Load_Char(this._font, code, FT_LOAD_RENDER);
                if(errCode != 0)
                {
                    errorf("FreeType could not load the character for code %s. Error = %s", code, errCode);
                    continue;
                }

                // Stitch it into the character set's texture atlas.
                RectangleI area;
                auto mapSize = ivec2(this._font.glyph.bitmap.width, this._font.glyph.bitmap.rows);
                set.texture.stitch!GL_RED(this._font.glyph.bitmap.buffer[0..(mapSize.y * mapSize.x)],
                                          mapSize,
                                          area);

                // Then store the information about the glyph.
                set.glyphs[code] = Glyph(
                    area,
                    ivec2(this._font.glyph.bitmap_left, this._font.glyph.bitmap_top),
                    ivec2(this._font.glyph.advance.x, this._font.glyph.advance.y)
                );
            }
            glPixelStorei(GL_UNPACK_ALIGNMENT, 4); // So we don't mess up any other code, set the alignment back to default.
            this._sets[size] = set;
        }
        
        CharSet getSetForSize(CharSize size)
        {
            auto ptr = (size in this._sets);
            if(ptr is null)
            {
                this.generateForSize(size);
                assert((size in this._sets) !is null, "bug");
                return this._sets[size];
            }
            else
                return *ptr;
        }
    }

    public
    {
        /++
         + Create a new `Font` using the font file at the given path.
         +
         + Params:
         +  fontPath = The path to the font file to load.
         + ++/
        @trusted
        this(string fontPath)
        {
            import std.string : toStringz;
            import std.exception : enforce;
            import std.file : exists;
            
            tracef("Loading font from path: '%s'", fontPath);
            enforce(fontPath.exists, "The file doesn't exist: " ~ fontPath);
            
            // Load an instance of FT for this font.
            auto error = FT_Init_FreeType(&this._ft);
            fatalf(error != 0,
                "FreeType was unable to initialise. Error code = %s",
                error
            );

            // Create a face for it.
            error = FT_New_Face(this._ft, fontPath.toStringz, 0,  &this._font);
            fatalf(error != 0,
                "Failed to load font. Error code = %s",
                error
            );
        }

        /++
         + Dumps all of the texture atlases currently being used by this font.
         +
         + Only for debug use.
         + ++/
        void dumpAllTextures(string name)
        {
            import std.format : format;
            foreach(charSize, set; this._sets)
                set.texture.dump(format("%s_%s", name, charSize));
        }

        ~this()
        {
            FT_Done_Face(this._font);
            FT_Done_FreeType(this._ft);
            this._sets = null;
        }
    }
}

/++
 + A class which is used to create renderable text.
 +
 + Issues:
 +  In some cases, whenever the text object's position is changed, rendering of the text
 +  becomes slightly messed up.
 + ++/
class Text : ITransformable
{
    private
    {
        Font          _font;
        const(char)[] _text;
        Transform     _transform;
        uint          _charSize;
        Buffer!Vertex _verts;
        Buffer!Vertex _transformed;
        vec2          _size;
        Colour        _colour;

        @trusted
        this(Font font, vec2 position, uint charSize, Colour colour)
        {
            assert(font !is null);
            this._transformed = new Buffer!Vertex();
            this._verts   = new Buffer!Vertex();
            this._font    = font;
            this.charSize = charSize;
            this.colour   = colour;
            this.position = position;
        }
    }

    public final
    {
        /++
         + Params:
         +  font     = The `Font` to use.
         +  text     = The text to use.
         +  position = The position.
         +  charSize = The character size to use.
         +  colour   = The colour to render the text as.
         + ++/
        @trusted
        this(Font font, const(char[]) text, vec2 position = vec2(0), uint charSize = 14, Colour colour = Colour.white)
        {
            this(font, position, charSize, colour);
            this.asciiText = text;
        }

        /++
         + Returns:
         +  The position of this object.
         + ++/
        @property @safe @nogc
        const(vec2) position() nothrow const
        {
            return this._transform.translation;
        }

        /++
         + Sets the position of the transformable object.
         +
         + Params:
         +  pos = The position to set the object at.
         + ++/
        @property @safe @nogc
        void position(vec2 pos) nothrow
        {
            if(ivec2(pos) == ivec2(this.position))
                return;

            this._transform.translation = pos;
            this._transform.markDirty();
        }
        
        /// Returns: The character size being used.
        @property @trusted @nogc
        uint charSize() nothrow const
        {
            return this._charSize;
        }

        /++
         + Sets the character size being used.
         +
         + Notes:
         +  Please see the 'Issues' section for `Font` for potential issues with large
         +  character sizes.
         +
         +  At the moment, the size changes won't be performed until a call to `Text.asciiText`[set] is called.
         +
         + Params:
         +  size = The character size to use.
         + ++/
        @property @trusted @nogc
        void charSize(uint size) nothrow
        {
            this._charSize = size;
        }

        /// Returns: The size of the text on screen.
        @property @trusted @nogc
        const(vec2) screenSize() nothrow const
        {
            return this._size;
        }

        /// Returns: The colour of the text
        @property @trusted @nogc
        const(Colour) colour() nothrow const
        {
            return this._colour;
        }
        
        /++
         + Sets the colour of the text.
         +
         + Params:
         +  col = The colour to use.
         + ++/
        @property @trusted @nogc
        void colour(Colour col) nothrow
        {
            foreach(ref vert; this._verts[0..$])
                vert.colour = col;

            foreach(ref vert; this._transformed[0..$])
                vert.colour = col;

            this._colour = col;
        }    

        /// Returns: The text being used.
        @property @safe @nogc
        const(char[]) asciiText() nothrow const
        {
            return this._text;
        }

        /++
         + Sets the text to render.
         +
         + Notes:
         +  Anytime this function is called, the verticies that make up the text are re-calculated,
         +  meaning this function can become very slow if called too often (it can be unavoidable though).
         +
         +  The `text is $(B not) copied, so if it wasn't `immutable` before being passed to this function then
         +  it may be changed outside of this class' control (note that if that happens the on-screen text won't be updated though).
         + ++/
        @property @trusted
        void asciiText(const(char[]) text) //nothrow
        {
            auto set = this._font.getSetForSize(this.charSize);
            auto pos = vec2(0, 0);
            // TODO: Condense the `largest` variables into two vec2s
            float largestX = 0;
            float largestY = 0;
            float largestWidth = 0;
            float largestHeight = 0;
            auto charSize = vec2(0);
            bool wasNewline = false;
            this._transformed.length = 0;
            this._verts.length = 0;
            this._text = text;
            foreach(ch; text)
            {
                import std.math : abs;

                auto glyph    = set.glyphs[cast(ulong)ch];
                auto charPos  = pos + vec2(glyph.bearing.x, 0);
                     charSize = vec2(glyph.area.size);
                auto topLeft  = vec2(glyph.area.position); // UV coord

                // This is top-left maths to vertically align the characters properly.
                auto yDistance = (glyph.area.size.y - glyph.bearing.y);
                charPos -= vec2(0, glyph.area.size.y);
                charPos += vec2(0, yDistance);

                // Special case: new lines
                if(ch == cast(long)'\n')
                {
                    pos.x = 0;
                    pos.y = pos.y + largestHeight;
                    wasNewline = true;
                    continue;
                }

                // NOTE: For whatever reason, the glyphs are loaded in upside down
                // So we have to mix up the UVs to take this into account.
                this._verts ~= Vertex(charPos,                        // Top left
                                      topLeft + vec2(0, charSize.y),
                                      this.colour); 
                this._verts ~= Vertex(charPos + vec2(charSize.x, 0),  // Top right
                                      topLeft + charSize,
                                      this.colour);
                this._verts ~= Vertex(charPos + vec2(0, charSize.y),  // Bot left
                                      topLeft,
                                      this.colour);
                this._verts ~= Vertex(charPos + charSize,             // Bot right
                                      topLeft + vec2(charSize.x, 0),
                                      this.colour);

                // Update what the largest values are.
                if(charPos.y.abs > largestY)
                    largestY = charPos.y.abs;

                if(charPos.x.abs > largestX)
                    largestX = charPos.x.abs;

                if(charSize.y > largestHeight)
                    largestHeight = charSize.y;

                if(charSize.x > largestWidth)
                    largestWidth = charSize.x;

                // Change the 'cursor' to where the next character should be placed.
                pos.x = pos.x + cast(float)(glyph.advance.x >> 6); // >> 6 is to convert it into pixels.
                pos.y = pos.y + cast(float)(glyph.advance.y >> 6);
            }

            foreach(ref vert; this._verts[0..$])
                vert.position += vec2(0, largestHeight);
            this._transformed.length = this._verts.length;
            this._transform.markDirty();

            if(wasNewline)
                this._size = vec2(largestX + charSize.x, largestY + charSize.y);
            else
                this._size = vec2(largestX + charSize.x, largestY);
        }

        /// Internal use only
        @property @safe //@nogc
        Vertex[] verts() nothrow
        {
            if(this._transform.isDirty)
            {
                this._transformed[0..$]  = this._verts[0..$];
                this._transform.transformVerts(this._transformed[0..$]);
            }

            return this._transformed[0..$];
        }
        
        /// Internal/debug use only
        @property @trusted
        TextureBase texture()
        {
            auto set = this._font.getSetForSize(this.charSize);
            return set.texture;
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
             string uniText, 
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
        void onUpdate(Duration deltaTime, InputManager input){}

        ///
        void onRegister(PostOffice office){}

        ///
        void onRender(Window window)
        {
            window.renderer.drawText(this.text);
        }
    }
}
