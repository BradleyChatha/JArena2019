module jarena.maths.matrix;

private
{
    import std.math, std.traits, std.meta, std.range;
    import jarena.maths;
}

struct Matrix(T, size_t Columns_, size_t Rows_)
{
    static assert(Columns >= 2 && Columns <= 4, "There can only be 2, 3, or 4 columns.");
    static assert(Rows >= 2    && Rows <= 4,    "There can only be 2, 3, or 4 rows.");

    alias ThisType = typeof(this);
    alias ColumnT  = Vector!(T, Rows);
    alias Columns  = Columns_;
    alias Rows     = Rows_;

    ColumnT[Columns] columns; // Column major

    // #############
    // # FUNCTIONS #
    // #############
    public
    {
        pragma(inline, true) @safe @nogc
        void clear(T value) nothrow pure
        {
            foreach(ref column; this.columns)
                column = ColumnT(value);
        }

        @property @safe @nogc
        static ThisType identity() nothrow pure
        {
            ThisType data;
            data.clear(0);
            foreach(i; 0..(Columns < Rows) ? Columns : Rows)
                data.columns[i].components[i] = 1;

            return data;
        }
        ///
        unittest
        {
            assert(mat4.identity.columns ==
            [
                vec4(1, 0, 0, 0),
                vec4(0, 1, 0, 0),
                vec4(0, 0, 1, 0),
                vec4(0, 0, 0, 1)
            ]);
        }

        pragma(inline, true) @safe @nogc
        T determinant() nothrow const pure
        {
            static if(Columns == 4)
            {
                auto c0 = this.columns[0].components;
                auto c1 = this.columns[1].components;
                auto c2 = this.columns[2].components;
                auto c3 = this.columns[3].components;
                return
                  c0[3] * c1[2] * c2[1] * c3[0] - c0[2] * c1[3] * c2[1] * c3[0]
				- c0[3] * c1[1] * c2[2] * c3[0] + c0[1] * c1[3] * c2[2] * c3[0]
				+ c0[2] * c1[1] * c2[3] * c3[0] - c0[1] * c1[2] * c2[3] * c3[0]
				- c0[3] * c1[2] * c2[0] * c3[1] + c0[2] * c1[3] * c2[0] * c3[1]
				+ c0[3] * c1[0] * c2[2] * c3[1] - c0[0] * c1[3] * c2[2] * c3[1]
				- c0[2] * c1[0] * c2[3] * c3[1] + c0[0] * c1[2] * c2[3] * c3[1]
				+ c0[3] * c1[1] * c2[0] * c3[2] - c0[1] * c1[3] * c2[0] * c3[2]
				- c0[3] * c1[0] * c2[1] * c3[2] + c0[0] * c1[3] * c2[1] * c3[2]
				+ c0[1] * c1[0] * c2[3] * c3[2] - c0[0] * c1[1] * c2[3] * c3[2]
				- c0[2] * c1[1] * c2[0] * c3[3] + c0[1] * c1[2] * c2[0] * c3[3]
				+ c0[2] * c1[0] * c2[1] * c3[3] - c0[0] * c1[2] * c2[1] * c3[3]
                - c0[1] * c1[0] * c2[2] * c3[3] + c0[0] * c1[1] * c2[2] * c3[3];
            }
            
            assert(false);
        }
        ///
        unittest
        {
	        imat4 mat;
            mat.columns = [ ivec4(  1.0,   2.0,   3.0,   4.0),
					        ivec4(- 2.0,   1.0,   5.0, - 2.0),
					        ivec4(  2.0, - 1.0,   7.0,   1.0),
					        ivec4(  3.0, - 3.0,   2.0,   0.0) ];
            
            assert(mat.determinant == -8.0);
        }

        pragma(inline, true) @safe @nogc
        ThisType inverted() nothrow const pure
        {
            auto d = this.determinant;

            static if(Columns == 4)
            {
                auto c0 = this.columns[0].components;
                auto c1 = this.columns[1].components;
                auto c2 = this.columns[2].components;
                auto c3 = this.columns[3].components;

                ThisType data;
                data.columns =
                [
				ColumnT(( c1[ 1 ] * c2[ 2 ] * c3[ 3 ] + c1[ 2 ] * c2[ 3 ] * c3[ 1 ] + c1[ 3 ] * c2[ 1 ] * c3[ 2 ]
						- c1[ 1 ] * c2[ 3 ] * c3[ 2 ] - c1[ 2 ] * c2[ 1 ] * c3[ 3 ] - c1[ 3 ] * c2[ 2 ] * c3[ 1 ] ) / d,
						( c0[ 1 ] * c2[ 3 ] * c3[ 2 ] + c0[ 2 ] * c2[ 1 ] * c3[ 3 ] + c0[ 3 ] * c2[ 2 ] * c3[ 1 ]
						- c0[ 1 ] * c2[ 2 ] * c3[ 3 ] - c0[ 2 ] * c2[ 3 ] * c3[ 1 ] - c0[ 3 ] * c2[ 1 ] * c3[ 2 ] ) / d,
						( c0[ 1 ] * c1[ 2 ] * c3[ 3 ] + c0[ 2 ] * c1[ 3 ] * c3[ 1 ] + c0[ 3 ] * c1[ 1 ] * c3[ 2 ]
						- c0[ 1 ] * c1[ 3 ] * c3[ 2 ] - c0[ 2 ] * c1[ 1 ] * c3[ 3 ] - c0[ 3 ] * c1[ 2 ] * c3[ 1 ] ) / d,
						( c0[ 1 ] * c1[ 3 ] * c2[ 2 ] + c0[ 2 ] * c1[ 1 ] * c2[ 3 ] + c0[ 3 ] * c1[ 2 ] * c2[ 1 ]
						- c0[ 1 ] * c1[ 2 ] * c2[ 3 ] - c0[ 2 ] * c1[ 3 ] * c2[ 1 ] - c0[ 3 ] * c1[ 1 ] * c2[ 2 ] ) / d ),
				ColumnT(( c1[ 0 ] * c2[ 3 ] * c3[ 2 ] + c1[ 2 ] * c2[ 0 ] * c3[ 3 ] + c1[ 3 ] * c2[ 2 ] * c3[ 0 ]
						- c1[ 0 ] * c2[ 2 ] * c3[ 3 ] - c1[ 2 ] * c2[ 3 ] * c3[ 0 ] - c1[ 3 ] * c2[ 0 ] * c3[ 2 ] ) / d,
						( c0[ 0 ] * c2[ 2 ] * c3[ 3 ] + c0[ 2 ] * c2[ 3 ] * c3[ 0 ] + c0[ 3 ] * c2[ 0 ] * c3[ 2 ]
						- c0[ 0 ] * c2[ 3 ] * c3[ 2 ] - c0[ 2 ] * c2[ 0 ] * c3[ 3 ] - c0[ 3 ] * c2[ 2 ] * c3[ 0 ] ) / d,
						( c0[ 0 ] * c1[ 3 ] * c3[ 2 ] + c0[ 2 ] * c1[ 0 ] * c3[ 3 ] + c0[ 3 ] * c1[ 2 ] * c3[ 0 ]
						- c0[ 0 ] * c1[ 2 ] * c3[ 3 ] - c0[ 2 ] * c1[ 3 ] * c3[ 0 ] - c0[ 3 ] * c1[ 0 ] * c3[ 2 ] ) / d,
						( c0[ 0 ] * c1[ 2 ] * c2[ 3 ] + c0[ 2 ] * c1[ 3 ] * c2[ 0 ] + c0[ 3 ] * c1[ 0 ] * c2[ 2 ]
						- c0[ 0 ] * c1[ 3 ] * c2[ 2 ] - c0[ 2 ] * c1[ 0 ] * c2[ 3 ] - c0[ 3 ] * c1[ 2 ] * c2[ 0 ] ) / d ),
				ColumnT(( c1[ 0 ] * c2[ 1 ] * c3[ 3 ] + c1[ 1 ] * c2[ 3 ] * c3[ 0 ] + c1[ 3 ] * c2[ 0 ] * c3[ 1 ]
						- c1[ 0 ] * c2[ 3 ] * c3[ 1 ] - c1[ 1 ] * c2[ 0 ] * c3[ 3 ] - c1[ 3 ] * c2[ 1 ] * c3[ 0 ] ) / d,
						( c0[ 0 ] * c2[ 3 ] * c3[ 1 ] + c0[ 1 ] * c2[ 0 ] * c3[ 3 ] + c0[ 3 ] * c2[ 1 ] * c3[ 0 ]
						- c0[ 0 ] * c2[ 1 ] * c3[ 3 ] - c0[ 1 ] * c2[ 3 ] * c3[ 0 ] - c0[ 3 ] * c2[ 0 ] * c3[ 1 ] ) / d,
						( c0[ 0 ] * c1[ 1 ] * c3[ 3 ] + c0[ 1 ] * c1[ 3 ] * c3[ 0 ] + c0[ 3 ] * c1[ 0 ] * c3[ 1 ]
						- c0[ 0 ] * c1[ 3 ] * c3[ 1 ] - c0[ 1 ] * c1[ 0 ] * c3[ 3 ] - c0[ 3 ] * c1[ 1 ] * c3[ 0 ] ) / d,
						( c0[ 0 ] * c1[ 3 ] * c2[ 1 ] + c0[ 1 ] * c1[ 0 ] * c2[ 3 ] + c0[ 3 ] * c1[ 1 ] * c2[ 0 ]
						- c0[ 0 ] * c1[ 1 ] * c2[ 3 ] - c0[ 1 ] * c1[ 3 ] * c2[ 0 ] - c0[ 3 ] * c1[ 0 ] * c2[ 1 ] ) / d ),
				ColumnT(( c1[ 0 ] * c2[ 2 ] * c3[ 1 ] + c1[ 1 ] * c2[ 0 ] * c3[ 2 ] + c1[ 2 ] * c2[ 1 ] * c3[ 0 ]
						- c1[ 0 ] * c2[ 1 ] * c3[ 2 ] - c1[ 1 ] * c2[ 2 ] * c3[ 0 ] - c1[ 2 ] * c2[ 0 ] * c3[ 1 ] ) / d,
						( c0[ 0 ] * c2[ 1 ] * c3[ 2 ] + c0[ 1 ] * c2[ 2 ] * c3[ 0 ] + c0[ 2 ] * c2[ 0 ] * c3[ 1 ]
						- c0[ 0 ] * c2[ 2 ] * c3[ 1 ] - c0[ 1 ] * c2[ 0 ] * c3[ 2 ] - c0[ 2 ] * c2[ 1 ] * c3[ 0 ] ) / d,
						( c0[ 0 ] * c1[ 2 ] * c3[ 1 ] + c0[ 1 ] * c1[ 0 ] * c3[ 2 ] + c0[ 2 ] * c1[ 1 ] * c3[ 0 ]
						- c0[ 0 ] * c1[ 1 ] * c3[ 2 ] - c0[ 1 ] * c1[ 2 ] * c3[ 0 ] - c0[ 2 ] * c1[ 0 ] * c3[ 1 ] ) / d,
						( c0[ 0 ] * c1[ 1 ] * c2[ 2 ] + c0[ 1 ] * c1[ 2 ] * c2[ 0 ] + c0[ 2 ] * c1[ 0 ] * c2[ 1 ]
						- c0[ 0 ] * c1[ 2 ] * c2[ 1 ] - c0[ 1 ] * c1[ 0 ] * c2[ 2 ] - c0[ 2 ] * c1[ 1 ] * c2[ 0 ] ) / d ) 
                ];
                    
                return data;
            }

            assert(false);
        }
        ///
        unittest
        {
            mat4 m4;
            m4.columns = [ vec4(   1.0f,   2.0f,   3.0f,   4.0f),
					       vec4( - 2.0f,   1.0f,   5.0f, - 2.0f),
					       vec4(   2.0f, - 1.0f,   7.0f,   1.0f),
					       vec4(   3.0f, - 3.0f,   2.0f,   0.0f) ];
            assert( m4.determinant == - 8.0f );
            assert( m4.inverted.columns ==  [vec4(   6.875f,   7.875f, - 11.75f,  11.125f),
                                             vec4(   6.625f,   7.625f, - 11.25f,  10.375f),
                                             vec4( - 0.375f, - 0.375f,    0.75f, - 0.625f),
                                             vec4( - 4.5f,   -   5.5f,     8.0f,   - 7.5f )]);
        }

        // ###############
        // # TRANSLATION #
        // ###############
        static if(Columns == 2) // Reminder: Only 2, 3, and 4 are valid values for Columns and Rows.
        {
        }
        else static if(Columns == 3)
        {

        }
        else static if(Columns == 4)
        {
            pragma(inline, true) @safe @nogc
            static ThisType translation(T x, T y, T z) nothrow pure
            {
                ThisType data = ThisType.identity;
                data.columns[3].xyz = Vector!(T, 3)(x, y, z);
                return data;
            }

            pragma(inline, true) @safe @nogc
            ThisType translate(T x, T y, T z) nothrow pure
            {
                this = ThisType.translation(x, y, z) * this;
                return this;
            }
        }

        // ############
        // # ROTATION #
        // ############
        static if(Columns >= 2)
        {
        }
        static if(Columns >= 3)
        {
            pragma(inline, true) @safe @nogc
            ThisType rotationZ(AngleDegrees degrees) nothrow pure
            {
                ThisType data = ThisType.identity;
                data.columns[0].components[0] = cast(T)cos(degrees);
                data.columns[0].components[1] = cast(T)sin(degrees);
                data.columns[1].components[0] = cast(T)-sin(degrees);
                data.columns[1].components[1] = cast(T)cos(degrees);

                return data;
            }

            pragma(inline, true) @safe @nogc
            ThisType rotateZ(AngleDegrees degrees) nothrow pure
            {
                this = ThisType.rotationZ(degrees) * this;
                return this;
            }
        }

        // #########
        // # SCALE #
        // #########
        static if(Columns >= 2)
        {
        }
        static if(Columns >= 3)
        {
            pragma(inline, true) @safe @nogc
            static ThisType scaling(T x, T y, T z) nothrow pure
            {
                ThisType data = ThisType.identity;
                data.columns[0].x = x;
                data.columns[1].y = y;
                data.columns[2].z = z;
                return data;
            }

            pragma(inline, true) @safe @nogc
            ThisType scale(T x, T y, T z) nothrow pure
            {
                this = ThisType.scaling(x, y, z) * this;
                return this;
            }
        }
    }

