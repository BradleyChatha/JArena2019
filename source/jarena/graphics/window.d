///
module jarena.graphics.window;

private
{
    import std.experimental.logger;
    import derelict.sdl2.sdl;
    import opengl;
    import jarena.core, jarena.graphics;
}

public
{
    import derelict.sdl2.sdl : SDL_KeyboardEvent;
    import jarena.graphics.scancode;
}

/++
 + Represents a window.
 + ++/
final class Window
{
    /++
     + Enum of events that the `Window` will mail to the `PostOffice`.
     +
     + Notes:
     +  The `Window` will never directly call `PostOffice.reserveTypes`, so it is recommended for that to be done manually.
     + ++/
    enum Event : Mail.MailTypeT
    {
        /++
         + Sent when the 'X' button on the window is pressed.
         +
         + Mail:
         +  `CommandMail`
         + ++/
        Close = 100,

        /++
         + Sent when a key is pressed down on the keyboard.
         +
         + Mail:
         +  `ValueMail`!SDL_KeyboardEvent
         + ++/
        KeyDown = 101,

        /++
         + Sent when a key is no longer being pressed down on the keyboard.
         +
         + Mail:
         +  `ValueMail`!SDL_KeyboardEvent
         + ++/
        KeyUp = 102,

        /++
         + Sent when text is entered into the window.
         +
         + See: https://www.sfml-dev.org/tutorials/2.0/window-events.php#the-textentered-event
         +
         + Mail:
         +  `ValueMail!dchar`
         + ++/
        TextEntered = 103,

        /++
         + Sent when the mouse is moved.
         + 
         + See: https://www.sfml-dev.org/tutorials/2.4/window-events.php#the-mousemoved-event
         +
         + Mail:
         +  `ValueMail!vec2`, which contains the mouse's current position, relative to the window.
         + ++/
        MouseMoved = 104,

        /++
         + Sent when a mouse button is pressed.
         +
         + Mail:
         +  `ValueMail!MouseButton`, which contains the button that was pressed.
         + ++/
        MouseButtonPressed = 105,

        /++
         + Sent when a mouse button is released.
         +
         + Mail:
         +  `ValueMail!MouseButton`, which contains the button that was released.
         + ++/
        MouseButtonReleased = 106,

        /++
         + Sent when the window is resized.
         +
         + Mail:
         +  `ValueMail!uvec2`, which contains the new size of the window.
         + ++/
        Resized = 107
    }

    private
    {
        Renderer      _renderer;
        SDL_Window*   _handle;
        SDL_GLContext _context;
        bool          _shouldClose;
        
        // Instead of making a bunch of different objects every frame where the user does something
        // we instead just reuse the objects.
        CommandMail                 _commandMail;       // Mail used for events without extra data (e.g. closing the window)
        ValueMail!SDL_KeyboardEvent _keyMail;           // Mail used for key events.
        ValueMail!dchar             _textMail;          // Mail used for the Text Entered event.
        ValueMail!vec2              _positionMail;      // Mail used for any event that provides a position (e.g. mouse moved)
        ValueMail!uvec2             _upositionMail;     // ^^ but for uintegers.
        ValueMail!MouseButton       _mouseMail;         // Mail used for mouse button events.

        @property @safe @nogc
        inout(SDL_GLContext) context() nothrow inout
        {
            assert(this._context !is null);
            return this._context;
        }
    }

