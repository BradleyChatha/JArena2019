///
module jarena.core.maths;

public
{
    import dlsl.vector, dlsl.matrix;
    import arsd.colour; // This is where the other modules got Colour from, which was previously used for colours.
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

    ///
    bool contains(Vect)(Vect point)
    if(isVector!Vect && Vect.dimension == 2)
    {
        return point.x >= this.position.x
            && point.y >= this.position.y
            && point.x < this.position.x + this.size.x
            && point.y < this.position.y + this.size.y;
    }

    ///
    @safe @nogc
    inout(VecType) topLeft() nothrow pure inout
    {
        return position;
    }

    ///
    @safe @nogc
    inout(VecType) topRight() nothrow pure inout
    {
        return position + VecType(this.size.x, 0);
    }

    ///
    @safe @nogc
    inout(VecType) botLeft() nothrow pure inout
    {
        return position + VecType(0, this.size.y);
    }

    ///
    @safe @nogc
    inout(VecType) botRight() nothrow pure inout
    {
        return position + this.size;
    }
}

///
alias RectangleF = Rectangle!float;

///
alias RectangleI = Rectangle!int;
