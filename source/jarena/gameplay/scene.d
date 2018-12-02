///
module jarena.gameplay.scene;

private
{
    import std.experimental.logger;
    import std.typecons : Flag;

    import jarena.audio, jarena.core, jarena.graphics, jarena.maths, jarena.gameplay.gui;

    const TOGGLE_EDITOR_KEY = Scancode.F12;
}

/// Passed to `Scene.register`
alias AutoRender = Flag!"render";

/// A UDA to attach onto a `Scene` to provide it's name
/// The reason a UDA is used is because overriding static functions seems impossible
/// and leaving it up to the programmer/scene instance itself is just buggy/annoying.
struct SceneName
{
    /// The name to give the scene
    string name;

    /// Gets a `SceneName.name` from `T`.
    static string getFrom(T : Scene)()
    {
        import std.traits : getUDAs;

        alias udas = getUDAs!(T, SceneName);
        static assert(udas.length == 1, "Class " ~ T.stringof ~ " has either 0, or more than 1 @SceneName attached. Only 1 is allowed.");

        return udas[0].name;
    } 
}

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
        FreeformContainer   _gui;
        Camera              _guiCamera;
        Camera              _sceneCamera;
        
        @safe
        void registerDrawable(DrawableObject object)
        {
            import std.range : retro, enumerate;
            object._flags |= GameObject.Flags.IS_AUTO_RENDERED;

            bool wasInsertion = false;
            for(size_t i = 0; i < this._drawOrder.length; i++)
            {
                if(this._drawOrder[i].yLevel > object.yLevel)
                {
                    auto toMove = this._drawOrder[i..$];
                    this._drawOrder.length += 1;

                    foreach(i2, spr; toMove.retro.enumerate)
                        this._drawOrder[($ - 1) - i2] = spr;

                    this._drawOrder[i] = object;
                    wasInsertion = true;
                    break;
                }
            }

            // If there was no insertion, then that means there's no obbjects with a higher y-level than this object.
            if(!wasInsertion)
                this._drawOrder ~= object;

            debug
            {
                import std.algorithm : map, joiner;

                //auto names = this._drawOrder.map!(o => "\"" ~ o.name ~ "\"").joiner(", ");
                //tracef("Draw Order after addition: [%s]", names);
            }
        }

        @trusted
        void unregisterDrawable(DrawableObject object)
        {
            if(object._flags & GameObject.Flags.IS_AUTO_RENDERED)
            {
                object._flags &= ~cast(int)GameObject.Flags.IS_AUTO_RENDERED;

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

        // Needed for any setup that needs to access the scene manager.
        void _onInit()
        {
            auto cameraRect         = RectangleF(0, 0, vec2(Systems.window.size));
            this._proxyEventOffice  = new PostOffice();
            this._gui               = new FreeformContainer();
            this._gui.margin        = RectangleF(0, 0, 0, 0);
            this._guiCamera         = new Camera(cameraRect);
            this._sceneCamera       = new Camera(cameraRect);
        }

        void _onUpdate(Duration deltaTime, InputManager input)
        {
            import std.stdio : writeln;
            
            // if(this.manager.input.wasKeyTapped(TOGGLE_EDITOR_KEY))
            // {
            //     this._oldGui.canEdit = !this._oldGui.canEdit;
            //     if(this._oldGui.canEdit)
            //         writeln("!!!<SCENE GUI EDITOR ENABLED>!!!");
            //     else
            //         writeln("!!!<SCENE GUI EDITOR DISABLED>!!!");
            // }

            // if(this._oldGui.canEdit)
            //     this.updateUI(deltaTime);
            // else
                this.onUpdate(deltaTime, input);
        }
    }

    protected final
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
         + Gets a game object.
         +
         + Params:
         +  objectName = The name of the object to get.
         +
         + Returns:
         +  The object, or null if the object wasn't found.
         + ++/
        T get(T : GameObject = GameObject)(string objectName)
        {
            auto ptr = (objectName in this._objects);
            if(ptr is null)
                return null;

            auto obj = cast(T)*ptr;
            assert(obj !is null, "Cannot cast object '" ~ objectName ~ "' into a " ~ T.stringof);

            return obj;
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
         + Any drawable object that is hidden won't be rendered to the screen.
         +
         + The `Camera` for the window's `Renderer` will be set to this Scene's `Scene.camera`
         + before rendering, and $(B won't) be reset back to it's original.
         +
         + Params:
         +  window = The game's window.
         + ++/
        void renderScene(Window window)
        {
            import std.algorithm : filter;
            window.renderer.camera = this.camera;
            foreach(object; this._drawOrder.filter!(o => !o.isHidden))
                object.onRender(window);
        }

        /++
         + Updates all `GameObjects` that have been registered.
         +
         + Params:
         +  deltaTime = The amount of time the last frame took to process.
         + ++/
        void updateScene(Duration deltaTime)
        {
            foreach(object; this._objects.byValue)
                object.onUpdate(deltaTime, this.manager.input);
        }

        /++
         + Renders the Scene's UI.
         +
         + This means it also renders any `OldUIElement`s added to the scene's `Scene.gui` container.
         +
         + Unlike `renderScene`, this function does not get affected by a `Camera`.
         + When this function is called, it will store the current camera temporarily, set
         + the camera to (0, 0, windowSize), render the gui, then set the old camera back.
         +
         + This is to ensure no funky logic is needed to make sure the UI is kept in the same place
         + on screen.
         +
         + Params:
         +  window = The game's window.
         + ++/
        void renderUI(Window window)
        {
            auto old = window.renderer.camera;

            window.renderer.camera = this._guiCamera;
            this._gui.onRender(window.renderer);
            window.renderer.camera = old;
        }

        /++
         + Updates the Scene's UI.
         +
         + This means it also updates any `OldUIElement`s added to the scene's `Scene.gui` container.
         +
         + Params:
         +  deltaTime = The amount of time the previous frame took.
         + ++/
        void updateUI(Duration deltaTime)
        {
            this._gui.onUpdate(this.manager.input, deltaTime);
        }

        @property
        FreeformContainer gui()
        {
            return this._gui;
        }

        /++
         + Sets the `Camera` used by `renderScene` to render the scene.
         +
         + Any scene that renders outside of `renderScene` should aim to use this
         + camera for any rendering, unless there is a good reason not to.
         +
         + Params:
         +  cam = The camera to use.
         + ++/
        @property @safe @nogc
        void camera(Camera cam) nothrow
        {
            assert(cam !is null, "The camera is null");
            this._sceneCamera = cam;
        }
        
        /++
         + Returns:
         +  The `Camera` used by `renderScene` to render the scene.
         + ++/
        @property @safe @nogc
        Camera camera() nothrow
        {
            return this._sceneCamera;
        }

        /++
         + Notes:
         +  A few issues prevent this camera from being marked `const`, but should still
         +  be treated as such.
         +
         + Returns:
         +  The camera used when rendering the GUI, to make custom UI elements easier to render.
         + ++/
        @property @safe @nogc
        Camera guiCamera() nothrow
        {
            return this._guiCamera;
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
        /// The `SceneManager` this scene has been registered with.
        @property @safe @nogc
        inout(SceneManager) manager() nothrow inout
        {
            assert(this._manager !is null, "This scene hasn't been registered yet.");
            return this._manager;
        }

        /++
         + Notes:
         +  The name of a scene is only set after it's registered with a `SceneManager`.
         +
         + Returns:
         +  The name of this scene.
         + ++/
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
         + Notes:
         +  `office` is $(B not) the proxy office each scene contains, but rather the proper, main post office.
         +  In most cases the proxy will be fine, and onSwap/onUnswap will be fairly useless, but there may be cases
         +  where a proxy isn't what's needed.
         +
         +  The main example is for when a Scene wants to listen and react to a certain mail event, while not being
         +  the currently processed scene.
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
         +  deltaTime = The amount of time the last frame took to process (used for making speed frame-independent).
         +  input     = A shortcut to the `SceneManager`'s `InputManager`. (so you don't have to do `super.manager.input` everywhere)
         + ++/
        void onUpdate(Duration deltaTime, InputManager input);

        /++
         + Called everytime the scene should render it's current state to the screen.
         +
         + Params:
         +  window = The game's window.
         + ++/
        void onRender(Window window);
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
        InputManager    _input;                 // Input Manager for the game's window.
        Buffer!Scene    _sceneStack;            // Stack of scenes.
    }

    public
    {
        /++
         + Notes:
         +  If `input` is `null`, then one is created, and paired with the `eventOffice`.
         +
         + Params:
         +  eventOffice = A `PostOffice` that is recieving events from core game features, such as the `Window`.
         +  input = An `InputManager` that should be paried with the `eventOffice`.
         + ++/
        this(PostOffice eventOffice, InputManager input = null)
        {
            assert(eventOffice !is null);

            this._eventOffice = eventOffice;
            this._scenes      = new Cache!Scene;
            this._sceneStack  = new Buffer!Scene;
            this._input       = (input is null) ? new InputManager(eventOffice) : input;
        }
		
		/// Registers a `Scene` using it's `@SceneName` UDA.
		/// See_Also: The other overload of this function.
		void register(S : Scene)(S scene)
		{
			this.register(SceneName.getFrom!S, scene);
		}

        /++
         + Registers a `Scene` with a custom name.
         +
         + Notes:
         +  If the scene inheirts `IPostBox` then the `SceneManager` will automatically handle subscribing and unsubscribing it.
         +
		 +  This function will ignore the Scene's @SceneName UDA, please see the other overload of this function for that.
		 +  This overload is generally advised for when a Scene object is created and registered multiple times
		 +  (e.g. You may have a single class that is used to represent a level, but each level has their own object of that class.)
		 +
         + Params:
		 +  name  = The name to give the scene.
         +  scene = The scene to register. 
         + ++/
        void register(string name, Scene scene)
        {
            assert(scene !is null);
            scene._manager = this;
            scene._name = name;

            tracef("Registering Scene called '%s'", scene.name);
            static if(is(S : IPostBox))
            {
                trace("The Scene inherits from an IPostBox, so it's onMail function will be subscribed automatically.");
                scene._flags |= Scene.Flags.IS_POSTBOX;
            }
            
            this._scenes.add(scene.name, scene);

            trace("Initialising Scene");
            scene._onInit();
            scene.onInit();
        }

        /++
         + Updates and renders the current `Scene` (if there is one.)
         +
         + Params:
         +  window = The game's `Window`.
         +  deltaTime = The time the last frame of the game took.
         + ++/
        void onUpdate(Window window, Duration deltaTime)
        {
            assert(window !is null);

            if(this._currentScene !is null)
            {
                this._currentScene._onUpdate(deltaTime, this.input);
                this._currentScene.onRender(window);
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
         +  S = The `Scene` to swap to.
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

        /// ditto
        void swap(S : Scene)()
        {
            this.swap(SceneName.getFrom!S);
        }

        /++
         + Pushes a scene.
         +
         + Notes:
         +  When a scene is pushed, the $(B current) scene is added onto a stack.
         +
         +  The given scene is then swapped into.
         +
         + Params:
         +  sceneName = The name of the scene to push.
         + ++/
        void push(string sceneName)
        {
            tracef("Pushing scene '%s'", sceneName);

            if(this._currentScene !is null)
                this._sceneStack ~= this._currentScene;

            this.swap(sceneName);
        }

        /// ditto
        void push(S : Scene)()
        {
            this.push(SceneName.getFrom!S);
        }

        /++
         + Pops the scene from the top of the stack and swaps to it.
         +
         + Returns:
         +  `false` if the stack is empty.
         + ++/
        bool pop()
        {
            if(this._sceneStack.length == 0)
            {
                warning("Attempted to pop the scene stack when the stack is empty.");
                return false;
            }

            trace("Popping scene stack.");
            this.swap(this._sceneStack[$-1].name);
            this._sceneStack.length = this._sceneStack.length - 1;

            return true;
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
         +  This is because, a `Scene` may provide it's own/different `PostOffices`, so having GameObjects auto-subscribe to the
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
         +  deltaTime = The amount of time the last frame took to process.
         +  input     = A shortcut to the `SceneManager`'s `InputManager`. (so you don't have `super.scene.manager.input` everywhere.)
         + ++/
        void onUpdate(Duration deltaTime, InputManager input);
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
                this._flags &= ~cast(int)Flags.IS_HIDDEN;
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