    // Functions
    public
    {
        /++
         + Creates the window.
         + ++/
        this(string title, uvec2 size, uint fps = 60)
        {
            import std.string : toStringz;

            trace("Initial OpenGL load...");
            DerelictGL3.load();
            
            tracef("Creating Window called '%s' with size of %s", title, size);
            this._handle = SDL_CreateWindow(title.toStringz,
                                            SDL_WINDOWPOS_CENTERED,
                                            SDL_WINDOWPOS_CENTERED,
                                            size.x,
                                            size.y,
                                            SDL_WindowFlags.SDL_WINDOW_OPENGL
                                           );
            checkSDLError();

            tracef("Configuring to use a core OpenGL%s context with a double buffer.", OPENGL_VERSION);
            SDL_GL_SetAttribute(SDL_GLattr.SDL_GL_CONTEXT_PROFILE_MASK,  SDL_GLprofile.SDL_GL_CONTEXT_PROFILE_CORE);
            SDL_GL_SetAttribute(SDL_GLattr.SDL_GL_CONTEXT_MAJOR_VERSION, OPENGL_VERSION.x);
            SDL_GL_SetAttribute(SDL_GLattr.SDL_GL_CONTEXT_MINOR_VERSION, OPENGL_VERSION.y);
            SDL_GL_SetAttribute(SDL_GLattr.SDL_GL_DOUBLEBUFFER,          1);
            SDL_GL_SetAttribute(SDL_GLattr.SDL_GL_DEPTH_SIZE,            24);
            checkSDLError();

            trace("Creating OpenGL context");
            this._context = SDL_GL_CreateContext(this.handle);
            checkSDLError();

            trace("Reloading OpenGL");
            DerelictGL3.reload();

            SDL_GL_SetSwapInterval(1);        // Vsync
            glViewport(0, 0, size.x, size.y); // Use the entire window to render
            glEnable(GL_BLEND);               // Enable blending
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            checkGLError();
            
            trace("Creating Renderer");
            this._renderer = new Renderer(this);
            this._renderer.camera = new Camera(RectangleF(0, 0, vec2(size)));

            trace("Setting up reusuable mail");
            this._commandMail   = new CommandMail(0);
            this._keyMail       = new ValueMail!SDL_KeyboardEvent(0, SDL_KeyboardEvent());
            this._textMail      = new ValueMail!dchar(0, '\0');
            this._positionMail  = new ValueMail!vec2(0, vec2(0));
            this._upositionMail = new ValueMail!uvec2(0, uvec2(0));
            this._mouseMail     = new ValueMail!MouseButton(0, MouseButton.Left);
        }

        ~this()
        {
            if(this._context !is null)
                SDL_GL_DeleteContext(this.context);
            
            if(this._handle !is null)
                SDL_DestroyWindow(this.handle);
        }

        /++
         + Polls all queued events, and will post the relevent mail to the given `PostOffice`.
         +
         + Notes:
         +  If a certain event hasn't been added to the handler, then it is simply ignored.
         +
         + Params:
         +  office = The `PostOffice` to send the mail to.
         +
         + See_Also:
         +  `Window.Event`
         + ++/
        void handleEvents(PostOffice office)
        {
            assert(office !is null);

            SDL_Event e;
            while(SDL_PollEvent(&e))
            {
                switch(e.type) with(SDL_EventType)
                {
                    case SDL_QUIT:
                        this._commandMail.type = Window.Event.Close;
                        office.mail(this._commandMail);
                        break;

                    case SDL_KEYDOWN:
                        this._keyMail.type = Window.Event.KeyDown;
                        this._keyMail.value = e.key;
                        office.mail(this._keyMail);
                        break;

                    case SDL_KEYUP:
                        this._keyMail.type = Window.Event.KeyUp;
                        this._keyMail.value = e.key;
                        office.mail(this._keyMail);
                        break;
                    //
                    //case sfEvtTextEntered:
                    //    import std.conv : to;
                    //    this._textMail.type = Window.Event.TextEntered;
                    //    this._textMail.value = e.text.unicode.to!dchar;
                    //    office.mail(this._textMail);
                    //    break;
                    //
                    case SDL_MOUSEMOTION:
                        this._positionMail.type  = Window.Event.MouseMoved;
                        this._positionMail.value = vec2(e.motion.x, e.motion.y);
                        office.mail(this._positionMail);
                        break;

                    case SDL_MOUSEBUTTONDOWN:
                        this._mouseMail.type  = Window.Event.MouseButtonPressed;
                        this._mouseMail.value = e.button.button.toArenaButton!MouseButton;
                        office.mail(this._mouseMail);
                        break;

                    case SDL_MOUSEBUTTONUP:
                        this._mouseMail.type  = Window.Event.MouseButtonReleased;
                        this._mouseMail.value = e.button.button.toArenaButton!MouseButton;
                        office.mail(this._mouseMail);
                        break;

                    case SDL_WINDOWEVENT:
                        switch(e.window.event) with(SDL_WindowEventID)
                        {
                            case SDL_WINDOWEVENT_RESIZED:
                                this._upositionMail.type  = Window.Event.Resized;
                                this._upositionMail.value = uvec2(e.window.data1, e.window.data2);
                                office.mail(this._upositionMail);
                                break;

                            default:
                                break;
                        }
                        break;

                    default:
                        break;
                }
            }
        }

        /// Closes the window
        @safe @nogc
        void close() nothrow pure
        {
            this._shouldClose = true;
        }
    }

    // Properties
    public
    {
        /// Returns:
        ///  If the window should close or not.
        @property @safe @nogc
        bool shouldClose() nothrow const
        {
            return this._shouldClose;
        }

        /// Returns:
        ///  The `Renderer` for this window.
        @property @safe @nogc
        inout(Renderer) renderer() nothrow inout
        out(r)
        {
            assert(r !is null);
        }
        do
        {
            return this._renderer;
        }

        /// Returns:
        ///  The size of the window
        @property @trusted @nogc
        uvec2 size() nothrow
        {
            ivec2 value;
            SDL_GetWindowSize(this.handle, &value.data[0], &value.data[1]);
            return uvec2(value);
        }

         @property @safe @nogc
        inout(SDL_Window*) handle() nothrow inout
        {
            assert(this._handle !is null);
            return this._handle;
        }
    }
}

