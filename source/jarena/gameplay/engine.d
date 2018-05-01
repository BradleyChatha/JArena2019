module jarena.gameplay.engine;

private
{
    import std.experimental.logger;
    import std.typecons;
    import jarena.audio, jarena.core, jarena.graphics, jarena.gameplay, jarena.data;
    import opengl;

    const ENGINE_CONFIG_PATH        = "data/engineConf.sdl";
    const ENGINE_DATA_PATH          = "data/data.sdl";
    const WINDOW_NAME               = "JArena";
    const WINDOW_DEFAULT_SIZE       = uvec2(860, 740);
    const WINDOW_DEFAULT_FPS        = 60;
    const DEBUG_FONT                = "Data/Fonts/Spaceport_2006.otf";
    const DEBUG_FONT_SIZE           = 10;
    const DEBUG_TEXT_COLOUR         = Colours.rockSalt;
    const DEBUG_CONTAINER_COLOUR    = Colour(0, 0, 0, 128);
    const DEBUG_CONTAINER_POSITION  = vec2(1);
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
        char[512]       _debugBuffer;
        Font            _debugFont;
        SimpleLabel     _debugText;
        StackContainer  _debugGui;
        Camera          _debugCamera;
    }

    public final
    {
        ///
        void onInit()
        {
            import sdlang;
            import std.file : exists;
            
            // Read in the config
            if(exists(ENGINE_CONFIG_PATH))
            {
                tracef("Loading config file from '%s'", ENGINE_CONFIG_PATH);
                this._config.updateFromSdlTag(parseFile(ENGINE_CONFIG_PATH));
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
            this._debugGui      = new StackContainer(DEBUG_CONTAINER_POSITION, StackContainer.Direction.Horizontal, DEBUG_CONTAINER_COLOUR);
            this._debugGui.addChild(this._debugText);
            this._debugCamera   = new Camera(RectangleF(0, 0, vec2(this._window.size)));
            this._frameTime     = (1000 / this._config.targetFPS.get(WINDOW_DEFAULT_FPS)).msecs;
            this._audio         = new AudioManager();
            
            // Setup init info
            Systems.window = this._window;
            Systems.audio  = this._audio;
            Systems.finalise();

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
                this._debugText.updateTextASCII(sformat(this._debugBuffer, "FPS: %s | Time: %sms | RAM: %sMB", 
                                                        this._fps.frameCount, 
                                                        this._fps.elapsedTime.total!"msecs",
                                                        getMemInfo().usedRAM / (1024 * 1024)));
            });
            this.events.subscribe(Window.Event.Close, (_,__) => this._window.close());

            // Load in assets
            SdlangLoader.parseFile(ENGINE_DATA_PATH, this.scenes.cache);

            // Debug stuff
            debug this._config.showDebugText = true;
            if(this._config.showDebugText.get(false))
                this._timers.every(1.seconds, (){this.events.mailCommand(Event.UpdateFPSDisplay);});
        }

        ///
        void onUpdate()
        {
            this._fps.onUpdate();
            this._input.onUpdate();
            this._window.handleEvents(this._eventOffice);
            
            if(this._input.isKeyDown(Scancode.ESCAPE))
                this._window.close();

            this._window.renderer.clear();
            this._timers.onUpdate(this._fps.elapsedTime);
            this._scenes.onUpdate(this._window, this._fps.elapsedTime);
            this._audio.onUpdate();

            auto old = this._window.renderer.camera;
            this._window.renderer.camera = this._debugCamera; // So the debug UI doesn't fly off the screen.
            this._debugGui.onUpdate(this.input, this._fps.elapsedTime);
            this._debugGui.onRender(this._window);
            this._window.renderer.camera = old;
            
            this._window.renderer.displayChanges();
            checkSDLError();
            GL.checkForError();
        }

        ///
        void doLoop()
        {
            while(!this._window.shouldClose)
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
    @Serialisable
    struct Config
    {
        mixin SerialisableInterface;

        Nullable!uvec2 windowSize;
        Nullable!int   targetFPS;
        Nullable!bool  showDebugText;
    }
}
