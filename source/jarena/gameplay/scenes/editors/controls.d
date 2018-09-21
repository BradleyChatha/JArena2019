module jarena.gameplay.scenes.editors.controls;

private
{
    import jarena.core, jarena.gameplay, jarena.graphics;

    enum TOOLTIP_FONT_KEY       = "Calibri";
    enum TOOLTIP_BOX_FILL       = Colours.perfume;
    enum TOOLTIP_TEXT_SIZE      = 18;
    enum TOOLTIP_TITLE_COLOUR   = Colours.yellowMetal;
    enum TOOLTIP_DESC_COLOUR    = Colours.battleshipGrey;
    enum TOOLTIP_OFFSET         = vec2(15, 0);
}

class ButtonTooltip : Control
{
    private
    {
        StackContainer _box;
        SimpleLabel    _name;
        SimpleLabel    _description;

        bool _showing;
    }

    this(string name, string description)
    {
        this._box = new StackContainer(StackContainer.Direction.Vertical, TOOLTIP_BOX_FILL);
        this._box.autoSize = true;

        // "SimpleLabel" certainly isn't Simple to make T.T
        this._name = this._box.addChild(
            new SimpleLabel(
                new Text(Systems.assets.get!Font(TOOLTIP_FONT_KEY),
                         name,
                         vec2(0),
                         TOOLTIP_TEXT_SIZE,
                         TOOLTIP_TITLE_COLOUR
                )
            )
        );
        this._description = this._box.addChild(
            new SimpleLabel(
                new Text(Systems.assets.get!Font(TOOLTIP_FONT_KEY),
                         description,
                         vec2(0),
                         TOOLTIP_TEXT_SIZE,
                         TOOLTIP_DESC_COLOUR
                )
            )
        );
    }

    public
    {
        @property @safe @nogc
        void showing(bool value) nothrow
        {
            this._showing = value;
        }
    }

    public override
    {
        protected void onAddChild(UIElement child){}
        protected void onRemoveChild(UIElement child){}
        protected void onNewParent(UIElement newParent, UIElement oldParent){}
        protected void onChildStateChanged(UIElement child, StateChange change){}

        protected void onPositionChanged(vec2 oldPos, vec2 newPos)
        {
            this._box.position = newPos;
        }

        protected void onSizeChanged(vec2 oldSize, vec2 newSize){}

        protected void onColourChanged(Colour oldColour, Colour newColour)
        {
            this._box.colour = newColour;
        }

        ///
        public void onUpdate(InputManager input, Duration deltaTime)
        {
            if(!this._showing)
                return;

            this._box.position = input.mousePosition + TOOLTIP_OFFSET;
            this._box.onUpdate(input, deltaTime);
        }

        ///
        public void onRender(Window window)
        {
            if(!this._showing)
                return;

            this._box.onRender(window);
        }
    }
}

class EditorButton : Button
{
    private
    {
        Sprite          _image;
        ButtonTooltip   _tooltip;
        bool            _isSelected;
        Colour          _baseColour;
    }

    this(Texture image, string name, string description, OnClickFunc onClick = null)
    {
        this._image     = new Sprite(image);
        this._tooltip   = new ButtonTooltip(name, description);
        this.size       = this._image.bounds.size;
        this.onClick    = onClick;
        this.isSelected = false;
    }

    @property
    bool isSelected()
    {
        return this._isSelected;
    }

    @property
    void isSelected(bool value)
    {
        this._isSelected = value;
        this._baseColour = (value) ? Colour.green : Colour.white;
    }

