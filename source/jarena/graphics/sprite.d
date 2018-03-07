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
        const(vec2) position() nothrow const
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
        const(RectangleI) textureRect() nothrow const
        {
            return sfSprite_getTextureRect(this.handle).to!RectangleI;
        }

        ///
        @property @trusted @nogc
        void textureRect(RectangleI rect) nothrow
        {
            sfSprite_setTextureRect(this.handle, rect.toSF!sfIntRect);
        }

        /++
         + Details:
         +  The bounds of a sprite is a 'screen-accurate' rectangle of the sprite.
         +
         +  For example, while you *could* use sprite.position and sprite.texture.size for all your rectangular needs,
         +  what if you end up using sprite.textureRect for something like animation? Well, then all of your code using
         +  sprite.texture.size is gonna be a *little* off.
         +
         +  This function is basically so the `Sprite` class and any inheriting classes can properly provide
         +  a rectangle describing the 'correct' position and size of the sprite in it's current state.
         +
         + Returns:
         +  The bounds of the sprite.
         + ++/
        @property @trusted @nogc
        RectangleF bounds() nothrow
        {
            auto rect = this.textureRect;
            return RectangleF(this.position, vec2(rect.size.x, rect.size.y));
        }
    }
}

///
class SpriteAtlas
{
    /// Contains information about a sprite sheet
    struct Sheet
    {
        /// How many columns the sheet has.
        uint columns;
        
        /// How many rows the sheet has.
        uint rows;

        /// The frames that make up the sheet.
        RectangleI[] frames;

        /// The atlas that the sheet belongs to.
        SpriteAtlas atlas;
        
        ///
        @safe @nogc
        this(SpriteAtlas atlas) nothrow
        {
            this.atlas = atlas;
        }

        /++
         + Params:
         +  column = The column of the frame.
         +  row    = The row of the frame.
         +
         + Returns:
         +  The frame at (column, row).
         + ++/
        @safe
        const(RectangleI) getFrame(uint column, uint row) const
        {
            import std.exception : enforce;
            import std.format : format;

            enforce(column < this.columns, format("The column given was too big. Columns = %s | ColumnWanted = %s (keep in mind it's 0-based)", columns, column));
            enforce(row < this.rows, format("The row given was too big. Rows = %s | RowWanted = %s (keep in mind it's 0-based)", rows, row));

            return this.frames[(this.columns * row) + column];
        }

        ///
        @safe
        Sprite makeSprite(uint column, uint row, vec2 position = vec2(0))
        {
            auto sprite = new Sprite(this.atlas._texture);
            sprite.textureRect = this.getFrame(column, row);
            sprite.position = position;

            return sprite;
        }

        ///
        @safe
        Sprite changeSprite(return Sprite sprite, uint column, uint row)
        {
            sprite.textureRect = this.getFrame(column, row);
            return sprite;
        }
    }

    private
    {
        Texture             _texture;
        RectangleI[string]  _sprites;
        Sheet[string]       _spriteSheets;

        @safe
        void enforceFrame(RectangleI frame, string spriteName, string objectName = "sprite frame")
        {
            // Enforce is used here, as this function will most likely be called using data from a file
            // so rather than it being a code bug, it's an input bug.
            import std.exception : enforce;
            import std.format    : format;

            auto texSize = this._texture.size;
            auto maxX = frame.position.x + frame.size.x;
            auto maxY = frame.position.y + frame.size.y;
            enforce(frame.position.x >= 0, format("The X position for %s '%s' cannot be lower than 0. Value = %s", objectName, spriteName, frame.position.x));
            enforce(frame.position.y >= 0, format("The Y position for %s '%s' cannot be lower than 0. Value = %s", objectName, spriteName, frame.position.y));
            enforce(maxX <= texSize.x, format("The %s '%s' is too wide. Atlas width = %s | frameX + frameWidth = %s", objectName, spriteName, texSize.x, maxX));
            enforce(maxY <= texSize.y, format("The %s '%s' is too high. Atlas height = %s | frameY + frameHeight = %s", objectName, spriteName, texSize.y, maxY));
        }
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
            import std.exception : enforce;
            import std.format    : format;

            tracef("Registering sprite frame '%s' with frame rect of %s", spriteName, frame);
            enforce((spriteName in this._sprites) is null, format("Attempted to register sprite frame called '%s' twice.", spriteName));
            this.enforceFrame(frame, spriteName, "sprite frame");
            
            this._sprites[spriteName] = frame;
        }

