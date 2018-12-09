module jarena.gameplay.gui.core;

private
{
    import std.traits, std.meta, std.range, std.math;
    import jarena.core, jarena.graphics, jarena.maths, jarena.data, jarena.gameplay;
}

/++
 + A signal is essentially an event callback.
 +
 + Slots (which are just delegates) can be `Signal.connect`ed to the signal, which
 + means when the signal has been `Signal.emit`ed, it will call all connected slots.
 + ++/
struct Signal(Params...)
if(allSatisfy!(isType, Params) || Params.length == 0)
{
    ///
    alias SlotT = void delegate(Params);

    private
    {
        SlotT[] _slots;
    }

    public
    {
        /++
         + Connects a slot to this signal.
         +
         + Params:
         +  slot = The slot to connect.
         +
         + Returns:
         +  `slot`.
         + ++/
        @safe
        SlotT connect(SlotT slot)
        {
            import std.algorithm : canFind;
            assert(slot !is null);

            if(this._slots.canFind(slot))
                return slot;

            this._slots ~= slot;
            return slot;
        }

        /++
         + Disconnects a previously connected slot.
         +
         + Params:
         +  slot = The slot to disconnect.
         +
         + Returns:
         +  Whether the slot was removed or not.
         + ++/
        @safe
        bool disconnect(SlotT slot)
        {
            import std.algorithm : countUntil;
            assert(slot !is null);
            
            auto index = this._slots.countUntil(slot);
            if(index == -1)
                return false;

            this._slots.removeAt(index);
            return true;
        }

        /++
         + Emits this signal (and params) to all connected slots.
         +
         + Params:
         +  params = The params to pass to the slots.
         + ++/
        void emit(Params params)
        {
            foreach(slot; this._slots)
                slot(params);
        }
    }
}
///
unittest
{
    Signal!(int, int) muhSignal;

    bool called = false;
    muhSignal.connect((a, b) => assert(a + b == 7));
    muhSignal.connect((a, b) => assert(a * b == 10));
    auto slot = muhSignal.connect((a, b) {called = true;});

    muhSignal.emit(5, 2);
    assert(called);

    muhSignal.disconnect(slot);
    called = false;
    muhSignal.emit(5, 2);
    assert(!called);
}

/++
 + A property is essentially a wrapper around any object/type/whatever.
 +
 + The upside about properties, is that it contains certain `Signal`s,
 + which can be used to monitor changes to a property. This is very useful
 + for GUI code.
 +
 + As a general rule, if you have to use `Property.value` to modify/access the
 + underlying data, don't expect the signals to be emitted. Emit them yourself
 + in cases such as these.
 + ++/
final class Property(T)
{
    alias ValueT = T;
    static if(isArray!T) alias ItemT = ElementEncodingType!T;

    private
    {
        T _value;
    }

    // ###########
    // # SIGNALS #
    // ###########
    public 
    {
        /++
         + For non-array types, this is emitted whenever the value of the
         + underlying data is changed. For example via opAssign, opOpAssign.
         +
         + For array types, this is emitted for the same reasons as non-array types,
         + as well as for when anything to do with the array's items are modified. For
         + example, opIndexAssign, opOpAssign!"~".
         + ++/
        Signal!(typeof(this)) onValueChanged;

        static if(isArray!T)
        {
            /// Emitted whenever an item is added to the array.
            Signal!(typeof(this), size_t, ItemT) onItemAdded;

            /// Emitted whenever an item is removed from the array.
            Signal!(typeof(this), size_t, ItemT) onItemRemoved;

            /// Emitted whenever an item in the array has been modified.
            Signal!(typeof(this), size_t, ItemT) onItemModified;
        }
    }
    
    ///
    this(T init = T.init)
    {
        this._value = init;
    }

    /// Returns: A reference to the underlying data.
    @property @safe @nogc
    ref T value() nothrow pure
    {
        return this._value;
    }

    /++
     + Emits:
     +  `onValueChanged`
     + ++/
    @property
    void value(T val)
    {
        this._value = val;
        this.onValueChanged.emit(this);
    }