    public override
    {
        protected void onAddChild(UIElement child){}
        protected void onRemoveChild(UIElement child){}
        protected void onNewParent(UIElement newParent, UIElement oldParent){}
        protected void onChildStateChanged(UIElement child, StateChange change){}

        protected void onPositionChanged(vec2 oldPos, vec2 newPos)
        {
            this._image.position = newPos;
        }

        protected void onSizeChanged(vec2 oldSize, vec2 newSize){}
        protected void onColourChanged(Colour oldColour, Colour newColour)
        {
            this._image.colour = newColour;
        }

        public void onUpdate(InputManager input, Duration deltaTime)
        {
            if(this._image.bounds.contains(input.mousePosition))
            {
                this._tooltip.showing = true;
                if(input.wasMouseButtonTapped(MouseButton.Left))
                {
                    this.colour = this._baseColour.darken(0.5);

                    if(super.onClick() !is null)
                        super.onClick()(this);
                }
                else
                    this.colour = this._baseColour.darken(0.75);
            }
            else
            {
                this._tooltip.showing = false;
                this.colour = this._baseColour;
            }

            this._tooltip.onUpdate(input, deltaTime);
        }

        public void onRender(Window window)
        {
            window.renderer.drawSprite(this._image);
            this._tooltip.onRender(window);
        }
    }
}

class EditorScrollBoxContainer : Container
{
    enum SCROLL_BAR_WIDTH   = 32;
    enum MAIN_BOX_COLOUR    = Colour(128, 128, 128, 255);
    enum SCROLL_BACK_COLOUR = Colour(64, 64, 64, 255);
    enum SCROLL_BAR_COLOUR  = Colour(168, 168, 168, 255);

    private
    {
        UIElement[] _children;
        int         _toSkip;
        size_t      _renderCount;

        // Visual elements
        RectangleShape _mainBox;
        RectangleShape _scrollBarBackground;
        RectangleShape _scrollBar;

        void sortPositions()
        {
            this._renderCount = 0;
            auto currentY = 0.0f;
            foreach(i, child; this.children)
            {
                if(i < this._toSkip)
                    continue;

                if(child.size.y + currentY > this.size.y)
                    break;

                child.position = this.position + vec2(0, currentY);
                currentY += child.size.y;
                this._renderCount += 1;
            }
        }

        void calculateScrollbarHeight()
        {
            // TODO:
        }
    }

    this()
    {
        this._mainBox = new RectangleShape();
        this._scrollBar = new RectangleShape(RectangleF(0, 0, SCROLL_BAR_WIDTH, SCROLL_BAR_WIDTH));
        this._scrollBarBackground = new RectangleShape(RectangleF(0, 0, SCROLL_BAR_WIDTH, 0));

        this._mainBox.colour = MAIN_BOX_COLOUR;
        this._scrollBar.colour = SCROLL_BAR_COLOUR;
        this._scrollBarBackground.colour = SCROLL_BACK_COLOUR;
    }

    public override
    {
        protected void onColourChanged(Colour oldColour, Colour newColour){}
        protected void onNewParent(UIElement newParent, UIElement oldParent){}

        protected void onSizeChanged(vec2 oldSize, vec2 newSize)
        {
            this._mainBox.size                 = newSize - vec2(SCROLL_BAR_WIDTH, 0);
            this._scrollBar.position           = this._mainBox.area.topRight;
            this._scrollBarBackground.position = this._mainBox.area.topRight;
            this._scrollBarBackground.size     = vec2(this._scrollBarBackground.size.x, newSize.y);
            this.sortPositions();
            this.calculateScrollbarHeight();
        }

        protected void onPositionChanged(vec2 oldPos, vec2 newPos)
        {
            this._mainBox.position = newPos;
            this.size = this.size; // Recalcs positions for the scrollbar and sorts child positions.
        }

        protected void onChildStateChanged(UIElement child, StateChange change)
        {

        }

        protected void onAddChild(UIElement child)
        {
            this._children ~= child;
            this.sortPositions();
            this.calculateScrollbarHeight();
        }

        protected void onRemoveChild(UIElement child)
        {
            import std.algorithm : countUntil;
            this._children.removeAt(this._children.countUntil(child));
            this.sortPositions();
            this.calculateScrollbarHeight();
        }

        public void onUpdate(InputManager input, Duration deltaTime)
        {
            foreach(child; this.children[this._toSkip..this._toSkip + this._renderCount])
                child.onUpdate(input, deltaTime);

            if(!RectangleF(this.position, this.size).contains(input.mousePosition))
                return;

            if(input.wheelDelta != 0)
            {
                this._toSkip -= input.wheelDelta;

                if(this._toSkip < 0)
                    this._toSkip = 0;
                else if(this._toSkip >= this.children.length) // This needs to be revisited.
                    this._toSkip = cast(int)this.children.length;

                this.sortPositions();
            }
        }

        public void onRender(Window window)
        {
            window.renderer.drawRectShape(this._mainBox);
            foreach(child; this.children[this._toSkip..this._toSkip + this._renderCount])
                child.onRender(window);
            window.renderer.drawRectShape(this._scrollBarBackground);
            window.renderer.drawRectShape(this._scrollBar);
        }

        @property
        inout(UIElement[]) children() inout
        {
            return this._children;
        }
    }
}