/++
 + Contains information about a Camera, which can be used to control what is shown on screen.
 +
 + Helpful_Read:
 +  https://www.sfml-dev.org/tutorials/2.4/graphics-view.php
 +
 + Notes:
 +  
 + ++/
final class Camera
{
    const DEFAULT_CAMERA_RECT = RectangleF(float.nan, float.nan, float.nan, float.nan);
    
    private
    {
        //sfView* _handle;
    }

    public
    {
        /++
         + 
         + ++/
        this(RectangleF rect = DEFAULT_CAMERA_RECT)
        {
            if(rect == DEFAULT_CAMERA_RECT)
                rect = RectangleF(0, 0, vec2(InitInfo.windowSize));

            //this._handle = sfView_createFromRect(rect.toSF!sfFloatRect);
        }

        ///
        @trusted @nogc
        void move(vec2 offset) nothrow
        {
            //sfView_move(this.handle, offset.toSF!sfVector2f);
        }

        /++
         + Resets the camera to a certain portion of the world.
         +
         + Notes:
         +  This will also reset the camera's rotation.
         +
         +  The camera will of course, be centered within `rect`.
         +
         + Params:
         +  rect = The portion of the world to reset to viewing.
         + ++/
        @trusted @nogc
        void reset(RectangleF rect) nothrow
        {
            //sfView_reset(this.handle, rect.toSF!sfFloatRect);
        }

        ///
        @property @trusted @nogc
        vec2 center() nothrow const
        {
            return vec2();
            //return sfView_getCenter(this.handle).to!vec2;
        }

        ///
        @property @trusted @nogc
        void center(vec2 centerPos) nothrow
        {
            //sfView_setCenter(this.handle, centerPos.toSF!sfVector2f);
        }

        ///
        @property @trusted @nogc
        const(AngleDegrees) rotation() nothrow const
        {
            return AngleDegrees(0);
            //return typeof(return)(sfView_getRotation(this.handle));
        }

        ///
        @property @trusted @nogc
        void rotation(float degrees) nothrow
        {
            //sfView_setRotation(this.handle, degrees);
        }

        ///
        @property @trusted @nogc
        void rotation(AngleDegrees degrees) nothrow
        {
            this.rotation = degrees.angle;
        }

        ///
        @property @trusted @nogc
        const(vec2) size() nothrow const
        {
            return vec2();
            //return sfView_getSize(this.handle).to!vec2;
        }

        ///
        @property @trusted @nogc
        void size(vec2 siz) nothrow
        {
            //sfView_setSize(this.handle, siz.toSF!sfVector2f);
        }

        ///
        @property @trusted @nogc
        const(RectangleF) viewport() nothrow const
        {
            return RectangleF(0, 0, 0, 0);
            //return sfView_getViewport(this.handle).to!RectangleF;
        }
        
        ///
        @property @trusted @nogc
        void viewport(RectangleF port) nothrow
        {
            //sfView_setViewport(this.handle, port.toSF!sfFloatRect);
        }
    }
}

///
enum MouseButton : ubyte
{
    None = 0,

    ///
    Left = 1 << 0,
    
    ///
    Right = 1 << 1,
    
    ///
    Middle = 1 << 2
}

