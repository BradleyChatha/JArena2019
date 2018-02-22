module jarena.gameplay.scene;

private
{
    import std.experimental.logger;
    import std.typecons : Flag;

    import jarena.core.cache, jarena.core.maths, jarena.core.post, jarena.core.time;
    import jarena.graphics.sprite, jarena.graphics.window;
}

alias AutoRender = Flag!"render";

/// Defines a scene, which can be thought of as a gamestate.
abstract class Scene
{
    private
    {
        enum Flags : ubyte
        {
            None = 0,

            IS_POSTBOX = 1 << 0
        }

        Flags               _flags;
        SceneManager        _manager;
        string              _name;
        GameObject[string]  _objects;
        DrawableObject[]    _drawOrder;
        PostOffice          _proxyEventOffice; // GameObjects will subscribe to this proxy, so GameObjects don't need any knowledge of when a scene is swapped in and out.

        @safe
        void registerDrawable(DrawableObject object)
        {
            object._flags |= GameObject.Flags.IS_AUTO_RENDERED;

            bool wasInsertion = false;
            for(size_t i = 0; i < this._drawOrder.length; i++)
            {
                if(this._drawOrder[i].yLevel > object.yLevel)
                {
                    auto toMove = this._drawOrder[i..$];
                    this._drawOrder.length += 1;

                    foreach(i2, spr; toMove)
                        this._drawOrder[i + (i2 + 1)] = spr;

                    this._drawOrder[i] = object;
                    wasInsertion = true;
                    break;
                }
            }

            // If there was no insertion, then that means there's no obbjects with a higher y-level than this object.
            if(!wasInsertion)
                this._drawOrder ~= object;
        }

        @trusted
        void unregisterDrawable(DrawableObject object)
        {
            if(object._flags & GameObject.Flags.IS_AUTO_RENDERED)
            {
                object._flags &= ~GameObject.Flags.IS_AUTO_RENDERED;

                import std.algorithm : countUntil;
                auto index = this._drawOrder.countUntil(object);
                assert(index != -1, "Bug");

                this._drawOrder.removeAt(index);
            }
        }

        void _onSwap(PostOffice office)
        {
            office.addProxy(this.eventOffice);   
        }

        void _onUnswap(PostOffice office)
        {
            office.removeProxy(this.eventOffice);
        }
    }

