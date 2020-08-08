module jarena.gameplay.gui.container;

private
{
    import std.typecons, std.math;
    import jarena.core, jarena.maths, jarena.graphics, jarena.gameplay.gui;
    import jaster.serialise;
}

@DataBinding
struct StackContainerBinding
{
    @BindingFor("direction")
    Nullable!(StackContainer.Direction) direction;

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
        bool           _arrangeLock;

        void rearrangeChildren(bool doResize = true)
        {
            if(this._arrangeLock)
                return;
            this._arrangeLock = true;
            scope(exit) this._arrangeLock = false;

            vec2 largest  = vec2(0);
            vec2 cursor   = this._clip.position;
            vec2 sizeLeft = this._clip.size;
            foreach(child; super.children.value)
            {
                if(!child.isVisible.value)
                    continue;

                auto areaUsed = child.arrangeInRect(RectangleF(cursor, sizeLeft));
                
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

        void onChildVisibleChanged(Property!bool)
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
            v.isVisible.onValueChanged.connect(&this.onChildVisibleChanged);
        });
        super.children.onItemRemoved.connect((_, i, v)
        {
            v.onInvalidate.disconnect(&this.onChildInvalidated);
            v.margin.onValueChanged.disconnect(&this.onChildMarginChanged);
            v.size.onValueChanged.disconnect(&this.onChildSizeChanged);
            v.isVisible.onValueChanged.disconnect(&this.onChildVisibleChanged);
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
            return this._clip.size + (this.background.borderSize * 2);
        }
        
        void onUpdateImpl(InputManager input, Duration dt)
        {
            foreach(child; this.children.value)
                child.onUpdate(input, dt);
        }

        void onRenderImpl(Renderer renderer)
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
                v.arrangeInRect(RectangleF(
                    this.areaArranged.position, 
                    (this.size.value.isNaN) ? vec2(Systems.window.size) : this.size.value), 
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
        
        void onUpdateImpl(InputManager input, Duration dt)
        {
            foreach(child; this.children.value)
                child.onUpdate(input, dt);
        }

        void onRenderImpl(Renderer renderer)
        {
            foreach(child; this.children.value)
                child.onRender(renderer);
        }
    }
}

class ViewContainer : FreeformContainer
{
    // In the future, views may get special functionality, which is why this class exists.
}

@DataBinding
struct GridContainerBinding
{
    @Setting(Serialiser.Settings.ArrayAsObject)
    @BindingFor("rows")
    GridContainer.Definition[] rows;

    @Setting(Serialiser.Settings.ArrayAsObject)
    @BindingFor("columns")
    GridContainer.Definition[] columns;

    @BindingFor("showDebugGrid")
    Nullable!bool showDebugGrid;
}

@UsesBinding!GridContainerBinding
@ChildProperty!("GridSlot", VectorProperty!(uint, 2))
@ChildProperty!("GridSlotSpan", VectorProperty!(uint, 2))
class GridContainer : UIBase
{
    static struct Definition
    {
        enum Type
        {
            Pixels,
            Star
        }

        Type  type;
        float amount;
    }

    public
    {
        Property!(Definition[]) rows;
        Property!(Definition[]) columns;
        Property!(RectangleF[]) slots;
        Property!bool           showDebugGrid;
    }

    this()
    {
        super.children.onValueChanged.connect(_ => this.rearrangeChildren());
        super.children.onItemAdded.connect((_, i, v)
        {
            v.onInvalidate.connect(&this.onChildInvalidated);
            v.margin.onValueChanged.connect(&this.onChildMarginChanged);
            v.size.onValueChanged.connect(&this.onChildSizeChanged);
            v.isVisible.onValueChanged.connect(&this.onChildVisibleChanged);
        });
        super.children.onItemRemoved.connect((_, i, v)
        {
            v.onInvalidate.disconnect(&this.onChildInvalidated);
            v.margin.onValueChanged.disconnect(&this.onChildMarginChanged);
            v.size.onValueChanged.disconnect(&this.onChildSizeChanged);
            v.isVisible.onValueChanged.disconnect(&this.onChildVisibleChanged);
        });

        this.rows          = new Property!(Definition[])();
        this.columns       = new Property!(Definition[]);
        this.slots         = new Property!(RectangleF[]);
        this.showDebugGrid = new Property!bool;

        this.rows.onValueChanged.connect(_ => this.rearrangeSlots());
        this.columns.onValueChanged.connect(_ => this.rearrangeSlots());
    }

