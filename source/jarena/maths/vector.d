module jarena.maths.vector;

private
{
    import std.math, std.traits, std.meta, std.range;
}

///
enum isVector(T) = is(typeof(isVectorImpl(T.init)));

private void isVectorImpl(T, int Dimension)(Vector!(T, Dimension) vec) {}
private enum isScalarOrVector(T) = isScalarType!T || isVector!T;
private enum isCompatibleType(T) = isScalarOrVector!T || (isStaticArray!T && isScalarType!(ElementType!T));

/++
 + A vector type that supports between 2 and 4 dimensions.
 +
 + Swizzling:
 +  This type supports swizzling (if you've used gl3n, GLSL itself, or DLSL, then you know what to expect).
 +
 +  Up to 4 swizzles (x, y, z, w) can be used at a time, in any order, and my appear multiple times.
 + ++/
struct Vector(T, size_t Dimension_)
{
    static assert(Dimension > 1 && Dimension < 5, "Can only have a dimension between 2 and 4 (inclusive)");

    alias ThisType  = typeof(this);
    alias Dimension = Dimension_;

    /// The components making up this vector.
    T[Dimension] components;

    @trusted
    private void construction(int i, Data...)(Data data)
    {
        alias HeadT = typeof(data[0]);

        static assert(i < Dimension, "Too many components were passed.");

        static if(isScalarType!HeadT)
        {
            static if(data.length == 1 && i == 0)
                this.components[0..$] = cast(T)data[0];
            else
            {
                this.components[i] = cast(T)data[0];

                static if(data.length > 1)
                    this.construction!(i + 1)(data[1..$]);
            }
        }
        else static if(isVector!HeadT || isStaticArray!HeadT)
        {
            static if(isVector!HeadT)
                auto arr = data[0].components;
            else
                auto arr = data[0];

            static assert((i + arr.length) <= Dimension, "Too many components were passed.");
            foreach(arrI, v; arr)
                this.components[i+arrI] = cast(T)v;

            static if(data.length > 1)
                this.construction!(i + arr.length)(data[1..$]);
        }
        else static assert(false, "Unsupported type: " ~ HeadT.stringof);
    }

    /++
     + Constructs a vector using the given values.
     +
     + Usage:
     +  If only a single scalar type is passed through, then all of this vector's components will be
     +  set to that value.
     +
     +  If multiple scalar types are passed through, then the components will be set in the order
     +  the values were passed in. For example, the parameters `(20, 40)` would set X to 20, and Y to 40.
     +
     +  If a static array of scalars or another vector are passed in, then the components will be
     +  set in the order the values appear in the array/vector. So `[20, 40]/ivec2(20, 40)` sets X to 20, and Y to 40.
     +
     +  If less values are passed in than there are components in this vector, then the leftover components are
     +  left at their initial value (excluding the single scalar rule).
     +
     +  You can mix all 3 together if needed, and the components will be set in order. For example,
     +  `ivec2(20, ivec2(40, 60), cast(int[1])[80])` would be the same as `ivec2(20, 40, 60, 80)`.
     + ++/
    this(Args...)(Args args)
    if(Args.length > 0 && allSatisfy!(isCompatibleType, Args))
    {
        this.components[] = 0;
        this.construction!0(args);
    }
    ///
    unittest
    {
        assert(ivec2(200, 600).components               == [200, 600]); // Normal (x,y)
        assert(ivec2(ivec2(200, 600)).components        == [200, 600]); // Can use other vectors
        assert(ivec4(vec2(500, 200), 1, 2).components   == [500, 200, 1, 2]); // Can use a mixture
        assert(ivec2(cast(int[2])[200, 600]).components == [200, 600]); // Can use static arrays
        assert(vec2(0).components                       == [0, 0]);
    }

    // #############
    // # FUNCTIONS #
    // #############
    public
    {
        string toString()
        {
            import std.format;
            return format("%s", this.components);
        }

        /// Returns: A normalised version of this vector.
        pragma(inline, true) @safe @nogc
        ThisType normalised() nothrow const pure
        {
            Unqual!ThisType value = this;
            auto len = this.length;
            foreach(ref component; value.components)
                component /= len;

            return value;
        }

        /// The dot product between this vector and `vect`.
        T dot(VectT)(VectT vect) const
        if(isVector!VectT)
        {
            static assert(VectT.Dimension == ThisType.Dimension, "The two vects have different dimensions.");
            T result = 0;
            foreach(i; 0..ThisType.Dimension)
                result += this.components[i] * vect.components[i];

            return result;
        }
        ///
        unittest
        {
            assert(ivec2(20, 50).dot(ivec2(2)) == 140);
        }

        /++
         + Calculates the length of this vector.
         +
         + Notes:
         +  If you are comparing two vector's lengths to eachother (for example, checking distance), then
         +  you may prefer to simply use `myVect.dot(myVect)` to obtain these numbers, as this skips the square root
         +  that has to be performed.
         + ++/
        pragma(inline, true) @safe @nogc
        T length() nothrow const pure
        {
            import std.math : sqrt;

            return cast(T)sqrt(cast(real)this.dot(this));
        }
        ///
        unittest
        {
            assert(ivec2(2, 5).length == 5);
        }
    }

    // #############
    // # SWIZZLING #
    // #############
    private // Generation functions are private, actual generated things are public.
    {
        enum _swizzleMap = ['x':0, 'y':1, 'z':2, 'w':3];

        static uint getSwizzleIndex(string swizzle)(char swizzChar)
        {
            auto ptr = (swizzChar in _swizzleMap);
            if(ptr is null || *ptr >= Dimension)
                assert(false, "Invalid swizzle character '"~swizzChar~"' in swizzle '"~swizzle~"'");

            return *ptr;
        }

        static dstring generateGetterDispatch(string swizzle)()
        {
            import std.algorithm;
            import std.conv;
            import codebuilder;

            auto code = new CodeBuilder();
            code.putf("return ");

            static if(swizzle.length > 1)
                code.putf("Vector!(T, %s)(", swizzle.length);

            code.putf("%s",
                swizzle.map!(chr => getSwizzleIndex!swizzle(cast(char)chr))
                       .map!(indx => "components["~indx.to!string~"]")
                       .joiner(", ")
            );

            static if(swizzle.length > 1)
                code.put(")");
            code.put(";");

            return code.data.idup;
        }

        static dstring generateVectSetterDispatch(string swizzle, VectT)()
        {
            import std.algorithm;
            import std.conv;
            import codebuilder;

            static assert(VectT.Dimension == swizzle.length, 
                "Swizzle is " ~ swizzle.length.to!string ~ " components long, but the "
               ~"given vector is " ~ VectT.Dimension.to!string ~ " components long. They must match."
            );

            auto code = new CodeBuilder();

            foreach(i, chr; swizzle)
                code.putf("this.components[%s] = vect.components[%s];\n", getSwizzleIndex!swizzle(chr), i);

            return code.data.idup;
        }
    }
    public
    {
        /// Swizzled getter
        auto opDispatch(string swizzle)() const
        {
            mixin(generateGetterDispatch!swizzle);
        }
        ///
        unittest
        {
            ivec4 data = ivec4(1, 2, 3, 4);

            assert(data.x == 1);
            assert(data.xyzw == ivec4(1, 2, 3, 4));
            assert(data.wxzy == ivec4(4, 1, 3, 2));
        }

        /// Swizzled setter (Vector types)
        void opDispatch(string swizzle, VectT)(VectT vect)
        if(isVector!VectT)
        {
            mixin(generateVectSetterDispatch!(swizzle, VectT));
        }
        ///
        unittest
        {
            auto data = ivec4(1, 2, 3, 4);

            data.zy = data.yz;
            assert(data == ivec4(1, 3, 2, 4));
        }

        /// Swizzled setter (Scalar types)
        @property
        void opDispatch(string swizzle, ST)(ST scalarType)
        if(isScalarType!ST)
        {
            import std.conv;

            static assert(swizzle.length == 1, "Can only assign a single component to a scalar value for now.");
            enum index = getSwizzleIndex!swizzle(swizzle[0]);

            mixin("this.components["~index.to!string~"] = scalarType;");
        }
        ///
        unittest
        {
            auto data = vec2(50, 60);
            data.x    = 20;

            assert(data.xy == vec2(20, 60));
        }
    }

    // ######################
    // # OPERATOR OVERLOADS #
    // ######################
    public
    {
        /// Vector-Scalar operations
        ThisType opBinary(string op, ST)(ST scalar) const
        if(isScalarType!ST)
        {
            ThisType toReturn = this;
            foreach(ref comp; toReturn.components)
                mixin("comp "~op~"= scalar;");

            return toReturn;
        }
        ///
        unittest
        {
            assert(vec2(200, 600) * 2 == vec2(400, 1200));
            assert(vec2(200, 600) + 2 == vec2(202, 602));
            assert(vec2(200, 600) / 2 == vec2(100, 300));
            assert(vec2(200, 600) - 2 == vec2(198, 598));
        }

        /// Vector-Vector operations
        ThisType opBinary(string op, VectT)(VectT vect) const
        if(isVector!VectT)
        {
            static assert(VectT.Dimension == ThisType.Dimension, "The vectors must have matching dimensions.");
            
            ThisType data = this;
            foreach(i; 0..Dimension)
                mixin("data.components[i] "~op~"= vect.components[i];");

            return data;
        }
        ///
        unittest
        {
            assert(vec2(200, 600) * vec2(2, 1) == vec2(400, 600));
            assert(vec2(200, 600) + vec2(2, 1) == vec2(202, 601));
            assert(vec2(200, 600) / vec2(2, 1) == vec2(100, 600));
            assert(vec2(200, 600) - vec2(2, 1) == vec2(198, 599));
        }

        /// Generic assign
        void opOpAssign(string op, Type)(Type data)
        {
            this = mixin("this "~op~" data");
        }
        ///
        unittest
        {
            auto vec = vec2(200, 400);

            vec *= 2;
            assert(vec == vec2(400, 800));
            
            vec /= 2;
            assert(vec == vec2(200, 400));

            vec += 2;
            assert(vec == vec2(202, 402));

            vec -= 2;
            assert(vec == vec2(200, 400));
        }

        /// Negation
        ThisType opUnary(string op)() const
        if(op == "-")
        {
            ThisType data = this;
            foreach(ref component; data.components)
                component *= -1;

            return data;
        }
    }
}

alias vec2  = Vector!(float, 2);
alias ivec2 = Vector!(int,   2);
alias uvec2 = Vector!(uint,  2);

alias vec3  = Vector!(float, 3);
alias ivec3 = Vector!(int,   3);
alias uvec3 = Vector!(uint,  3);

alias vec4  = Vector!(float, 4);
alias ivec4 = Vector!(int,   4);
alias uvec4 = Vector!(uint,  4);