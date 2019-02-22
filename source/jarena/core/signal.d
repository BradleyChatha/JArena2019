module jarena.core.signal;

private
{
    import std.traits, std.range, std.meta;
    import jarena.core;
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
    static if(isDynamicArray!T && !is(T == immutable) && !is(ElementEncodingType!T == immutable))
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