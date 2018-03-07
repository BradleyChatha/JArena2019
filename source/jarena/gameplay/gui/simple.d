/// Contains simple, easy to use, yet low-customisable controls.
module jarena.gameplay.gui.simple;

private
{
    import jarena.core, jarena.gameplay, jarena.graphics;
}

class SimpleButton : Button
{
    private
    {
        // SFML is slightly incorrect when reporting the size of text, so these offsets can be fiddled with to give
        // a better result.
        const SFML_TEXT_OFFSET_X = 0;
        const SFML_TEXT_OFFSET_Y = -2;

        uvec4b _idleColour;
        uvec4b _mouseOverColour;
        uvec4b _mouseClickColour;
        Text   _text;
        bool   _clickLock;

        void centerText()
        {
            auto textSize       = this._text.screenSize;
            auto textSizeHalf   = vec2(textSize.x / 2, textSize.y / 2);

            auto thisSize       = super.size;
            auto thisPos        = super.position;
            auto thisSizeHalf   = vec2(thisSize.x / 2, thisSize.y / 2);

            auto centerPos      = (thisPos + thisSizeHalf) - textSizeHalf;
            this._text.position = centerPos + vec2(SFML_TEXT_OFFSET_X, SFML_TEXT_OFFSET_Y);
        }
    }

    public
    {
        ///
        this(Text text,
             OnClickFunc func       = null, 
             vec2 position          = vec2(0),
             vec2 size              = vec2(80, 40),
             uvec4b colour          = jarena.core.colour(128, 0, 128, 255),
             uvec4b mouseOverColour = jarena.core.colour(64, 0, 64, 255),
             uvec4b clickColour     = jarena.core.colour(32, 0, 32, 255))
        {
            assert(text !is null);

            this._text              = text;
            this._idleColour        = colour;
            this._mouseClickColour  = clickColour;
            this._mouseOverColour   = mouseOverColour;

            super.onClick   = func;
            super.position  = position;
            super.size      = size;
            super.colour    = colour;
        }

        /// Changes the size of the button to fit the size of the text
        void fitToText(vec2 padding = vec2(80.0f, 8.0f))
        {
            auto textSize = this._text.screenSize;
            super.size = textSize + padding;
        }

        /// Call this function if it's text is modified outside of the provided functions.
        void updateLayout()
        {
            this.centerText();
        }

        ///
        @property @safe @nogc
        inout(Text) text() nothrow inout
        {
            return this._text;
        }
    }

    override
    {
        protected void onNewParent(UIElement newParent, UIElement oldParent){}
        protected void onChildStateChanged(UIElement child, StateChange change){}
        protected void onAddChild(UIElement child){}
        protected void onRemoveChild(UIElement child){}
        protected void onColourChanged(uvec4b oldColour, uvec4b newColour){}

        protected void onPositionChanged(vec2 oldPos, vec2 newPos)
        {
            this.updateLayout();
        }
        
        protected void onSizeChanged(vec2 oldSize, vec2 newSize)
        {
            this.updateLayout();
        }
        
        public void onUpdate(InputManager input, GameTime deltaTime)
        {
            auto thisRect = RectangleF(super.position, super.size);
            if(thisRect.contains(input.mousePostion)) // If the mouse is hovered over
            {
                if(input.isMouseButtonDown(MouseButton.Left) && !this._clickLock)
                {
                    this._clickLock = true;
                    super.colour = this._mouseClickColour;

                    auto func = super.onClick;
                    if(func !is null)
                        func(this);
                }
                else
                    super.colour = this._mouseOverColour;

                if(!input.isMouseButtonDown(MouseButton.Left))
                    this._clickLock = false;
            }
            else
            { // Not hovered, nor clicked, so set the colour to the default.
                super.colour = this._idleColour;
                this._clickLock = true; 
            }
        }

        public void onRender(Window window)
        {
            window.renderer.drawRect(super.position, super.size, super.colour);
            window.renderer.drawText(this._text);
        }
    }
}

class SimpleLabel : Control
{
    private
    {
        Text _text;
    }

    public
    {
        this(Text text, vec2 position = vec2(0))
        {
            assert(text !is null);
            this._text = text;
            super.colour   = text.colour;
            super.position = position;
        }

        /// Call this function if it's text is modified outside of the provided functions.
        void updateLayout()
        {
            this._text.position = super.position;
            this._text.colour   = super.colour;
            super.size          = this._text.screenSize + vec2(0, this._text.charSize / 2);
        }

        void updateTextASCII(const(char)[] ascii)
        {
            this._text.asciiText = ascii;
            this.updateLayout();
        }

        @property @safe @nogc
        inout(Text) text() nothrow inout
        {
            return this._text;
        }
    }

    override
    {
        protected void onNewParent(UIElement newParent, UIElement oldParent){}
        protected void onChildStateChanged(UIElement child, StateChange change){}
        protected void onAddChild(UIElement child){}
        protected void onRemoveChild(UIElement child){}
        public void onUpdate(InputManager input, GameTime deltaTime){}
        protected void onSizeChanged(vec2 oldSize, vec2 newSize){}

        protected void onPositionChanged(vec2 oldPos, vec2 newPos)
        {
            this.updateLayout();
        }

        protected void onColourChanged(uvec4b oldColour, uvec4b newColour)
        {
            this.updateLayout();
        }

        public void onRender(Window window)
        {
            window.renderer.drawText(this.text);
        }
    }
}