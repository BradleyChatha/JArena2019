module jarena.graphics.renderer;

private
{
    import std.experimental.logger;
    import derelict.sdl2.sdl;
    import opengl;
    import jarena.core, jarena.graphics;

    const COMPOUNT_TEXTURE_DIRECTORY = "data/debug/compound/";
}

///
final class Renderer
{
    private
    {
        Window _window;
        //sfRectangleShape* _rect;
        Camera _camera;
        RendererResources _resources;
    }

    public
    {
        this(Window window)
        {
            this._window = window;
            this._resources = new RendererResources();
            InitInfo.renderResources = this._resources;
            //this._rect = sfRectangleShape_create();
        }

        ~this()
        {
            //if(this._rect !is null)
                //sfRectangleShape_destroy(this._rect);
        }

        /// Clears the screen
        void clear(Colour clearColour = Colour.white)
        {
            float[4] clear = clearColour.asGLColour;
            glClearColor(clear[0], clear[1], clear[2], clear[3]);
            glClear(GL_COLOR_BUFFER_BIT);
        }

        /// Displays all rendered changes to the screen.
        void displayChanges()
        {
            SDL_GL_SwapWindow(this._window.handle);
        }

        /++
         + Draws a rectangle to the screen.
         +
         + Params:
         +  position        = The position of the rectangle.
         +  size            = The size of the rectangle.
         +  fillColour      = The colour of the inside of the rectangle. (See also - `jarena.util.colour`)
         +  borderColour    = The colour of the border.
         +  borderThickness = The thiccness of the border.
         + ++/
        void drawRect(vec2 position, vec2 size, Colour fillColour = Colour(255, 0, 0, 255), Colour borderColour = Colour.black, uint borderThickness = 1)
        {
            //sfRectangleShape_setPosition        (this._rect, position.toSF!sfVector2f);
            //sfRectangleShape_setSize            (this._rect, size.toSF!sfVector2f);
            //sfRectangleShape_setFillColor       (this._rect, fillColour.toSF!sfColor);
            //sfRectangleShape_setOutlineColor    (this._rect, borderColour.toSF!sfColor);
            //sfRectangleShape_setOutlineThickness(this._rect, borderThickness);

            //sfRenderWindow_drawRectangleShape(this._window.handle, this._rect, null);
        }

        /// Draws a `Sprite` to the screen.
        void drawSprite(Sprite sprite)
        {
            assert(sprite !is null);
            //sfRenderWindow_drawSprite(this._window.handle, sprite.handle, null);
        }

        /// Draws `Text` to the screen.
        void drawText(Text text)
        {
            assert(text !is null);
            //sfRenderWindow_drawText(this._window.handle, text.handle, null);
        }

        /// Draws a FixedVertexBuffer
        void drawBuffer(B)(ref B buffer)
        if(isFixedVertexBuffer!B)
        {
            glBindVertexArray(buffer.vao);
            glDrawElements(buffer.dataType, buffer.indicies.length, GL_UNSIGNED_INT, null);
        }

        /// Sets whether to draw in wireframe or not.
        @property @nogc
        void useWireframe(bool use) nothrow
        {
            glPolygonMode(GL_FRONT_AND_BACK, (use) ? GL_LINE : GL_FILL);
        }

        /// Returns: The current `Camera` being used.
        @property
        Camera camera()
        {
            return this._camera;
        }

        /// Sets the current `Camera` to use.
        @property
        void camera(Camera cam)
        {
            assert(cam !is null);
            
            this._camera = cam;
            //sfRenderWindow_setView(this._window.handle, this._camera.handle);
        }
    }
}

/++
 + A class that is used to manage the resources used by the renderer.
 +
 + This class is mostly for internal usage of the engine, and can be safely
 + ignored by most other parts of the game.
 + ++/
final class RendererResources
{
    struct TextureHandle
    {
        private RendererResources _resources;
        private CompoundTexture   _texture;
        
        const(RectangleI) area;

        void bind()
        {
            glBindTexture(GL_TEXTURE_2D, this._texture.textureID);
        }

        @safe @nogc
        bool isNull() nothrow pure const
        {
            return (this._texture !is null);
        }
    }
    
    private
    {
        CompoundTexture[] _textures;
    }

