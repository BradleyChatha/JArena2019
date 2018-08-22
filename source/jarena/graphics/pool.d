module jarena.graphics.pool;

private
{
    import jarena.graphics, jarena.core;
}

/++
 + A pool of `Sprite`s that all use the same `Texture`.
 +
 + Description:
 +  This is a specialised class used for rendering optimisation.
 +
 +  Imagine you had a level, and for all of the sprites making up the level's background there were
 +  200 individual sprites. All of these sprites would have to be passed to the `Renderer` which would then
 +  upload the data for these 200 sprites to the GPU $(B every frame) for rendering. This can become an annoying bottleneck.
 +
 +  This class solves this problem however (though with restrictions). With the `Renderer` class, it makes use of it's own
 +  internal `VertexBuffer` which cleared and updated every single frame (making it slow, but easy to use). Each instance
 +  of this class will also contain their own `VertexBuffer`s, but instead of changing all of it's data every frame, it's
 +  data is only updated on an as-needed basis.
 +
 +  Essentially, instead of sending the data of at least 200 sprites to the GPU every frame for just the level, this data in it's
 +  entirety is sent all at once, and then only portions of the data are updated as needed resulting in much faster rendering.
 +
 +  The reason the `Renderer` doesn't work like this by default is #1, I'm bad. And #2, the aim of the main `Renderer` class
 +  is to have easy to use yet slow functions for drawing all the basic primitve graphics `Renderer.drawSprite`, `Renderer.drawShape`, etc.
 +  While specialised classes such as `SpritePool` exist for optimisation purposes, but are more effort to use.
 +
 + Usage:
 +  * Create the `SpritePool` with an initial size of sprites.
 +  
 +  * Use functions such as `SpritePool.sprites` to gain access to all of the sprites in the pool.
 +
 +  * Call `SpritePool.flagForUpdate` whenever the data on the GPU needs to be updated for a sprite.
 +
 +  * Call `SpritePool.readyForRender` before rendering, so that all of the data is updated on the GPU side, and then
 +    call `Renderer.drawPool` to instruct the renderer to render the pool.
 +
 +  * Call `SpritePool.size[set]` and `SpritePool.grow` to allocate space for more sprites. Shrinking is unsupported for the time being.
 +
 +  The less updates that need to be made to a sprite, the faster the rendering from this class is.
 +  If every single sprite is being updated every frame, it may be best to just go with the normal Renderer for now.
 +
 + Limitations:
 +  There is no way to 'hide' a sprite so it can't render. A workaround is to set a sprite's alpha channel to 0.
 +
 +  Sprites will be rendered in the same order as they appear in `SpritePool.sprites`, so careful management of sprites must be done
 +  if certain sprites need to be on top/behind other sprites.
 +
 +  Because this is class uses Batch Rendering, all sprites can only use the same texture (look into the `SpriteAtlas` class).
 +  If a sprite's `Sprite.texture` is changed, then an assert will fail in `SpritePool.readyForRender`.
 +
 +  There is no support for shrinking the pool. There is no mechanism yet in the engine to dispose of resources such as `Sprite`s,
 +  so it is essentially impossible to manually destroy them without causing issues.
 +
 +  There is currently no support for culling in the `Renderer`/engine, so all the verts will be instructed to render at once.
 +
 + Notes:
 +  Functions that say they return sprites actually return `SpritePool.Handle` objects. These handles have an
 +  `alias this` to their inner sprite though, so they be used like they were a normal sprite.
 +
 +  Certain functions can perform their task faster if they're passed a handle instead of a sprite directly.
 + ++/
final class SpritePool
{
    struct Handle
    {
        alias sprite this;

        private SpritePool owner;
        private size_t id; // Index into _sprites
        Sprite sprite;
    }

    private
    {
        alias VertBuffer = VertexBuffer!(BufferFeatures.FullUploadSubData | BufferFeatures.PartialUploadSubData | BufferFeatures.MutableSize | BufferFeatures.CanMapBuffers);

        Texture       _texture;
        Handle[]      _sprites;
        Buffer!Handle _needsUpdateSprites;
        VertBuffer    _verts;
    }

    public final
    {
        /++
         +
         + ++/
        this(Texture texture, size_t initialSize = 0)
        {
            assert(texture !is null);

            //this._sprites = new Buffer!Handle();
            this._needsUpdateSprites = new Buffer!Handle();
            this._verts.setup();
            this._texture = texture;
            this.size = initialSize;
        }

        void flagForUpdate(Handle handle)
        {
            if(handle.owner != this)
                assert(false, "The given handle doesn't belong to this SpritePool");

            this._needsUpdateSprites ~= handle;
        }

        void flagForUpdate(Sprite sprite)
        {
            import std.algorithm : countUntil;

            auto index = this.sprites.countUntil!"a.sprite == b"(sprite);
            if(index < 0)
                assert(false, "The given sprite doesn't belong to this SpritePool");

            this.flagForUpdate(this._sprites[index]);
        }

        void prepareForRender()
        {
            // TODO: Optimise this
            //       Group handles that are side-by-side into a single update.
            foreach(handle; this._needsUpdateSprites[0..$])
            {
                // 4 = Verts per sprite
                auto verts = handle.sprite.verts; // Stack variable, need to have a copy alive.
                this.buffer.subUpload(handle.id * 4, verts[]);
            }

            this._needsUpdateSprites.length = 0;
        }

        /++
         + Grows the size of the pool a certain amount, and returns a slice to the sprites that were allocated.
         + ++/
        Handle[] grow(size_t amount)
        {
            this.size = this.size + amount;
            return this._sprites[$-amount..$];
        }

        ///
        @property @safe @nogc
        inout(Handle[]) sprites() nothrow inout
        {
            return this._sprites;
        }

        /++
         + Sets the size of the pool (can only be increased).
         + ++/
        @property
        void size(size_t newSize)
        {
            if(newSize < this._sprites.length)
                assert(false, "Attempted to shrink a sprite pool.");

            enum IPS = 6; // Indicies per sprite
            enum VPS = 4; // Verts per sprite

            // Update array/buffer sizes
            auto oldSize = this._sprites.length;
            this._sprites.length = newSize;
            this._verts.vboSize = newSize * Vertex.sizeof * VPS;
            this._verts.eboSize = newSize * uint.sizeof * IPS;

            // Generate the EBO indicies for each new sprite, as well as the sprite itself.
            uint[] eboUpdater;
            eboUpdater.length = ((newSize - oldSize) * IPS);

            auto firstVert  = oldSize * VPS;
            auto startIndex = 0;
            foreach(i; oldSize..newSize)
            {
                this._sprites[i] = Handle(this, i, new Sprite(this._texture));

                eboUpdater[startIndex..startIndex + IPS] = 
                [
                    cast(uint)firstVert,   cast(uint)firstVert+1, cast(uint)firstVert+2,
                    cast(uint)firstVert+1, cast(uint)firstVert+2, cast(uint)firstVert+3
                ];
                startIndex += IPS;
                firstVert += VPS;
            }

            // Upload it to the EBO
            this.buffer.subUpload(oldSize * uint.sizeof, eboUpdater);
        }

        /++
         + Returns:
         +  The size of the pool.
         + ++/
        @property @safe @nogc
        const(size_t) size() nothrow const pure
        {
            return this._sprites.length;
        }

        @property @safe @nogc
        inout(Texture) texture() nothrow inout pure
        {
            return this._texture;
        }

        // Internal use only.
        @property
        ref VertBuffer buffer()
        {
            return this._verts;
        }
    }
}