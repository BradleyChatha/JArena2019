module jarena.data.serialisation.binary;

private
{
    import std.exception, std.traits, std.bitmanip, std.utf, std.algorithm, std.array, std.range;
    import jarena.core;
}

/++
 + A class used to easily create an array of bytes.
 +
 + This is useful for encoding data into a binary format.
 +
 + Notes:
 +  Functions are marked as either [Easy] or [Advanced].
 +
 +  [Easy] functions are designed to be easy to use, and should be fine
 +  for general cases.
 +
 +  [Advanced] functions are a bit less "automatic" or perform some other function,
 +  and are best used when the binary data needs to be a bit more customised.
 + ++/
final class BinaryStream
{
    private
    {
        Buffer!ubyte _data;
        size_t       _position;

        void resizeIfNeeded(size_t newPos)
        {
            if(newPos >= this.length)
                this._data.length = newPos;
        }
    }

    this(ubyte[] data = null)
    {
        this._data = new Buffer!ubyte();
        this._data ~= data;
    }

    // ###########
    // # READING #
    // ###########
    public
    {
        /++
         + [Advanced] Reads a certain amount of bytes.
         +
         + Notes:
         +  This is a slice into the underlying data instead of a copy.
         + ++/
        ubyte[] readBytes(size_t amount)
        {
            if(amount == 0)
                return null;

            enforce((this.position + amount) <= this.length, "Attempted to read past the end of the stream.");
            auto slice = this._data[this.position..this.position+amount];
            this._position += amount;

            return slice;
        }

        /++
         + [Advanced] Reads in a length of something in a compact format.
         + ++/
        size_t readLengthBytes()
        {
            auto info       = this.read!ubyte() & 0b1100_0000; // NOTE: This only works because numbers are in big-endian
            this._position -= 1;

            if(info == 0)
                return this.read!ubyte();
            else if(info == 0b0100_0000)
                return this.read!ushort() & 0b00111111_11111111;
            else if(info == 0b1000_0000)
                return this.read!uint() & 0b00111111_11111111_11111111_11111111;
            else
                throw new Exception("Length size info 0b1100_0000 is not used right now.");
        }

        /++
         + [Easy] Reads in a single numeric value.
         + ++/
        T read(T)()
        if(isNumeric!T)
        {
            auto bytes = this.readBytes(T.sizeof);
            return bigEndianToNative!T(cast(ubyte[T.sizeof])bytes[0..T.sizeof]);
        }

        /++
         + [Easy] Reads in an array of numeric values.
         + ++/
        T read(T)()
        if(isNumeric!(ElementType!T) && isDynamicArray!T)
        {
            auto length = this.readLengthBytes();
            T arr;
            foreach(i; 0..length)
                arr ~= this.read!(ElementType!T)();

            return arr;
        }

        /++
         + [Easy] Reads in a string.
         +
         + Notes:
         +  If the character type isn't immutable, then a slice to the underlying data is returned instead of
         +  a copy.
         +
         +  If it is immutable, then a `.idup` of the slice is returned.
         + ++/
        T read(T)()
        if(isSomeString!T)
        {
            auto length = this.readLengthBytes();
            auto slice  = this.readBytes(length);
            T    data;

            static if(is(ElementType!T == immutable))
                data = cast(T)slice.idup;
            else
                data = cast(T)slice;

            validate(data);
            return data;
        }
    }

