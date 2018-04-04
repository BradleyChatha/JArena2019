module jarena.graphics.renderer;

private
{
    import std.experimental.logger;
    import derelict.sdl2.sdl;
    import opengl;
    import jarena.core, jarena.graphics;

    const COMPOUNT_TEXTURE_DIRECTORY = "data/debug/compound/";
}

/++
 + Contains information about a Camera, which can be used to control what is shown on screen.
 +
 + Helpful_Read:
 +  https://www.sfml-dev.org/tutorials/2.4/graphics-view.php
 +
 + Notes:
 +  
 + ++/
final class Camera
{
    static const DEFAULT_CAMERA_RECT = RectangleF(float.nan, float.nan, float.nan, float.nan);
    
    private
    {
        Transform _view;
        mat4      _ortho;
    }

    public
    {
        /++
         + 
         + ++/
        this(RectangleF rect = DEFAULT_CAMERA_RECT)
        {
            if(rect == DEFAULT_CAMERA_RECT)
                rect = RectangleF(0, 0, vec2(InitInfo.windowSize));

            this.reset(rect);
        }

        ///
        @safe @nogc
        void move(vec2 offset) nothrow pure
        {
            this._view.translation += offset;
            this._view.markDirty();
        }

        /++
         + Resets the camera to a certain portion of the world.
         +
         + Notes:
         +  This will also reset the camera's rotation.
         +
         +  The camera will of course, be centered within `rect`.
         +
         + Params:
         +  rect = The portion of the world to reset to viewing.
         + ++/
        @trusted
        void reset(RectangleF rect) nothrow
        {
            import std.exception : assumeWontThrow;
            import dlsl.projection;
            this._ortho = glOrthographic(rect.position.x, rect.size.x, rect.size.y, rect.position.y, -1, 1).assumeWontThrow;
        }

        ///
        @property @trusted @nogc
        vec2 center() nothrow const
        {
            return vec2();
            //return sfView_getCenter(this.handle).to!vec2;
        }

        ///
        @property @trusted @nogc
        void center(vec2 centerPos) nothrow
        {
            //sfView_setCenter(this.handle, centerPos.toSF!sfVector2f);
        }

        ///
        @property @trusted @nogc
        const(AngleDegrees) rotation() nothrow const
        {
            return AngleDegrees(0);
            //return typeof(return)(sfView_getRotation(this.handle));
        }

        ///
        @property @trusted @nogc
        void rotation(float degrees) nothrow
        {
            //sfView_setRotation(this.handle, degrees);
        }

        ///
        @property @trusted @nogc
        void rotation(AngleDegrees degrees) nothrow
        {
            this.rotation = degrees.angle;
        }

        ///
        @property @trusted @nogc
        const(vec2) size() nothrow const
        {
            return vec2();
            //return sfView_getSize(this.handle).to!vec2;
        }

        ///
        @property @trusted @nogc
        void size(vec2 siz) nothrow
        {
            //sfView_setSize(this.handle, siz.toSF!sfVector2f);
        }

        ///
        @property @trusted @nogc
        const(RectangleF) viewport() nothrow const
        {
            return RectangleF(0, 0, 0, 0);
            //return sfView_getViewport(this.handle).to!RectangleF;
        }
        
        ///
        @property @trusted @nogc
        void viewport(RectangleF port) nothrow
        {
            //sfView_setViewport(this.handle, port.toSF!sfFloatRect);
        }
    }
}

///
final class Renderer
{
    private
    {
        // Used for batching.
        struct RenderBucket
        {
            Texture  texture;
            Vertex[] verts;
            uint[]   indicies;
        }
        
        Window              _window;
        Sprite              _rect; // Feels a bit hacky, but I'm not gonna have a 'RectangleShape' class for a while/at all.
        Camera              _camera;
        RendererResources   _resources;
        RenderBucket[]      _buckets;
        VertexBuffer        _buffer;
        Shader              _defaultShader;
    }

