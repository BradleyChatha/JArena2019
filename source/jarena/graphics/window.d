/++
 + Contains a class representing the game's window (using SDL). Also contains
 + enums and a class relating to input handling.
 + ++/
module jarena.graphics.window;

private
{
    import std.experimental.logger;
    import derelict.sdl2.sdl;
    import opengl;
    import jarena.core, jarena.graphics, jarena.maths;
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
         + See: https://wiki.libsdl.org/Tutorials/TextInput
         +
         + Notes:
         +  $(B Copy the data from this mail if you need to store it), since it refers to a stack variable.
         +
         + Mail:
         +  `ValueMail!char[]` (UTF-8 encoded)
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
        Resized = 107,

        /++
         + Send when the mouse wheeled is moved.
         +
         + Mail:
         +  `ValueMail!MouseWheelDirection`, which contains the direction the wheel was moved in.
         + ++/
         MouseWheelMoved = 108
    }

    private
    {
        Renderer      _renderer;
        SDL_Window*   _handle;
        SDL_GLContext _context;
        bool          _isClosed;
        
        // Instead of making a bunch of different objects every frame where the user does something
        // we instead just reuse the objects.
        CommandMail                     _commandMail;       // Mail used for events without extra data (e.g. closing the window)
        ValueMail!SDL_KeyboardEvent     _keyMail;           // Mail used for key events.
        ValueMail!(char[])              _textMail;          // Mail used for the Text Entered event.
        ValueMail!vec2                  _positionMail;      // Mail used for any event that provides a position (e.g. mouse moved)
        ValueMail!uvec2                 _upositionMail;     // ^^ but for uintegers.
        ValueMail!MouseButton           _mouseMail;         // Mail used for mouse button events.
        ValueMail!MouseWheelDirection   _mouseWheelMail;    // Mail used for when the mouse wheel is moved.

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
         +
         + Params:
         +  title = The window's title.
         +  size  = The size of the window.
         + ++/
        this(string title, uvec2 size)
        {
            import std.string : toStringz;

            GL.preContextLoad();
            
            tracef("Creating Window called '%s' with size of %s", title, size);
            this._handle = SDL_CreateWindow(title.toStringz,
                                            SDL_WINDOWPOS_CENTERED,
                                            SDL_WINDOWPOS_CENTERED,
                                            size.x,
                                            size.y,
                                            SDL_WindowFlags.SDL_WINDOW_OPENGL
                                           );
            checkSDLError();

            GL.createContextSDL(this.handle);
            GL.postContextLoad();
            //debug GL.debugLogEnable();

            glEnable(GL_BLEND);               // Enable blending
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            GL.checkForError();
            
            trace("Creating Renderer");
            this._renderer = new Renderer(this);
            this._renderer.camera = new Camera(RectangleF(0, 0, vec2(size)));

            trace("Setting up reusuable mail");
            this._commandMail    = new CommandMail(0);
            this._keyMail        = new ValueMail!SDL_KeyboardEvent(0, SDL_KeyboardEvent());
            this._textMail       = new ValueMail!(char[])(0, []);
            this._positionMail   = new ValueMail!vec2(0, vec2(0));
            this._upositionMail  = new ValueMail!uvec2(0, uvec2(0));
            this._mouseMail      = new ValueMail!MouseButton(0, MouseButton.Left);
            this._mouseWheelMail = new ValueMail!MouseWheelDirection(0, MouseWheelDirection.Down);
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
                    
                    case SDL_TEXTINPUT:
                        import core.stdc.string : strlen;

                        auto len = strlen(&e.text.text[0]);

                        this._textMail.type = Window.Event.TextEntered;
                        this._textMail.value = e.text.text[0..len]; // UTF-8 **Lives on the stack**
                        office.mail(this._textMail);
                        break;
                    
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

                    case SDL_MOUSEWHEEL:
                        auto wheelEvent = e.wheel;
                        if(wheelEvent.direction == SDL_MOUSEWHEEL_FLIPPED)
                            wheelEvent.y *= -1;

                        this._mouseWheelMail.type  = Window.Event.MouseWheelMoved;
                        this._mouseWheelMail.value = (wheelEvent.y < 0) ? MouseWheelDirection.Down : MouseWheelDirection.Up;
                        office.mail(this._mouseWheelMail);
                        break;

                    // Window events, unfortunately, are nested within the main event object.
                    case SDL_WINDOWEVENT:
                        switch(e.window.event) with(SDL_WindowEventID)
                        {
                            case SDL_WINDOWEVENT_RESIZED:
                                this._upositionMail.type  = Window.Event.Resized;
                                this._upositionMail.value = uvec2(e.window.data1, e.window.data2);
                                office.mail(this._upositionMail);
                                break;

                            default: break;
                        }
                        break;

                    default: break;
                }
            }
        }

        /// Closes the window
        @nogc
        void close() nothrow
        {
            this._isClosed = true;
            SDL_HideWindow(this.handle);
        }
    }

    // Properties
    public
    {
        /// Returns:
        ///  If the window is closed or not.
        @property @safe @nogc
        bool isClosed() nothrow const
        {
            return this._isClosed;
        }

        /// Returns:
        ///  The `Renderer` for this window.
        @property @safe @nogc
        inout(Renderer) renderer() nothrow inout
        out(r)
        {
            assert(r !is null, "The Renderer is somehow null.");
        }
        do
        {
            return this._renderer;
        }

        /// Returns:
        ///  The size of the window
        @property @trusted @nogc
        const(uvec2) size() nothrow const
        {
            ivec2 value;
            SDL_GetWindowSize(cast(SDL_Window*)this.handle, &value.components[0], &value.components[1]);
            return uvec2(value);
        }

        /// Returns:
        ///  Whether V-Sync is enabled.
        @property @trusted @nogc
        bool vsync() nothrow const
        {
            return cast(bool)SDL_GL_GetSwapInterval();
        }

        /// Sets whether V-Sync should be used or not
        ///
        /// Notes:
        ///  In some cases, V-Sync may not be able to be used.
        ///
        /// Params:
        ///  isOn = Whether to use V-Sync or not.
        @property @trusted @nogc
        void vsync(bool isOn) nothrow
        {
            SDL_GL_SetSwapInterval(isOn);
        }

        /// Returns:
        ///  The handle for this window. 
        ///  $(B Only for internal use, add a function if it's missing instead of using the handle directly.)
        @property @safe @nogc
        inout(SDL_Window*) handle() nothrow inout
        {
            assert(this._handle !is null);
            return this._handle;
        }
    }
}