    // ######################
    // # OPERATOR OVERLOADS #
    // ######################
    public
    {
        /// Matrix-Matrix addition and subtraction
        pragma(inline, true) @safe @nogc
        ThisType opBinary(string op)(ThisType mat) nothrow const pure
        if(op == "+" || op == "-")
        {
            ThisType data = this;
            foreach(i, ref column; data.columns)
                mixin("column "~op~"= mat.columns[i];");

            return data;
        }
        ///
        unittest
        {
            imat4 mat;
            mat.columns = 
            [
                ivec4(20, 0,  0, 10),
                ivec4(0, 40,  0, 20),
                ivec4(0,  0, 60, 30),
                ivec4(0,  0,  0, 90)
            ];

            assert((mat + mat.identity).columns == 
            [
                ivec4(21, 0,  0, 10),
                ivec4(0, 41,  0, 20),
                ivec4(0,  0, 61, 30),
                ivec4(0,  0,  0, 91)
            ]);
        }

        /// Matrix-Matrix multiplication
        pragma(inline, true) @safe @nogc
        ThisType opBinary(string op)(ThisType rhs) nothrow const pure
        if(op == "*")
        {
            ThisType data = this;
            foreach(column; 0..Columns)
                data.columns[column] = this * rhs.columns[column];

            return data;
        }
        ///
        unittest
        {
            import std.conv : to;
            imat2 mat;
            mat.columns = 
            [
                ivec2(1, 2),
                ivec2(3, 4)
            ];

            imat2 mat_2;
            mat_2.columns =
            [
                ivec2(2, 4),
                ivec2(6, 8)
            ];

            assert((mat * mat_2).columns == 
            [
                ivec2(1*2+3*4, 2*2+4*4),
                ivec2(1*6+3*8, 2*6+4*8)
            ], (mat * mat_2).to!string);

            mat2 m2;
            m2.columns = [vec2(2.0f, 4.0f), vec2(6.0f, 8.0f)];
            assert(( m2 * m2 ).columns == [ vec2( 28.0f, 40.0f ), vec2( 60.0f, 88.0f ) ] );
        }

        /// Matrix-Vector multiplication
        pragma(inline, true) @safe @nogc
        VectT opBinary(string op, VectT)(VectT rhs) nothrow const pure
        if(op == "*" && isVector!VectT)
        {
            static assert(VectT.Dimension == Columns, "The Vector's dimension must be the same as this matrix's column count.");
            static assert(VectT.Dimension == Rows, "Because I'm lazy, right now there is only support for when the Vector's dimension is the same as this matrix's row count.");
            
            auto data = VectT(0);

            // 1st component
            static if(VectT.Dimension >= 1)
            {
                                        data.components[0] += this.columns[0].components[0] * rhs.components[0];
                                        data.components[0] += this.columns[1].components[0] * rhs.components[1];
                static if(Columns >= 3) data.components[0] += this.columns[2].components[0] * rhs.components[2];
                static if(Columns >= 4) data.components[0] += this.columns[3].components[0] * rhs.components[3];
            }

            // 2nd
            static if(VectT.Dimension >= 2)
            {
                                        data.components[1] += this.columns[0].components[1] * rhs.components[0];
                                        data.components[1] += this.columns[1].components[1] * rhs.components[1];
                static if(Columns >= 3) data.components[1] += this.columns[2].components[1] * rhs.components[2];
                static if(Columns >= 4) data.components[1] += this.columns[3].components[1] * rhs.components[3];
            }

            // 3rd
            static if(VectT.Dimension >= 3)
            {
                                        data.components[2] += this.columns[0].components[2] * rhs.components[0];
                                        data.components[2] += this.columns[1].components[2] * rhs.components[1];
                static if(Columns >= 3) data.components[2] += this.columns[2].components[2] * rhs.components[2];
                static if(Columns >= 4) data.components[2] += this.columns[3].components[2] * rhs.components[3];
            }

            // 4th
            static if(VectT.Dimension >= 4)
            {
                                        data.components[3] += this.columns[0].components[3] * rhs.components[0];
                                        data.components[3] += this.columns[1].components[3] * rhs.components[1];
                static if(Columns >= 3) data.components[3] += this.columns[2].components[3] * rhs.components[2];
                static if(Columns >= 4) data.components[3] += this.columns[3].components[3] * rhs.components[3];
            }

            return data;
        }
        ///
        unittest
        {
            import std.conv : to;

            imat2 mat;
            mat.columns = 
            [
                ivec2(1, 2),
                ivec2(3, 4)
            ];

            assert(mat * ivec2(2, 4) == ivec2(1*2+3*4, 2*2+4*4), to!string(mat * ivec2(2, 4)));
            assert(mat * ivec2(6, 8) == ivec2(1*6+3*8, 2*6+4*8));
        }
    }
}

alias imat2 = Matrix!(int,   2, 2);
alias mat2  = Matrix!(float, 2, 2);

alias imat4 = Matrix!(int,   4, 4);
alias mat4  = Matrix!(float, 4, 4);

mat4 glOrthographic(float left, float right, float bottom, float top, float near, float far)
{
    auto data = mat4.identity;

    data.columns[0].components[0] = 2 / (right - left);
    data.columns[1].components[1] = 2 / (top - bottom);
    data.columns[2].components[2] = -2 / (far - near);
    data.columns[3].components[0] = -((right + left) / (right - left));
    data.columns[3].components[1] = -((top + bottom) / (top - bottom));
    data.columns[3].components[2] = -((far + near) / (far - near));

    return data;
}