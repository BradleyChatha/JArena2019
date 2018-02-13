module jarena.gameplay.scene;

private
{
    import std.experimental.logger;

    import jarena.core.cache, jarena.core.maths, jarena.core.post, jarena.core.time;
    import jarena.graphics.sprite, jarena.graphics.window;
}

/// Defines a scene, which can be thought of as a gamestate.
abstract class Scene
{
    private
    {
        SceneManager _manager;
        string       _name;
    }

    protected
    {
        // Protected, so inheriting classes can call SceneManager.registerSprite, but because *that's* private, no other class can
        // outside of this function.
        
        /++
         + Registers a `Sprite` to be drawn (handled by the `SceneManager`)
         +
         + Notes:
         +  The y-level defines the order in which the sprites get drawn.
         +  Lower y-levels get drawn first, higher y-levels get drawn last.
         +  This allows greater control over which sprites are rendered over eachother.
         +
         + Params:
         +  sprite = The sprite to register.
         +  yLevel = The y-level to give the sprite.
         + ++/
        void registerSprite(Sprite sprite, int yLevel)
        {
            this._manager.registerSprite(this, sprite, yLevel);
        }

        /++
         + Unregisters a sprite previously registered using `registerSprite`.
         +
         + Params:
         +  sprite = The sprite to unregister.
         + ++/
        void unregisterSprite(Sprite sprite)
        {
            this._manager.unregisterSprite(this, sprite);
        }

        /++
         + Returns:
         +  Whether the given `sprite` has been registered.
         + ++/
        bool isRegistered(Sprite sprite)
        {
            import std.algorithm : canFind;

            if(sprite is null) return false;

            return this._manager._scenes.get(this.name).sprites.canFind!"a.sprite == b"(sprite);
        }
    }

    public
    {
        /++
         + Params:
         +  name = The name to give the scene.
         + ++/
        @safe @nogc
        this(string name) nothrow
        {
            this._name = name;
        }

        /// The `SceneManager` this scene has been registered with.
        @property @safe @nogc
        inout(SceneManager) manager() nothrow inout
        {
            return this._manager;
        }

        /// The name of this Scene.
        @property @safe @nogc
        string name() nothrow const
        {
            return this._name;
        }
    }

    public abstract
    {
        /++
         + Called when the scene is first registered with a `SceneManager`.
         +
         + Use this function to load in any initial assests
         + ++/
        void onInit();

        /++
         + Called when this scene is swapped in.
         +
         + For now, this function and `onUnswap` are used to subscribe/unsubscribe to the `office`.
         +
         + Params:
         +  office = The main event `PostOffice`.
         + ++/
        void onSwap(PostOffice office);

        /++
         + Called when this scene is swapped out.
         +
         + Params:
         +  office = The main event `PostOffice`.
         + ++/
        void onUnswap(PostOffice office);

        /++
         + Called everytime the scene should process a frame.
         +
         + Params:
         +  window = The game's window.
         +  deltaTime = The amount of time the last frame took to process (used for making speed frame-independent).
         + ++/
        void onUpdate(Window window, GameTime deltaTime);
    }
}

/// Manages multiple `Scene`s and is required for certain utility functions that a `Scene` provides.
class SceneManager
{
    private class SceneInfo
    {
        enum Flags : ubyte
        {
            None = 0,

            IS_POSTBOX = 1 << 0
        }

        Scene scene;
        SpriteInfo[] sprites;
        Flags flags;

        this(Scene scene, Flags flags = Flags.None)
        {
            this.scene = scene;
            this.flags = flags;
        }
    }

    private struct SpriteInfo
    {
        Sprite sprite;
        int yLevel;
    }

    private
    {
        Cache!SceneInfo _scenes;                // Cache of all scenes.
        SceneInfo       _currentScene;          // Current scene to update
        PostOffice      _eventOffice;           // Main event office.
        Cache!Texture   _commonTextureCache;    // Shared texture cache.
        InputManager    _input;                 // 

        // Private, so only the Scene class can access it (don't want some random function randomly adding sprites in.)
        void registerSprite(Scene scene, Sprite sprite, int yLevel)
        {
            assert(scene !is null);
            assert(sprite !is null);
            auto spriteInfo = SpriteInfo(sprite, yLevel);
            auto sceneInfo = this._scenes.get(scene.name);

            infof("Scene '%s' is registering a sprite with Y-Level of %s", scene.name, yLevel);

            bool wasInsertion = false;
            for(size_t i = 0; i < sceneInfo.sprites.length; i++)
            {
                if(sceneInfo.sprites[i].yLevel > yLevel)
                {
                    auto toMove = sceneInfo.sprites[i..$];
                    sceneInfo.sprites.length += 1;

                    foreach(i2, spr; toMove)
                        sceneInfo.sprites[i + (i2 + 1)] = spr;

                    sceneInfo.sprites[i] = spriteInfo;
                    wasInsertion = true;
                    break;
                }
            }

            if(!wasInsertion)
                sceneInfo.sprites ~= spriteInfo;
        }

        void unregisterSprite(Scene scene, Sprite sprite)
        {
            import std.algorithm : countUntil;

            assert(scene !is null);
            assert(sprite !is null);

            infof("Scene '%s' is unregistering a sprite.", scene.name);

            auto sceneInfo = this._scenes.get(scene.name);
            auto index = sceneInfo.sprites.countUntil!"a.sprite == b"(sprite);
            assert(index != -1, "Tried to unregister an unregistered sprite.");

            sceneInfo.sprites.removeAt(index);
        }
    }