///
final class InputManager
{
    private
    {
        enum KEY_COUNT = SDL_Scancode.SDL_NUM_SCANCODES;
        
        enum FuncKeyMask : ubyte
        {
            None, 
            Shift   = 1 << 0,
            Control = 1 << 1,
            Alt     = 1 << 2
        }
        
        struct KeyState
        {
            bool isDown;      // True = down, false = up
            bool wasTapped;   // True = tapped this frame, false = either up, or has been down longer than 1 frame.
            bool wasRepeated; // True = The window/OS repeated the key input. False = no repeat has happened.
        }

        struct MouseState
        {
            vec2 position;
            MouseButton buttonMask;
        }

        KeyState[KEY_COUNT]  _keyStates; // Keys are indexed by scan code
        Scancode[]           _tapped;    // Any ScanCodes in this array were tapped down this frame.
        MouseState           _mouse;
        FuncKeyMask          _funcKeyMask;

        void onKeyEvent(PostOffice office, Mail m)
        {
            auto mail = cast(ValueMail!SDL_KeyboardEvent)m;
            assert(mail !is null);

            SDL_KeyboardEvent key = mail.value;
            //assert(keyCode < this._keyStates.length); //Caps lock is enough to crash it...

            this._funcKeyMask  = FuncKeyMask.None;
            this._funcKeyMask |= (key.keysym.mod & KMOD_SHIFT) ? FuncKeyMask.Shift   : 0;
            this._funcKeyMask |= (key.keysym.mod & KMOD_CTRL)  ? FuncKeyMask.Control : 0;
            this._funcKeyMask |= (key.keysym.mod & KMOD_ALT)   ? FuncKeyMask.Alt     : 0;
            
            if(key.keysym.scancode > this._keyStates.length)
                return;

            auto state        = &this._keyStates[key.keysym.scancode];
            state.wasRepeated = (state.isDown && key.repeat);
            state.isDown      = (m.type == Window.Event.KeyDown);
            state.wasTapped   = state.isDown;

            if(state.wasTapped)
                this._tapped ~= cast(Scancode)key.keysym.scancode; // Scancode is just SDL_Scancode, so this is safe.
        }

        void onMouseMoved(PostOffice office, Mail m)
        {
            auto mail = cast(ValueMail!vec2)m;
            assert(mail !is null);

            this._mouse.position = mail.value;
        }

        void onMouseButton(PostOffice office, Mail m)
        {
            auto mail = cast(ValueMail!MouseButton)m;
            assert(mail !is null);

            if(m.type == Window.Event.MouseButtonPressed)
                this._mouse.buttonMask |= mail.value;
            else
                this._mouse.buttonMask &= ~cast(int)(mail.value);
        }
    }

    public
    {
        ///
        this(PostOffice office)
        {
            assert(office !is null);

            this._tapped.reserve(this._keyStates.length);

            office.subscribe(Window.Event.KeyDown,              &this.onKeyEvent);
            office.subscribe(Window.Event.KeyUp,                &this.onKeyEvent);
            office.subscribe(Window.Event.MouseMoved,           &this.onMouseMoved);
            office.subscribe(Window.Event.MouseButtonPressed,   &this.onMouseButton);
            office.subscribe(Window.Event.MouseButtonReleased,  &this.onMouseButton);
        }

        /// $(B Important: This function should be called _before_ the window processes it's events, or at the very end of a frame's update)
        void onUpdate()
        {
            foreach(keyCode; this._tapped)
                this._keyStates[keyCode].wasTapped = false;

            this._tapped.length = 0;
        }

        ///
        @safe @nogc
        bool isKeyDown(Scancode key) nothrow const
        {
            assert(key < this._keyStates.length);
            return this._keyStates[key].isDown;
        }

        /++
         + Returns:
         +  `true` if `key` was only pressed down this specific frame.
         +  `false` if `key` isn't pressed down, or if `key` has been held down for longer than 1 frame.
         + ++/
        @safe @nogc
        bool wasKeyTapped(Scancode key) nothrow const
        {
            assert(key < this._keyStates.length);
            return this._keyStates[key].wasTapped;
        }

        /++
         + Returns:
         +  `true` if the `key` has had it's input repeated by the OS (in the case that key repeation is enabled for the window).
         + ++/
        @safe @nogc
        bool wasKeyRepeated(Scancode key) nothrow const
        {
            assert(key < this._keyStates.length);
            return this._keyStates[key].wasRepeated;
        }

        ///
        @safe @nogc
        bool isShiftDown() nothrow const
        {
            return (this._funcKeyMask & FuncKeyMask.Shift) > 0;
        }

        ///
        @safe @nogc
        bool isControlDown() nothrow const
        {
            return (this._funcKeyMask & FuncKeyMask.Control) > 0;
        }

        ///
        @safe @nogc
        bool isAltDown() nothrow const
        {
            return (this._funcKeyMask & FuncKeyMask.Alt) > 0;
        }

        ///
        @safe @nogc
        bool isMouseButtonDown(MouseButton button) nothrow const
        {
            return (this._mouse.buttonMask & button) > 0;
        }

        /// Returns: The last known position of the mouse.
        @property @safe @nogc
        vec2 mousePosition() nothrow const
        {
            return this._mouse.position;
        }
    }
}

private MouseButton toArenaButton(T : MouseButton)(ubyte button)
{
    /*final*/ switch(cast(SDL_D_MouseButton)button) with(SDL_D_MouseButton)
    {
        case SDL_BUTTON_LEFT:
            return MouseButton.Left;

        case SDL_BUTTON_RIGHT:
            return MouseButton.Right;

        case SDL_BUTTON_MIDDLE:
            return MouseButton.Middle;

        default:
            return MouseButton.None;
    }
}