    public
    {
        /++
         + Notes:
         +  The texture pointer to by `texID` $(B will be deleted) at the end of this function.
         + ++/
        TextureHandle finaliseTexture(uint texID)
        {
            scope(exit) glDeleteTextures(1, &texID);
            
            RectangleI area;
            foreach(compound; this._textures)
            {
                auto stitched = compound.stitch(texID, area);

                if(stitched)
                    return TextureHandle(this, compound, area);
            }

            // No avaliable textures could stitch it, so make a new one.
            auto texture = new CompoundTexture(uvec2(2048, 2048));
            this._textures ~= texture;

            if(!texture.stitch(texID, area))
                assert(false, "The texture is probably too large, or there's a bug.");

            return TextureHandle(this, texture, area);
        }

        /++
         + Saves all current compound textures as PNG files.
         + ++/
        void dumpTextures()
        {
            import derelict.freeimage.freeimage;

            if(this._textures.length == 0)
                return;

            trace("Dumping all compound textures");
            trace("Allocating FreeImage buffer");
            auto size  = this._textures[0].size; // They all have the same size for now.
            auto image = FreeImage_Allocate(size.x, size.y, 32);
            scope(exit) FreeImage_Unload(image);

            // I don't gain much by using the GC here.
            trace("Allocating pixel buffer");
            import core.stdc.stdlib : malloc, free;
            auto totalBytes = (size.y * size.x) * Colour.sizeof;
            auto buffer     = (cast(ubyte*)malloc(totalBytes))[0..totalBytes];
            scope(exit)
            {
                if(buffer.ptr !is null)
                    free(buffer.ptr);
            }
            tracef("Buffer size in bytes: %s", buffer.length);

            if(buffer.ptr is null)
            {
                error("Malloc returned null when allocating the buffer. Aborting dump.");
                return;
            }

            foreach(i, compound; this._textures)
            {
                import std.conv : to;

                trace("Getting pixel data from OpenGL");
                glBindTexture(GL_TEXTURE_2D, compound.textureID);
                glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, cast(void*)buffer.ptr);
                checkGLError();

                RGBQUAD quad;
                uint x, y;
                foreach(i2; 0..buffer.length / 4)
                {
                    auto bgra = buffer[i2*4..(i2*4)+4];
                    quad = RGBQUAD(bgra[2], bgra[1], bgra[0], bgra[3]);

                    FreeImage_SetPixelColor(image, x, y, &quad);
                    x += 1;

                    if(x >= size.x)
                    {
                        y += 1;
                        x = 0;
                    }
                }
                
                auto fileName = COMPOUNT_TEXTURE_DIRECTORY~(i.to!string~".png\0");
                tracef("Writing to file '%s'", fileName);
                FreeImage_Save(FIF_PNG, image, fileName.ptr);
            }
        }
    }
}

private class CompoundTexture
{
    uint textureID;
    const(uvec2) size;
    uint nextY; // For now, we just stack them on top of eachother, and pretend the X-axis doesn't exist.
                // TODO: Come up with/research packing algorithms.
                // IMPORTANT: Normally OpenGL goes from the bottom-left, but our code makes coordinates work from the top-left.

    this(uvec2 size)
    {
        // Find the max size of a texture.
        //auto size = uvec2();
        //glGetIntegerv(GL_MAX_TEXTURE_SIZE, cast(int*)&size.data[0]);
        //size.data[1] = size.data[0];
        this.size = size;

        // Then generate the texture.
        glGenTextures(1, &this.textureID);
        glBindTexture(GL_TEXTURE_2D, this.textureID);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,     GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,     GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, size.x, size.y, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
        checkGLError();
    }

    ~this()
    {
        if(textureID > 0)
            glDeleteTextures(1, &this.textureID);
    }

    /// Returns: Whether it was able to stitch the texture on or not.
    bool stitch(uint texID, ref RectangleI area)
    {
        import std.experimental.logger;
        tracef("Attempting to stitch texture %s", texID);
        
        glBindTexture(GL_TEXTURE_2D, texID);
        
        ivec2 size;
        glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH,  &size.data[0]);
        glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, &size.data[1]);
        tracef("The texture has a size of %s", size);

        if(size.y + this.nextY >= this.size.y) // Not enough space vertically.
        {
            trace("There is not enough room for the texture");
            return false;
        }
        debug infof("[DEBUG] nextY = %s", nextY);

        // I don't gain much by using the GC here.
        import core.stdc.stdlib : malloc, free;
        auto totalBytes = (size.y * size.x) * 4;
        auto bytes      = (cast(ubyte*)malloc(totalBytes))[0..totalBytes];
        scope(exit) free(bytes.ptr);
        debug infof("[DEBUG] totalBytes = %s", totalBytes);

        trace("Getting pixels...");
        glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, cast(void*)bytes.ptr);
        checkGLError();

        trace("Transferring pixels...");
        glBindTexture(GL_TEXTURE_2D, this.textureID);
        glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
        glTexSubImage2D(
            GL_TEXTURE_2D,
            0,
            0, // xoffset
            (this.size.y - nextY) - size.y, // yoffset, with some maths so we can work from the top-left
            size.x,
            size.y,
            GL_RGBA,
            GL_UNSIGNED_BYTE,
            cast(void*)bytes.ptr
        );
        checkGLError();

        area = RectangleI(0, nextY, size);
        trace("Texture was stiched to area %s", area);

        this.nextY += size.y;
        return true;
    }
}
