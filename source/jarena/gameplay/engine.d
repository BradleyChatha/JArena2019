module jarena.gameplay.engine;

private
{
    import std.experimental.logger;
    import jarena.core, jarena.graphics, jarena.gameplay, jarena.data;
}

const ENGINE_CONFIG_PATH = "data/engineConf.sdl";
const WINDOW_NAME = "JArena";
const DEBUG_FONT = "Data/Fonts/crackdown.ttf";
const DEBUG_FONT_SIZE = 10;
const DEBUG_TEXT_COLOUR = colour(255, 255, 255, 255);
const DEBUG_TEXT_THICC = 0;
const DEBUG_CONTAINER_COLOUR = colour(0, 0, 0, 128);
const DEBUG_CONTAINER_POSITION = vec2(0);

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

        // Debug stuff
        char[512]       _debugBuffer;
        Font            _debugFont;
        SimpleLabel     _debugText;
        StackContainer  _debugGui;
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
                this._config.fromSdlTag(parseFile(ENGINE_CONFIG_PATH));
            }
            else
                tracef("No config file exists. Please create one at '%s'", ENGINE_CONFIG_PATH);
                
            // Setup variables
            this._window        = new Window(WINDOW_NAME, this._config.windowSize, this._config.targetFPS);
            this._eventOffice   = new PostOffice();
            this._input         = new InputManager(this._eventOffice);
            this._fps           = new FPS();
            this._scenes        = new SceneManager(this._eventOffice, this._input);
            this._timers        = new Timers();
            this._debugFont     = new Font(DEBUG_FONT);
            this._debugText     = new SimpleLabel(new Text(this._debugFont, ""d, vec2(0), DEBUG_FONT_SIZE, DEBUG_TEXT_COLOUR));
            this._debugText.text.outlineThickness(DEBUG_TEXT_THICC);
            this._debugGui      = new StackContainer(DEBUG_CONTAINER_POSITION, StackContainer.Direction.Horizontal, DEBUG_CONTAINER_COLOUR);
            this._debugGui.addChild(this._debugText);

            // Setup init info
            InitInfo.windowSize = this._window.size;

            // Make sure the post office types are valid
            this._eventOffice.reserveTypes!(Window.Event);
            this._eventOffice.reserveTypes!(Engine.Event);

            // Add in other stuff
            this.events.subscribe(Event.UpdateFPSDisplay, (_, __)
            {
                import std.format : sformat;
                this._debugText.updateTextASCII(sformat(this._debugBuffer, "FPS: %s | Time: %sms", 
                                                        this._fps.frameCount, this._fps.elapsedTime.asMilliseconds));
            });
            this.events.subscribe(Window.Event.Close, (_,__) => this._window.close());

            // Load in assets
            SdlangLoader.parseDataListFile(this._scenes.cache.getCache!AnimationInfo,
                                           this._scenes.cache.getCache!SpriteAtlas,
                                           this._scenes.cache.getCache!Texture,
                                           this._scenes.cache.getCache!Font);

            debug this.timers.every(GameTime.fromMilliseconds(1), (){this.events.mailCommand(Event.UpdateFPSDisplay);});
        }

        ///
        void onUpdate()
        {
            import derelict.sfml2.window : sfKeyEscape;

            this._fps.onUpdate();
            this._input.onUpdate();
            this._window.handleEvents(this._eventOffice);

            if(this._input.isKeyDown(sfKeyEscape))
                this._window.close();

            this._window.renderer.clear();
            this._timers.onUpdate(this._fps.elapsedTime);
            this._scenes.onUpdate(this._window, this._fps.elapsedTime);
            this._debugGui.onUpdate(this.input, this._fps.elapsedTime);
            this._debugGui.onRender(this.window);
            this._window.renderer.displayChanges();
        }

        ///
        void doLoop()
        {
            while(this._window.isOpen)
            {
                this.onUpdate();
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

        ///
        @property @safe @nogc
        inout(Timers) timers() nothrow inout
        {
            return this._timers;
        }
    }

    ///
    @Serialisable
    struct Config
    {
        mixin SerialisableInterface;

        uvec2 windowSize;
        int targetFPS;
    }
}
