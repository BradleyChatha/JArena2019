module jarena.gameplay.gui.core;

private
{
    import std.traits, std.meta, std.range, std.math, std.experimental.logger;
    import jarena.core, jarena.graphics, jarena.maths, jarena.data, jarena.gameplay;
}

//version = PROPERTY_DEBUG;

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

        /// NOTE: `HorizontalAlignment.Stretch` only applies if the `size.x` is set to `float.nan`
        Property!HorizontalAlignment horizAlignment;

        /// NOTE: `VerticalAlignment.Stretch` only applies if the `size.y` is set to `float.nan`
        Property!VerticalAlignment vertAlignment;

        ///
        Property!vec2 size;

        ///
        Property!string name;

        ///
        Property!bool isVisible;

        /// Properties that are added at runtime, via `addProperty`.
        private Object[string] properties; // `Property` doesn't support hashmaps :( ... yet!
        Signal!(string, Object) propertiesOnAdd; /// Work around.

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
        Property!T addProperty(T)(string name, T value)
        {
            version(PROPERTY_DEBUG) tracef("Adding property '%s' of type %s with value of %s.", name, T.stringof, value);

            enforceAndLogf(!this.hasProperty(name), "The property '%s' already exists.", name);
            auto prop = new Property!T(value);
            this.properties[name] = prop;

            return prop;
        }

        ///
        void removeProperty(string name)
        {
            version(PROPERTY_DEBUG) tracef("Removing property '%s'.", name);
            this.properties.remove(name);
        }
        
        ///
        bool hasProperty(string name)
        {
            return (name in this.properties) !is null;
        }

        ///
        Property!T getProperty(T)(string name, lazy T default_ = T.init)
        {
            auto ptr = (name in this.properties);
            
            if(ptr is null)
                return new Property!T(default_);

            auto obj = cast(Property!T)(*ptr);
            enforceAndLogf(
                obj !is null, 
                "Could not cast property '%s' of type '%s' to type '%s'",
                name,
                ptr.classinfo,
                typeid(T)
            );

            return obj;
        }

        ///
        bool testPropertyType(T)(string name)
        {
            auto ptr = (name in this.properties);
            return (ptr is null) ? false : (cast(Property!T)(*ptr)) !is null;
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