    /++
     + Emits:
     +  `onItemRemoved`, `onValueChanged`
     +
     + Returns:
     +  Whether an element was removed or not.
     + ++/
    static if(isArray!T && !is(T == immutable) && !is(ElementEncodingType!T == immutable))
    bool removeAt(size_t index)
    {
        if(index >= this.length || this.length == 0)
            return false;

        auto value = this._value[index];

        if(index != this.length - 1)
        {
            foreach(i; index..this.length - 1)
                this._value[i] = this._value[i+1];
        }
        this._value.length -= 1;

        this.onItemRemoved.emit(this, index, value);
        this.onValueChanged.emit(this);
        return true;
    }

    // #############
    // # OPERATORS #
    // #############
    public
    {
        /// Emits: `onValueChanged`
        typeof(this) opUnary(string op)()
        {
            mixin(op~"this._value;");
            this.onValueChanged.emit(this);
            return this;
        }

        ///
        auto opCast(T2)()
        {
            return cast(T2)this._value;
        }

        ///
        auto opBinary(string op, T2)(T2 rhs)
        if(op != "~")
        {
            return mixin("this._value "~op~" rhs");
        }

        /// Emits: `onValueChanged`
        void opAssign(T2)(T2 rhs)
        if(!is(T2 == typeof(this)))
        {
            this._value = rhs;
            this.onValueChanged.emit(this);
        }

        /// Emits: `onValueChanged`
        void opOpAssign(string op, T2)(T2 rhs)
        if(op != "~")
        {
            mixin("this._value "~op~"= rhs;");
            this.onValueChanged.emit(this);
        }

        static if(isArray!T)
        {
            ///
            auto opDollar() { return this._value.length; }

            ///
            alias length = opDollar;

            /// Emits: `onValueChanged`, `onItemAdded`
            typeof(this) opOpAssign(string op : "~", V : ItemT)(V rhs)
            {
                this._value ~= rhs;
                this.onItemAdded.emit(this, this._value.length - 1, rhs);
                this.onValueChanged.emit(this);

                return this;
            }

            /// Emits: `onValueChanged`, `onItemAdded` (for each element in `rhs`)
            typeof(this) opOpAssign(string op : "~", VA)(VA rhs)
            if(isArray!VA && is(ElementEncodingType!VA : ItemT))
            {
                auto oldLength = this._value.length;
                this._value ~= rhs;

                foreach(i, v; rhs)
                    this.onItemAdded.emit(this, oldLength + i, v);

                this.onValueChanged.emit(this);
                return this;
            }

            ///
            ref auto opIndex(size_t i)
            {
                return this._value[i];
            }

            /// Emits: `onValueChanged`, `onItemModified`
            void opIndexAssign(V : ItemT)(V value, size_t i)
            {
                this._value[i] = value;
                this.onItemModified.emit(this, i, value);
                this.onValueChanged.emit(this);
            }

            // void opIndexAssign(V : ItemT)(V value, size_t[2] slice)
            // {
            //     auto dataSlice = this._value[slice[0]..slice[1]];
            //     foreach(i, ref val; dataSlice)
            //     {
            //         val = value;
            //         this.onItemModified.emit(this, slice[0] + i, value);
            //     }
            //     this.onValueChanged.emit(this);
            // }

            ///
            @safe @nogc
            size_t[2] opSlice(size_t i, size_t i2) nothrow pure
            {
                return [i, i2];
            }
        }
    }
}
///
unittest
{
    import fluent.asserts;

    Property!int prop = new Property!int();
    int sum = 0;

    prop.onValueChanged.connect((i) {sum += i.value;});

    prop += 200;
    sum.should.equal(200);

    prop -= 50;
    sum.should.equal(350).because("The new value of the property gets *added* into sum, not taken away from it.");

    prop = 20;
    sum.should.equal(370);

    (prop + 80).should.equal(100);
    
    ++prop;
    sum.should.equal(391);

    (cast(short)prop).should.equal(cast(short)21);
}
///
unittest
{
    import fluent.asserts;

    auto prop = new Property!(char[]);
    char lastAdded;
    size_t lastAddedIndex;
    char lastModifiedValue;
    size_t lastModifiedIndex;

    prop.onItemAdded.connect((p, i, v) { p.should.equal(prop); lastAdded = v; lastAddedIndex = i; });
    prop.onItemModified.connect((p, i, v) { p.should.equal(prop); lastModifiedValue = v; lastModifiedIndex = i; });

    prop ~= 'H';
    lastAdded.should.equal('H');
    lastAddedIndex.should.equal(0);
    prop.value.should.equal("H");

    prop ~= "ello world!";
    lastAdded.should.equal('!');
    lastAddedIndex.should.equal(11);
    prop.value.should.equal("Hello world!");

    prop[2].should.equal('l');

    prop[2] = 'y';
    lastModifiedValue.should.equal('y');
    lastModifiedIndex.should.equal(2);
    prop.value.should.equal("Heylo world!");

    prop.removeAt(0);
    prop.value.should.equal("eylo world!");
}

