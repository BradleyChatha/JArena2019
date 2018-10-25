module jarena.gameplay.gui.control;

private
{
    import std.traits    : isSomeString;
    import std.algorithm : equal;
    import jarena.core, jarena.graphics, jarena.maths;
}

abstract class UIElement
{
    enum StateChange
    {
        PositionChanged,
        SizeChanged,
        ColourChanged
    }

    private
    {
        UIElement _parent;
        string    _name;
        vec2      _position;
        vec2      _size;
        Colour    _colour;
    }

    protected
    {
        /++
         + If `true`, then changes to this element's state (position, size, colour)
         + $(B not) trigger the `onPositionChanged`, `onSizeChanged`, etc. events.
         +
         + If `false`, then changes to this element's state will cause the events to be
         + triggered.
         +
         + For ignoring the state changes of a child (useful for containers), please see
         + `ignoreChildStateChanges`.
         + ++/
        bool ignoreStateChanges = false;

        /++ 
         + Similar to `ignoreStateChanges`, except it is used for the 
         + `onChildStateChanged` event.
         + ++/
        bool ignoreChildStateChanges = false;
    }

    public
    {
        /++
         + Sets the parent for this UIElement.
         +
         + Notes:
         +  [The following functions are called in order]
         +
         +  * oldParent.onRemoveChild(this); [if oldParent is not null]
         +
         +  * newParent.onAddChild(this); [if newParent is not null]
         +
         +  * this.onNewParent(newParent, oldParent);
         +
         + Param:
         +  newParent = The new parent for this UIElement.
         + ++/
        @property
        final void parent(UIElement newParent)
        {
            auto old = this._parent;
            this._parent = newParent;

            if(old !is null)
                old.onRemoveChild(this);

            if(newParent !is null)
                newParent.onAddChild(this);

            this.onNewParent(newParent, old);
        }

        /++
         + Sets the position for this UIElement.
         +
         + Notes:
         +  All inheriting classes should assure that their actual position on screen is kept in sync,
         +  and also respects the position set by this function.
         +
         +  [The following functions are called in order]
         +
         +  * parent.onChildStateChanged(this, StateChange.PositionChanged); [if parent is not null]
         +
         +  * this.onPositionChanged(oldPos, newPos);
         + ++/
        @property
        final void position(vec2 newPosition)
        {
            auto old = this._position;
            this._position = newPosition;

            if(this.parent !is null && !this.parent.ignoreChildStateChanges)
                this.parent.onChildStateChanged(this, StateChange.PositionChanged);

            if(!this.ignoreStateChanges)
                this.onPositionChanged(old, newPosition);
        }

        /++
         + Sets the size for this UIElement.
         +
         + Notes:
         +  All inheriting classes should assure that their actual size on screen is kept in sync,
         +  and also respects the size set by this function. Containers are an exception,
         +  as some containers may not support resizing.
         +
         +  [The following functions are called in order]
         +
         +  * parent.onChildStateChanged(this, StateChange.SizeChanged); [if parent is not null]
         +
         +  * this.onSizeChanged(oldSize, newSize);
         + ++/
        @property
        final void size(vec2 newSize)
        {
            auto old = this._size;
            this._size = newSize;

            if(this.parent !is null && !this.parent.ignoreChildStateChanges)
                this.parent.onChildStateChanged(this, StateChange.SizeChanged);

            if(!this.ignoreStateChanges)
                this.onSizeChanged(old, newSize);
        }

        /++
         + Sets the colour for this UIElement.
         +
         + Notes:
         +  All inheriting classes should assure that their actual colour on screen is kept in sync,
         +  and also respects the colour set by this function.
         +
         +  [The following functions are called in order]
         +
         +  * parent.onChildStateChanged(this, StateChange.ColourChanged); [if parent is not null]
         +
         +  * this.onColourChanged(oldSize, newSize);
         + ++/
        @property
        final void colour(Colour newColour)
        {
            auto old = this._colour;
            this._colour = newColour;

            if(this.parent !is null && !this.parent.ignoreChildStateChanges)
                this.parent.onChildStateChanged(this, StateChange.ColourChanged);

            if(!this.ignoreStateChanges)
                this.onColourChanged(old, newColour);
        }

        /// Sets the name of this UIElement.
        @property @safe @nogc
        final void name(string name) nothrow pure
        {
            this._name = name;
        }

        /// Returns: The parent for this UIElement.
        @property @safe @nogc
        final inout(UIElement) parent() nothrow inout
        {
            return this._parent;
        }

        /// Returns: The position for this UIElement.
        @property @safe @nogc
        final const(vec2) position() nothrow const
        {
            return this._position;
        }

        /// Returns: The size for this UIElement.
        @property @safe @nogc
        final const(vec2) size() nothrow const
        {
            return this._size;
        }

        /// Returns: The colour for this UIElement.
        @property @safe @nogc
        final const(Colour) colour() nothrow const
        {
            return this._colour;
        }

        /// Returns: The name for this UIElement.
        @property @safe @nogc
        final string name() nothrow const
        {
            return this._name;
        }
    }

