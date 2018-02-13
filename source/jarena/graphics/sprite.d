module jarena.graphics.sprite;

private
{
    import std.experimental.logger;
    import derelict.sfml2.system, derelict.sfml2.graphics;
    import jarena.core.util, jarena.core.maths, jarena.core.cache;
}

///
class Texture
{
    private
    {
        sfTexture* _handle;
    }

    public
    {
        ///
        this(string filePath)
        {
            import std.file      : exists;
            import std.exception : enforce;
            import std.format    : format;
            import std.string    : toStringz;

            tracef("Loading texture at path '%s'", filePath);
            enforce(filePath.exists, format("File does not exist: '%s'", filePath));

            this._handle = sfTexture_createFromFile(filePath.toStringz, null);
            enforce(this._handle !is null, "Unable to load texture at: '%s'", filePath);
        }

        ~this()
        {
            if(this._handle !is null)
                sfTexture_destroy(this.handle);
        }

        @property @safe @nogc
        inout(sfTexture*) handle() nothrow inout
        {
            assert(this._handle !is null);
            return this._handle;
        }
    }
}

///
class Sprite
{
    private
    {
        sfSprite* _handle;
        Texture   _texture;
    }

    public
    {
        ///
        this(Texture texture)
        {
            assert(texture !is null);
            this._texture = texture;

            this._handle = sfSprite_create();
            sfSprite_setTexture(this.handle, texture.handle, true);
        }

        ~this()
        {
            if(this._handle !is null)
                sfSprite_destroy(this.handle);
        }

        ///
        @trusted @nogc
        void move(vec2 offset) nothrow
        {
            sfSprite_move(this.handle, offset.toSF!sfVector2f);
        }

        @property @safe @nogc
        inout(sfSprite*) handle() nothrow inout
        {
            assert(this._handle !is null);
            return this._handle;
        }

        ///
        @property @trusted @nogc
        inout(vec2) position() nothrow inout
        {
            return sfSprite_getPosition(this.handle).to!vec2;
        }

        ///
        @property @trusted @nogc
        void position(vec2 pos) nothrow
        {
            sfSprite_setPosition(this.handle, pos.toSF!sfVector2f);
        }
    }
}

/++
 + Will either return a cached texture, or load in, cache, then return a texture.
 +
 + Params:
 +  cache = The texture cache to use.
 +  path = The path to the texture.
 +
 + Returns:
 +  If `cache` contains a texture called `path`, then the cached texture is returned.
 +
 +  Otherwise, a new texture is loaded in from the `path`, cached into the `cache`, and then returned.
 + ++/
Texture loadOrGet(Cache!Texture cache, string path)
{
    auto cached = cache.get(path);
    if(cached is null)
    {
        cached = new Texture(path);
        cache.add(path, cached);
    }

    return cached;
}