/++
 + Contains static resources for UI elements.
 + ++/
static final class UIResources
{
    // #############
    // # CONSTANTS #
    // #############
    public static
    {
        ///
        const DEFAULT_FONT_PATH  = "fonts/allerta_medium.otf";

        ///
        const DEFAULT_FONT_BYTES = cast(immutable(ubyte[]))import(DEFAULT_FONT_PATH);
    }

    // #############
    // # VARIABLES #
    // #############
    public static
    {
        /// The default font controls should use.
        Font defaultFont;
    }

    // #############
    // # FUNCTIONS #
    // #############
    public static
    {
        ///
        void setup()
        {
            defaultFont = new Font(DEFAULT_FONT_BYTES);
        }
    }
}

/// Specifies the alignment for an element on the X-axis
enum HorizontalAlignment
{
    /// Aligned to the left
    Left,

    /// Aligned in the center
    Center,

    /// Aligned to the right
    Right,

    /// Stretches to fill the entire area
    Stretch
}

/// Specifies the alignment for an element on the Y-axis
enum VerticalAlignment
{
    /// Aligned to the top
    Top,

    /// Aligned in the center
    Center,

    /// Aligned to the bottom
    Bottom,

    /// Stretches to fill the entire area
    Stretch
}

/++
 + The base class for all UI elements.
 +
 + Please get yourself acquianted with with `Signal`s, `Property`s, and the `DataBinder` system.
 + ++/
@UsesBinding!UIBaseBinding
abstract class UIBase
{
    private
    {
        RectangleF _areaArranged;
        RectangleF _areaUsed;
    }

    // ########################
    // # PROPERTIES & SIGNALS #
    // ########################
    public
    {
        /++
         + The margin for the element.
         +
         + `margin.position` is an offset from the top-left corner of rectangle passed to
         + `UIBase.arrangeInRect`.
         +
         + `margin.size` is used to specify padding between this element and another.
         + ++/
        Property!RectangleF margin;
        
        ///
        Property!(UIBase[]) children;

        /// NOTE: `HorizontalAlignment.Stretch` only applies if the `size` is set to `float.nan`
        Property!HorizontalAlignment horizAlignment;

        /// NOTE: `VerticalAlignment.Stretch` only applies if the `size` is set to `float.nan`
        Property!VerticalAlignment vertAlignment;

        ///
        Property!vec2 size;

        ///
        Property!string name;

        ///
        Property!bool isVisible;

        /// An object given by user code for whatever reasons they desire.
        Object tag;

        /// Parents should connect to this signal so the child can inform the parent that it's
        /// layout needs to be updated.
        Signal!() onInvalidate;
    }