    // =============================================
    // = Functions that can be overidden as needed =
    // =============================================

    /++
    + Called whenever this UIElement is set as the `UIElement.parent` for another
    + UIElement (therefore, making this element the parent, and the other element a child).
    +
    + Params:
    +  child = The child UIElement that has had it's parent set to this UIElement.
    + ++/
    protected void onAddChild(UIElement child){}

    /++
    + Called whenever this UIElement $(B was) set as the `UIElement.parent` for another
    + UIElement, but is then replaced with another parent (meaning this element should no longer have it as a child).
    +
    + Params:
    +  child = The child UIElement that should no longer be treated as a child.
    + ++/
    protected void onRemoveChild(UIElement child){}

    /++
    + Called whenever the parent of this UIElement is changed.
    +
    + Note:
    +  It is expected that the parent be responsible for aligning the child's position,
    +  if needed (for example, with containers).
    +
    + Params:
    +  newParent = The new UIElement acting as this element's parent. May be null.
    +  oldParent = The old UIElement that used to act as this element's parent. May be null.
    + ++/
    protected void onNewParent(UIElement newParent, UIElement oldParent){}

    /++
    + Called whenever a child of this UIElement has a change in state.
    +
    + Params:
    +  child = The child that fired this event.
    +  change = The change in the child's state.
    + ++/
    protected void onChildStateChanged(UIElement child, StateChange change){}

    /++
    + Called whenever the position for this UIElement is changed.
    +
    + Params:
    +  oldPos = The old position for this UIElement.
    +  newPos = The new position for this UIElement.
    + ++/
    protected void onPositionChanged(vec2 oldPos, vec2 newPos){}

    /++
    + Called whenever the size for this UIElement is changed.
    +
    + Params:
    +  oldSize = The old size for this UIElement.
    +  newSize = The new size for this UIElement.
    + ++/
    protected void onSizeChanged(vec2 oldSize, vec2 newSize){}

    /++
    + Called whenever the colour for this UIElement is changed.
    +
    + Params:
    +  oldColour = The old colour for this UIElement.
    +  newColour = The new colour for this UIElement.
    + ++/
    protected void onColourChanged(Colour oldColour, Colour newColour){}

    ///
    public void onUpdate(InputManager input, Duration deltaTime){}

    ///
    public void onRender(Window window){}
}

///
abstract class Control : UIElement
{
}

final class TestControl : UIElement
{
    Colour colour;

    this(vec2 position, vec2 size, Colour colour)
    {
        this.position = position;
        this.size     = size;
        this.colour   = colour;
    }

    override
    {
        public void onRender(Window window)
        {
            window.renderer.drawRect(this.position, this.size, this.colour);
        }
    }
}

/++
 + Containers are controls that specialise in containing other controls within them.
 +
 + Examples of containers are a scrollbox container, and a container that aligns controls in a grid.
 + ++/
abstract class Container : UIElement
{
    public
    {
        ///
        final UI addChild(UI : UIElement)(UI child)
        {
            assert(child !is null);
            child.parent = this;

            return child;
        }

        ///
        final UI addChild(UI : UIElement)(string name, UI child)
        {
            assert(child !is null);
            child.parent = this;
            child.name = name;

            return child;
        }

        ///
        final UI getChild(UI : UIElement)(size_t index) 
        {
            return cast(UI)this.children[index];
        }

        ///
        final UI getChild(UI : UIElement)(UI element)
        {
            import std.algorithm : filter;
            if(element is null)
                return null;

            auto results = this.children.filter!(c => c == element);
            return (results.empty) ? null : cast(UI)results.front;
        }

        ///
        final UI getChild(UI : UIElement, Str)(Str name)
        if(isSomeString!Str)
        {
            import std.algorithm : filter;
            if(name is null)
                return null;

            auto results = this.children.filter!(c => c.name.equal(name));
            return (results.empty) ? null : cast(UI)results.front;
        }
    }

    abstract
    {
        /// Returns: The children for this container.
        @property
        inout(UIElement[]) children() inout;
    }
}

/// Base class for all button-like controls.
/// This class intentionally leaves the logic of "is mouse over and mouse button down?" logic to inheriting classes.
abstract class Button : Control
{
    alias OnClickFunc = void delegate(Button caller);
    private
    {
        OnClickFunc _onClick;
    }

