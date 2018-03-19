/// Contains containers
module jarena.gameplay.gui.containers;

private
{
    import std.typecons : Flag;
    import jarena.core, jarena.gameplay, jarena.graphics;
}

/++
 + A container that will stack controls either vertically or horizontally.
 +
 + Controls added to this container will have their positions managed by the container,
 + meaning any changes made to the positions of this container's children will have no effect.
 +
 + For this container, setting it's colour will add a background colour to the container's area.
 + ++/
final class StackContainer : Container
{
    /// Determines whether the contain auto re-sizes itself.
    alias AutoSize = Flag!"autoSize";

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
        AutoSize    _shouldResize = AutoSize.yes;

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

            if(this.autoSize)
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

            if(this.autoSize)
                this.size = newSize;
        }
    }

    public
    {
        ///
        this(Direction direction = Direction.Vertical, Colour colour = Colour.transparent)
        {
            this._direction = direction;
            super.colour = colour;
        }

        ///
        this(vec2 position, Direction direction = Direction.Vertical, Colour colour = Colour.transparent)
        {
            this(direction, colour);
            super.position = position;
        }

        /// Returns: Whether the container will automatically change it's size or not.
        @property @safe @nogc
        bool autoSize() nothrow const
        {
            return this._shouldResize;
        }

        /++
         + Determines whether the container will automatically change it's
         + size to tightly fit around it's children.
         +
         + It may be desirable to disable this feature in some cases, such as making use of
         + the container's background colour.
         + ++/
        @property @safe @nogc
        void autoSize(AutoSize flag) nothrow
        {
            this._shouldResize = flag;
        }
    }

    override
    {
        protected void onNewParent(UIElement newParent, UIElement oldParent){}
        protected void onSizeChanged(vec2 oldSize, vec2 newSize){}
        protected void onColourChanged(Colour oldColour, Colour newColour){}
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

        public void onUpdate(InputManager input, GameTime deltaTime)
        {
            foreach(child; this.children)
                child.onUpdate(input, deltaTime);
        }

        public void onRender(Window window)
        {
            window.renderer.drawRect(super.position, super.size, super.colour);

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
        protected void onColourChanged(Colour oldColour, Colour newColour){}

        public void onUpdate(InputManager input, GameTime deltaTime)
        {
            foreach(child; this.children)
                child.onUpdate(input, deltaTime);
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
