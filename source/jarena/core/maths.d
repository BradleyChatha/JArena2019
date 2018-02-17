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
}

///
alias RectangleF = Rectangle!float;

///
alias RectangleI = Rectangle!int;