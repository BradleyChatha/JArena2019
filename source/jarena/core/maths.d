module jarena.core.maths;

public
{
    import dlsl.vector, dlsl.matrix;
}

/++
 + Describes a rectangle.
 + ++/
struct Rectangle(T)
{
    /// The type of `Vector` used by this rectangle.
    alias VecType = Vector!(T, 2);

    /// The position (the top-left pixel) of the rectangle.
    VecType position;
    
    /// The size of the rectangle.
    VecType size;

    ///
    @safe @nogc
    this(VecType pos, VecType size) nothrow pure
    {
        this.position = pos;
        this.size = size;
    }

    ///
    @safe @nogc
    this(T x, T y, T width, T height) nothrow pure
    {
        this(VecType(x, y), VecType(width, height));
    }

    ///
    @safe @nogc
    this(T x, T y, VecType size) nothrow pure
    {
        this(VecType(x, y), size);
    }

    ///
    @safe @nogc
    this(VecType pos, T width, T height) nothrow pure
    {
        this(pos, VecType(width, height));
    }
}

///
alias RectangleF = Rectangle!float;

///
alias RectangleI = Rectangle!int;