    private
    {
        void onChildMarginChanged(Property!RectangleF margin)
        {
            this.rearrangeChildren();
        }

        void onChildSizeChanged(Property!vec2 size)
        {
            this.rearrangeChildren();
        }

        void onChildVisibleChanged(Property!bool)
        {
            this.rearrangeChildren();
        }

        void onChildInvalidated()
        {
            super.onInvalidate.emit();
            this.rearrangeChildren();
        }

        void rearrangeSlots()
        {
            this.arrangeSlots(this.areaArranged);
        }

        bool _lock = false;
        void rearrangeChildren()
        {
            if(_lock)
                return;
            _lock = true;
            scope(exit) _lock = false;

            foreach(child; this.children.value)
            {
                if(!child.isVisible.value)
                    continue;

                auto slot = GridContainer.getSlot(child);
                auto span = GridContainer.getSlotSpan(child);
                enforceAndLogf(slot.x <= this.columns.length, "Column %s is out of bounds. Max = %s", this.columns.value.length);
                enforceAndLogf(slot.y <= this.rows.length, "Row %s is out of bounds. Max = %s", this.rows.value.length);

                auto start = ((this.columns.length + 1) * slot.y) + slot.x;
                auto rect = this.slots.value[start];
                foreach(i; 1..span.x)
                    rect.size.x = rect.size.x + this.slots.value[start+i].size.x;
                foreach(i; 1..span.y)
                    rect.size.y = rect.size.y + this.slots.value[start + ((this.columns.length + 1) * i)].size.y;

                child.arrangeInRect(rect);
            }
        }

        void arrangeSlots(RectangleF area)
        {
            import std.algorithm : filter;

            // First rows + 1 happens because there's always a single row.
            // Second rows + 1 happens to account for the first slot of each row always being there (regardless of what the columns are like).
            this.slots.value.length = ((this.rows.value.length + 1) * this.columns.value.length) + (this.rows.value.length + 1);

            if(this.slots.value.length == 0)
                return;

            auto colsPerRow = this.columns.value.length + 1;

            // TODO: Optimise this.
            //       There are intentionally more loops than there needs to be, just to keep the logic clear in my head
            //       while I work everything out.

            // See how much space the statically sized blocks take up.
            vec2 usedSize = vec2(0);
            foreach(col; this.columns.value.filter!(c => c.type == Definition.Type.Pixels))
                usedSize.x = usedSize.x + col.amount;

            foreach(row; this.rows.value.filter!(r => r.type == Definition.Type.Pixels))
                usedSize.y = usedSize.y + row.amount;

            // Calculate how many "dynamic" blocks there are, then determine how much space each block gets.
            vec2     sizeLeft = area.size - usedSize;
            int[][2] emptyBlocks;

            void doEmptyCalc(Property!(Definition[]) defs, size_t blockIndex)
            {
                bool inEmptyBlock;
                foreach(def; defs.value)
                {
                    if(def.type == Definition.Type.Star)
                    {
                        if(!inEmptyBlock)
                            emptyBlocks[blockIndex] ~= 0;

                        emptyBlocks[blockIndex][$-1]++;
                        inEmptyBlock = true;
                    }
                    else if(inEmptyBlock)
                        inEmptyBlock = false;
                }
            }
            doEmptyCalc(this.columns, 0);
            doEmptyCalc(this.rows,    1);

            // Then set the size and position of all the slots.
            vec2  sizePerEmptyBlock = sizeLeft / vec2(emptyBlocks[0].length, emptyBlocks[1].length);
            uvec2 currentEmptyBlock;
            vec2  previousPos = area.position;

            void doPosSizeCalc(Property!(Definition[]) defs, bool useX)
            {
                float getAxis(vec2 v)
                {
                    return (useX) ? v.x : v.y;
                }

                void setAxis(ref vec2 v, float amount)
                {
                    if(useX)
                        v.x = amount;
                    else
                        v.y = amount;
                }

                size_t getIndex(size_t i)
                {
                    return (useX) ? i : (colsPerRow * i);
                }

                for(auto i = 0; i < defs.value.length; i++)
                {
                    auto def = defs.value[i];
                    final switch(def.type) with(Definition.Type)
                    {
                        case Pixels:
                            setAxis(this.slots.value[getIndex(i)].position, getAxis(previousPos));
                            setAxis(this.slots.value[getIndex(i)].size,     def.amount);
                            setAxis(previousPos,                            getAxis(previousPos) + def.amount);
                            break;

                        case Star:
                            auto block = emptyBlocks[(useX) ? 0 : 1][(useX) ? currentEmptyBlock.x : currentEmptyBlock.y];
                            if(useX)
                                currentEmptyBlock.x = currentEmptyBlock.x + 1;
                            else
                                currentEmptyBlock.y = currentEmptyBlock.y + 1;

                            foreach(k; 0..block)
                            {
                                setAxis(this.slots.value[getIndex(i)].position, getAxis(previousPos));
                                setAxis(this.slots.value[getIndex(i)].size,     getAxis(sizePerEmptyBlock) / block);
                                setAxis(previousPos,                            getAxis(previousPos) + (getAxis(sizePerEmptyBlock) / block));
                                i++;
                            }

                            if(block > 0)
                                i--; // To counter the loop's i++
                            break;
                    }
                }
            }

            // Width + X pos.
            doPosSizeCalc(this.columns, true);
            doPosSizeCalc(this.rows,    false);

            // Copy the values onto the other rows, and set the last slots on each row to fill in the rest of the space.
            auto colSlots = this.slots.value[0..colsPerRow];            
            if(colSlots.length == 1)
                colSlots[0].size.x = area.size.x;
            else
            {
                colSlots[$-1].position.x = colSlots[$-2].topRight.x; 
                colSlots[$-1].size.x     = (area.topRight - colSlots[$-2].topRight).x;
            }
            foreach(i; 1..this.slots.value.length / colSlots.length)
            {
                foreach(k, ref rect; this.slots.value[i * colSlots.length..(i+1) * colSlots.length])
                {
                    rect.position.x = colSlots[k].position.x;
                    rect.size.x     = colSlots[k].size.x;
                }
            }

            // Same for the rows.          
            if(this.rows.value.length == 0)
                this.slots.value[0].size.y = area.size.y;
            else
            {
                auto lastRow = (colsPerRow * this.rows.value.length);
                auto prevRow = lastRow - colsPerRow;

                this.slots[lastRow].position.y = this.slots[prevRow].botLeft.y;
                this.slots[lastRow].size.y     = (area.botLeft.y - this.slots[prevRow].botLeft.y);
            }

            foreach(i, ref slot; this.slots.value)
            {
                auto row = (i / colsPerRow) * colsPerRow;

                slot.position.y = this.slots[row].position.y;
                slot.size.y     = this.slots[row].size.y;
            }

            // If we don't actually have any columns, just set their width to max
            if(this.columns.value.length == 0)
            {
                foreach(ref slot; this.slots.value)
                    slot.size.x = area.size.x;
            }

            // Same for rows
            if(this.rows.value.length == 0)
            {
                foreach(ref slot; this.slots.value)
                    slot.size.y = area.size.y;
            }
        }
    }
    