/// Represents a button on a mouse.
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

/// Represents the direction that the mouse wheel was moved
enum MouseWheelDirection : ubyte
{
    Up,
    Down
}

/++
 + A class that will handle taking the input events from the `Window`, and provides an
 + interface to access the data from the input.
 + ++/
final class InputManager
{
    private
    {
        // Self note: `Scancode` is literally just `SDL_Scancode` but with the values renamed.
        enum KEY_COUNT = SDL_Scancode.SDL_NUM_SCANCODES;
        
        enum FuncKeyMask : ubyte
        {
            None, 
            Shift   = 1 << 0,
            OldControl = 1 << 1,
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
            MouseButton buttonTappedMask;
            int wheelDelta;
        }

        char[SDL_TEXTINPUTEVENT_TEXT_SIZE] _textInput;
        size_t               _textLength;
        bool                 _listenForText; // Whether to handle TextEntered events or not.
        KeyState[KEY_COUNT]  _keyStates; // Keys are indexed by scan code
        Buffer!Scancode      _tapped;    // Any ScanCodes in this array were tapped down this frame.
        MouseState           _mouse;
        FuncKeyMask          _funcKeyMask;

        void onKeyEvent(PostOffice office, Mail m)
        {
            auto mail = cast(ValueMail!SDL_KeyboardEvent)m;
            assert(mail !is null);

            SDL_KeyboardEvent key = mail.value;
            //assert(keyCode < this._keyStates.length); //Caps lock is enough to crash it...

            // Handle the special function keys.
            this._funcKeyMask  = FuncKeyMask.None;
            this._funcKeyMask |= (key.keysym.mod & KMOD_SHIFT) ? FuncKeyMask.Shift   : 0;
            this._funcKeyMask |= (key.keysym.mod & KMOD_CTRL)  ? FuncKeyMask.OldControl : 0;
            this._funcKeyMask |= (key.keysym.mod & KMOD_ALT)   ? FuncKeyMask.Alt     : 0;
            
            if(key.keysym.scancode > this._keyStates.length)
                return;

            auto state        = &this._keyStates[key.keysym.scancode];
            state.wasRepeated = (state.isDown && key.repeat);
            state.isDown      = (m.type == Window.Event.KeyDown);
            state.wasTapped   = state.isDown; // This will be set to false in `onUpdate` if it's set to true.

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
            {
                this._mouse.buttonMask |= mail.value;
                this._mouse.buttonTappedMask |= mail.value;
            }
            else
                this._mouse.buttonMask &= ~cast(int)(mail.value);
        }

        void onTextInput(PostOffice office, Mail m)
        {
            auto mail = cast(ValueMail!(char[]))m;
            assert(mail !is null);
            assert(mail.value.length <= this._textInput.length);

            if(!this._listenForText)
                return;

            this._textInput[0..mail.value.length] = mail.value[0..$];
            this._textLength = mail.value.length;
        }

        void onMouseWheel(PostOffice office, Mail m)
        {
            auto mail = cast(ValueMail!MouseWheelDirection)m;
            assert(mail !is null);

            this._mouse.wheelDelta += (mail.value == MouseWheelDirection.Up) ? 1 : -1;
        }
    }

