/// Contains code related to the main rendering process.
module jarena.graphics.renderer;

private
{
    import std.experimental.logger, std.typecons;
    import derelict.sdl2.sdl;
    import opengl;
    import jarena.core, jarena.graphics, jarena.maths;

    const COMPOUNT_TEXTURE_DIRECTORY = "data/debug/compound/";
}

/++
 + Contains information about a Camera, which can be used to control what is shown on screen.
 +
 + Helpful_Read:
 +  https://www.sfml-dev.org/tutorials/2.4/graphics-view.php
 + ++/
final class Camera
{
    /// If this is passed as the camera's view area, then it will select a default area for itself.
    static const DEFAULT_RECTF = RectangleF(-1, -1, -1, -1);
    static const DEFAULT_RECTI = RectangleI(-1, -1, -1, -1);

    private
    {
        Transform  _view;
        RectangleI _viewport;
        vec2       _size;
        mat4       _ortho;
        mat4       _viewInverted;

        @trusted
        void updateProjection() nothrow
        {
            import std.exception : assumeWontThrow;
            this._ortho = glOrthographic(0, this.size.x, this.size.y, 0, -1, 1).assumeWontThrow;
            this._view.origin = this.worldToScreenPos(this.center);
        }
    }

    public final
    {
        /++
         + Creates a new Camera with a given view area.
         +
         + Params:
         +  rect = The view area to use.
         + ++/
        @safe
        this(RectangleF rect = DEFAULT_RECTF) nothrow
        {
            if(rect == DEFAULT_RECTF)
                rect = RectangleF(0, 0, vec2(Systems.window.size));

            this.reset(rect);
            this.viewport = DEFAULT_RECTI;
        }

        /++
         + Converts a screen position, to a world position.
         +
         + Notes:
         +  For now, this function will only take into account the camera's position, but not it's rotation.
         +
         + Params:
         +  screenPos = The screen position to convert.
         +
         + Returns:
         +  `screenPos` as a world position.
         + ++/
        @safe
        vec2 screenToWorldPos(vec2 screenPos)
        {
            auto pv = this._ortho * this.viewMatrix;
            return (pv.inverted * vec4( 2.0 * screenPos.x / this.size.x - 1.0, 
                                       -2.0 * (screenPos.y - this.size.y) / this.size.y - 1.0, 
                                        1, 
                                        1)
                    ).xy;
        }

        /++
         + Converts a screen position, to a world position.
         +
         + Notes:
         +  For now, this function will only take into account the camera's position, but not it's rotation.
         +
         + Params:
         +  worldPos = The world position to convert.
         +
         + Returns:
         +  `worldPos` as a screen position.
         + ++/
        @safe @nogc
        inout(vec2) worldToScreenPos(vec2 worldPos) nothrow pure inout
        {
            return worldPos - this._view.translation;
        }

        /++
         + Moves the camera by a certain offset.
         +
         + Params:
         +  offset = The offset to move by.
         + ++/
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
            return this._view.translation + (this.size / 2);
        }

        ///
        @property @safe
        void center(vec2 centerPos) nothrow
        {
            this._view.translation = centerPos - (this.size / 2);
            this._view.markDirty();
            this.updateProjection();
        }

        ///
        @property @safe @nogc
        const(AngleDegrees) rotation() nothrow const
        {
            return this._view.rotation;
        }

        ///
        @property @safe @nogc
        void rotation(float degrees) nothrow
        {
            this._view.rotation = AngleDegrees(degrees);
            this._view.markDirty();
        }

        ///
        @property @safe @nogc
        void rotation(AngleDegrees degrees) nothrow
        {
            this.rotation = degrees.angle;
        }

        /// Returns: The size of the camera's viewing area.
        @property @safe @nogc
        const(vec2) size() nothrow const
        {
            return this._size;
        }

        /++
         + Sets the size of the camera's viewing area.
         +
         + Params:
         +  siz = The new size.
         + ++/
        @property @safe
        void size(vec2 siz) nothrow
        {
            this._size = siz;
            this.updateProjection();
        }