class EditorAtlasPicker : Control
{
    enum BUTTON_HEIGHT = 32;
    enum BUTTON_COLOUR = Colour(128, 64, 128, 255);
    enum FONT_KEY = "Calibri";
    enum BUTTON_TEXT_SIZE = 14;
    enum BUTTON_TEXT_COLOUR = Colour.white;

    alias OnSelectFunc = void delegate(SpriteAtlas selected);

    class PickButton : SimpleTextButton
    {
        EditorAtlasPicker picker;
        SpriteAtlas atlas;

        this(string name, SpriteAtlas atlas, EditorAtlasPicker picker)
        {
            this.atlas = atlas;
            this.picker = picker;
            super(new Text(Systems.assets.get!Font(FONT_KEY), name, vec2(0), BUTTON_TEXT_SIZE, BUTTON_TEXT_COLOUR),
                  &this.onPick,
                  vec2(0),
                  vec2(picker._box.size.x - EditorScrollBoxContainer.SCROLL_BAR_WIDTH, BUTTON_HEIGHT),
                  BUTTON_COLOUR,
                  BUTTON_COLOUR.darken(0.8),
                  BUTTON_COLOUR.darken(0.5)
            );
        }

        void onPick(Button b)
        {
            this.picker._onSelect(this.atlas);
        }
    }

    private
    {
        EditorScrollBoxContainer _box;
        OnSelectFunc _onSelect;
    }

    this(OnSelectFunc func, vec2 position, vec2 size)
    {
        this._box = new EditorScrollBoxContainer();
        this.position = position;
        this.size = size;
        this._onSelect = func;
    }

    public
    {
        void reloadList()
        {
            // I could *probably* reuse these instead of making new ones each time
            // But meh, this is only a developer tool.
            foreach(child; this._box.children)
                child.parent = null;

            foreach(kvp; Systems.assets.byKeyValueFiltered!SpriteAtlas)
                this._box.addChild(new PickButton(kvp.key, kvp.value, this));
        }
    }

    public override
    {
        protected void onAddChild(UIElement child){}
        protected void onRemoveChild(UIElement child){}
        protected void onNewParent(UIElement newParent, UIElement oldParent){}
        protected void onChildStateChanged(UIElement child, StateChange change){}

        protected void onPositionChanged(vec2 oldPos, vec2 newPos)
        {
            this._box.position = newPos;
        }

        protected void onSizeChanged(vec2 oldSize, vec2 newSize)
        {
            this._box.size = newSize;
        }

        protected void onColourChanged(Colour oldColour, Colour newColour)
        {
            this._box.colour = newColour;
        }

        public void onUpdate(InputManager input, Duration deltaTime)
        {
            this._box.onUpdate(input, deltaTime);
        }

        public void onRender(Window window)
        {
            this._box.onRender(window);
        }
    }
}