        /++
         + Registers a sprite sheet.
         +
         + Details:
         +  A sprite sheet is like a mini sprite atlas, where it consists of many different frames.
         +  
         +  The difference is that these frames are very closely linked together. An example of this
         +  is that the frames in the sheet may come together to create an animation.
         +
         +  The number of frames in the sheet are worked out like so;
         +  FramesPerRow = `sheet.size.x / frameSize.x`;
         +  Rows = `sheet.size.y / frameSize.y`
         +
         +  As you might have noticed with the calculations above, sprite sheets can only contain frames that are equally sized.
         +  Non-equallly sized frames don't have a solution yet, so you'll have to make one yourself.
         +
         +  There are two ways to access the frames of a sprite sheet.
         +
         +  $(B TODO: Not implemented yet, but this is planned for.)
         +  #1, each frame of the sheet is registered as a normal sprite (using `SpriteAtlas.register`) under the name
         +  of "[sheetName]:[column]_[row]". So for example, the second frame on the third row of a sheet named "Animation"
         +  will have the name of "Animation:1_2" (0-based of course). 
         +
         +  #2, the function `SpriteAtlas.getSpriteSheet` will return a `SpriteAtlas.Sheet` struct, containing
         +  each frame of the sheet, alongside other pieces of information and helper functions to select the frames you want.
         +
         + Params:
         +  sheetName = The name to register the sheet as.
         +  sheetRect = The part of the atlas that contains the sheet.
         +  frameSize = The size of a single frame in the sheet.
         + ++/
        @safe
        void registerSpriteSheet(string sheetName, RectangleI sheetRect, ivec2 frameSize)
        {
            import std.exception : enforce;
            import std.format    : format;

            tracef("Registering sprite sheet called '%s', location in atlas is %s, with a frame size of %s.",
                   sheetName, sheetRect, frameSize);
            enforce((sheetName in this._spriteSheets) is null, format("Attempted to register sprite sheet called '%s' twice.", sheetName));
            enforce(sheetRect.size.x % frameSize.x == 0, 
                    format("The width of the sheet(%s) is not evenly divisible by the width of a frame(%s).", sheetRect.size.x, frameSize.x));
            enforce(sheetRect.size.y % frameSize.y == 0, 
                    format("The height of the sheet(%s) is not evenly divisible by the height of a frame(%s).", sheetRect.size.y, frameSize.y));

            auto sheet = Sheet(this);
            sheet.columns = sheetRect.size.x / frameSize.x;
            sheet.rows = sheetRect.size.y / frameSize.y;
            sheet.frames.reserve(sheet.columns * (sheet.rows + 1));

            tracef("Sprite sheet has %s columns and %s rows.", sheet.columns, sheet.rows);
            foreach(row; 0..sheet.rows)
            {
                foreach(col; 0..sheet.columns)
                {
                    auto frame = RectangleI(frameSize.x * col + sheetRect.position.x, 
                                            frameSize.y * row + sheetRect.position.y, 
                                            frameSize);
                    this.enforceFrame(frame, sheetName, "sprite sheet");
                    sheet.frames ~= frame;
                }
            }

            this._spriteSheets[sheetName] = sheet;
        }

        ///
        @safe
        Sheet getSpriteSheet(string sheetName)
        {
            import std.exception : enforce;
            enforce((sheetName in this._spriteSheets) !is null, "Cannot find sprite sheet called: " ~ sheetName);

            return this._spriteSheets[sheetName];
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
        
        ///
        @property @safe @nogc
        inout(Texture) texture() nothrow inout
        {
            return this._texture;
        }
    }
}

/// Contains information about an animation.
struct AnimationInfo
{
    /// The name of the animation.
    string name;

    /// The sprite sheet that contains the animation's frames.
    SpriteAtlas.Sheet spriteSheet;

    /// How many milliseconds to wait between each frame.
    uint delayPerFrameMS;

    /// Whether the animation should repeat or not.
    bool repeat;
}

