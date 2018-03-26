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
        // To explain the ' - 1' stuff:
        //  Imagine a rect (0, 0, 32, 32)
        //  The top right corner should be (31, 0)
        //  But (0, 0) + (32, 0) = (32, 0)
        //  So we take away 1 to get the correct pixel.
        return position + VecType(this.size.x - 1, 0);
    }

    ///
    @safe @nogc
    inout(VecType) botLeft() nothrow pure inout
    {
        return position + VecType(0, this.size.y - 1);
    }

    ///
    @safe @nogc
    inout(VecType) botRight() nothrow pure inout
    {
        return position + this.size - VecType(1, 1);
    }
}

///
alias RectangleF = Rectangle!float;

///
alias RectangleI = Rectangle!int;

///
enum AngleType
{
    ///
    Degrees,

    ///
    Radians
}

/++
 + A struct to easily convert an angle between Radians and Degrees.
 +
 + If a conversion does not need to take place (e.g Radians -> Radians) then this struct is zero-cost.
 + ++/
struct Angle(AngleType type)
{
    import std.math : PI;
    
    /// The angle (This struct is `alias this`ed to this variable).
    float angle;
    alias angle this;

    ///
    @property @safe @nogc
    AngleDegrees degrees() nothrow pure const
    {
        static if(type == AngleType.Degrees)
            return this;
        else
            return AngleDegrees(this * (180 / PI));
    }

    ///
    @property @safe @nogc
    AngleRadians radians() nothrow pure const
    {
        static if(type == AngleType.Radians)
            return this;
        else
            return AngleRadians(this * (PI / 180));
    }

    ///
    @safe @nogc
    void opAssign(AngleDegrees rhs) nothrow pure
    {
        static if(type == AngleType.Degrees)
            this.angle = rhs.degrees;
        else
            this.angle = rhs.radians;
    }

    ///
    @safe @nogc
    void opAssign(AngleRadians rhs) nothrow pure
    {
        static if(type == AngleType.Radians)
            this.angle = rhs.radians;
        else
            this.angle = rhs.degrees;
    }
}

///
alias AngleDegrees = Angle!(AngleType.Degrees);
///
alias AngleRadians = Angle!(AngleType.Radians);
