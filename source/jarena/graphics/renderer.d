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
        vec2      _size;
        mat4      _ortho;

        @trusted
        void updateProjection() nothrow
        {
            import std.exception : assumeWontThrow;
            import dlsl.projection;
            this._ortho = glOrthographic(0, this.size.x, this.size.y, 0, -1, 1).assumeWontThrow;
        }
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
        @safe
        void reset(RectangleF rect) nothrow
        {
            this.size = rect.size;
            this._view.translation = rect.position;

            this._view.markDirty();
            this.updateProjection();
        }

        ///
        @property @safe @nogc
        vec2 center() nothrow const
        {
            return vec2();
            //return sfView_getCenter(this.handle).to!vec2;
        }

        ///
        @property @safe @nogc
        void center(vec2 centerPos) nothrow
        {
            //sfView_setCenter(this.handle, centerPos.toSF!sfVector2f);
        }

        ///
        @property @safe @nogc
        const(AngleDegrees) rotation() nothrow const
        {
            return AngleDegrees(0);
            //return typeof(return)(sfView_getRotation(this.handle));
        }

        ///
        @property @safe @nogc
        void rotation(float degrees) nothrow
        {
            //sfView_setRotation(this.handle, degrees);
        }

        ///
        @property @safe @nogc
        void rotation(AngleDegrees degrees) nothrow
        {
            this.rotation = degrees.angle;
        }

        ///
        @property @safe @nogc
        const(vec2) size() nothrow const
        {
            return this._size;
        }

        ///
        @property @safe
        void size(vec2 siz) nothrow
        {
            this._size = siz;
            this.updateProjection();
        }

        ///
        @property @safe @nogc
        const(RectangleF) viewport() nothrow const
        {
            return RectangleF(0, 0, 0, 0);
            //return sfView_getViewport(this.handle).to!RectangleF;
        }
        
        ///
        @property @safe @nogc
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
        // Since we want to use the info in the current camera *at the time that verticies are submitted*
        // we have to store it in a struct before the actual rendering, otherwise the camera info may be incorrect.
        struct CameraInfo
        {
            mat4 view;
            mat4 projection;
        }

        // Used for batching.
        struct RenderBucket
        {
            TextureBase texture;
            Shader      shader;
            CameraInfo  camera; // To make cameras work how I want, this is needed.
            Vertex[]    verts;
            uint[]      indicies;
        }
        
        Window              _window;
        Camera              _camera;
        RendererResources   _resources;
        RenderBucket[]      _buckets;
        VertexBuffer        _quadBuffer;
        Shader              _textureShader;
        Shader              _colourShader;
        Shader              _textShader;
        RectangleShape      _rect;
    }

    public
    {
        this(Window window)
        {
            this._window             = window;
            this._resources          = new RendererResources();
            this._textureShader      = new Shader(defaultVertexShader, texturedFragmentShader);
            this._colourShader       = new Shader(defaultVertexShader, colouredFragmentShader);
            this._textShader         = new Shader(defaultVertexShader, textFragmentShader);
            InitInfo.renderResources = this._resources;
            this._rect               = new RectangleShape();
            
            this._quadBuffer.setup();
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
            Shader previousShader;
            CameraInfo previousCam;
            foreach(bucket; this._buckets)
            {
                // Change the shader/camera data
                if(bucket.shader != previousShader || bucket.camera != previousCam)
                {
                    bucket.shader.use();
                    bucket.shader.setUniform("view", bucket.camera.view);
                    bucket.shader.setUniform("projection", bucket.camera.projection);
                    previousShader = bucket.shader;
                    previousCam    = bucket.camera;
                }

                this._quadBuffer.verts = bucket.verts;
                this._quadBuffer.indicies = bucket.indicies;
                
                this._quadBuffer.update();
                debug checkGLError();

                // Textureless renders can be used for things like shapes
                if(bucket.texture !is null)
                {
                    bucket.texture.use();
                    glActiveTexture(GL_TEXTURE0);
                }
                else
                    glBindTexture(GL_TEXTURE_2D, 0);
                
                this.drawBuffer(this._quadBuffer);
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
            this._rect.area         = RectangleF(position, size);
            this._rect.colour       = fillColour;
            this._rect.borderColour = borderColour;
            this._rect.borderSize   = borderThickness;

            // Draw the rectangle's filling
            this.drawQuad(null, this._rect.verts, this._colourShader);

            // Draw the border.
            this.drawQuad(null, this._rect.borderLeftVerts,   this._colourShader);
            this.drawQuad(null, this._rect.borderRightVerts,  this._colourShader);
            this.drawQuad(null, this._rect.borderTopVerts,    this._colourShader);
            this.drawQuad(null, this._rect.borderBottomVerts, this._colourShader);
        }

        /// Draws a `Sprite` to the screen.
        void drawSprite(Sprite sprite)
        {
            import std.algorithm : countUntil;
            assert(sprite !is null);

            this.drawQuad(sprite.texture, sprite.verts, this._textureShader);
        }

        /// Draws `Text` to the screen.
        void drawText(Text text)
        {
            assert(text !is null);
            auto verts = text.verts;
            if(verts.length == 0)
                return;

            assert((verts.length % 4) == 0);

            Vertex[4] buffer;
            foreach(i; 0..verts.length / 4)
            {
                buffer[0..4] = verts[i*4..(i*4)+4];
                this.drawQuad(text.texture, buffer, this._textShader);
            }
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
    private void drawQuad(TextureBase texture, Vertex[4] verts, Shader shader)
    {
        // All sprites that have the same texture and shader are batched together into a single bucket
        // When 'sprite' has a different texture or shader than the last one, a new bucket is created
        // Even there is a bucket that already has 'sprite''s texture and shader, it won't be added into that bucket unless it's the latest one
        // This preserves draw order, while also being a slight optimisation.
        auto camera = CameraInfo(this.camera._view.matrix.invert, this.camera._ortho);
        if(this._buckets.length == 0 
        || (this._buckets[$-1].texture != texture)
        || this._buckets[$-1].shader != shader
        || this._buckets[$-1].camera != camera)
            this._buckets ~= RenderBucket(texture, shader, camera, []~verts[], [0, 1, 2, 1, 2, 3]);
        else
        {
            auto firstVert = this._buckets[$-1].indicies[$-1];
            this._buckets[$-1].verts    ~= verts[];
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
        private MutableTexture    _texture;
        
        const(RectangleI) area;

        void bind()
        {
            this._texture.use();
        }

        bool opEquals(const ref TextureHandle other)
        {
            return (this._texture == other._texture);
        }

        @safe @nogc
        bool isNull() nothrow pure const
        {
            return (this._texture is null);
        }
    }
    
    private
    {
        MutableTexture[] _textures;
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
            scope(exit)
            {
                glDeleteTextures(1, &texID);
                texID = 0;
            }
            
            RectangleI area;
            foreach(compound; this._textures)
            {
                auto stitched = compound.stitch(texID, area);

                if(stitched)
                    return TextureHandle(this, compound, area);
            }

            // No avaliable textures could stitch it, so make a new one.
            auto texture = new MutableTexture(uvec2(2048, 2048));
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
            import std.conv : to;

            if(this._textures.length == 0)
                return;

            trace("Dumping all compound textures");
            foreach(i, tex; this._textures)
                tex.dump(i.to!string);
        }
    }
}