        ///
        void scale(vec2 sc)
        {
            this._view.scale = sc;
            this._view.markDirty();
        }

        ///
        vec2 scale()
        {
            return this._view.scale;
        }

        ///
        @property @safe @nogc
        RectangleI viewport() nothrow
        {
            return this._viewport;
        }
        
        ///
        @property @safe @nogc
        void viewport(RectangleI port) nothrow
        {
            this._viewport = port;
        }

        /++
         + Returns: A matrix suitable for the 'View' matrix within an MVP triplet.
         + ++/
        @property @trusted
        mat4 viewMatrix()
        {
            if(this._view.isDirty)
                this._viewInverted = this._view.matrix.inverted; // Note: ".matrix" updates it from being dirty.

            return this._viewInverted;
        }
    }
}

/++
 + Contains code for rendering things to the screen.
 +
 + Notes:
 +  Unless specified otherwise, all draw functions (such as `drawSprite` and `drawRect`) produce commands
 +  for the renderer, which won't be executed until `Renderer.displayChanges` is called.
 +
 +  The renderer performs automatic batching of verticies if the following conditions are met -
 +  
 +  1. All verticies make use of the same `TextureBase`.
 +  2. All verticies make use of the same `Shader`.
 +  3. The state of `Renderer.camera` hasn't changed since the last call to a draw function.
 +
 +  This means, for example, that 20 calls to `drawRect`, without any changes to the camera, will
 +  produce a single command that batches them all into one single draw call.
 +
 +  As another example, imagine 6 sprites are passed to `drawSprite`. Sprite 1 and 2 use Texture X, 
 +  sprite 3 and 4 use Texture Y, and finally sprite 5 and 6 also use Texture X. For this example we will assume
 +  that Texture X and Texture Y are not equal.
 +
 +  Each sprite is passed in order, so sprite 1 then 2 then 3, etc. are passed.
 +
 +  Sprite 1 and 2 are batched together, since they use the same texture, but when Sprite 3 is passed,
 +  because it has a different texture, it won't be batched with the other two sprites and will instead be batched
 +  with sprite 4. When sprite 5 and 6 are passed, even though they use the same texture as Sprite 1 and 2, because
 +  of the 'gap' created by Sprite 1 and 2, it means Sprite 5 and 6 are batched seperately from them, in order to preserve draw order.
 + ++/
final class Renderer
{
    private
    {
        alias VertexBufferFU = VertexBuffer!(BufferFeatures.FullUploadSubData | BufferFeatures.PartialUploadSubData);

        struct Slice
        {
            size_t start;
            size_t end;
        }

        // Since we want to use the info in the current camera *at the time that verticies are submitted*
        // we have to store it in a struct before the actual rendering, otherwise the camera info may be incorrect.
        struct CameraInfo
        {
            mat4       view;
            mat4       projection;
            RectangleI viewport;
        }

        struct BufferInfo
        {
            uint vao;
            uint elementCount;
            VertexDataType dataType;
        }

        enum BucketCommand
        {
            Quads,
            Buffer,
            Scissor,
            UseWireframe
        }

        union BucketData
        {
            Slice      quadVerts;    // [Quads]        Slice into _vertBuffer
            BufferInfo buffer;       // [Buffer]       The buffer to draw
            RectangleI scissorRect;  // [Scissor]      The rect to scissor
            bool       useWireframe; // [UseWireframe] The value to set the wireframe flag to
        }

        // Used for batching.
        struct RenderBucket
        {
            // Common between buckets
            TextureBase texture;
            Shader      shader;
            CameraInfo  camera;   // To make cameras work how I want, this is needed.

            // Command specific
            BucketCommand command;
            BucketData    data;
        }
        
        Window              _window;
        Camera              _camera;
        RendererResources   _resources;
        Buffer!RenderBucket _buckets;
        Shader              _textureShader;
        Shader              _colourShader;
        Shader              _textShader;
        RectangleShape      _rect;
        RectangleI          _scissorRect;

        // Despite having very similar names, they're used for different purposes.
        // VertexBuffer is used to store the data that is uploaded to the GPU
        // Buffer!Vertex stores all verticies registered for rendering, which may or may not be rendered right away.
        VertexBufferFU _quadBuffer;
        Buffer!Vertex  _vertBuffer;
        Buffer!uint    _indexBuffer;
    }

