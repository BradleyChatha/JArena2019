module jarena.gameplay.gui.control;

private
{
    import jarena.core, jarena.graphics;
}

abstract class UIElement
{
    enum StateChange
    {
        PositionChanged,
        SizeChanged
    }

    private
    {
        UIElement _parent;
        vec2      _position;
        vec2      _size;
    }

    protected
    {
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

            if(this.parent !is null)
                this.parent.onChildStateChanged(this, StateChange.PositionChanged);

            this.onPositionChanged(old, newPosition);
        }

        /++
         + Sets the size for this UIElement.
         +
         + Notes:
         +  All inheriting classes should assure that their actual size on screen is kept in sync,
         +  and also respects the size set by this function.
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

            if(this.parent !is null)
                this.parent.onChildStateChanged(this, StateChange.SizeChanged);

            this.onSizeChanged(old, newSize);
        }

        /// Returns: The parent for this UIElement.
        @property @safe @nogc
        final inout(UIElement) parent() nothrow inout
        {
            return this._parent;
        }

        /// Returns: The position for this UIElement.
        @property @safe @nogc
        final inout(vec2) position() nothrow inout
        {
            return this._position;
        }

        /// Returns: The size for this UIElement.
        @property @safe @nogc
        final inout(vec2) size() nothrow inout
        {
            return this._size;
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

        ///
        public void onUpdate(GameTime deltaTime);

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
    uvec4b colour;

    this(vec2 position, vec2 size, uvec4b colour)
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
        public void onUpdate(GameTime deltaTime){}

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
        UIElement addChild(UIElement child)
        {
            assert(child !is null);
            child.parent = this;

            return child;
        }
    }

    abstract
    {
        /// Returns: The children for this container.
        @property
        inout(UIElement[]) children() inout;
    }
}

final class StackContainer : Container
{
    enum Direction
    {
        Horizontal,
        Vertical
    }

    private
    {
        const float _padding = 4; // TODO: Make this changeable.
        UIElement[] _children;
        bool        _ignoreStateChanges;
        Direction   _direction;

        void sortPositions()
        {
            this._ignoreStateChanges = true;

            if(this._direction == Direction.Vertical)
                this.sortVertical();
            else
                this.sortHorizontal();

            this._ignoreStateChanges = false;
        }

        void sortHorizontal()
        {
            vec2 newSize = vec2(0);
            vec2 nextPos = this.position;
            foreach(child; this._children)
            {
                child.position = nextPos;

                if(child.size.y > newSize.y)
                    newSize.y = child.size.y;

                newSize.x = (child.position.x + child.size.x) - this.position.x;
                nextPos.x = nextPos.x + child.size.x + this._padding; // += doesn't work.
            }

            this.size = newSize;
        }

        void sortVertical()
        {
            vec2 newSize = vec2(0);
            vec2 nextPos = this.position;
            foreach(child; this._children)
            {
                child.position = nextPos;

                if(child.size.x > newSize.x)
                    newSize.x = child.size.x;

                newSize.y = (child.position.y + child.size.y) - this.position.y;
                nextPos.y = nextPos.y + child.size.y + this._padding; // += doesn't work.
            }

            this.size = newSize;
        }
    }

    public
    {
        ///
        this(Direction direction = Direction.Vertical)
        {
            this._direction = direction;
        }

        ///
        this(vec2 position, Direction direction = Direction.Vertical)
        {
            this(direction);
            this.position = position;
        }
    }

    override
    {
        protected void onNewParent(UIElement newParent, UIElement oldParent){}
        protected void onSizeChanged(vec2 oldSize, vec2 newSize){}
        protected void onChildStateChanged(UIElement child, StateChange change)
        {
            if(!this._ignoreStateChanges)
                this.sortPositions();
        }

        protected void onAddChild(UIElement child)
        {
            this._children ~= child;
            this.sortPositions();
        }

        protected void onRemoveChild(UIElement child)
        {
            import std.algorithm : countUntil;
            this._children.removeAt(this._children.countUntil(child));
            this.sortPositions();
        }
        
        protected void onPositionChanged(vec2 oldPos, vec2 newPos)
        {
            this.sortPositions();
        }

        public void onUpdate(GameTime deltaTime)
        {
            foreach(child; this.children)
                child.onUpdate(deltaTime);
        }

        public void onRender(Window window)
        {
            debug window.renderer.drawRect(this.position, this.size, colour(0, 0, 0, 128));

            foreach(child; this.children)
                child.onRender(window);
        }

        @property
        inout(UIElement[]) children() inout
        {
            return this._children;
        }
    }
}

/// A container that doesn't give a single damn about keeping things aligned with itself.
/// Size and position for this container are completely useless.
final class FreeFormContainer : Container
{
    private
    {
        UIElement[] _children;
    }

    override
    {        
        protected void onNewParent(UIElement newParent, UIElement oldParent){}
        protected void onSizeChanged(vec2 oldSize, vec2 newSize){}
        protected void onChildStateChanged(UIElement child, StateChange change){}

        protected void onAddChild(UIElement child)
        {
            this._children ~= child;
        }

        protected void onRemoveChild(UIElement child)
        {
            import std.algorithm : countUntil;
            this._children.removeAt(this._children.countUntil(child));
        }
        
        protected void onPositionChanged(vec2 oldPos, vec2 newPos){}

        public void onUpdate(GameTime deltaTime)
        {
            foreach(child; this.children)
                child.onUpdate(deltaTime);
        }

        public void onRender(Window window)
        {
            foreach(child; this.children)
                child.onRender(window);
        }

        @property
        inout(UIElement[]) children() inout
        {
            return this._children;
        }
    }
}