    public
    {
        /++
         + Notes:
         +  If `input` is `null`, then one is created, and paired with the `eventOffice`.
         +
         +  If `commonTextures` is `null`, then one is created.
         +
         + Params:
         +  eventOffice = A `PostOffice` that is recieving events from core game features, such as the `Window`.
         +  input = An `InputManager` that should be paried with the `eventOffice`.
         +  commonTextures = A texture cache to contain common textures shared between all scenes.
         + ++/
        this(PostOffice eventOffice, InputManager input = null, Cache!Texture commonTextures = null)
        {
            assert(eventOffice !is null);

            this._eventOffice = eventOffice;
            this._scenes = new Cache!SceneInfo;
            this._commonTextureCache = (commonTextures is null) ? new Cache!Texture() : commonTextures;
            this._input = (input is null) ? new InputManager(eventOffice) : input;
        }

        /++
         + Registers a `Scene`.
         +
         + Notes:
         +  If the scene inheirts `IPostBox` then the `SceneManager` will automatically handle subscribing and unsubscribing it's onMail function.
         +
         + Params:
         +  scene = The scene to register. 
         + ++/
        void register(S : Scene)(S scene)
        {
            assert(scene !is null);
            scene._manager = this;

            auto info = new SceneInfo(scene);
            static if(is(S : IPostBox))
            {
                trace("The Scene inherits from an IPostBox, so it's onMail function will be subscribed automatically.");
                info.flags |= SceneInfo.Flags.IS_POSTBOX;
            }

            tracef("Registering Scene called '%s'", scene.name);
            this._scenes.add(scene.name, info);

            trace("Initialising Scene");
            scene.onInit();
        }

        /++
         + Updates the current `Scene` (if there is one.
         +
         + Notes:
         +  This function will also draw any sprites registered with `Scene.registerSprite` *after* updating the `Scene`.
         +
         + Params:
         +  window = The game's `Window`.
         +  deltaTime = The time the last frame of the game took.
         + ++/
        void onUpdate(Window window, GameTime deltaTime)
        {
            assert(window !is null);

            if(this._currentScene.scene !is null)
            {
                this._currentScene.scene.onUpdate(window, deltaTime);

                foreach(info; this._currentScene.sprites)
                    window.renderer.drawSprite(info.sprite);
            }
        }

        /++
         + Swaps the current scene.
         +
         + Notes:
         +  If the `Scene` that is getting swapped $(B out) inherits from `IPostBox`, it will be unsubscribed from the `PostOffice`.
         +
         +  If the `Scene` that is getting swapped $(B in) inherits from `IPostBox`, it will be subscribed to the `PostOffice`.
         +
         + Params:
         +  sceneName = The name of the `Scene` to swap to.
         + ++/
        void swap(string sceneName)
        {
            tracef("Swapping to scene called '%s'", sceneName);

            auto info = this._scenes.get(sceneName);
            assert(info !is null, sceneName);
            assert(this._currentScene != info, "Trying to swap to the current scene, probably a bug.");

            if(this._currentScene !is null)
            {
                this._currentScene.scene.onUnswap(this._eventOffice);

                if(this._currentScene.flags & SceneInfo.Flags.IS_POSTBOX)
                {
                    trace("Old Scene inherits from IPostBox, unsubscribing it from the post office.");
                    this._eventOffice.unsubscribe(cast(IPostBox)this._currentScene.scene);
                }
            }            

            this._currentScene = info;

            this._currentScene.scene.onSwap(this._eventOffice);
            if(this._currentScene.flags & SceneInfo.Flags.IS_POSTBOX)
            {
                trace("New Scene inherits from IPostBox, subscribing it to the post office.");
                this._eventOffice.subscribe(cast(IPostBox)this._currentScene.scene);
            }
        }

        /// A texture cache shared between all `Scene`s
        @property @safe @nogc
        Cache!Texture commonTextures() nothrow
        {
            return this._commonTextureCache;
        }

        /// An `InputManager` provided for easy access for `Scene`s to get user input.
        @property @safe @nogc
        InputManager input() nothrow
        {
            return this._input;
        }
    }
}