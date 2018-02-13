module jarena.gameplay.scene;

private
{
    import std.experimental.logger;

    import jarena.core.cache, jarena.core.maths, jarena.core.post, jarena.core.time;
    import jarena.graphics.sprite, jarena.graphics.window;
}

///
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
        ///
        void registerSprite(Sprite sprite, int yLevel)
        {
            this._manager.registerSprite(this, sprite, yLevel);
        }
    }

    public
    {
        ///
        @safe @nogc
        this(string name) nothrow
        {
            this._name = name;
        }

        ///
        @property @safe @nogc
        inout(SceneManager) manager() nothrow inout
        {
            return this._manager;
        }

        ///
        @property @safe @nogc
        string name() nothrow const
        {
            return this._name;
        }
    }

    public abstract
    {
        void onInit();
        void onSwap(PostOffice office);
        void onUnswap(PostOffice office);
        void onUpdate(Window window, GameTime deltaTime);
    }
}

///
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
        Cache!SceneInfo _scenes;
        SceneInfo       _currentScene;
        PostOffice      _eventOffice; // Main event office.
        Cache!Texture   _commonTextureCache;
        InputManager    _input;

        // Private, so only the Scene class can access it (don't want some random function randomly adding sprites in.)
        void registerSprite(Scene scene, Sprite sprite, int yLevel)
        {
            assert(scene !is null);
            assert(sprite !is null);
            auto spriteInfo = SpriteInfo(sprite, yLevel);
            auto sceneInfo = this._scenes.get(scene.name);

            infof("Registering sprite with Y-Level of %s", yLevel);

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
    }

    public
    {
        ///
        this(PostOffice eventOffice, InputManager input = null, Cache!Texture commonTextures = null)
        {
            assert(eventOffice !is null);

            this._eventOffice = eventOffice;
            this._scenes = new Cache!SceneInfo;
            this._commonTextureCache = (commonTextures is null) ? new Cache!Texture() : commonTextures;
            this._input = (input is null) ? new InputManager(eventOffice) : input;
        }

        ///
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

        ///
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

        ///
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