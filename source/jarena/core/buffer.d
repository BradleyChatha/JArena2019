/++
 + 
 + ++/
module jarena.core.buffer;

private
{
    import std.traits : isType;
}

/++
 + A type that specialises in acting like a normal built-in D array, with the benefit
 + of that it will attempt to always reuse memory.
 + ++/
final class Buffer(T)
if(isType!T)
{
    private
    {
        T[] _buffer; // All the memory that this buffer has allocated
        T[] _slice;  // A *Slice* to the _buffer. This should *never* be appended to.
    }

    public final
    {
        @safe
        this(size_t initialCapacity = 128)
        {
            this._buffer.length = initialCapacity;
        }

        void opOpAssign(string op)(T value)
        if(op == "~")
        {
            this.length = this.length + 1;
            this._slice[$-1] = value;
        }

        void opOpAssign(string op)(T[] values)
        if(op == "~")
        {
            this.length = this.length + values.length;
            this[$-values.length..$] = values[0..$];
        }

        @safe @nogc
        ref inout(T) opIndex(size_t index) nothrow inout
        {
            return this._slice[index];
        }

        @safe @nogc
        inout(T[]) opSlice(size_t i1, size_t i2) nothrow inout
        {
            return this._slice[i1..i2];
        }

        @safe @nogc
        void opIndexAssign(T value, size_t index) nothrow
        {
            this[index] = value;
        }

        @safe @nogc
        void opSliceAssign(T value, size_t i1, size_t i2) nothrow
        {
            this._slice[i1..i2] = value;
        }

        @safe @nogc
        void opSliceAssign(T[] values, size_t i1, size_t i2) nothrow
        {
            this._slice[i1..i2] = values[0..$];
        }

        @safe @nogc
        size_t opDollar() nothrow const
        {
            return this._slice.length;
        }

        @property @safe @nogc
        size_t length() nothrow const
        {
            return this._slice.length;
        }

        @property @safe
        void length(size_t len) nothrow
        {
            if(len > this._buffer.length)
                this._buffer.length = (len * 2) + 1;

            this._slice = this._buffer[0..len];
        }
    }
}