class EditorLabeledInput : Control
{
    enum COLOUR = Colour.white;

    private
    {
        StackContainer _box;
    }

    this(string label, Font font, vec2 boxSize, uint charSize = 14)
    {
        this._box = new StackContainer(StackContainer.Direction.Horizontal);
        this._box.addChild(new SimpleLabel(new Text(font, label~":", vec2(0), charSize, COLOUR)));
        this._box.addChild("Input", new SimpleTextBox(new Text(font, "", vec2(0), charSize, Colour.black), vec2(0), boxSize));

        this.size = boxSize;
    }

    @property
    SimpleTextBox input()
    {
        return this._box.getChild!SimpleTextBox("Input");
    }

    public override
    {
        protected void onAddChild(UIElement child){}
        protected void onRemoveChild(UIElement child){}
        protected void onNewParent(UIElement newParent, UIElement oldParent){}
        protected void onChildStateChanged(UIElement child, StateChange change){}

        protected void onPositionChanged(vec2 oldPos, vec2 newPos)
        {
            this._box.position = newPos;
        }

        protected void onSizeChanged(vec2 oldSize, vec2 newSize)
        {
            this._box.size = newSize;
        }

        protected void onColourChanged(Colour oldColour, Colour newColour)
        {
            this._box.colour = newColour;
        }

        public void onUpdate(InputManager input, Duration deltaTime)
        {
            this._box.onUpdate(input, deltaTime);
        }

        public void onRender(Window window)
        {
            this._box.onRender(window);
        }
    }
}

class EditorSpriteInfo : Control
{
    enum FONT_KEY = "Calibri";
    enum FONT_SIZE = 14;
    enum FONT_COLOUR = Colour.white;
    enum INPUT_BOX_SIZE = vec2(120, 14);
    enum APPLY_BUTTON_SIZE = vec2(120, EditorAtlasPicker.BUTTON_HEIGHT);

    alias OnSpriteModify = void delegate(SpriteAtlas atlas, string spriteName);

    private
    {
        EditorScrollBoxContainer _box;
        SpriteAtlas _atlas;
        string _currentSpriteName;
        OnSpriteModify _onModifySprite;

        void addInput(string name)
        {
            this._box.addChild(name, 
                new EditorLabeledInput(
                    name, 
                    Systems.assets.get!Font(FONT_KEY),
                    INPUT_BOX_SIZE,
                    FONT_SIZE
                )
            );
        }

        const(char[]) getInput(string name)
        {
            return this._box.getChild!EditorLabeledInput(name).input.textInput;
        }

        void setInput(string name, string value)
        {
            this._box.getChild!EditorLabeledInput(name).input.textInput = value;
        }

        void onApply(Button btn)
        {
            import std.conv : to;

            if(this._currentSpriteName is null)
                return;

            this._atlas.unregister(this._currentSpriteName);
            this._currentSpriteName = this.getInput("Name").idup;
            this._atlas.register(this._currentSpriteName, RectangleI(
                this.getInput("X").to!int,
                this.getInput("Y").to!int,
                this.getInput("W").to!int,
                this.getInput("H").to!int
            ));

            this._onModifySprite(this._atlas, this._currentSpriteName);
        }
    }

    this(vec2 position, vec2 size)
    {
        this._box = new EditorScrollBoxContainer();
        this._box.position = position;
        this._box.size = size;

        this.addInput("Name");
        this.addInput("X");
        this.addInput("Y");
        this.addInput("W");
        this.addInput("H");

        this._box.addChild("Apply", new SimpleTextButton(
            new Text(Systems.assets.get!Font(FONT_KEY), "Apply", vec2(0), FONT_SIZE, FONT_COLOUR),
            &this.onApply,
            vec2(0),
            APPLY_BUTTON_SIZE
        ));

        this.position = position;
        this.size = size;
    }

