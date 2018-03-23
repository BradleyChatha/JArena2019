module jarena.gameplay.gui.control;

private
{
    import std.traits    : isSomeString;
    import std.algorithm : equal;
    import jarena.core, jarena.graphics;
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

    // All of the functions that need to be defined in child classes.
    abstract
    {
        /++
         + Called whenever this UIElement is set as the `UIElement.parent` for another
         + UIElement (therefore, making this element the parent, and the other element a child).
         +
         + Params:
         +  child = The child UIElement that has had it's parent set to this UIElement.
         + ++/
        protected void onAddChild(UIElement child);

        /++
         + Called whenever this UIElement $(B was) set as the `UIElement.parent` for another
         + UIElement, but is then replaced with another parent (meaning this element should no longer have it as a child).
         +
         + Params:
         +  child = The child UIElement that should no longer be treated as a child.
         + ++/
        protected void onRemoveChild(UIElement child);

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
        protected void onNewParent(UIElement newParent, UIElement oldParent);

        /++
         + Called whenever a child of this UIElement has a change in state.
         +
         + Params:
         +  child = The child that fired this event.
         +  change = The change in the child's state.
         + ++/
        protected void onChildStateChanged(UIElement child, StateChange change);

        /++
         + Called whenever the position for this UIElement is changed.
         +
         + Params:
         +  oldPos = The old position for this UIElement.
         +  newPos = The new position for this UIElement.
         + ++/
        protected void onPositionChanged(vec2 oldPos, vec2 newPos);

        /++
         + Called whenever the size for this UIElement is changed.
         +
         + Params:
         +  oldSize = The old size for this UIElement.
         +  newSize = The new size for this UIElement.
         + ++/
        protected void onSizeChanged(vec2 oldSize, vec2 newSize);

        /++
         + Called whenever the colour for this UIElement is changed.
         +
         + Params:
         +  oldColour = The old colour for this UIElement.
         +  newColour = The new colour for this UIElement.
         + ++/
        protected void onColourChanged(Colour oldColour, Colour newColour);

        ///
        public void onUpdate(InputManager input, GameTime deltaTime);

        ///
        public void onRender(Window window);
    }
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
        protected void onNewParent(UIElement newParent, UIElement oldParent){}
        protected void onSizeChanged(vec2 oldSize, vec2 newSize){}
        protected void onChildStateChanged(UIElement child, StateChange change){}
        protected void onAddChild(UIElement child){}
        protected void onRemoveChild(UIElement child){}
        protected void onPositionChanged(vec2 oldPos, vec2 newPos){}
        protected void onColourChanged(Colour oldColour, Colour newColour){}
        public void onUpdate(InputManager input, GameTime deltaTime){}

        public void onRender(Window window)
        {
            window.renderer.drawRect(this.position, this.size, this.colour);
        }
    }
}

/// NOTE: For containers, `UIElement.size` doesn't actually have any real effect, but it's still useful for alignment within other containers.
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
        inout(UI) getChild(UI : UIElement)(size_t index) inout
        {
            return cast(inout(UI))this.children[index];
        }

        ///
        inout(UI) getChild(UI : UIElement)(UI element) inout
        {
            import std.algorithm : filter;
            if(element is null)
                return null;

            auto results = this.children.filter!(c => c == element);
            return (results.empty) ? null : cast(inout(UI))results.front;
        }

        ///
        inout(UI) getChild(UI : UIElement, Str)(Str name) inout
        if(isSomeString!Str)
        {
            import std.algorithm : filter;
            if(name is null)
                return null;

            auto results = this.children.filter!(c => c.name.equal(name));
            return (results.empty) ? null : cast(inout(UI))results.front;
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
