module jarena.graphics.window;

private
{
    import std.experimental.logger;
    import derelict.sfml2.system, derelict.sfml2.window, derelict.sfml2.graphics;
    import jarena.core.maths, jarena.core.post, jarena.core.util;
    import jarena.graphics.sprite;
    
    enum BITS_PER_PIXEL = 32;
    enum FPS            = 60;
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
        KeyUp = 102
    }

    private
    {
        Renderer _renderer;
        sfRenderWindow* _handle;

        // Instead of making a bunch of different objects every frame where the user does something
        // we instead just reuse the objects.
        CommandMail             _commandMail; // Mail used for events without extra data (e.g. closing the window)
        ValueMail!sfKeyEvent    _keyMail;     // Mail used for key events.

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

            tracef("Setting FPS target to %s", FPS);
            sfRenderWindow_setFramerateLimit(this.handle, FPS);

            trace("Creating Renderer");
            this._renderer = new Renderer(this);

            trace("Setting up reusuable mail");
            this._commandMail = new CommandMail(0);
            this._keyMail     = new ValueMail!sfKeyEvent(0, sfKeyEvent());
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

        /// Clears the screen
        void clear(uvec4b clearColour = colour(255, 255, 255, 255))
        {
            sfRenderWindow_clear(this.handle, clearColour.toSF!sfColor);
        }

        /// Displays all rendered changes to the screen.
        void displayChanges()
        {
            sfRenderWindow_display(this.handle);
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
    }
}

///
class InputManager
{
    private
    {
        bool[sfKeyCount] _keyStates; // true = down, false = up

        void onKeyEvent(PostOffice office, Mail m)
        {
            auto mail = cast(ValueMail!sfKeyEvent)m;
            assert(mail !is null);

            auto keyCode = mail.value.code;
            auto newState = (m.type == Window.Event.KeyDown) ? true : false;

            assert(keyCode < this._keyStates.length);
            this._keyStates[keyCode] = newState;
        }
    }

    public
    {
        ///
        this(PostOffice office)
        {
            assert(office !is null);

            office.subscribe(Window.Event.KeyDown, &this.onKeyEvent);
            office.subscribe(Window.Event.KeyUp,   &this.onKeyEvent);
        }

        ///
        bool isKeyDown(sfKeyCode key)
        {
            assert(key < this._keyStates.length);
            return this._keyStates[key];
        }

        ///
        bool isKeyUp(sfKeyCode key)
        {
            assert(key < this._keyStates.length);
            return !this._keyStates[key];
        }
    }
}