    public
    {
        void useAtlas(SpriteAtlas atlas)
        {
            this._atlas = atlas;
        }

        void useSprite(string spriteName)
        {
            import std.format : format;
            import std.conv   : to;

            this._currentSpriteName = spriteName;

            auto sprite = this._atlas.getSpriteRect(spriteName);
            this.setInput("Name", spriteName);
            this.setInput("X", sprite.position.x.to!string);
            this.setInput("Y", sprite.position.y.to!string);
            this.setInput("W", sprite.size.x.to!string);
            this.setInput("H", sprite.size.y.to!string);
        }

        @property
        void onModifySprite(OnSpriteModify func)
        {
            this._onModifySprite = func;
        }
    }

    public override
    {
        protected void onAddChild(UIElement child){}
        protected void onRemoveChild(UIElement child){}
        protected void onNewParent(UIElement newParent, UIElement oldParent){}
        protected void onChildStateChanged(UIElement child, StateChange change){}

        protected void onPositionChanged(vec2 oldPos, vec2 newPos)
        {
            this._box.position = newPos;
        }

        protected void onSizeChanged(vec2 oldSize, vec2 newSize)
        {
            this._box.size = newSize;
        }

        protected void onColourChanged(Colour oldColour, Colour newColour)
        {
            this._box.colour = newColour;
        }

        public void onUpdate(InputManager input, Duration deltaTime)
        {
            if(input.wasKeyTapped(Scancode.RETURN))
                this.onApply(null);

            this._box.onUpdate(input, deltaTime);
        }

        public void onRender(Window window)
        {
            this._box.onRender(window);
        }
    }
}

class EditorRectangle(MetadataT) : DrawableObject
{
    enum Mode
    {
        Select,
        Move,
        Resize
    }

    alias OnSelectFunc = void delegate(typeof(this) rect);
    alias OnChangeFunc = void delegate(typeof(this) rect);

    private
    {
        MetadataT      _metadata;
        RectangleShape _rect;
        Mode           _mode;
        Colour         _baseColour;
        OnSelectFunc   _onSelect;
        OnChangeFunc   _onChange;
        Camera         _camera;
        bool           _isSelected;
        vec2           _lastMousePos;
        RectangleF     _allowedArea;
    }

    this(Camera camera, RectangleF area, Colour fillColour, RectangleF allowedArea, MetadataT metadata = MetadataT.init)
    {
        this._rect = new RectangleShape(area);
        this._rect.colour = fillColour;
        this._rect.borderColour = Colour.black;
        this._metadata = metadata;
        this._baseColour = fillColour;
        this._camera = camera;
        this._allowedArea = allowedArea;
    }

    public
    {
        @property
        ref Mode mode()
        {
            return this._mode;
        }

        @property
        ref MetadataT metadata()
        {
            return this._metadata;
        }

        @property
        ref OnSelectFunc onSelect()
        {
            return this._onSelect;
        }

        @property
        ref OnChangeFunc onChange()
        {
            return this._onChange;
        }

        @property
        RectangleShape shape()
        {
            return this._rect;
        }
    }