    public
    {
        this(Window window)
        {
            this._window             = window;
            this._resources          = new RendererResources();
            this._defaultShader      = new Shader(defaultVertexShader, defaultFragmentShader);
            InitInfo.renderResources = this._resources;
            
            this._buffer.setup();

            this._rect = new Sprite(null, true);
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
            this._defaultShader.use();
            this._defaultShader.setUniform("view", this.camera._view.matrix);
            this._defaultShader.setUniform("projection", this.camera._ortho);
            
            foreach(bucket; this._buckets)
            {
                // Setting their length to 0 lets me reuse the memory without angering the GC
                this._buffer.verts.length = 0;
                this._buffer.indicies.length = 0;

                this._buffer.verts ~= bucket.verts;
                this._buffer.indicies ~= bucket.indicies;
                
                this._buffer.update();
                debug checkGLError();

                // Textureless renders can be used for things like shapes
                if(bucket.texture !is null)
                {
                    bucket.texture.use();
                    glActiveTexture(GL_TEXTURE0);
                }
                else
                    glBindTexture(GL_TEXTURE_2D, 0);
                
                this.drawBuffer(this._buffer);
            }

            this._buckets.length = 0;
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
            // TODO: Actually use most of those parameters when possible (border stuff will be a bit hard with our current hack)
            this.drawQuad(null, this._rect.verts[]);
        }

        /// Draws a `Sprite` to the screen.
        void drawSprite(Sprite sprite)
        {
            import std.algorithm : countUntil;
            assert(sprite !is null);

            this.drawQuad(sprite.texture, []~sprite.verts[]);
        }

        /// Draws `Text` to the screen.
        void drawText(Text text)
        {
            assert(text !is null);
            //sfRenderWindow_drawText(this._window.handle, text.handle, null);
        }

        /// Draws a VertexBuffer
        void drawBuffer(ref VertexBuffer buffer)
        {
            glBindVertexArray(buffer.vao);
            glDrawElements(buffer.dataType, cast(uint)buffer.indicies.length, GL_UNSIGNED_INT, null);
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
        }
    }

    // Long functions go at the bottom
    private void drawQuad(Texture texture, Vertex[] verts)
    {
        // All sprites that have the same texture are batched together into a single bucket
        // When 'sprite' has a different texture than the last one, a new bucket is created
        // Even there is a bucket that already has 'sprite''s texture, it won't be added into that bucket unless it's the latest one
        // This preserves draw order, while also being a slight optimisation.
        if(this._buckets.length == 0 || this._buckets[0].texture != texture)
            this._buckets ~= RenderBucket(texture, verts, [0, 1, 2, 1, 2, 3]);
         else
         {
            auto firstVert = this._buckets[$-1].indicies[$-1];
            this._buckets[$-1].verts ~= verts;
            this._buckets[$-1].indicies ~= [firstVert+1, firstVert+2, firstVert+3, 
                                            firstVert+2, firstVert+3, firstVert+4];

            assert(this._buckets[$-1].indicies[$-1] < this._buckets[$-1].verts.length);
         }

        // TODO:
        //   If the GC becomes an issue, with the constant array allocations then
        //   keep an array of Vertex[]s that is then given to newly made buckets.
        //
        //   Modify the length of the slices so that the previous memory is still
        //   allocated, but can be used like normal, avoiding _some_ (not all) GC allocations.
        //
        //   This also means that if the game runs for a bit, eventually no/very little
        //   GC allocations should take place, since everything will have all the memory it needs then.
    }
}

/++
 + A class that is used to manage the special resources used by the renderer.
 +
 + This class is mostly for internal usage of the engine, and can be safely
 + ignored by most other parts of the game.
 + ++/
final class RendererResources
{
    static struct TextureHandle
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
            return (this._texture is null);
        }
    }
    
    private
    {
        CompoundTexture[] _textures;
    }

    /++
     +==================================
     +=            Textures            =
     +==================================
     + ++/
    public
    {
        /++
         + Notes:
         +  The texture pointer to by `texID` $(B will be deleted) at the end of this function.
         + ++/
        TextureHandle finaliseTexture(ref uint texID)
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

            texID = 0;
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
