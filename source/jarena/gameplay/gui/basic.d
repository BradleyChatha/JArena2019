module jarena.gameplay.gui.basic;

private
{
    import jarena.gameplay, jarena.graphics, jarena.core, jarena.maths;
}

@UsesBinding!(ColourBinding!(BasicButton.baseColour))
@UsesBinding!(RectangleShapeBinding, BasicButton.shape)
@UsesBinding!(TextBinding, BasicButton.text)
@DisableBinding!(RectangleShapeBinding.colour, "shape", "For BasicButtons, the 'BasicButton.baseColour' property should be used over 'BasicButton.shape.colour'")
class BasicButton : UIBase
{
    private
    {
        bool _clickLock;
    }

    /// Properties & Signals
    public
    {
        Property!RectangleShape shape;
        Property!Text           text;
        Property!Colour         baseColour;
        Signal!BasicButton      onClick;
    }

    public
    {
        this()
        {
            this.shape                    = new Property!RectangleShape(new RectangleShape());
            this.shape.value.colour       = Colours.azure;
            this.shape.value.borderSize   = 1;
            this.shape.value.borderColour = Colour.black;
            this.text                     = new Property!Text(new Text(UIResources.defaultFont, "", vec2(0), 14, Colour.white));
            this.baseColour               = new Property!Colour(Colours.azure);
        }
    }
    
    public override
    {
        void arrange(RectangleF rect)
        {
            this.shape.value.position = rect.position;
            this.shape.value.size     = rect.size;
            this.text.value.position  = rect.position + ((rect.size / 2) - (this.text.value.screenSize / 2));

            this.shape.onValueChanged.emit(this.shape);
            this.text.onValueChanged.emit(this.text);
        }
        
        vec2 estimateSizeNeeded()
        {
            return this.text.value.screenSize;
        }

        void onUpdateImpl(InputManager input, Duration dt)
        {
            auto thisRect = this.shape.value.area;
            if(thisRect.contains(input.mousePosition)) // If the mouse is hovered over
            {
                if(input.isMouseButtonDown(MouseButton.Left) && !this._clickLock)
                {
                    this._clickLock = true;
                    this.shape.value.colour = this.baseColour.value.darken(0.5);

                    this.onClick.emit(this);
                }
                else
                    this.shape.value.colour = this.baseColour.value.darken(0.25);

                if(!input.isMouseButtonDown(MouseButton.Left))
                    this._clickLock = false;
            }
            else
            { // Not hovered, nor clicked, so set the colour to the default.
                this._clickLock = true;
                this.shape.value.colour = this.baseColour.value;
            }
        }

        void onRenderImpl(Renderer renderer)
        {
            renderer.drawRectShape(this.shape.value);
            renderer.drawText(this.text.value);
        }
    }
}

@UsesBinding!(RectangleShapeBinding, BasicTextBox.shape)
class BasicTextBox : UITextInputBase
{
    public
    {
        Property!RectangleShape shape;
    }

    this()
    {
        this.shape                    = new Property!RectangleShape(new RectangleShape(RectangleF(0, 0, 0, 0)));
        this.shape.value.borderSize   = 1;
        this.shape.value.borderColour = Colour.black;
        this.shape.value.colour       = Colour.white;
    }

    public override
    {
        void arrange(RectangleF rect)
        {
            this.shape.value.position       = rect.position;
            this.shape.value.size           = rect.size;
            super.textObject.value.position = rect.position + vec2(2, 2);
            super.textArea                  = rect.size;
        }

        void onUpdateImpl(InputManager input, Duration dt)
        {
            if(input.wasMouseButtonTapped(MouseButton.Left))
                super.isActive = this.shape.value.area.contains(input.mousePosition);
                
            super.onUpdateImpl(input, dt);
        }

        void onRenderImpl(Renderer renderer)
        {
            renderer.drawRectShape(this.shape.value);
            super.onRenderImpl(renderer);
        }
    }
}

@UsesBinding!(TextBinding, BasicLabel.text)
class BasicLabel : UIBase
{
    public
    {
        Property!Text text;
    }

    this()
    {
        this.text = new Property!Text(new Text(UIResources.defaultFont, "", vec2(0), 14, Colour.black));
    }

    public override
    {
        void arrange(RectangleF rect)
        {
            this.text.value.position = rect.position;
        }

        vec2 estimateSizeNeeded()
        {
            return this.text.value.screenSize;
        }

        void onUpdateImpl(InputManager input, Duration dt){}
        void onRenderImpl(Renderer renderer)
        {
            renderer.drawText(this.text.value);
        }
    }
}