    public final
    {
        /++
         + Setup the InputManager.
         +
         + Events:
         +  `Window.Event.KeyDown` & `Window.Event.KeyUp`
         + 
         +  `Window.Event.MouseMoved`
         +
         +  `Window.Event.MouseButtonPressed` & `Window.Event.MouseButtonReleased`
         +
         + Params:
         +  office = The `PostOffice` to listen to events for.
         +           This office should be fed events from the `Window` for this class to work properly.
         + ++/
        this(PostOffice office)
        {
            assert(office !is null);

            // This slightly confusing code is used to pre-allocate the space for a `Buffer`.
            this._tapped        = new Buffer!Scancode();
            this._tapped.length = this._keyStates.length;
            this._tapped.length = 0;

            this.listenForText = false;

            office.subscribe(Window.Event.KeyDown,              &this.onKeyEvent);
            office.subscribe(Window.Event.KeyUp,                &this.onKeyEvent);
            office.subscribe(Window.Event.MouseMoved,           &this.onMouseMoved);
            office.subscribe(Window.Event.MouseButtonPressed,   &this.onMouseButton);
            office.subscribe(Window.Event.MouseButtonReleased,  &this.onMouseButton);
            office.subscribe(Window.Event.TextEntered,          &this.onTextInput);
            office.subscribe(Window.Event.MouseWheelMoved,      &this.onMouseWheel);
        }

        /// $(B Important: This function should be called _before_ the window processes it's events, or at the very end of a frame's update)
        void onUpdate()
        {
            foreach(keyCode; this._tapped[0..$])
                this._keyStates[keyCode].wasTapped = false;

            this._mouse.wheelDelta = 0;
            this._mouse.buttonTappedMask = MouseButton.None;
            this._tapped.length = 0;
            this._textLength = 0;
        }

        /// Returns: `true` if `key` is currently being pressed down.
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
         + Voids the specified `key` for this frame's input so it
         + always return `false` for all of it's related functions.
         +
         + Params:
         +  key = The `Scancode` to void.
         + ++/
        @safe @nogc
        void voidKey(Scancode key) nothrow
        {
            this._keyStates[key] = KeyState.init;
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



        /// Returns: Whether SHIFT is pressed down.
        @safe @nogc
        bool isShiftDown() nothrow const
        {
            return (this._funcKeyMask & FuncKeyMask.Shift) > 0;
        }

        /// Returns: Whether CTRL is pressed down.
        @safe @nogc
        bool isControlDown() nothrow const
        {
            return (this._funcKeyMask & FuncKeyMask.OldControl) > 0;
        }

        /// Returns: Whether ALT is pressed down.
        @safe @nogc
        bool isAltDown() nothrow const
        {
            return (this._funcKeyMask & FuncKeyMask.Alt) > 0;
        }

        /// Returns: Whether the `button` is currently being pressed down.
        @safe @nogc
        bool isMouseButtonDown(MouseButton button) nothrow const
        {
            return (this._mouse.buttonMask & button) > 0;
        }

        /++
         + Returns:
         +  `true` if `button` was only pressed down this specific frame.
         +  `false` if `button` isn't pressed down, or if `button` has been held down for longer than 1 frame.
         + ++/
        @safe @nogc
        bool wasMouseButtonTapped(MouseButton button) nothrow const
        {
            return (this._mouse.buttonTappedMask & button) > 0;
        }

        /++
         + Voids the specified mouse `button` so it
         + always return `false` for all of it's related functions.
         +
         + Params:
         +  button = The `MouseButton` to void.
         + ++/
        @safe @nogc
        void voidMouseButton(MouseButton button) nothrow
        {
            this._mouse.buttonTappedMask &= ~cast(int)button;
            this._mouse.buttonMask       &= ~cast(int)button;
        }

        /// Returns: The last known position of the mouse.
        @property @safe @nogc
        vec2 mousePosition() nothrow const
        {
            return this._mouse.position;
        }

        /++
         + Notes:
         +  Make sure to store a copy of this data if it is needed beyond a single frame.
         +
         +  The value of this variable is reset to all '\0' characters whenever `onUpdate` is called.
         +
         + Returns:
         +  A slice to a $(B reused internal buffer) that contains text entered by the user.
         + ++/
        @property @safe @nogc
        const(char[]) textInput() nothrow const
        {
            return this._textInput[0..this._textLength];
        }

        /++
         + Returns:
         +  Whether the input manager is handling `Window.TextEntered` events.
         + ++/
        @property @safe @nogc
        bool listenForText() nothrow const
        {
            return this._listenForText;
        }

        /++
         + Sets whether to handle `Window.TextEntered` events.
         +
         + If the value is `true`, then the result of the event is stored in `Input.textInput`.
         +
         + Otherwise, no handling is done and the event is completely ignored, meaning `Input.textInput` will be left empty.
         +
         + Notes:
         +  If `shouldListen` is false, then the value of `Input.textInput` is instantly reset.
         +
         + Params:
         +  shouldListen = Whether to listen or not.
         + ++/
        @property @trusted @nogc
        void listenForText(bool shouldListen) nothrow
        {
            if(!shouldListen)
                SDL_StopTextInput();
            else
                SDL_StartTextInput();

            this._listenForText = shouldListen;
        }

        /++
         + A number representing how many ticks the mouse has moved this frame.
         +
         + A positive number means it has been moved up.
         + A negative number means it has been moved down.
         + 0 means it hasn't been moved.
         + ++/
        @property @safe @nogc
        int wheelDelta() nothrow inout
        {
            return this._mouse.wheelDelta;
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