    ///
    this()
    {
        this.isVisible      = new Property!bool(true);
        this.margin         = new Property!RectangleF(RectangleF(0, 0, 0, 0));
        this.children       = new Property!(UIBase[])([]);
        this.horizAlignment = new Property!HorizontalAlignment(HorizontalAlignment.Left);
        this.vertAlignment  = new Property!VerticalAlignment(VerticalAlignment.Top);
        this.size           = new Property!vec2(vec2(float.nan));
        this.name           = new Property!string(null);
        this._areaArranged  = RectangleF(0, 0, 0, 0);
        this._areaUsed      = RectangleF(0, 0, 0, 0);
    }

    public final
    {
        /++
         + Determines the final size for the element (using it's current information).
         +
         + Notes:
         +  This value is passed to `UIBase.arrange` when `UIBase.arrangeInRect` is used.
         +
         + Algorithm:
         +  This applies to both axes, but the X-axis will be used for this explanation.
         +
         +  Get the estimated width (X-axis) from `UIBase.estimageSizeNeeded`.
         +
         +  If `UIBase.size.x` is `float.nan` and `UIBase.horizAlignment` is `HorizontalAlignment.Stretch`,
         +  then the final width will be `avaliableSize.x`.
         +
         +  If `UIBase.size.x` is `float.nan`, and `UIBase.horizAlignment` isn't `Stretch`, then
         +  the final width is the estimated width.
         +
         +  Otherwise, the final width is `UIBase.size.x`.
         +
         + Params:
         +  avaliableSize = How much space is avaliable to the element.
         +
         + Returns:
         +  The size this element will be using up.
         + ++/
        vec2 getFinalSize(vec2 avaliableSize)
        {
            auto estimate = this.estimateSizeNeeded();
            if(this.size.value.x.isNaN)
                estimate.x = (this.horizAlignment.value == HorizontalAlignment.Stretch) ? avaliableSize.x : estimate.x;
            else
                estimate.x = this.size.value.x;

            if(this.size.value.y.isNaN)
                estimate.y = (this.vertAlignment.value == VerticalAlignment.Stretch) ? avaliableSize.y : estimate.y;
            else
                estimate.y = this.size.value.y;

            return estimate;
        }

        /++
         + Calculates a position and size for `UIBase.arrange`, based on the given information.
         +
         + Notes:
         +  This function automatically applies the margin, and both alignments.
         +
         + Params:
         +  rect = The rectangle to arrange the element in.
         + 
         + Returns:
         +  The final area that will be used by the element, including padding and margin.
         + ++/
        RectangleF arrangeInRect(RectangleF rect)
        {
            auto pos  = rect.position;
            auto size = this.getFinalSize(rect.size);

            final switch(this.horizAlignment.value) with(HorizontalAlignment)
            {
                case Stretch:
                case Left:
                    break;

                case Center:
                    pos.x = rect.position.x + ((rect.topRight.x - rect.topLeft.x) / 2) - (size.x / 2);
                    break;

                case Right:
                    pos.x = rect.topRight.x - size.x;
                    break;
            }

            final switch(this.vertAlignment.value) with(VerticalAlignment)
            {
                case Stretch:
                case Top:
                    break;

                case Center:
                    pos.y = rect.position.y + ((rect.botRight.y - rect.topRight.y) / 2) - (size.y / 2);
                    break;

                case Bottom:
                    pos.y = rect.botRight.y - size.y;
                    break;
            }

            pos += this.margin.value.position;
            this._areaArranged = RectangleF(pos, size);
            this.arrange(this._areaArranged);
            
            this._areaUsed.position = rect.position;
            this._areaUsed.size     = this.margin.value.position + this.margin.value.size + size;

            return this._areaUsed;
        }

        ///
        final UI addChild(UI : UIBase)(UI child)
        {
            assert(child !is null);
            this.children ~= child;

            return child;
        }

        ///
        final UI addChild(UI : UIBase)(string name, UI child)
        {
            assert(child !is null);
            child.name = name;
            this.children ~= child;

            return child;
        }

        ///
        final UI getChild(UI : UIBase)(size_t index) 
        {
            return cast(UI)this.children[index];
        }

        ///
        final UI getChild(UI : UIBase)(UI element)
        {
            import std.algorithm : filter;
            if(element is null)
                return null;

            auto results = this.children.value.filter!(c => c == element);
            return (results.empty) ? null : cast(UI)results.front;
        }

        ///
        final UI getChild(UI : UIBase, Str)(Str name)
        if(isSomeString!Str)
        {
            import std.algorithm : filter;
            if(name is null)
                return null;

            auto results = this.children.value.filter!(c => c.name.equal(name));
            return (results.empty) ? null : cast(UI)results.front;
        }

        ///
        final UI getDeepChild(UI : UIBase)(string name)
        {
            foreach(child; this.children.value)
            {
                if(child.name.value == name)
                    return cast(UI)child;
                
                auto result = child.getDeepChild!UI(name);
                if(result !is null)
                    return result;
            }

            return null;
        }

        ///
        final UI removeChild(UI : UIBase = UIBase)(size_t index)
        {
            auto child = this.getChild!UI(index);
            this.children.removeAt(index);
            return child;
        }

        ///
        final bool removeChild(UI : UIBase)(UI child)
        {
            import std.algorithm : countUntil;

            auto index = this.children.value.countUntil(child);
            if(index == -1)
                return false;

            this.children.removeAt(index);
            return true;
        }

        ///
        void onUpdate(InputManager input, Duration dt)
        {
            if(this.isVisible.value)
                this.onUpdateImpl(input, dt);
        }

        ///
        void onRender(Renderer renderer)
        {
            if(this.isVisible.value)
                this.onRenderImpl(renderer);
        }

        /++
         + Notes:
         +  This will generally hold the actual position & size of the control.
         +
         +  This defaults to (0,0,0,0) if the control hasn't been arranged yet.
         +
         + Returns:
         +  The last area passed to the `UIBase.arrange` function.
         + ++/
        @property @safe @nogc
        const(RectangleF) areaArranged() nothrow const
        {
            return this._areaArranged;
        }

        /++
         + Notes:
         +  This defaults to (0,0,0,0) if the control hasn't been arranged yet.
         +
         +  This differs from `areaArranged` in that this also takes into account padding,
         +  alignment, and margins.
         +
         +  This is generally only useful for containers, so they can properly space things out.
         +
         +  This is also the value returned by the latest `arrangeInRect`.
         +
         + Returns:
         +  The last area calulated by `UIBase.arrangeInRect`.
         + ++/
        @property @safe @nogc
        const(RectangleF) areaUsed() nothrow const
        {
            return this._areaUsed;
        }

        /++
         + Returns:
         +  This object's `tag` casted to `T`, or `null` if either the tag is null or the cast fails.
         + ++/
        @property
        T tagAs(T)()
        {
            return cast(T)this.tag;
        }
    }

    abstract
    {
        /++
         + Instructs the element to arrange itself within the given rect.
         +
         + Params:
         +  rect = The rectangle to arrange in.
         + ++/
        void arrange(RectangleF rect);
        
        /++
         + Estimates the size needed by this control.
         +
         + See_Also:
         +  `UIBase.getFinalSize`
         + ++/
        vec2 estimateSizeNeeded();

        ///
        protected void onUpdateImpl(InputManager input, Duration dt);

        ///
        protected void onRenderImpl(Renderer renderer);
    }
}

///
@UsesBinding!(RectangleShapeBinding, TestControl.shape)
final class TestControl : UIBase
{
    RectangleShape shape;