    protected
    {
        /++
         + Registers a `GameObject` to this scene.
         +
         + Notes:
         +  This is required for any `GameObject` that calls `GameObject.scene`, or relies on any of the `onXXX` functions.
         +
         +  Any `GameObject` that is registered will have it's `onUpdate` function called when `Scene.updateScene` is called.
         +
         +  Any `GameObject` that is $(B not) registered will have to have their `onUpdate` function called manually.
         +
         +  If `autoRender` is `AutoRender.yes`, and if `object` inherits from `DrawableObject`, then `object` will be flagged for AutoRendering.
         +
         +  An auto rendered object is drawn to the screen whenever the `Scene.renderScene` function is called (usually by inheriting classes in their onUpdate function).
         +
         +  DrawableObjects contain a field called `yLevel`, which determines the order of which the objects are drawn.
         +  The lower the y-level, the sooner the object is drawn. The higher the y-level, the later it is drawn.
         +
         +  Using the y-level is neccessary for making sure certain sprites will always be drawn on top of others (e.g. a player is always drawn on top of the background).
         +
         + Params:
         +  name = The name to give the game object. (This can then be gotten with `GameObject.name`)
         +  object = The game object to register.
         +  autoRender = Whether the object should be automatically rendered or not. (See Notes)
         + ++/
        void register(string name, GameObject object, AutoRender autoRender = AutoRender.yes)
        {
            infof("Scene '%s' is registering a game object named '%s'", this.name, name);

            assert(object !is null);
            object._name = name;
            object._scene = this;

            assert(!this.isRegistered(object), "Attempted to register an object twice, this is a bug.");
            this._objects[name] = object;

            // If the object should be rendered automatically, then add it into the drawOrder array.
            if(autoRender)
            {
                auto drawable = cast(DrawableObject)object;
                assert(drawable !is null, "Attempted to assign a GameObject that does *not* inherit from DrawableObject as an AutoRender object.");

                infof("The game object is being flagged to be auto rendered, it has a Y-level of %s", drawable.yLevel);
                this.registerDrawable(drawable);
            }

            object.onRegister(this._proxyEventOffice);
        }

        /++
         + Unregisters a previously-registered GameObject.
         +
         + Notes:
         +  Any calls to `GameObject.scene` after using this function will result in an assertion failure, as it gets reset to null.
         +
         + Params:
         +  object = The game object to unregister.
         + ++/
        void unregister(GameObject object)
        {
            import std.algorithm : countUntil;

            assert(object !is null);

            infof("Scene '%s' is unregistering a GameObject called '%s'.", this.name, object.name);
            assert(this.isRegistered(object.name), "Attempted to unregister an object with non-existant name: " ~ object.name);

            this._objects.remove(object.name);

            // DrawableObjects have some specialised unregister stuff
            auto drawable = cast(DrawableObject)object;
            if(drawable !is null)
                this.unregisterDrawable(drawable);

            // Final cleanup.
            object.onUnregister(this._proxyEventOffice);
            object._scene = null;
        }

        /++
         + Unregisters a previously-registered `GameObject`.
         +
         + Params:
         +  objectName = The name of the game object to unregister.
         + ++/
        void unregister(string objectName)
        {
            assert(this.isRegistered(objectName), "Attempted to unregister an object with non-existant name: " ~ objectName);
            this.unregister(*(objectName in this._objects));
        }

        /++
         + Returns:
         +  `true` if a `GameObject` with the name of `objectName` is registered.
         + ++/
        bool isRegistered(string objectName)
        {
            return (objectName in this._objects) !is null;
        }

        /++
         + Returns:
         +  `true` if `object` is registered with this scene.
         + ++/
        bool isRegistered(GameObject object)
        {
            return this.isRegistered(object.name);
        }

        /++
         + Renders all `DrawableObjects` that have been flagged as `AutoRender`able.
         +
         + Params:
         +  window = The game's window.
         + ++/
        void renderScene(Window window)
        {
            import std.algorithm : filter;
            foreach(object; this._drawOrder.filter!(o => !o.isHidden))
                object.onRender(window);
        }

        /++
         + Updates all `GameObjects` that have been registered.
         +
         + Params:
         +  window = The game's window.
         +  deltaTime = The amount of time the last frame took to process.
         + ++/
        void updateScene(Window window, GameTime deltaTime)
        {
            foreach(object; this._objects.byValue)
                object.onUpdate(window, deltaTime);
        }

        /++
         + The main event office.
         +
         + Notes:
         +  This is actually a proxy of the main event office, so `GameObjects` don't need to worry about subscribing and unsubscribing during scene swaps.
         + ++/
        @property
        PostOffice eventOffice()
        {
            return this._proxyEventOffice;
        }
    }

    public
    {
        /++
         + Params:
         +  name = The name to give the scene.
         + ++/
        @safe
        this(string name) nothrow
        {
            this._name = name;
            this._proxyEventOffice = new PostOffice();
        }

        /// The `SceneManager` this scene has been registered with.
        @property @safe @nogc
        inout(SceneManager) manager() nothrow inout
        {
            assert(this._manager !is null, "This scene hasn't been registered yet.");
            return this._manager;
        }

        /// The name of this Scene.
        @property @safe @nogc
        string name() nothrow const
        {
            return this._name;
        }
    }

    // The public API is seperated from the protected one, to provide clarity (and make it a lot easier to see what you need to override)
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
    private
    {
        Cache!Scene     _scenes;                // Cache of all scenes.
        Scene           _currentScene;          // Current scene to update
        PostOffice      _eventOffice;           // Main event office.
        Cache!Texture   _commonTextureCache;    // Shared texture cache.
        InputManager    _input;                 // Input Manager for the game's window.
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
            this._scenes = new Cache!Scene;
            this._commonTextureCache = (commonTextures is null) ? new Cache!Texture() : commonTextures;
            this._input = (input is null) ? new InputManager(eventOffice) : input;
        }

        /++
         + Registers a `Scene`.
         +
         + Notes:
         +  If the scene inheirts `IPostBox` then the `SceneManager` will automatically handle subscribing and unsubscribing it.
         +
         + Params:
         +  scene = The scene to register. 
         + ++/
        void register(S : Scene)(S scene)
        {
            tracef("Registering Scene called '%s'", scene.name);

            assert(scene !is null);
            Scene deprecationWorkaround = scene; // Because S is a template param, D doesn't realise that it's valid for this class to access private members.
                                                 // So it gives me a deprecation warning.
            deprecationWorkaround._manager = this;

            static if(is(S : IPostBox))
            {
                trace("The Scene inherits from an IPostBox, so it's onMail function will be subscribed automatically.");
                deprecationWorkaround._flags |= Scene.Flags.IS_POSTBOX;
            }
            
            this._scenes.add(scene.name, scene);

            trace("Initialising Scene");
            scene.onInit();
        }

