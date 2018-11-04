module jarena.gameplay.engine;

private
{
    import std.experimental.logger;
    import std.typecons, std.datetime;
    import jarena.audio, jarena.core, jarena.graphics, jarena.gameplay, jarena.data, jarena.maths;
    import opengl;

    const ENGINE_CONFIG_PATH        = "data/engineConf.sdl";
    const ENGINE_DATA_PATH          = "data/data.sdl";
    const DEFAULT_COMPOUND_SIZE     = uvec2(256, 256);
    const WINDOW_NAME               = "JArena";
    const WINDOW_DEFAULT_SIZE       = uvec2(860, 740);
    const WINDOW_DEFAULT_FPS        = 60;
    const WINDOW_DEFAULT_VSYNC      = true;
    const DEBUG_FONT                = "Data/Fonts/Spaceport_2006.otf";
    const DEBUG_FONT_SIZE           = 10;
    const DEBUG_TEXT_COLOUR         = Colours.rockSalt;
    const DEBUG_CONTAINER_COLOUR    = Colour(0, 0, 0, 128);
    const DEBUG_CONTAINER_POSITION  = vec2(1);
    const STATISTIC_DISPLAY_CHANGES = "displayChanges";
    const STATISTIC_FRAME_UPDATE    = "frameUpdate";
    const STATISTIC_DEBUG_UPDATE    = "debugUpdate";
}

/++
 + Contains all the core code for the game.
 + ++/
final class Engine
{
    enum Event : Mail.MailTypeT
    {
        UpdateFPSDisplay = 200
    }

    private
    {
        Window       _window;
        PostOffice   _eventOffice;
        InputManager _input;
        FPS          _fps;
        SceneManager _scenes;
        Timers       _timers;
        Config       _config;
        Duration     _frameTime;
        AudioManager _audio;

        // Debug stuff
        char[512]           _debugBuffer;
        Font                _debugFont;
        SimpleLabel         _debugText;
        StackContainer      _debugGui;
        Camera              _debugCamera;
        EngineDebugControls _debugControls;
    }

