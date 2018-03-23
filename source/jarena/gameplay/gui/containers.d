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
        const float _padding = 4; // TODO: Make this changeable.
        UIElement[] _children;
        Direction   _direction;
        AutoSize    _shouldResize = AutoSize.yes;

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
        protected void onNewParent(UIElement newParent, UIElement oldParent){}
        protected void onSizeChanged(vec2 oldSize, vec2 newSize){}
        protected void onColourChanged(Colour oldColour, Colour newColour){}
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

/++
 + 
 + ++/
final class GridContainer : Container
{
    // TODO: Add some common functionality so other containers can make use of anchoring.
    enum Anchor
    {
        None,

        TopLeft = None,
        Top,
        TopRight,
        Left,
        Middle,
        Right,
        BottomLeft,
        Bottom,
        BottomRight
    }
    
    enum SizeType
    {
        Pixels // Offset = Space between this definition and previous definition, in pixels.
    }
    
    private
    {
        alias IsRow = Flag!"isRow";
        
        // To make it easier to tell the difference between when they're used.
        alias RowDef = Definition;
        alias ColumnDef = Definition;
        struct Definition
        {
            SizeType type;
            float offset;
        }

        struct GridSlot
        {
            RectangleF rect;
        }

        struct ElementInfo
        {
            UIElement element;
            ivec2     slot;
        }
        
        UIElement[]     _children;
        ElementInfo[]   _childrenInfo; // Need two arrays, since I need a UIElement[] for Container.children to return.
        GridSlot[]      _slots;
        RowDef[]        _rows;
        ColumnDef[]     _columns;

        @safe
        void calculateGrid() nothrow
        {
            size_t getSlotIndex(size_t column, size_t row)
            {
                return (this._columns.length * row) + column;
            }
            
            this._slots.length = getSlotIndex(this._columns.length, this._rows.length);
            vec2 previous = this.position;
            foreach(rowIndex, currentRow; this._rows)
            {
                previous.x = this.position.x;
                foreach(columnIndex, currentColumn; this._columns)
                {
                    auto slotIndex = getSlotIndex(columnIndex, rowIndex);

                    GridSlot slot;
                    slot.rect = RectangleF(previous.x,
                                           previous.y,
                                           currentColumn.offset,
                                           currentRow.offset
                                          );

                    /*
                    debug
                    {
                        import std.exception : assumeWontThrow;
                        import std.stdio;
                        assumeWontThrow(
                            writefln(
                                "============================\n"~
                                "ColumnIndex: %s | RowIndex: %s\n"~
                                "SlotIndex: %s\n"~
                                "Column: %s | Row: %s\n"~
                                "PrevX: %s | PrevY: %s\n"~
                                "xDiff: %s | yDiff: %s\n"~
                                "SlotRect: %s\n"~
                                "============================",
                                columnIndex, rowIndex,
                                slotIndex,
                                currentColumn, currentRow,
                                previousX, previousY,
                                xDiff, yDiff,
                                slot.rect
                            )
                        );
                    }Quite useful, keep it here*/

                    this._slots[slotIndex] = slot;
                    
                    previous.x = slot.rect.topRight.x + 1;
                    if(columnIndex == this._columns.length - 1)
                        previous.y = slot.rect.botRight.y + 1;
                }
            }
        }
    }

    public
    {
        bool drawGrid = false;

        this(vec2 position, vec2 size = vec2(float.nan, float.nan))
        {
            this.position = position;
            this.size     = (size == vec2(float.nan, float.nan))
                            ? vec2(InitInfo.windowSize)
                            : size;
        }
        
        @safe
        void addRow(SizeType type, float offset) nothrow
        {
            this._rows ~= RowDef(type, offset);
            this.calculateGrid();
        }
        
        @safe
        void addColumn(SizeType type, float offset) nothrow
        {
            this._columns ~= ColumnDef(type, offset);
            this.calculateGrid();
        }
    }
    
    override
    {        
        protected void onNewParent(UIElement newParent, UIElement oldParent){}
        protected void onSizeChanged(vec2 oldSize, vec2 newSize){}
        protected void onChildStateChanged(UIElement child, StateChange change){}
        protected void onPositionChanged(vec2 oldPos, vec2 newPos){}
        protected void onColourChanged(Colour oldColour, Colour newColour){}
        
        protected void onAddChild(UIElement child)
        {
            this._children ~= child;
            this._childrenInfo.length += 1;
        }

        protected void onRemoveChild(UIElement child)
        {
            import std.algorithm : countUntil;

            auto index = this._children.countUntil(child);
            this._children.removeAt(index);
            this._childrenInfo.removeAt(index);
        }

        public void onUpdate(InputManager input, GameTime deltaTime)
        {
            foreach(child; this.children)
                child.onUpdate(input, deltaTime);
        }

        public void onRender(Window window)
        {
            foreach(child; this.children)
                child.onRender(window);

            if(this.drawGrid)
            {
                foreach(slot; this._slots)
                    window.renderer.drawRect(slot.rect.position, slot.rect.size, Colours.blossom);
            }
        }

        @property
        inout(UIElement[]) children() inout
        {
            return this._children;
        }
    }
}
