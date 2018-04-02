///
module jarena.graphics.window;

private
{
    import std.experimental.logger;
    import derelict.sfml2.system, derelict.sfml2.window, derelict.sfml2.graphics;
    import jarena.core, jarena.graphics;
    
    enum BITS_PER_PIXEL = 32;
}

public
{
    import derelict.sfml2.window : sfKeyEvent;
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
         +  `ValueMail`!sfKeyEvent
         + ++/
        KeyDown = 101,

        /++
         + Sent when a key is no longer being pressed down on the keyboard.
         +
         + Mail:
         +  `ValueMail`!sfKeyEvent
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
        Renderer _renderer;
        sfRenderWindow* _handle;

        // Instead of making a bunch of different objects every frame where the user does something
        // we instead just reuse the objects.
        CommandMail             _commandMail;       // Mail used for events without extra data (e.g. closing the window)
        ValueMail!sfKeyEvent    _keyMail;           // Mail used for key events.
        ValueMail!dchar         _textMail;          // Mail used for the Text Entered event.
        ValueMail!vec2          _positionMail;      // Mail used for any event that provides a position (e.g. mouse moved)
        ValueMail!uvec2         _upositionMail;     // ^^ but for uintegers.
        ValueMail!MouseButton   _mouseMail;         // Mail used for mouse button events.

        @property @safe @nogc
        inout(sfRenderWindow*) handle() nothrow inout
        {
            assert(this._handle !is null);
            return this._handle;
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

            tracef("Creating Window with size of %s and title of '%s'", size, title);
            this._handle = sfRenderWindow_create(
                                sfVideoMode(size.x, size.y, BITS_PER_PIXEL),
                                title.toStringz(),
                                sfClose,
                                null
                            );

            tracef("Setting FPS target to %s", fps);
            sfRenderWindow_setFramerateLimit(this.handle, fps);

            trace("Creating Renderer");
            this._renderer = new Renderer(this);
            this._renderer.camera = new Camera(RectangleF(0, 0, vec2(size)));

            trace("Setting up reusuable mail");
            this._commandMail   = new CommandMail(0);
            this._keyMail       = new ValueMail!sfKeyEvent(0, sfKeyEvent());
            this._textMail      = new ValueMail!dchar(0, '\0');
            this._positionMail  = new ValueMail!vec2(0, vec2(0));
            this._upositionMail = new ValueMail!uvec2(0, uvec2(0));
            this._mouseMail     = new ValueMail!MouseButton(0, MouseButton.Left);
        }

        ~this()
        {
            if(this._handle !is null)
                sfRenderWindow_destroy(this.handle);
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

            sfEvent e;
            while(sfRenderWindow_pollEvent(this.handle, &e))
            {
                switch(e.type)
                {
                    case sfEvtClosed:
                        this._commandMail.type = Window.Event.Close;
                        office.mail(this._commandMail);
                        break;

                    case sfEvtKeyPressed:
                        this._keyMail.type = Window.Event.KeyDown;
                        this._keyMail.value = e.key;
                        office.mail(this._keyMail);
                        break;

                    case sfEvtKeyReleased:
                        this._keyMail.type = Window.Event.KeyUp;
                        this._keyMail.value = e.key;
                        office.mail(this._keyMail);
                        break;

                    case sfEvtTextEntered:
                        import std.conv : to;
                        this._textMail.type = Window.Event.TextEntered;
                        this._textMail.value = e.text.unicode.to!dchar;
                        office.mail(this._textMail);
                        break;

                    case sfEvtMouseMoved:
                        this._positionMail.type = Window.Event.MouseMoved;
                        this._positionMail.value = vec2(e.mouseMove.x, e.mouseMove.y);
                        office.mail(this._positionMail);
                        break;

                    case sfEvtMouseButtonPressed:
                        this._mouseMail.type = Window.Event.MouseButtonPressed;
                        this._mouseMail.value = e.mouseButton.button.toArenaButton!MouseButton;
                        office.mail(this._mouseMail);
                        break;

                    case sfEvtMouseButtonReleased:
                        this._mouseMail.type = Window.Event.MouseButtonReleased;
                        this._mouseMail.value = e.mouseButton.button.toArenaButton!MouseButton;
                        office.mail(this._mouseMail);
                        break;

                    case sfEvtResized:
                        this._upositionMail.type = Window.Event.Resized;
                        this._upositionMail.value = uvec2(e.size.width, e.size.height);
                        office.mail(this._upositionMail);
                        break;

                    default:
                        break;
                }
            }
        }

        /// Closes the window
        void close()
        {
            sfRenderWindow_close(this.handle);
        }
    }

    // Properties
    public
    {
        /// Returns:
        ///  If the window is open or not.
        @property @trusted @nogc
        bool isOpen() nothrow const
        {
            return cast(bool)sfRenderWindow_isOpen(this.handle);
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
        uvec2 size() nothrow const
        {
            return sfRenderWindow_getSize(this.handle).to!uvec2;
        }
    }
}

///
final class Renderer
{
    private
    {
        Window _window;
        sfRectangleShape* _rect;
        Camera _camera;
    }

