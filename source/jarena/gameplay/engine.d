module jarena.gameplay.engine;

private
{
    import std.experimental.logger;
    import std.typecons;
    import jarena.core, jarena.graphics, jarena.gameplay, jarena.data;
    import opengl;
}

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
        uvec2*       _windowSizePtr;
        Duration     _frameTime;

        // Debug stuff
        char[512]       _debugBuffer;
        Font            _debugFont;
        SimpleLabel     _debugText;
        StackContainer  _debugGui;
        Camera          _debugCamera;
    }

    public
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
            
            // Setup init info
            InitInfo.windowSize = this._window.size;
            this._windowSizePtr = InitInfo.windowSize_ptr; // Reminder: Only one pointer is given out before an assert fails, so this is safe.

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
            this.events.subscribe(Window.Event.Resized, (_, m)
            {
                auto mail = cast(ValueMail!uvec2)m;
                assert(mail !is null);

                *this._windowSizePtr = mail.value;
            });

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

            auto old = this.window.renderer.camera;
            this.window.renderer.camera = this._debugCamera; // So the debug UI doesn't fly off the screen.
            this._debugGui.onUpdate(this.input, this._fps.elapsedTime);
            this._debugGui.onRender(this.window);
            this.window.renderer.camera = old;
            
            this._window.renderer.displayChanges();
            checkSDLError();
            checkGLError();
        }

        ///
        void doLoop()
        {
            import core.thread : Thread;

            MonoTime start;
            MonoTime end;
            while(!this._window.shouldClose)
            {
                start = MonoTime.currTime;
                this.onUpdate();
                end = MonoTime.currTime;

                auto taken = (end - start);
                if(taken < this._frameTime)
                    Thread.sleep(this._frameTime - taken);
            }
        }

        ///
        @property @safe @nogc
        inout(Window) window() nothrow inout
        {
            return this._window;
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