/// Adds the ability for a `Sprite` to be animated.
class AnimatedSprite : Sprite
{
    private
    {
        Cache!AnimationInfo _animations;

        // Information about the current animation.
        AnimationInfo _currentAnimation;
        uvec2 _currentFrame;
        uint _currentDelayMS;
        bool _finished;

        @safe
        void changeFrame()
        {
            this._currentAnimation.spriteSheet.changeSprite(this, this._currentFrame.x, this._currentFrame.y);
        }
    }

    public
    {
        /++
         + Notes:
         +  For sprites that have the ability to change animations, it's recommended to only use
         +  `AnimationInfo`s that all come from the same `SpriteAtlas`, as changing textures
         +  might cause peformance issues.
         +
         + Params:
         +  animation  = The sprite's animation.
         +  animations = A cache of different animations.
         +               This can be null, and is only needed for sprites that can change animations.
         + ++/
        @safe
        this(AnimationInfo animation, Cache!AnimationInfo animations = null)
        {
            super(animation.spriteSheet.atlas.texture);

            this.animation = animation;
            this._animations = animations;
        }

        /++
         + Updates the animation.
         + ++/
        @safe
        void onUpdate(GameTime delta)
        {
            if(this._finished)
                return;

            this._currentDelayMS += delta.asMilliseconds;
            if(this._currentDelayMS >= this.animation.delayPerFrameMS)
            {
                this._currentFrame.x = this._currentFrame.x + 1;
                if(this._currentFrame.x >= this._currentAnimation.spriteSheet.columns)
                {
                    this._currentFrame.x = 0;
                    this._currentFrame.y = this._currentFrame.y + 1;

                    if(this._currentFrame.y >= this._currentAnimation.spriteSheet.rows)
                    {
                        if(!this._currentAnimation.repeat)
                        {
                            this._finished = true;
                            return;
                        }
                        else
                            this._currentFrame.y = 0;
                    }
                }

                this.changeFrame();
                this._currentDelayMS = 0;
            }
        }

        /// Restarts the animation.
        void restart()
        {
            this._currentDelayMS = 0;
            this._finished = false;
            this._currentFrame = uvec2(0);

            if(this._currentAnimation.spriteSheet.columns > 0)
                this.changeFrame();
        }

        /// Sets the current animation of the sprite. (Doesn't require a cache).
        @property @trusted
        void animation(AnimationInfo info)
        {
            // Reset state
            this.restart();
            this._currentAnimation = info;

            sfSprite_setTexture(super.handle, info.spriteSheet.atlas._texture.handle, 1);
            info.spriteSheet.changeSprite(this, 0, 0);
        }

        /// Returns: The current animation of the sprite.
        @property @safe
        AnimationInfo animation()
        {
            return this._currentAnimation;
        }

        /// Returns: Whether the current animation has finished. Always `false` for repeating animations.
        @property @safe @nogc
        bool finished() nothrow const
        {
            return this._finished;
        }
    }
}

/++
 + A simple object that does nothing other than draw an animated sprite to the screen.
 +
 + This class is `alias this`ed to it's sprite, to make it work exactly like a normal sprite.
 + ++/
class AnimatedObject : DrawableObject
{
    alias sprite this;

    private
    {
        AnimatedSprite _sprite;
    }

    public
    {
        /++
         + Creates a new AnimatedObject using a pre-made sprite.
         +
         + Params:
         +  sprite = The Sprite to use.
         +  position = The position to set the sprite at.
         +  yLevel = The yLevel to use
         + ++/
        @safe
        this(AnimatedSprite sprite, vec2 position = vec2(0), int yLevel = 0)
        {
            assert(sprite !is null);
            this._sprite = sprite;
            this.yLevel = yLevel;
            sprite.position = position;
        }

        /// The sprite for this AnimatedObject.
        @property
        AnimatedSprite sprite()
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
        void onUpdate(Window window, GameTime deltaTime)
        {
            this._sprite.onUpdate(deltaTime);
        }

        ///
        void onRegister(PostOffice office){}

        ///
        void onRender(Window window)
        {
            window.renderer.drawSprite(this._sprite);
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
if(isMultiCache!Multi_Cache && canCache!(Multi_Cache, Texture))
{
    return cache.getCache!Texture.loadOrGet(path);
}