    public
    {
        this(Window window)
        {
            this._window = window;
            this._rect = sfRectangleShape_create();
        }

        ~this()
        {
            if(this._rect !is null)
                sfRectangleShape_destroy(this._rect);
        }

        /// Clears the screen
        void clear(Colour clearColour = Colour.white)
        {
            sfRenderWindow_clear(this._window.handle, clearColour.toSF!sfColor);
        }

        /// Displays all rendered changes to the screen.
        void displayChanges()
        {
            sfRenderWindow_display(this._window.handle);
        }

        /++
         + Draws a rectangle to the screen.
         +
         + Params:
         +  position        = The position of the rectangle.
         +  size            = The size of the rectangle.
         +  fillColour      = The colour of the inside of the rectangle. (See also - `jarena.util.colour`)
         +  borderColour    = The colour of the border.
         +  borderThickness = The thiccness of the border.
         + ++/
        void drawRect(vec2 position, vec2 size, Colour fillColour = Colour(255, 0, 0, 255), Colour borderColour = Colour.black, uint borderThickness = 1)
        {
            sfRectangleShape_setPosition        (this._rect, position.toSF!sfVector2f);
            sfRectangleShape_setSize            (this._rect, size.toSF!sfVector2f);
            sfRectangleShape_setFillColor       (this._rect, fillColour.toSF!sfColor);
            sfRectangleShape_setOutlineColor    (this._rect, borderColour.toSF!sfColor);
            sfRectangleShape_setOutlineThickness(this._rect, borderThickness);

            sfRenderWindow_drawRectangleShape(this._window.handle, this._rect, null);
        }

        /// Draws a `Sprite` to the screen.
        void drawSprite(Sprite sprite)
        {
            assert(sprite !is null);
            sfRenderWindow_drawSprite(this._window.handle, sprite.handle, null);
        }

        /// Draws `Text` to the screen.
        void drawText(Text text)
        {
            assert(text !is null);
            sfRenderWindow_drawText(this._window.handle, text.handle, null);
        }

        /// Returns: The current `Camera` being used.
        @property
        Camera camera()
        {
            return this._camera;
        }

        /// Sets the current `Camera` to use.
        @property
        void camera(Camera cam)
        {
            assert(cam !is null);
            
            this._camera = cam;
            sfRenderWindow_setView(this._window.handle, this._camera.handle);
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
        sfView* _handle;
        
        @property @safe @nogc
        inout(sfView*) handle() nothrow inout
        {
            assert(this._handle !is null);
            return this._handle;
        }
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

            this._handle = sfView_createFromRect(rect.toSF!sfFloatRect);
        }
        
        ~this()
        {
            if(this._handle !is null)
                sfView_destroy(this.handle);
        }

        ///
        @trusted @nogc
        void move(vec2 offset) nothrow
        {
            sfView_move(this.handle, offset.toSF!sfVector2f);
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
            sfView_reset(this.handle, rect.toSF!sfFloatRect);
        }

        ///
        @property @trusted @nogc
        vec2 center() nothrow const
        {
            return sfView_getCenter(this.handle).to!vec2;
        }

        ///
        @property @trusted @nogc
        void center(vec2 centerPos) nothrow
        {
            sfView_setCenter(this.handle, centerPos.toSF!sfVector2f);
        }

        ///
        @property @trusted @nogc
        const(AngleDegrees) rotation() nothrow const
        {
            return typeof(return)(sfView_getRotation(this.handle));
        }

        ///
        @property @trusted @nogc
        void rotation(float degrees) nothrow
        {
            sfView_setRotation(this.handle, degrees);
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
            return sfView_getSize(this.handle).to!vec2;
        }

        ///
        @property @trusted @nogc
        void size(vec2 siz) nothrow
        {
            sfView_setSize(this.handle, siz.toSF!sfVector2f);
        }

        ///
        @property @trusted @nogc
        const(RectangleF) viewport() nothrow const
        {
            return sfView_getViewport(this.handle).to!RectangleF;
        }
        
        ///
        @property @trusted @nogc
        void viewport(RectangleF port) nothrow
        {
            sfView_setViewport(this.handle, port.toSF!sfFloatRect);
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

        KeyState[sfKeyCount] _keyStates;
        sfKeyCode[]          _tapped;    // Any sfKey in this array was tapped down this frame.
        MouseState           _mouse;
        FuncKeyMask          _funcKeyMask;

        void onKeyEvent(PostOffice office, Mail m)
        {
            auto mail = cast(ValueMail!sfKeyEvent)m;
            assert(mail !is null);

            auto keyCode = mail.value.code;
            //assert(keyCode < this._keyStates.length); //Caps lock is enough to crash it...

            // Set/unset whether one of the function keys are pressed.
            ubyte mask = 0;
            mask |= (mail.value.shift)   ? FuncKeyMask.Shift   : 0;
            mask |= (mail.value.control) ? FuncKeyMask.Control : 0;
            mask |= (mail.value.alt)     ? FuncKeyMask.Alt     : 0;
            if(m.type == Window.Event.KeyDown) this._funcKeyMask |= mask;
            else                               this._funcKeyMask &= ~mask;

            // Unknown key
            if(keyCode > this._keyStates.length)
                return;

            // Update the key state.
            auto state        = &this._keyStates[keyCode];
            state.wasRepeated = (state.isDown && m.type == Window.Event.KeyDown);
            state.isDown      = (m.type == Window.Event.KeyDown);
            state.wasTapped   = state.isDown;

            if(state.wasTapped)
                this._tapped ~= keyCode;
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
                this._mouse.buttonMask &= ~(mail.value);
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
        bool isKeyDown(sfKeyCode key) nothrow const
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
        bool wasKeyTapped(sfKeyCode key) nothrow const
        {
            assert(key < this._keyStates.length);
            return this._keyStates[key].wasTapped;
        }

        /++
         + Returns:
         +  `true` if the `key` has had it's input repeated by the OS (in the case that key repeation is enabled for the window).
         + ++/
        @safe @nogc
        bool wasKeyRepeated(sfKeyCode key) nothrow const
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

private MouseButton toArenaButton(T : MouseButton)(sfMouseButton button)
{
    final switch(button)
    {
        case sfMouseLeft:
            return MouseButton.Left;

        case sfMouseRight:
            return MouseButton.Right;

        case sfMouseMiddle:
            return MouseButton.Middle;
    }
}