    public
    {
        /// Returns: The function that is called when this button is clicked.
        @property @safe @nogc
        inout(OnClickFunc) onClick() nothrow inout
        {
            return this._onClick;
        }

        /// Sets the function that should be called when this button is clicked.
        @property @safe @nogc
        void onClick(OnClickFunc func) nothrow
        {
            this._onClick = func;
        }
    }
}

/++
 + The basis for a control that can take keyboard input and display it on screen.
 +
 + Notes:
 +  For text capturing to work, both `SimpleTextInput.isActive` and `Input.listenForText` need to be true.
 +
 +  When `SimpleTextInput.textArea` isn't set to `vec2(float.infinity)`, it will make sure that it's text
 +  cannot grow in size outside of this area. Again, useful for things such as textboxes.
 +
 +  This class handles drawing the inputted text.
 +
 + Limitations:
 +  Currently, only a single line of text is supported.
 +
 +  Support for most control codes is either unsupported or undefined.
 +
 +  Currently, only the X-axis for `SimpleTextInput.textArea` is used.
 + ++/
class TextInput : Control
{
    enum BLINK_TIMER = 500; // ms

    private
    {
        Text     _textObject;
        Text     _cursorObject;
        char[]   _text;
        vec2     _area;
        bool     _isActive;
        bool     _displayCursor;
        Duration _blinkTimer;

        void appendText(const char[] text)
        {
            foreach(ch; text)
            {
                if(ch == '\n')
                    continue; // No support for new lines yet.

                // Add the character, and see if it can fit.
                this._text ~= ch;
                this._textObject.text = this._text;                
                if(this._textObject.getRectForChar(this._text.length - 1).topRight.x
                 > this._area.x + this.position.x)
                {
                    this._text.length -= 1;
                    this._textObject.text = this._text;
                }
            }
        }
    }

    public
    {
        this(Text text, vec2 position, vec2 textArea = vec2(float.infinity))
        {
            assert(text !is null);

            this._textObject = text;
            this._cursorObject = new Text(text.font, "|", vec2(0), text.charSize, text.colour);
            this._area = textArea;
            this.position = position;
        }

        @property @safe @nogc
        bool isActive() nothrow const
        {
            return this._isActive;
        }

        @property @safe @nogc
        void isActive(bool active) nothrow
        {
            this._isActive = active;
        }

        /++
         + Notes:
         +  $(B Copy this data if it needs to be kept before this control is updated again) as it wont
         +  be copied automatically, meaning it's data can change as the user types.
         +
         + Returns:
         +  The text that has been inputted so far.
         + ++/
        @property @safe @nogc
        const(char[]) textInput() nothrow const
        {
            return this._text;
        }
        
        /++
         + Manually sets the text input.
         +
         + This can be useful to set a default value, or to update an input that can also be changed.
         + ++/
        @property
        void textInput(const(char[]) text)
        {
            this._text.length = 0;
            this.appendText(text);
        }
    }

    protected
    {
        @property @safe @nogc
        ref inout(vec2) textArea() nothrow inout
        {
            return this._area;
        }

        /++
         + Returns:
         +  The on-screen `Text` object.
         + ++/
        @property @safe @nogc
        inout(Text) textObject() nothrow inout
        {
            return this._textObject;
        }
    }

    override
    {        
        protected void onPositionChanged(vec2 oldPos, vec2 newPos)
        {
            this._textObject.position = newPos;
        }

        protected void onColourChanged(Colour oldColour, Colour newColour)
        {
            this._textObject.colour = newColour;
        }

        public void onUpdate(InputManager input, Duration deltaTime)
        {
            if(!this._isActive || !input.listenForText)
                return;

            // Blink the cursor
            this._blinkTimer -= deltaTime;
            if(this._blinkTimer.asSeconds <= 0)
            {
                this._displayCursor = !this._displayCursor;
                this._blinkTimer += BLINK_TIMER.msecs;
            }

            // Removes the last character.
            void doBackspace() scope
            {
                if(this._text.length > 0)
                {
                    this._text.length -= 1;
                    this._textObject.text = this._text;
                }
            }

            // Handle special input keys.
            if(input.wasKeyTapped(Scancode.BACKSPACE))
                doBackspace();

            this.appendText(input.textInput);

            // Update the cursor's position.
            if(this._text.length == 0)
                this._cursorObject.position = this.position;
            else
            {
                auto rect = this._textObject.getRectForChar(this._text.length - 1);
                this._cursorObject.position = vec2(rect.position.x + rect.size.x, rect.position.y);
            }
        }

        public void onRender(Window window)
        {
            window.renderer.drawText(this._textObject);

            if(this._isActive && this._displayCursor)
                window.renderer.drawText(this._cursorObject);
        }
    }
}