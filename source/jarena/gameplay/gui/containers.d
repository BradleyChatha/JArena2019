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
 +
 + Setting the size for this container has no effect.
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
        const float     _padding = 4; // TODO: Make this changeable.
        UIElement[]     _children;
        Direction       _direction;
        AutoSize        _shouldResize = AutoSize.yes;
        RectangleShape  _rect;

        void sortPositions()
        {
            super.ignoreChildStateChanges = true;

            if(this._direction == Direction.Vertical)
                this.sortVertical();
            else
                this.sortHorizontal();

            super.ignoreChildStateChanges = false;
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
            this._rect              = new RectangleShape();
            this._rect.borderSize   = 1;
            this._rect.borderColour = Colour.black;
            this._direction         = direction;
            super.colour            = colour;
        }

        ///
        this(vec2 position, Direction direction = Direction.Vertical, Colour colour = Colour.transparent)
        {
            this(direction, colour);
            super.position = position;
        }

        ///
        void clear()
        {
            while(this.children.length > 0)
                this.children[0].parent = null;
        }
        
        /// Returns: Whether the container will automatically change it's size or not.
        @property @safe @nogc
        AutoSize autoSize() nothrow const
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

        /// ditto
        @property @safe @nogc
        void autoSize(bool flag) nothrow
        {
            this._shouldResize = cast(AutoSize)flag;
        }
    }

    override
    {
        protected void onChildStateChanged(UIElement child, StateChange change)
        {
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
            this._rect.position = newPos;
            this.sortPositions();
        }

        protected void onSizeChanged(vec2 oldSize, vec2 newSize)
        {
            this._rect.size = newSize;
        }

        protected void onColourChanged(Colour oldColour, Colour newColour)
        {
            this._rect.colour = newColour;
        }

        public void onUpdate(InputManager input, Duration deltaTime)
        {
            foreach(child; this.children)
                child.onUpdate(input, deltaTime);
        }

        public void onRender(Window window)
        {
            auto oldClip = window.renderer.scissorRect;
            scope(exit) window.renderer.scissorRect = oldClip;

            window.renderer.scissorRect = RectangleI(
                cast(int)(this.position.x - this._rect.borderSize),
                cast(int)(this.position.y - this._rect.borderSize),
                cast(int)(this.size.x     + (this._rect.borderSize * 2)),
                cast(int)(this.size.y     + (this._rect.borderSize * 2))
            );

            if(super.colour != Colour.transparent)
                window.renderer.drawRectShape(this._rect);

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
class FreeFormContainer : Container
{
    private
    {
        UIElement[] _children;
    }

    override
    {
        protected void onAddChild(UIElement child)
        {
            this._children ~= child;
        }

        protected void onRemoveChild(UIElement child)
        {
            import std.algorithm : countUntil;
            this._children.removeAt(this._children.countUntil(child));
        }

        public void onUpdate(InputManager input, Duration deltaTime)
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