    public override
    {
        void onRegister(PostOffice office){}
        void onUnregister(PostOffice office){}

        void onUpdate(Duration deltaTime, InputManager input)
        {
            if(this._rect.colour != this._baseColour)
                this._rect.colour = this._baseColour;

            final switch(this._mode) with(Mode)
            {
                case Select:
                    auto isMouseOver = this._rect.area.contains(this._camera.screenToWorldPos(input.mousePosition));
                    if(isMouseOver)
                    {
                        auto col = this._baseColour.lighten(0.25);
                        col.a = this._baseColour.a;
                        this._rect.colour = col;
                    }

                    if(input.wasMouseButtonTapped(MouseButton.Left))
                    {
                        if(isMouseOver)
                        {
                            this._onSelect(this);
                            this._isSelected = true;
                            this._rect.borderSize = 1;
                        }
                        else
                        {
                            this._isSelected = false;
                            this._rect.borderSize = 0;
                        }
                    }
                    break;

                case Move:
                    if(!this._isSelected)
                        break;

                    auto oldPos = this._rect.position;
                    
                    if(input.isMouseButtonDown(MouseButton.Left))
                        this._rect.position = this._rect.position + (input.mousePosition - this._lastMousePos);

                    if(input.wheelDelta != 0)
                    {
                        if(input.isAltDown)
                            this._rect.position = vec2(this._rect.position.x, this._rect.position.y - input.wheelDelta);
                        else
                            this._rect.position = vec2(this._rect.position.x + input.wheelDelta, this._rect.position.y);
                    }

                    // Check we're still in bounds.
                    if(this._rect.position.x < this._allowedArea.position.x)
                        this._rect.position = vec2(this._allowedArea.position.x, this._rect.position.y);

                    if(this._rect.position.y < this._allowedArea.position.y)
                        this._rect.position = vec2(this._rect.position.x, this._allowedArea.position.y);

                    if(this._rect.area.topRight.x > this._allowedArea.topRight.x)
                        this._rect.position = vec2(this._allowedArea.topRight.x - this._rect.size.x, this._rect.position.y);

                    if(this._rect.area.botRight.y > this._allowedArea.botRight.y)
                        this._rect.position = vec2(this._rect.position.x, this._allowedArea.botRight.y - this._rect.size.y);

                    // Make sure the position's actually changed before informing things.
                    if(oldPos != this._rect.position)
                        this._onChange(this);
                    break;

                case Resize:
                    if(!this._isSelected)
                        break;

                    auto oldPos = this._rect.position;
                    auto oldSize = this._rect.size;
                    if(input.wheelDelta != 0)
                    {
                        if(input.isAltDown)
                            this._rect.size = vec2(this._rect.size.x, this._rect.size.y + input.wheelDelta);
                        else if(input.isControlDown)
                        {
                            this._rect.size = vec2(this._rect.size.x, this._rect.size.y + input.wheelDelta);
                            this._rect.position = vec2(this._rect.position.x, this._rect.position.y - input.wheelDelta);
                        }
                        else if(input.isShiftDown)
                        {
                            this._rect.size = vec2(this._rect.size.x + input.wheelDelta, this._rect.size.y);
                            this._rect.position = vec2(this._rect.position.x - input.wheelDelta, this._rect.position.y);
                        }
                        else
                            this._rect.size = vec2(this._rect.size.x + input.wheelDelta, this._rect.size.y);
                    }

                    if(input.isMouseButtonDown(MouseButton.Left))
                        this._rect.size = this._rect.size + (input.mousePosition - this._lastMousePos);

                    if(this._rect.size.x < 0)
                    {
                        this._rect.position = vec2(oldPos.x, this._rect.position.y);
                        this._rect.size     = vec2(oldSize.x, this._rect.size.y);
                    }
                    if(this._rect.size.y < 0)
                    {
                        this._rect.position = vec2(this._rect.position.x, oldPos.y);
                        this._rect.size     = vec2(this._rect.size.x, oldSize.y);
                    }
                    if(this._rect.area.topRight.x > this._allowedArea.topRight.x)
                        this._rect.size = vec2(this._allowedArea.topRight.x - this._rect.position.x, this._rect.size.y);
                    if(this._rect.area.botRight.y > this._allowedArea.botRight.y)
                        this._rect.size = vec2(this._rect.size.x, this._allowedArea.botRight.y - this._rect.position.y);

                    if(oldPos != this._rect.position || oldSize != this._rect.size)
                        this._onChange(this);
                    break;
            }

            this._lastMousePos = input.mousePosition;
        }

        void onRender(Window window)
        {
            window.renderer.drawRectShape(this._rect);
        }
    }
}