        /++
         + Updates the current `Scene` (if there is one.)
         +
         + Params:
         +  window = The game's `Window`.
         +  deltaTime = The time the last frame of the game took.
         + ++/
        void onUpdate(Window window, GameTime deltaTime)
        {
            assert(window !is null);

            if(this._currentScene !is null)
                this._currentScene.onUpdate(window, deltaTime);
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

            auto scene = this._scenes.get(sceneName);
            assert(scene !is null, sceneName);
            assert(this._currentScene != scene, "Trying to swap to the current scene, probably a bug.");

            if(this._currentScene !is null)
            {
                this._currentScene.onUnswap(this._eventOffice);
                this._currentScene._onUnswap(this._eventOffice);
                if(this._currentScene._flags & Scene.Flags.IS_POSTBOX)
                {
                    trace("Old Scene inherits from IPostBox, unsubscribing it from the post office.");
                    this._eventOffice.unsubscribe(cast(IPostBox)this._currentScene);
                }
            }            

            this._currentScene = scene;

            this._currentScene._onSwap(this._eventOffice);
            this._currentScene.onSwap(this._eventOffice);
            if(this._currentScene._flags & Scene.Flags.IS_POSTBOX)
            {
                trace("New Scene inherits from IPostBox, subscribing it to the post office.");
                this._eventOffice.subscribe(cast(IPostBox)this._currentScene);
            }

            import core.memory : GC;
            GC.collect(); // Forcing a collection here should hopefully make the GC feel less inclined to collect during a Scene's update function.
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

/++
 + The base GameObject, contains information that is common to all other game objects.
 + ++/
abstract class GameObject
{
    private
    {
        enum Flags : byte
        {
            None = 0,

            IS_AUTO_RENDERED = 1 << 0, // only useful for DrawableObjects
            IS_HIDDEN        = 1 << 1, // only useful for DrawableObjects
        }

        string _name;
        Scene _scene;
        Flags _flags;
    }

    public
    {
        /// The `Scene` that this object belongs to.
        @property @safe @nogc
        inout(Scene) scene() nothrow inout
        {
            assert(this._scene !is null, "This GameObject hasn't been registered to a scene yet.");
            return this._scene;
        }

        /// The name that this object has been registered as.
        @property @safe @nogc
        string name() nothrow const
        {
            return this._name;
        }
    }

    public abstract
    {
        /++
         + Called whenever the game object is registered with a `Scene`.
         +
         + Notes:
         +  Unlike a `Scene`, game objects that inherit from `IPostBox` aren't automatically subscribed/unsubscribed
         +  to the main event `PostOffice`, so this must be done manually during onRegister and onUnregister.
         +
         +  This is because, a `Scene` may provide it's own/differente `PostOffices`, so having GameObjects auto subscribe to the
         +  main event office might be undesirable.
         +
         + Params:
         +  office = The main event office. (see `Scene.eventOffice`)
         + ++/
        void onRegister(PostOffice office);

        /++
         + Called whenever the game object is unregistered with a `Scene`.
         +
         + Params:
         +  office = The main event office.
         + ++/
        void onUnregister(PostOffice office);
        
        /++
         + Called whenever the game object should update (usually every frame).
         +
         + Params:
         +  window = The game's window.
         +  deltaTime = The amount of time the last frame took to process.
         + ++/
        void onUpdate(Window window, GameTime deltaTime);
    }
}

/++
 + The base class for any GameObject that can be drawn to the screen.
 +
 + Notes:
 +  This class will be special cased for classes that handle rendering, so please make sure any drawable objects inherit from this.
 + ++/
abstract class DrawableObject : GameObject
{
    private
    {
        int _yLevel;
    }

    public
    {
        /// The object's y-level (See `Scene.register`)
        @property @safe @nogc
        int yLevel() nothrow const
        {
            return this._yLevel;
        }

        /// The object's y-level
        @property @safe
        void yLevel(int level)
        {
            this._yLevel = level;

            if(this._flags & Flags.IS_AUTO_RENDERED)
            {
                super.scene.unregisterDrawable(this);
                super.scene.registerDrawable(this);
            }
        }

        /// Whether ths object is hidden from the scene or not.
        @property @safe @nogc
        bool isHidden() nothrow const
        {
            return (this._flags & Flags.IS_HIDDEN) > 0;
        }

        /// ditto
        @property @safe @nogc
        void isHidden(bool hidden) nothrow
        {
            if(hidden)
                this._flags |= Flags.IS_HIDDEN;
            else
                this._flags &= ~Flags.IS_HIDDEN;
        }
    }

    public abstract
    {
        /++
         + Called when the object should draw itself.
         +
         + Params:
         +  window = The game's window.
         + ++/
        void onRender(Window window);
    }
}