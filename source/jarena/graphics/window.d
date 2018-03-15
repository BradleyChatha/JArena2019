///
module jarena.graphics.window;

private
{
    import std.experimental.logger;
    import derelict.sfml2.system, derelict.sfml2.window, derelict.sfml2.graphics;
    import jarena.core.maths, jarena.core.post, jarena.core.util;
    import jarena.graphics.sprite, jarena.graphics.text;
    
    enum BITS_PER_PIXEL = 32;
    enum _FPS           = 60;
}

public
{
    import derelict.sfml2.window : sfKeyEvent;
}

/++
 + Represents a window.
 + ++/
class Window
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
        MouseButtonReleased = 106
    }

    private
    {
        Renderer _renderer;
        sfRenderWindow* _handle;

        // Instead of making a bunch of different objects every frame where the user does something
        // we instead just reuse the objects.
        CommandMail             _commandMail;  // Mail used for events without extra data (e.g. closing the window)
        ValueMail!sfKeyEvent    _keyMail;      // Mail used for key events.
        ValueMail!dchar         _textMail;     // Mail used for the Text Entered event.
        ValueMail!vec2          _positionMail; // Mail used for any event that provides a position (e.g. mouse moved)
        ValueMail!MouseButton   _mouseMail;    // Mail used for mouse button events.

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
        this(string title, uvec2 size)
        {
            import std.string : toStringz;

            tracef("Creating Window with size of %s and title of '%s'", size, title);
            this._handle = sfRenderWindow_create(
                                sfVideoMode(size.x, size.y, BITS_PER_PIXEL),
                                title.toStringz(),
                                sfClose,
                                null
                            );

            tracef("Setting FPS target to %s", _FPS);
            sfRenderWindow_setFramerateLimit(this.handle, _FPS);

            trace("Creating Renderer");
            this._renderer = new Renderer(this);

            trace("Setting up reusuable mail");
            this._commandMail  = new CommandMail(0);
            this._keyMail      = new ValueMail!sfKeyEvent(0, sfKeyEvent());
            this._textMail     = new ValueMail!dchar(0, '\0');
            this._positionMail = new ValueMail!vec2(0, vec2(0));
            this._mouseMail    = new ValueMail!MouseButton(0, MouseButton.Left);
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
class Renderer
{
    private
    {
        Window _window;
        sfRectangleShape* _rect;
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
        void clear(uvec4b clearColour = colour(255, 255, 255, 255))
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
        void drawRect(vec2 position, vec2 size, uvec4b fillColour = colour(255, 0, 0, 255), uvec4b borderColour = colour(0, 0, 0, 255), uint borderThickness = 1)
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
class InputManager
{
    private
    {
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

        void onKeyEvent(PostOffice office, Mail m)
        {
            auto mail = cast(ValueMail!sfKeyEvent)m;
            assert(mail !is null);

            auto keyCode = mail.value.code;
            //assert(keyCode < this._keyStates.length); //Caps lock is enough to crash it...

            if(keyCode > this._keyStates.length)
                return;

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
        bool isMouseButtonDown(MouseButton button) nothrow const
        {
            return (this._mouse.buttonMask & button) > 0;
        }

        /// Returns: The last known position of the mouse.
        @property @safe @nogc
        vec2 mousePostion() nothrow const
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