    public static
    {
        void setSlotSpan(UIBase ui, uvec2 slot)
        {
            assert(ui !is null);
            if(!ui.hasProperty("GridSlotSpan"))
                ui.addProperty!uvec2("GridSlotSpan", slot);
            else
                ui.getProperty!uvec2("GridSlotSpan").value = slot;
        }

        uvec2 getSlotSpan(UIBase ui)
        {
            return (ui.testPropertyType!uvec2("GridSlotSpan")) 
                    ? ui.getProperty!uvec2("GridSlotSpan").value
                    : uvec2(1);
        }

        void setSlot(UIBase ui, uvec2 slot)
        {
            assert(ui !is null);
            if(!ui.hasProperty("GridSlot"))
                ui.addProperty!uvec2("GridSlot", slot);
            else
                ui.getProperty!uvec2("GridSlot").value = slot;
        }

        uvec2 getSlot(UIBase ui)
        {
            return (ui.testPropertyType!uvec2("GridSlot")) 
                    ? ui.getProperty!uvec2("GridSlot").value
                    : uvec2(0);
        }
    }

    public override
    {
        void arrange(RectangleF rect)
        {
            this.arrangeSlots(rect);
            this.rearrangeChildren();
        }

        vec2 estimateSizeNeeded()
        {
            return vec2(0);
        }
        
        void onUpdateImpl(InputManager input, Duration dt)
        {
            foreach(child; this.children.value)
                child.onUpdate(input, dt);
        }

        void onRenderImpl(Renderer renderer)
        {
            if(this.showDebugGrid.value)
            {
                foreach(slot; this.slots.value)
                    renderer.drawRect(slot.position, slot.size, Colour.white, Colour.black, 1);
            }

            foreach(child; this.children.value)
                child.onRender(renderer);
        }
    }
}