    public final
    {
        ///
        void onInit()
        {
            import std.file : exists;
            
            // Read in the config
            if(exists(ENGINE_CONFIG_PATH))
            {
                tracef("Loading config file from '%s'", ENGINE_CONFIG_PATH);
                auto archive = new ArchiveSDL();
                archive.loadFromFile(ENGINE_CONFIG_PATH);

                this._config = Serialiser.deserialise!Config(archive.root);
            }
            else
                tracef("No config file exists. Please create one at '%s'", ENGINE_CONFIG_PATH);
                
            // Setup variables
            // The window also sets up the OpenGL context.
            import std.stdio;
            this._window        = new Window(WINDOW_NAME, this._config.windowSize.get(WINDOW_DEFAULT_SIZE));
            this._eventOffice   = new PostOffice();
            this._input         = new InputManager(this._eventOffice);
            this._fps           = new FPS();
            this._scenes        = new SceneManager(this._eventOffice, this._input);
            this._timers        = new Timers();
            this._debugFont     = new Font(DEBUG_FONT);
            this._debugText     = new SimpleLabel(new Text(this._debugFont, "", vec2(0), DEBUG_FONT_SIZE, DEBUG_TEXT_COLOUR));
            this._debugGui      = new StackContainer(DEBUG_CONTAINER_POSITION, StackContainer.Direction.Vertical, DEBUG_CONTAINER_COLOUR);
            this._debugGui.addChild(this._debugText);
            this._debugCamera   = new Camera(RectangleF(0, 0, vec2(this._window.size)));
            this._debugControls = new EngineDebugControls(this, this._config.debugControls.get(false));
            this._frameTime     = (1000 / this._config.targetFPS.get(WINDOW_DEFAULT_FPS)).msecs;
            this._audio         = new AudioManager();

            this._window.vsync = this._config.vsync.get(WINDOW_DEFAULT_VSYNC);

            // Setup init info
            Systems.window              = this._window;
            Systems.assets              = new AssetManager();
            Systems.loaderSdlang        = new LoaderSDL();
            Systems.audio               = this._audio;
            Systems.shortTermScheduler  = new ShortTermScheduler();
            Systems.statistics          = new EngineStatistics();
            Systems.finalise();

            Systems.statistics.makeTimer(STATISTIC_DISPLAY_CHANGES, 60);
            Systems.statistics.makeTimer(STATISTIC_FRAME_UPDATE, 60);
            Systems.statistics.makeTimer(STATISTIC_DEBUG_UPDATE, 60);
            Systems.renderResources.compoundTextureSize = this._config.compoundTextureSize.get(DEFAULT_COMPOUND_SIZE);

            // Make sure the post office types are valid
            // (_ALL_ events that are to be used with this office should be reserved here
            //  even if they're in completely unrelated modules. This makes it easy to see
            //  which events work with this office, and helps stay organised.)
            this._eventOffice.reserveTypes!(Window.Event);
            this._eventOffice.reserveTypes!(Engine.Event);

            // Add in other stuff
            this.events.subscribe(Event.UpdateFPSDisplay, (_, __)
            {
                import std.format : sformat;
                this._debugText.updateText(sformat(this._debugBuffer, "FPS: %s | Time: %sms | RAM: %sMB", 
                                                   this._fps.frameCount, 
                                                   this._fps.elapsedTime.total!"msecs",
                                                   getMemInfo().usedRAM / (1024 * 1024)));
            });
            this.events.subscribe(Window.Event.Close, (_,__) => this._window.close());

            // Load in assets
            version(JArena_EngineOnly){}
            else Systems.loaderSdlang.loadPackage("Data/data.sdl");

            // Debug stuff
            debug this._config.showDebugText = true;
            if(this._config.showDebugText.get(false))
                this._timers.every(1.seconds, (){this.events.mailCommand(Event.UpdateFPSDisplay);});
        }

        ///
        void onUpdate()
        {
            Systems.statistics.timeFunction(STATISTIC_FRAME_UPDATE,
            (){
                this._fps.onUpdate();
                this._input.onUpdate();
                this._window.handleEvents(this._eventOffice);
                
                if(this._input.isKeyDown(Scancode.ESCAPE))
                    this._window.close();

                this._window.renderer.clear();

                this._timers.onUpdate(this._fps.elapsedTime);
                this._scenes.onUpdate(this._window, this._fps.elapsedTime);
                this._audio.onUpdate();
            });

            Systems.statistics.timeFunction(STATISTIC_DEBUG_UPDATE,
            (){
                auto old = this._window.renderer.camera;
                this._window.renderer.camera = this._debugCamera; // So the debug UI doesn't fly off the screen.
                this._debugGui.onUpdate(this.input, this._fps.elapsedTime);
                this._debugControls.onUpdate(this.input, this._fps.elapsedTime);
                this._debugGui.onRender(this._window);
                this._debugControls.onRender(this._window.renderer);
                this._window.renderer.camera = old;
            });
            
            Systems.statistics.timeFunction(STATISTIC_DISPLAY_CHANGES, &this._window.renderer.displayChanges);

            checkSDLError();
            GL.checkForError();

            Systems.shortTermScheduler.onPostFrame();
        }

        ///
        void doLoop()
        {
            while(!this._window.isClosed)
                this.onUpdate();
        }

        ///
        @property @safe @nogc
        inout(PostOffice) events() nothrow inout
        {
            return this._eventOffice;
        }

        ///
        @property @safe @nogc
        inout(InputManager) input() nothrow inout
        {
            return this._input;
        }

        ///
        @property @safe @nogc
        inout(SceneManager) scenes() nothrow inout
        {
            return this._scenes;
        }
    }

    ///
    struct Config
    {
        Nullable!uvec2 windowSize;
        Nullable!int   targetFPS;
        Nullable!bool  showDebugText;
        Nullable!bool  vsync;
        Nullable!bool  debugControls;
        Nullable!uvec2 compoundTextureSize;
    }
}

/++
 + A system that is used to schedule certain tasks for an upcoming point of time.
 + ++/
class ShortTermScheduler
{
    private
    {
        IDisposable[] _endOfFrameDisposables;

        void onPostFrame()
        {
            foreach(disposable; this._endOfFrameDisposables)
                disposable.dispose(ScheduledDispose.yes);

            this._endOfFrameDisposables.length = 0;
        }
    }

    public
    {
        /++
         + Scheduels the given `IDisposable` to have it's `IDisposable.dispose` called, with the
         + 'scheduled' parameter set to `ScheduledDispose.yes`, after the current frame has been updated and rendered.
         +
         + Schedule a dispose for this time frame if your object might need to be used for one last frame before it can
         + safely be disposed of.
         +
         + Assertions:
         +  `disposable` can not be `null`.
         +
         + Params:
         +  disposable = The `IDisposable` to dispose of.
         + ++/
        void postFrameDispose(IDisposable disposable)
        {
            assert(disposable !is null);

            this._endOfFrameDisposables ~= disposable;
        }
    }
}

/++
 + A class that is used to keep track of performance statistics.
 +
 + This class is a system, so an instance can be accessed via the `Systems` class.
 +
 + To see the data contained in this class, make sure `debugControls` in the engine configuration is set to true,
 + and then press F11+S to enable the visuals.
 + ++/
final class EngineStatistics
{
    /// A timer will keep track of how long something took over a certain amount of frames
    struct Timer
    {
        /// The name of this statistic.
        string name;