    public final
    {
        /// Setup the renderer.
        this(Window window)
        {
            this._window            = window;
            this._buckets           = new Buffer!RenderBucket();
            this._vertBuffer        = new Buffer!Vertex();
            this._indexBuffer       = new Buffer!uint();
            this._resources         = new RendererResources();
            this._textureShader     = new Shader(defaultVertexShader, texturedFragmentShader);
            this._colourShader      = new Shader(defaultVertexShader, colouredFragmentShader);
            this._textShader        = new Shader(defaultVertexShader, textFragmentShader);
            Systems.renderResources = this._resources;
            this._rect              = new RectangleShape();

            this._quadBuffer.setup();
        }

        ~this()
        {
            //if(this._rect !is null)
                //sfRectangleShape_destroy(this._rect);
        }

        /++
         + Clears the screen to a certain colour.
         +
         + Params:
         +  clearColour = The colour to set the screen to.
         + ++/
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
            TextureBase previousTexture;

            foreach(bucket; this._buckets[0..$])
            {
                // Perform common bucket operations.
                // Change the shader/camera data
                if(bucket.shader != previousShader || bucket.camera != previousCam)
                {
                    bucket.shader.use();
                    bucket.shader.setUniform("view", bucket.camera.view);
                    bucket.shader.setUniform("projection", bucket.camera.projection);
                    previousShader = bucket.shader;
                    previousCam    = bucket.camera;

                    if(bucket.camera.viewport == Camera.DEFAULT_RECTI)
                        bucket.camera.viewport = RectangleI(0, 0, ivec2(this._window.size));
                    glViewport(bucket.camera.viewport.position.x, 
                               this._window.size.y - bucket.camera.viewport.position.y - bucket.camera.viewport.size.y,
                               bucket.camera.viewport.size.x,     
                               bucket.camera.viewport.size.y);

                    // Textureless renders can be used for things like shapes
                    if(bucket.texture !is null && bucket.texture != previousTexture && !bucket.texture.isDisposed)
                    {
                        bucket.texture.use();
                        glActiveTexture(GL_TEXTURE0);
                    }
                    else
                        glBindTexture(GL_TEXTURE_2D, 0);
                    previousTexture = bucket.texture;
                }

                // TODO: Move this into a function/seperate functions
                switch(bucket.command)
                {
                    case BucketCommand.Buffer:
                        this.displayBuffer(bucket.data.buffer);
                        break;

                    case BucketCommand.Scissor:
                        this._scissorRect = bucket.data.scissorRect;
                        if(bucket.data.scissorRect == RectangleI.init)
                            glDisable(GL_SCISSOR_TEST);
                        else
                        {
                            auto r = bucket.data.scissorRect;
                            glEnable(GL_SCISSOR_TEST);
                            glScissor(r.position.x, this._window.size.y - (r.position.y + r.size.y), r.size.x, r.size.y);
                        }
                        break;

                    case BucketCommand.UseWireframe:
                        glPolygonMode(GL_FRONT_AND_BACK, (bucket.data.useWireframe) ? GL_LINE : GL_FILL);
                        break;

                    case BucketCommand.Quads:
                        // Create the new indicies
                        assert((bucket.data.quadVerts.end - bucket.data.quadVerts.start) % 4 == 0);
                        auto quadCount = (bucket.data.quadVerts.end - bucket.data.quadVerts.start) / 4;
                        auto previous  = uint.max; // We add 1 right after, so uint.max becomes 0
                        uint[6] temp;
                        this._indexBuffer.length = 0;
                        foreach(i; 0..quadCount)
                        {
                            temp = 
                            [
                                previous+1, previous+2, previous+3,
                                previous+2, previous+3, previous+4
                            ];
                            previous += 4;
                            this._indexBuffer ~= temp;
                        }

                        // Update the VBO with the new data
                        this._quadBuffer.verts    = this._vertBuffer[bucket.data.quadVerts.start..bucket.data.quadVerts.end];
                        this._quadBuffer.indicies = this._indexBuffer[0..$];
                        
                        this._quadBuffer.upload();
                        debug GL.checkForError();
                        
                        auto info = BufferInfo(this._quadBuffer.vao, cast(uint)this._quadBuffer.indicies.length, this._quadBuffer.dataType);
                        this.displayBuffer(info);
                        break;

                    default:
                        assert(false);
                }
            }

            this._buckets.length = 0;
            this._vertBuffer.length = 0;
            this._indexBuffer.length = 0;
            SDL_GL_SwapWindow(this._window.handle);
        }

