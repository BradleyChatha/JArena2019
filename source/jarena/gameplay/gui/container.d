module jarena.gameplay.gui.container;

private
{
    import std.typecons, std.math;
    import jarena.core, jarena.maths, jarena.graphics, jarena.gameplay.gui;
}

@DataBinding
struct StackContainerBinding
{
    @ConverterBindingFor!(StackContainer.Direction, string)("direction", &DataConverters.stringToEnum!(StackContainer.Direction))
    Nullable!string direction;

    @ConverterBindingFor!(StackContainer.AutoSize, string)("autoSize", &DataConverters.stringToEnum!(StackContainer.AutoSize))
    Nullable!string autoSize;
}

@UsesBinding!(RectangleShapeBinding, StackContainer.background)
@UsesBinding!StackContainerBinding
final class StackContainer : UIBase
{
    alias AutoSize = Flag!"autoSize";

    enum Direction
    {
        Horizontal,
        Vertical
    }

    private
    {
        RectangleShape _background;
        RectangleF     _clip;

        void rearrangeChildren(bool doResize = true)
        {
            vec2 largest  = vec2(0);
            vec2 cursor   = this._clip.position;
            vec2 sizeLeft = this._clip.size;
            foreach(child; super.children.value)
            {
                RectangleF areaUsed;
                child.arrangeInRect(RectangleF(cursor, sizeLeft), areaUsed);
                
                if(this.direction.value == Direction.Vertical)
                {
                    sizeLeft.y = sizeLeft.y - areaUsed.size.y;
                    cursor.y   = cursor.y + areaUsed.size.y;
                }
                else
                {
                    sizeLeft.x = sizeLeft.x - areaUsed.size.x;
                    cursor.x   = cursor.x + areaUsed.size.x;
                }

                auto tempLargest = vec2(areaUsed.topRight.x, areaUsed.botRight.y);
                if(areaUsed.position.x < this._clip.position.x)
                    tempLargest.x = tempLargest.x + (this._clip.position.x - areaUsed.position.x);

                if(tempLargest.x > largest.x)
                    largest.x = fmax(tempLargest.x, this._clip.position.x) - fmin(tempLargest.x, this._clip.position.x);
                if(tempLargest.y > largest.y)
                    largest.y = fmax(tempLargest.y, this._clip.position.y) - fmin(tempLargest.y, this._clip.position.y);
            }

            if(this.autoSize.value && doResize)
            {
                this.size            = largest;
                this._clip.size      = largest;
                this.background.size = largest;
                this.rearrangeChildren(false);
            }
        }

        void onChildMarginChanged(Property!RectangleF margin)
        {
            this.rearrangeChildren();
        }

        void onChildSizeChanged(Property!vec2 size)
        {
            this.rearrangeChildren();
        }

        void onChildInvalidated()
        {
            super.onInvalidate.emit();
            this.rearrangeChildren();
        }
    }

    public
    {
        Property!Direction direction;
        Property!AutoSize  autoSize;
    }

    this()
    {
        this.autoSize = new Property!AutoSize(AutoSize.no);

        this.autoSize.onValueChanged.connect(_ => this.rearrangeChildren());
        super.children.onValueChanged.connect(_ => this.rearrangeChildren());
        super.children.onItemAdded.connect((_, i, v)
        {
            v.onInvalidate.connect(&this.onChildInvalidated);
            v.margin.onValueChanged.connect(&this.onChildMarginChanged);
            v.size.onValueChanged.connect(&this.onChildSizeChanged);
        });
        super.children.onItemRemoved.connect((_, i, v)
        {
            v.onInvalidate.disconnect(&this.onChildInvalidated);
            v.margin.onValueChanged.disconnect(&this.onChildMarginChanged);
            v.size.onValueChanged.disconnect(&this.onChildSizeChanged);
        });

        this._background        = new RectangleShape();
        this._background.colour = Colour.transparent;
        this.direction          = new Property!Direction();
        this._clip              = RectangleF(0, 0, 0, 0);
    }

    @property @safe @nogc
    RectangleShape background() nothrow pure
    {
        return this._background;
    }

    public override
    {
        void arrange(RectangleF rect)
        {
            this._clip = rect;
            this.background.size = rect.size;
            this.background.position = rect.position;
            this.rearrangeChildren();
        }

        vec2 estimateSizeNeeded()
        {
            return this._clip.size;
        }
        
        void onUpdate(InputManager input, Duration dt)
        {
            foreach(child; this.children.value)
                child.onUpdate(input, dt);
        }

        void onRender(Renderer renderer)
        {
            auto oldClip = renderer.scissorRect;
            scope(exit) renderer.scissorRect = oldClip;
            renderer.scissorRect = RectangleI(
                cast(int)(this._clip.position.x - this.background.borderSize),
                cast(int)(this._clip.position.y - this.background.borderSize),
                cast(int)(this._clip.size.x     + (this.background.borderSize * 2)),
                cast(int)(this._clip.size.y     + (this.background.borderSize * 2))
            );

            renderer.drawRectShape(this._background);
            foreach(child; this.children.value)
                child.onRender(renderer);
        }
    }
}

class FreeformContainer : UIBase
{
    private
    {
        bool _arrangeLock = false;
        void doArrange()
        {
            if(_arrangeLock)
                return;
            foreach(i, v; this.children.value)
            {
                _arrangeLock = true;
				scope(exit) _arrangeLock = false;
                RectangleF f;
                v.arrangeInRect(RectangleF(
                    this.actualPosition, 
                    (this.size.value.isNaN) ? vec2(Systems.window.size) : this.size.value), 
                    f
                );
            }
        }

        void onChildMarginChanged(Property!RectangleF margin)
        {
            this.doArrange();
        }

        void onChildSizeChanged(Property!vec2 size)
        {
            this.doArrange();
        }

        void onChildInvalidated()
        {
            this.onInvalidate.emit();
            this.doArrange();
        }
    }

    this()
    {
        super.children.onItemAdded.connect((_, i, v)
        {
            v.onInvalidate.connect(&this.onChildInvalidated);
            v.margin.onValueChanged.connect(&this.onChildMarginChanged);
            v.size.onValueChanged.connect(&this.onChildSizeChanged);
            this.doArrange();
        });
        super.children.onItemRemoved.connect((_, i, v)
        { 
            v.onInvalidate.disconnect(&this.onChildInvalidated);
            v.margin.onValueChanged.disconnect(&this.onChildMarginChanged);
            v.size.onValueChanged.disconnect(&this.onChildSizeChanged);
            this.doArrange();
        });
    }

    public override
    {
        void arrange(RectangleF rect)
        {
            this.doArrange();
        }

        vec2 estimateSizeNeeded()
        {
            return vec2(5);
        }
        
        void onUpdate(InputManager input, Duration dt)
        {
            foreach(child; this.children.value)
                child.onUpdate(input, dt);
        }

        void onRender(Renderer renderer)
        {
            foreach(child; this.children.value)
                child.onRender(renderer);
        }
    }
}

class ViewContainer : FreeformContainer
{
}