        /// How many frames the timer values span through.
        uint frameSpan;

        /// The durations, this array will be the have a length of `frameSpan`.
        Duration[] values;

        private size_t currentIndex;

        /++
         + Returns:
         +  The average of all the values in `value`.
         + ++/
        @property @safe
        Duration average() nothrow const
        {
            import std.algorithm : reduce;
            return reduce!"a + b"(0.seconds, this.values) / this.values.length;
        }
    }

    private
    {
        Timer[string] _timers;
    }

    public
    {
        /++
         + Creates a new timer to keep track of.
         +
         + Params:
         +  name        = The name to give tht timer.
         +  frameSpan   = How many frames to track the timer's values over.
         + ++/
        void makeTimer(string name, uint frameSpan = 60)
        {
            enforceAndLogf((name in this._timers) is null, "The timer '%s' already exists.", name);
            enforceAndLogf(frameSpan > 0, "Parameter frameSpan cannot be 0.");

            this._timers[name] = Timer(name, frameSpan, new Duration[frameSpan], 0);
        }

        /++
         + Adds a value into a timer.
         +
         + Params:
         +  name = The name of the timer to add a value to.
         +  time = The time to add as a value.
         + ++/
        void addTimerValue(string name, Duration time)
        {
            auto ptr = (name in this._timers);
            enforceAndLogf(ptr !is null, "The timer '%s' doesn't exist.", name);

            ptr.values[ptr.currentIndex++] = time;
            if(ptr.currentIndex >= ptr.values.length)
                ptr.currentIndex = 0;
        }

        /++
         + Times the execution time for a function, and adds it's execution time
         + to the specified timer.
         +
         + Params:
         +  timerName = The name of the timer to use.
         +  func      = The function to time.
         + ++/
        void timeFunction(string timerName, scope void delegate() func)
        {
            auto start = Clock.currTime;
            func();
            this.addTimerValue(timerName, (Clock.currTime - start));
        }

        /++
         + Returns:
         +  An InputRange of all the timers.
         + ++/
        @safe @nogc
        auto timers() nothrow inout pure
        {
            return this._timers.byValue;
        }
    }
}

private class EngineDebugControls
{
    // General variables.
    bool _enabled = false;
    bool statsEnabled = false;
    Engine engine;

    this(Engine engine, bool enabled)
    {
        if(!enabled) return;

        this.engine  = engine;
        this.onInitStats();

        this.enabled = enabled;
    }

    void onUpdate(InputManager input, Duration delta)
    {
        if(!this._enabled) return;

        if(input.isKeyDown(Scancode.F11) && input.wasKeyTapped(Scancode.S))
        {
            this.statsEnabled = !this.statsEnabled;
            if(this.statsEnabled)
                this.onEnableStats();
            else
                this.onDisableStats();
        }

        if(this.statsEnabled)
            this.onUpdateStats();
    }

    void onRender(Renderer renderer)
    {
        if(!this._enabled) return;
    }

    @property
    void enabled(bool en)
    {
        this._enabled = en;
        this.statsEnabled = false;
    }

    // ########################
    // # ENGINE STATISTICS UI #
    // ########################
    private
    {
        SimpleLabel         statHeaderLabel;
        SimpleLabel[string] statLabels;

        void onInitStats()
        {
            this.statHeaderLabel = new SimpleLabel(
                        new Text(
                            engine._debugFont,
                            "STATISTIC TIMERS:",
                            vec2(0),
                            DEBUG_FONT_SIZE,
                            DEBUG_TEXT_COLOUR
                        )
                    );
        }

        void onDisableStats()
        {
            foreach(k, v; this.statLabels)
                v.parent = null;

            this.statHeaderLabel.parent = null;
        }

        void onEnableStats()
        {
            this.engine._debugGui.addChild(this.statHeaderLabel);
            foreach(k, v; this.statLabels)
                this.engine._debugGui.addChild(v);
        }

        void onUpdateStats()
        {
            foreach(timer; Systems.statistics.timers)
            {
                auto ptr = (timer.name in this.statLabels);
                if(ptr is null)
                {
                    this.statLabels[timer.name] = new SimpleLabel(
                        new Text(
                            engine._debugFont,
                            "",
                            vec2(0),
                            DEBUG_FONT_SIZE,
                            DEBUG_TEXT_COLOUR
                        )
                    );
                    ptr = (timer.name in this.statLabels);
                    this.engine._debugGui.addChild(*ptr);
                }

                import std.format;
                ptr.updateText(format("%s: avg. %s ms (%s s) per %s frames", timer.name, timer.average.total!"msecs", timer.average.asSeconds, timer.frameSpan));
            }
        }
    }
}