        /++
         + Draws a rectangle to the screen.
         +
         + Notes:
         +  This is a less efficient, but more convinient way of drawing a `RectangleShape` to the screen.
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

            this.drawRectShape(this._rect);
        }

        /++
         + Draws a `RectangleShape` to the screen.
         +
         + Params:
         +  shape = The shape to draw.
         + ++/
        void drawRectShape(RectangleShape shape)
        {
            assert(shape !is null);

            // HACKY: The first 4 verts are the main filling, everything after are the borders
            auto verts = shape.verts; // Making sure the array stays on the stack long enough.
            if(shape.borderSize == 0)
                this.drawQuad(null, verts[0..4], this._colourShader);
            else
                this.drawQuadMultiple(null, verts[], this._colourShader);
        }

        /// Draws a `CircleShape`.
        void drawCircleShape(CircleShape shape)
        {
            assert(shape !is null);
            this.drawQuadMultiple(null, shape.verts, this._colourShader);
        }

        /// Draws a `Sprite` to the screen.
        void drawSprite(Sprite sprite)
        {
            assert(sprite !is null);

            this.drawQuad(sprite.texture, sprite.verts, this._textureShader);
        }

        /// Draws a `SpritePool`
        void drawPool(SpritePool pool)
        {
            assert(pool !is null);

            this.drawBuffer(pool.buffer, pool.texture, this._textureShader);
        }

        /// Draws `Text` to the screen.
        void drawText(Text text)
        {
            assert(text !is null);
            auto verts = text.verts;
            if(verts.length == 0)
                return;

            this.drawQuadMultiple(text.texture, text.verts, this._textShader);
        }

        /// Draws a VertexBufferObject
        void drawBuffer(VB)(ref VB buffer, TextureBase texture, Shader shader)
        if(isVertexBufferObject!VB)
        {
            auto bucket = RenderBucket(
                texture,
                shader,
                CameraInfo(this.camera.viewMatrix, this.camera._ortho, this.camera.viewport),
                BucketCommand.Buffer
            );
            bucket.data.buffer = BufferInfo(buffer.vao, cast(uint)(buffer.eboSizeBytes / uint.sizeof), buffer.dataType);
            this._buckets ~= bucket;
        }

        ///
        void drawQuad(TextureBase texture, Vertex[4] verts, Shader shader)
        {
            // Add in the verts
            auto vertSlice = Slice(this._vertBuffer.length, this._vertBuffer.length + 4);
            this._vertBuffer ~= verts[];

            this.addToBucket(texture, vertSlice, shader);
        }

        ///
        void drawQuadMultiple(TextureBase texture, Vertex[] verts, Shader shader)
        {
            assert(verts.length % 4 == 0, "The verts need to be a multiple of 4.");
            auto vertSlice = Slice(this._vertBuffer.length, this._vertBuffer.length + verts.length);
            this._vertBuffer ~= verts;

            this.addToBucket(texture, vertSlice, shader);
        }

        /++
         + Sets the rectangle of where on screen rendering should be limited to.
         +
         + For example, a rect of (0, 0, 200, 200) means only the first 200x200 pixels can be rendered to,
         + and anything outside of that rectangle is discarded.
         +
         + Note that if the `rect`'s size on either axis is below 0, it will be clamped to 0.
         +
         + `RectangleI.init` can be used to disable the limited rendering.
         + ++/
        @property @safe
        void scissorRect(RectangleI rect) nothrow
        {
            if(rect.size.x < 0) rect.size.x = 0;
            if(rect.size.y < 0) rect.size.y = 0;

            BucketData data;
            data.scissorRect = rect;
            this.addCommandBucket(BucketCommand.Scissor, data);
        }

        ///
        @property @safe
        inout(RectangleI) scissorRect() nothrow inout
        {
            return this._scissorRect;
        }

        /// Sets whether to draw in wireframe or not.
        @property @safe
        void useWireframe(bool use) nothrow
        {
            BucketData data;
            data.useWireframe = use;
            this.addCommandBucket(BucketCommand.UseWireframe, data);
        }

        /// Returns: The current `Camera` being used.
        @property @safe @nogc
        inout(Camera) camera() nothrow inout pure
        {
            return this._camera;
        }

        /// Sets the current `Camera` to use.
        @property @safe @nogc
        void camera(Camera cam) nothrow
        {
            assert(cam !is null);
            this._camera = cam;
        }
    }

    @safe
    private void addCommandBucket(BucketCommand command, BucketData data) nothrow
    {
        auto bucket = RenderBucket(
            null,
            this._colourShader, // dummy, we just need to not crash
            CameraInfo(mat4.init, mat4.init, Camera.DEFAULT_RECTI),
            command
        );
        bucket.data = data;
        this._buckets ~= bucket;
    }

    pragma(inline, true)
    private void displayBuffer(BufferInfo info)
    {
        glBindVertexArray(info.vao);
        glDrawElements(info.dataType, info.elementCount, GL_UNSIGNED_INT, null);
    }

    private void addToBucket(TextureBase texture, Slice vertSlice, Shader shader)
    {
        // All sprites that have the same texture and shader are batched together into a single bucket
        // When 'sprite' has a different texture or shader than the last one, a new bucket is created
        // Even there is a bucket that already has 'sprite''s texture and shader, it won't be added into that bucket unless it's the latest one
        // This preserves draw order, while also being a slight optimisation.
        auto camera     = CameraInfo(this.camera.viewMatrix, this.camera._ortho, this.camera.viewport);
        auto lastBucket = (this._buckets.length == 0) ? RenderBucket.init : this._buckets[$-1];
        if(this._buckets.length == 0
        || lastBucket.texture != texture
        || lastBucket.shader != shader
        || lastBucket.camera != camera
        || lastBucket.command != BucketCommand.Quads)
        {
            auto bucket = RenderBucket(texture, shader, camera, BucketCommand.Quads);
            bucket.data.quadVerts = vertSlice;
            this._buckets ~= bucket;
        }
        else
        {
            // If we get here, then we can just replace the end with the vertSlice
            assert(lastBucket != RenderBucket.init);
            assert(vertSlice.start == lastBucket.data.quadVerts.end);
            this._buckets[$-1].data.quadVerts.end = vertSlice.end;
        }
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
            assert(!this.isNull, "The texture handle is null.");

            this._texture.use();
        }

        void dispose()
        {
            this._resources = null;
            this._texture = null;
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
        uvec2            _newCompoundSize;
    }

    /++
     +=============
     += Vertacies =
     +=============
     + ++/
    public
    {
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
            ivec2 sizei;
            glBindTexture(GL_TEXTURE_2D, texID);
            glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH,  &sizei.components[0]);
            glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, &sizei.components[1]);

            // Determine if the texture can even fit within our specified compound size.
            auto size = this._newCompoundSize;
            if(sizei.x > size.x || sizei.y > size.y)
                size = uvec2(sizei + ivec2(1));

            auto texture = new MutableTexture(size);
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

        /++
        + Notes:
        +  If a texture is given that is too small for this size, then the given texture is simply
        +  used as-is.
        +
        + Params:
        +  newCompoundSize = The size of all newly made compound textures.
        + ++/
        void compoundTextureSize(uvec2 newCompoundSize)
        {
            this._newCompoundSize = newCompoundSize;
        }
    }
}