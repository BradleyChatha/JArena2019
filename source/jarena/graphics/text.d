/++
 + Contains clases related to rendering text.
 + ++/
module jarena.graphics.text;

private
{
    import std.experimental.logger, std.typecons;
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
        alias CharCode = dchar;

        alias SetSize = Flag!"setSize";
        alias SetGLAlignment = Flag!"setAlignment";

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

        // Generates a CharSet for the given CharSize.
        // Note that this function doesn't generate any glyph textures (well, it technically makes a single one).
        void generateForSize(CharSize size)
        {
            import opengl;

            assert((size in this._sets) is null, "Bug, this shouldn't have been called.");

            CharSet set;
            set.texture = new MutableTexture(uvec2(256, 256));
            this.generateGlyph!(SetSize.yes, SetGLAlignment.yes)(0, set, size); // Generate a single glyph, to make sure the AA is initialised.
            this._sets[size] = set;
        }

        void generateGlyph(SetSize setSize, SetGLAlignment setAlignment)(CharCode code, ref CharSet set, CharSize size = CharSize.max)
        {
            import opengl;

            // Set the size/alignment if we're told to handle that
            static if(setSize)
                FT_Set_Pixel_Sizes(this._font, 0, size);

            static if(setAlignment)
                glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

            // Load the glyph.
            auto errCode = FT_Load_Char(this._font, code, FT_LOAD_RENDER);
            if(errCode != 0)
            {
                errorf("FreeType could not load the character for code %s. Error = %s", code, errCode);
                return;
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

            // Reset the alignment
            static if(setAlignment)
                glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
        }

        /// Ensures that the given CharCode has been generated for the given CharSize.
        void ensureGlyphIsGenerated(CharSize size, CharCode code)
        {
            auto set = this.getSetForSize(size);

            if((code in set.glyphs) is null)
                this.generateGlyph!(SetSize.yes, SetGLAlignment.yes)(code, set, size);
        }

        /// Ensures that _all_ of the characters in the given piece of text have generated glyph textures for
        /// the specified CharSize.
        /// Note that this function have 0 optimisation (for now) so is slow.
        void ensureTextGlyphsAreGenerated(T : dchar)(CharSize size, const(T[]) text)
        {
            import std.algorithm : filter;
            import std.utf       : byUTF;
            import opengl;

            auto set = this.getSetForSize(size);

            // We handle the alignment and char size ourself, so there's less overhead than doing it every single generation.
            glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
            FT_Set_Pixel_Sizes(this._font, 0, size);
            foreach(code; text.byUTF!CharCode.filter!(c => (c in set.glyphs) is null))
                this.generateGlyph!(SetSize.no, SetGLAlignment.no)(code, set);

            set.glyphs.rehash();
            glPixelStorei(GL_UNPACK_ALIGNMENT, 4); // So we don't mess up any other code, set the alignment back to default.
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
        alias RecF = RectangleF;

        Font          _font;
        const(char)[] _text;
        uint          _charSize;
        Buffer!RecF   _charRects;
        Transform     _transform;
        Buffer!Vertex _verts;
        Buffer!Vertex _transformed;
        vec2          _size;
        Colour        _colour;

        @trusted
        this(Font font, vec2 position, uint charSize, Colour colour)
        {
            assert(font !is null);
            this._transformed   = new Buffer!Vertex();
            this._verts         = new Buffer!Vertex();
            this._charRects     = new Buffer!RectangleF();
            this._font          = font;
            this.charSize       = charSize;
            this.colour         = colour;
            this.position       = position;
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
            this.text = text;
        }

        /++
         + Retrieves a rectangle representing the position and size of a certain character of this text.
         +
         + Notes:
         +  Special characters such as new lines ('\n') do not have a rectangle created for them, so if there were a '\n' as
         +  character #0, and a 'B' as character #1, then `getRectForChar(0)' would return the rectangle for the 'B' character.
         +
         +  These rectangles are calculated during the `Text.text`[set] property, so calling this function multiple times is not slow.
         +
         + Special Characters:
         +  These characters do not have a rectangle created for them.
         +
         +  '\n'
         +
         + Params:
         +  charIndex = The index of the character to retrieve the rectangle of.
         +
         + Returns:
         +  Either null (check with 'returnValue.isNull'), or the rectangle for the character at `charIndex`.
         + ++/
        @safe @nogc
        const(Nullable!RectangleF) getRectForChar(size_t charIndex) nothrow const
        {
            return (charIndex < this._charRects.length) ? typeof(return)(this._charRects[charIndex]) : typeof(return).init;
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
         + Notes:
         +  Whenever the position of text isn't an integer, it generally has a few
         +  rendering issues, so this function will call `std.math.round` on the position
         +  automatically. Note that this also effects the return value of `Text.position`[getter]
         +
         + Params:
         +  pos = The position to set the object at.
         + ++/
        @property @safe @nogc
        void position(vec2 pos) nothrow
        {
            import std.math : round;

            if(ivec2(pos) == ivec2(this.position))
                return;

            this._transform.translation = vec2(pos.x.round, pos.y.round);
            this._transform.markDirty();
        }

        /++
         + Returns:
         +  The rotation of this object.
         + ++/
        @property @safe @nogc
        const(AngleDegrees) rotation() nothrow const
        {
            return this._transform.rotation;
        }

        /++
         + Sets the rotation of the transformable object.
         +
         + Params:
         +  angle = The rotation to set the object at.
         + ++/
        @property @safe @nogc
        void rotation(AngleDegrees angle) nothrow
        {
            this._transform.rotation = angle;
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
         + Params:
         +  size = The character size to use.
         + ++/
        @property @trusted
        void charSize(uint size)
        {
            this._charSize = size;
            this.text = this.text; // To recalculate the verts.
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
        const(char[]) text() nothrow const
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
         +
         +  This function will automatically decode the `text` into `dchar` UTF points, but the text is still stored as a `char[]`.
         +
         +  If a glyph for a character cannot be loaded, then it is not rendered. $(B This also means the size
         +  of the text doesn't take these missed characters into account, this will also effect how `getRectForChar` works.). 
         + ++/
        @property @trusted
        void text(const(char[]) text) //nothrow
        {
            import std.utf : byUTF;

            this._font.ensureTextGlyphsAreGenerated(this.charSize, text);

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
            this._charRects.length = 0;
            this._text = text;
            foreach(ch; text.byUTF!(Font.CharCode))
            {
                import std.math : abs;

                auto glyph = set.glyphs.get(cast(Font.CharCode)ch, Font.Glyph.init);
                if(glyph == Font.Glyph.init)
                    continue;

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

                // Store the rectangle for this character.
                this._charRects ~= RectangleF(charPos, charSize);

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