    this()
    {
        this.shape = new RectangleShape();
        this.shape.colour = Colour.red;
    }

    this(vec2 size, Colour col)
    {
        this.shape = new RectangleShape();
        this.shape.colour = col;
        this.size = size;
    }

    public override
    {
        void arrange(RectangleF rect)
        {
            this.shape.position = rect.position;
            this.shape.size     = rect.size;
        }

        vec2 estimateSizeNeeded()
        {
            return this.shape.size + this.shape.borderSize;
        }

        void onUpdateImpl(InputManager input, Duration dt)
        {
        }
        
        void onRenderImpl(Renderer renderer)
        {
            renderer.drawRectShape(this.shape);
        }
    }
}

/++
 + The basis for a control that can take keyboard input and display it on screen.
 +
 + Implementors:
 +  All you need to do is implement the `arrange` function, make sure to arrange the `textObject` property as well.
 +
 +  Also you'll need to set `isActive` according to the usage of your control.
 +
 + Notes:
 +  For text capturing to work, both `UITextInputBase.isActive` and `UITextInputBase.listenForText` need to be true.
 +
 +  When `UITextInputBase.textArea` isn't set to `vec2(float.infinity)`, it will make sure that it's text
 +  cannot grow in size outside of this area. Again, useful for things such as textboxes.
 +
 +  This class handles drawing the inputted text.
 +
 + Limitations:
 +  Currently, only a single line of text is supported.
 +
 +  Support for most control codes is either unsupported or undefined.
 +
 +  Currently, only the X-axis for `UITextInputBase.textArea` is used.
 + ++/
@UsesBinding!(TextBinding, UITextInputBase.textObject)
@UsesBinding!(TextBinding, UITextInputBase.cursorObject)
abstract class UITextInputBase : UIBase
{
    enum BLINK_TIMER = 500; // ms

