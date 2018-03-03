///
module jarena.graphics.sprite;

private
{
    import std.experimental.logger;
    import derelict.sfml2.system, derelict.sfml2.graphics;
    import sdlang;
    import jarena.core, jarena.gameplay, jarena.graphics;
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
        @trusted
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

        ///
        @property @safe @nogc
        inout(sfTexture*) handle() nothrow inout
        {
            assert(this._handle !is null);
            return this._handle;
        }

        ///
        @property @trusted @nogc
        inout(uvec2) size() nothrow inout
        {
            return sfTexture_getSize(this.handle).to!uvec2;
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
        @trusted
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

        ///
        @property @trusted @nogc
        inout(RectangleI) textureRect() nothrow inout
        {
            return sfSprite_getTextureRect(this.handle).to!RectangleI;
        }

        ///
        @property @trusted @nogc
        void textureRect(RectangleI rect) nothrow
        {
            sfSprite_setTextureRect(this.handle, rect.toSF!sfIntRect);
        }
    }
}

/++
 + A simple object that does nothing other than draw a sprite to the screen.
 +
 + This class is `alias this`ed to it's sprite, to make it work exactly like a normal sprite.
 + ++/
class StaticObject : DrawableObject
{
    alias sprite this;

    private
    {
        Sprite _sprite;
        string _texturePath;
        vec2   _initialPosition;
    }

    public
    {
        /++
         + Creates a new StaticObject using a pre-made sprite.
         +
         + Params:
         +  sprite = The Sprite to use.
         +  position = The position to set the sprite at.
         +  yLevel = The yLevel to use
         + ++/
        @safe
        this(Sprite sprite, vec2 position = vec2(0), int yLevel = 0)
        {
            assert(sprite !is null);
            this._sprite = sprite;
            this.yLevel = yLevel;
            sprite.position = position;
        }

        /++
         + Creates a new StaticObject, alongside a new sprite, using a given texture.
         +
         + Params:
         +  texture = The texture to use.
         +  position = The position to set the sprite at.
         +  yLevel = The yLevel to use
         + ++/
        @safe
        this(Texture texture, vec2 position = vec2(0), int yLevel = 0)
        {
            this(new Sprite(texture), position, yLevel);
        }

        /++
         + Creates a new StaticObject, using the texture provided by a path.
         +
         + Notes:
         +  The texture, and therefor the StaticObject's sprite, won't be loaded until
         +  the StaticObject is registered with a scene when this constructor is used.
         +
         + Params:
         +  texturePath = The path to the texture to use.
         +  position = The position to set the sprite at.
         +  yLevel = The yLevel to use
         + ++/
        @safe
        this(string texturePath, vec2 position = vec2(0), int yLevel = 0)
        {
            this._texturePath = texturePath;
            this._initialPosition = position;
            this.yLevel = yLevel;
        }

        /// The sprite for this StaticObject.
        @property
        Sprite sprite()
        {
            assert(this._sprite !is null, "The sprite hasn't been created yet.");
            return this._sprite;
        }
    }

    public override
    {
        ///
        void onUnregister(PostOffice office){}
        
        ///
        void onUpdate(Window window, GameTime deltaTime){}

        ///
        void onRegister(PostOffice office)
        {
            if(this._sprite is null && this._texturePath !is null)
            {
                // I really need to find a clean/shorter way to access that cache T.T
                auto texture = super.scene.manager.cache.loadOrGet(this._texturePath);
                this._sprite = new Sprite(texture);
                this.sprite.position = this._initialPosition;
            }
        }

        ///
        void onRender(Window window)
        {
            window.renderer.drawSprite(this._sprite);
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

/// ditto
Texture loadOrGet(Multi_Cache)(Multi_Cache cache, string path)
if(isMultiCache!Multi_Cache)
{
    return cache.getCache!Texture.loadOrGet(path);
}

///
class SpriteAtlas
{
    private
    {
        Texture             _texture;
        RectangleI[string]  _sprites;
    }

    public
    {
        ///
        this(Texture texture)
        {
            assert(texture !is null);
            this._texture = texture;
        }

        ///
        @safe
        void register(string spriteName, RectangleI frame)
        {
            // Enforce is used here, as this function will most likely be called using data from a file
            // so rather than it being a code bug, it's an input bug.
            import std.exception : enforce;
            import std.format    : format;

            auto texSize = this._texture.size;
            auto maxX    = frame.position.x + frame.size.x;
            auto maxY    = frame.position.y + frame.size.y;

            tracef("Registering sprite frame '%s' with frame rect of %s", spriteName, frame);
            enforce((spriteName in this._sprites) is null, format("Attempted to register sprite frame called '%s' twice.", spriteName));
            enforce(frame.position.x >= 0, format("The X position for sprite frame '%s' cannot be lower than 0. Value = %s", spriteName, frame.position.x));
            enforce(frame.position.y >= 0, format("The Y position for sprite frame '%s' cannot be lower than 0. Value = %s", spriteName, frame.position.y));
            enforce(maxX <= texSize.x, format("The sprite frame '%s' is too wide. Atlas width = %s | frameX + frameWidth = %s", spriteName, texSize.x, maxX));
            enforce(maxY <= texSize.y, format("The sprite frame '%s' is too high. Atlas height = %s | frameY + frameHeight = %s", spriteName, texSize.y, maxY));
            
            this._sprites[spriteName] = frame;
        }

        ///
        @safe
        RectangleI getSpriteRect(string spriteName)
        {
            import std.exception : enforce;
            enforce((spriteName in this._sprites) !is null, "Cannot find sprite frame called: " ~ spriteName);

            return this._sprites[spriteName];
        }

        ///
        @safe
        Sprite makeSprite(string spriteName, vec2 position = vec2(0, 0))
        {
            auto sprite = new Sprite(this._texture);
            sprite.textureRect = this.getSpriteRect(spriteName);
            sprite.position = position;

            return sprite;
        }

        ///
        @safe
        Sprite changeSprite(return Sprite sprite, string spriteName)
        {
            sprite.textureRect = this.getSpriteRect(spriteName);
            return sprite;
        }
    }
}