    // ###########
    // # WRITING #
    // ###########
    public
    {
        /++
         + [Advanced] Writes out a series of bytes into the stream.
         +
         + Notes:
         +  $(B All) other write functions are based off of this function.
         +
         +  This function will grow the stream's size if needed.
         +
         +  Use this function if the [Easy] functions don't fit your use case.
         + ++/
        void writeBytes(scope ubyte[] data)
        {
            this.resizeIfNeeded(this.position + data.length);
            this._data[this.position..this.position+data.length] = data[];
            this._position += data.length;
        }

        /++
         + [Advanced] Writes out a length in a compact format.
         +
         + Details:
         +  This function aims to minimize the amount of bytes needed to write out the length of an array.
         +
         +  If the length is <= to 63, then a single byte is used.
         +
         +  If the length is <= to 16,383, then two bytes are used.
         +
         +  If the length is <= to 1,073,741,823, then four bytes are used.
         +
         +  In some cases it may be better to set a strict byte limit for an array, so this function may not be useful.
         +
         + Notes:
         +  Use this function if you need to write out the length of an array (outside of the [Easy] functions).
         +
         +  The last two bits are reserved for size info, so the max value of `length` is (2^30)-1, or 1,073,741,823
         + ++/
        void writeLengthBytes(size_t length)
        {
            // Last two bits are reserved for size info.
            // 00 = Length is one byte.
            // 01 = Length is two bytes.
            // 10 = Length is four bytes.
            enforce(length <= 0b00111111_11111111_11111111_11111111, "Length is too much");

            if(length <= 0b00111111) // Single byte
                this.write!ubyte(cast(ubyte)length);
            else if(length <= 0b00111111_11111111) // Two bytes
            {
                length |= 0b01000000_00000000;
                this.write!ushort(cast(ushort)length);
            }
            else // Four bytes
            {
                length |= 0b10000000_00000000_00000000_00000000;
                this.write!uint(cast(uint)length);
            }
        }

        /++
         + [Easy] Writes a single numeric value.
         + ++/
        void write(T)(T value)
        if(isNumeric!T)
        {
            auto bytes = value.nativeToBigEndian;
            this.writeBytes(bytes[]);
        }

        /++
         + [Easy] Writes an array of numeric values.
         + ++/
        void write(T)(T[] value)
        if(isNumeric!T)
        {
            this.writeLengthBytes(value.length);
            foreach(val; value)
                this.write!T(val);
        }

        /++
         + [Easy] Writes a string.
         + ++/
        void write(T)(T[] value)
        if(is(T : const(char)))
        {
            auto bytes = cast(ubyte[])value;
            this.writeLengthBytes(bytes.length);
            this.writeBytes(bytes);
        }
    }

    // ###########
    // # SEEKING #
    // ###########
    public
    {
        /++
         + Sets the position to write/read from.
         + ++/
        @property @safe
        void position(size_t newPos)
        {
            enforce(newPos <= this.length, "Attempted to seek past end of stream.");
            this._position = newPos;
        }

        /++
         + Gets the position to write/read from.
         + ++/
        @property @safe @nogc
        size_t position() nothrow const
        {
            return this._position;
        }

        /++
         + Returns:
         +  How many bytes are in the stream.
         + ++/
        @property @safe @nogc
        size_t length() nothrow const
        {
            return this._data.length;
        }

        /++
         + Sets the length of the stream's data.
         +
         + Notes:
         +  The stream's position will remain unaffected.
         + ++/
        @property @safe
        void length(size_t newLen) nothrow
        {
            this._data.length = newLen;
        }
    }
}
///
unittest
{
    auto stream = new BinaryStream();

    // # Test numeric writes #
    stream.write!short(cast(short)0xFEED);
    stream.write!int(0xDEADBEEF);
    assert(stream.length == 6);

    stream.position = 0;
    assert(stream.readBytes(6) == [0xFE, 0xED, 0xDE, 0xAD, 0xBE, 0xEF]);

    stream.position = 0;
    assert(stream.read!short == cast(short)0xFEED);
    assert(stream.read!int   == 0xDEADBEEF);

    // # Test length byte writes #
    stream = new BinaryStream();

    stream.writeLengthBytes(60);       // One byte
    stream.writeLengthBytes(16_000);   // Two bytes
    stream.writeLengthBytes(17_000);   // Four bytes

    stream.position = 0;
    assert(stream.readBytes(7) == [0b0011_1100,
                                   0b0111_1110, 0b1000_0000,
                                   0b1000_0000, 0b0000_0000, 0b0100_0010, 0b0110_1000]);
                                
    stream.position = 0;
    assert(stream.readLengthBytes() == 60);
    assert(stream.readLengthBytes() == 16_000);
    assert(stream.readLengthBytes() == 17_000);

    // # Test array writes #
    stream = new BinaryStream();

    stream.write!ushort([0xAABB, 0xCCDD, 0xEEFF]);

    stream.position = 0;
    assert(stream.readBytes(7) == [0x03, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]);

    stream.position = 0;
    assert(stream.read!(ushort[]) == [0xAABB, 0xCCDD, 0xEEFF]);

    // # Test string writes #
    stream = new BinaryStream();

    stream.write("Gurl");

    stream.position = 0;
    assert(stream.readBytes(stream.length) == [0x04, 'G', 'u', 'r', 'l']);

    stream.position = 0;
    assert(stream.read!string() == "Gurl");
}