    private
    {
        vec2     _area;
        Duration _blinkTimer;
        bool     _displayCursor;
        char[]   _text;

        void appendText(const char[] text)
        {
            foreach(ch; text)
            {
                if(ch == '\n')
                    continue; // No support for new lines yet.

                // Add the character, and see if it can fit.
                this._text ~= ch;
                this.textObject.value.text = this._text;                
                if(this.textObject.value.getRectForChar(this._text.length - 1).topRight.x
                 > this._area.x + this.areaArranged.position.x)
                {
                    this._text.length -= 1;
                    this.textObject.value.text = this._text;
                }
            }
        }
    }

    public
    {
        @Name("text")
        Property!Text textObject;

        @Name("cursor")
        Property!Text cursorObject;
        Property!bool isActive;
    }

    public
    {
        this()
        {
            this._area        = vec2(float.infinity);
            this.textObject   = new Property!Text(new Text(UIResources.defaultFont, "",  vec2(0), 14, Colour.black));
            this.cursorObject = new Property!Text(new Text(UIResources.defaultFont, "|", vec2(0), 14, Colour.black));
            this.isActive     = new Property!bool(false);
            this._blinkTimer  = -1.msecs;
        }
    }

    protected
    {
        @property @safe @nogc
        ref inout(vec2) textArea() nothrow inout
        {
            return this._area;
        }
    }

    override
    { 
        vec2 estimateSizeNeeded()
        {
            return this.textObject.value.screenSize;
        }

        public void onUpdateImpl(InputManager input, Duration deltaTime)
        {
            if(!this.isActive.value || !input.listenForText)
                return;

            // Blink the cursor
            this._blinkTimer -= deltaTime;
            if(this._blinkTimer.asSeconds <= 0)
            {
                this._displayCursor = !this._displayCursor;
                this._blinkTimer += BLINK_TIMER.msecs;
            }

            // Removes the last character.
            void doBackspace() scope
            {
                if(this._text.length > 0)
                {
                    this._text.length -= 1;
                    this.textObject.value.text = this._text;
                }
            }

            // Handle special input keys.
            if(input.wasKeyTapped(Scancode.BACKSPACE))
                doBackspace();

            this.appendText(input.textInput);

            // Update the cursor's position.
            if(this._text.length == 0)
                this.cursorObject.value.position = this.margin.value.position;
            else
            {
                auto rect = this.textObject.value.getRectForChar(this._text.length - 1);
                this.cursorObject.value.position = vec2(rect.position.x + rect.size.x, rect.position.y);
            }
        }

        public void onRenderImpl(Renderer renderer)
        {
            renderer.drawText(this.textObject.value);

            if(this.isActive.value && this._displayCursor)
                renderer.drawText(this.cursorObject.value);
        }
    }
}