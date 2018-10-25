/++
 + Contains code relating to rendering different kinds of shapes.
 + ++/
module jarena.graphics.shape;

private
{
    import jarena.core, jarena.graphics, jarena.maths;
}

/// Describes a rectangle (or square) which can be rendered to the screen.
class RectangleShape : ITransformable
{
    private final
    {
        Transform    _transform;
        uint         _borderSize;
        Vertex[4]    _verts;       // [0]TopLeft|[1]TopRight|[2]BotLeft|[3]BotRight
        Vertex[4*4]  _borderVerts; // [Per corner][0]TopLeft|[1]TopRight|[2]BotLeft|[3]BotRight
                                   // [0..4] = Top Left Corner|[4..8]TopRight|[8..12]BotLeft|[12..16]BotRight
        Vertex[4*5]  _transformed; // [Final4] = _verts. [First16] = _borderVerts
        Vertex[4*5]  _cachedVerts; // This contains the _transformed verts, but in a specific order for rendering.

        @safe @nogc
        void recalcBorderVerts() nothrow
        {
            int borderSize = cast(int)this._borderSize;
            auto size      = this.size + vec2(borderSize);
            vec2[4] offsets = 
            [
                vec2(0,      0),      // TopLeft
                vec2(size.x, 0),      // TopRight
                vec2(0,      size.y), // BotLeft
                vec2(size.x, size.y)  // BotRight
            ];

            foreach(i; 0..this._borderVerts.length / 4)
            {
                // Space the verts out from eachother, and add an offset to them.
                auto offset = offsets[i];
                auto index = (i * 4);
                this._borderVerts[index].position   = vec2(-borderSize) + offset;
                this._borderVerts[index+1].position = vec2(0, -borderSize) + offset;
                this._borderVerts[index+2].position = vec2(-borderSize, 0) + offset;
                this._borderVerts[index+3].position = offset;
            }

            this._transform.markDirty();
        }
    }

    public final
    {
        /++
         + Creates a new RectangleShape.
         +
         + Params:
         +  area = The area that makes up the rectangle.
         + ++/
        @safe
        this(RectangleF area = RectangleF(0,0,0,0))
        {
            this._verts = 
            [
                Vertex(vec2(0), vec2(0), Colour.white),
                Vertex(vec2(0), vec2(0), Colour.white),
                Vertex(vec2(0), vec2(0), Colour.white),
                Vertex(vec2(0), vec2(0), Colour.white)
            ];

            this.area = area;
        }

        /++
         + Moves the rectangle by a certain offset.
         +
         + Params:
         +  offset = The offset to move by.
         + ++/
        @safe @nogc
        void move(vec2 offset) nothrow
        {
            this._transform.translation += offset;
            this._transform.markDirty();
        }

        /++
         + Returns:
         +  The position of this object.
         + ++/
        @property @safe @nogc
        const(vec2) position() nothrow const
        {
            return this._transform.translation;
        }

        /++
         + Sets the position of the transformable object.
         +
         + Params:
         +  pos = The position to set the object at.
         + ++/
        @property @safe @nogc
        void position(vec2 pos) nothrow
        {
            this._transform.translation = pos;
            this._transform.markDirty();
        }

        /++
         + Sets the rotation of the transformable object.
         +
         + Params:
         +  angle = The rotation to set the object at.
         + ++/
        @property @safe @nogc
        void rotation(AngleDegrees angle) nothrow
        {
            this._transform.rotation = angle;
            this._transform.markDirty();
        }

        /++
         + Sets the scale of the transformable object (default 1).
         +
         + Params:
         +  amount = The amount to scale it by.
         + ++/
        @property @safe @nogc
        void scale(vec2 amount) nothrow
        {
            this._transform.scale = amount;
            this._transform.markDirty();
        }

        /++
         + Returns:
         +  The amount to scale it by.
         + ++/
        @property @safe @nogc
        const(vec2) scale() nothrow const
        {
            return this._transform.scale;
        }

        /++
         + Returns:
         +  The origin of this object.
         + ++/
        @property @safe @nogc
        const(vec2) origin() nothrow const
        {
            return this._transform.origin;
        }

        /++
         + Sets the origin of the transformable object.
         +
         + Params:
         +  point = The point to set the object's origin to.
         + ++/
        @property @safe @nogc
        void origin(vec2 point) nothrow
        {
            this._transform.origin = point;
            this._transform.markDirty();
        }

        /// Returns: The size of this rectangle.
        @property @safe @nogc
        const(vec2) size() nothrow const
        {
            return this._verts[3].position;
        }

        /++
         + Sets the size of this rectangle.
         +
         + Params:
         +  siz = The new size.
         + ++/
        @property @safe @nogc
        void size(vec2 siz) nothrow
        {
            auto posRect = RectangleF(0, 0, siz);
            this._verts[0].position = vec2(0);
            this._verts[1].position = posRect.topRight;
            this._verts[2].position = posRect.botLeft;
            this._verts[3].position = posRect.botRight;

            this.recalcBorderVerts();
        }

        /// Returns: The size of this rectangle's border.
        @property @safe @nogc
        uint borderSize() nothrow const
        {
            return this._borderSize;
        }

        /++
         + Sets the size of this rectangle's border.
         +
         + Params:
         +  siz = The new size;
         + ++/
        @property @safe @nogc
        void borderSize(uint siz) nothrow
        {
            if(this._borderSize == siz)
                return;

            this._borderSize = siz;
            this.recalcBorderVerts();
        }

        /// Return: A `RectangleF` describing the area of this rectangle (not including borders)
        @property @safe @nogc
        const(RectangleF) area() nothrow const
        {
            return RectangleF(this.position, this.size);
        }

        /++
         + Sets the position and size of this rectangle to match the given area.
         +
         + Params:
         +  rect = The area to use.
         + ++/
        @property @safe @nogc
        void area(RectangleF rect) nothrow
        {
            this.position = rect.position;
            this.size     = rect.size;
        }

        /// Returns: The colour of this rectangle (the filling, not the borders)
        @property @safe @nogc
        const(Colour) colour() nothrow const
        {
            return this._verts[0].colour;
        }

        /++
         + Sets the colour of this rectangle (the filling, not the borders)
         +
         + Params:
         +  col = The new colour.
         + ++/
        @property @safe @nogc
        void colour(Colour col) nothrow
        {
            foreach(ref vert; this._verts)
                vert.colour = col;

            this._transform.markDirty();
        }

        /// Returns: The colour of this rectangle's border.
        @property @safe @nogc
        const(Colour) borderColour() nothrow const
        {
            return this._borderVerts[0].colour;
        }

        /++
         + Sets the colour of this rectangle's border.
         +
         + Params:
         +  col = The new colour.
         + ++/
        @property @safe @nogc
        void borderColour(Colour col) nothrow
        {
            foreach(ref vert; this._borderVerts)
                vert.colour = col;

            this._transform.markDirty();
        }

        /// Internal use only.
        /// NOTE: These verts will have the model transform already applied
        /// Also: We peform the model transform on the CPU, so we don't have to pass the data to the GPU
        ///       which would (in my beginner mind) make batching impossible.
        /// Also: When rendering the shape, $(B Call this function first) as this is the only function that
        ///       will transform the verts if the transform is dirty.
        @property @safe @nogc
        Vertex[20] verts() nothrow
        {
            if(this._transform.isDirty)
            {
                this._transformed[$-4..$] = this._verts[0..4];
                this._transformed[0..$-4] = this._borderVerts[0..$];
                this._transform.transformVerts(this._transformed);

                this._cachedVerts = 
                [
                    // Main body
                    this._transformed[$-4],
                    this._transformed[$-3],
                    this._transformed[$-2],
                    this._transformed[$-1],

                    // Left Border
                    this._transformed[0],
                    this._transformed[1],
                    this._transformed[10],
                    this._transformed[11],

                    // Bottom Border
                    this._transformed[8],
                    this._transformed[10],
                    this._transformed[13],
                    this._transformed[15],

                    // Right Border
                    this._transformed[4],
                    this._transformed[5],
                    this._transformed[14],
                    this._transformed[15],

                    // Top Border
                    this._transformed[0],
                    this._transformed[2],
                    this._transformed[5],
                    this._transformed[7]
                ];
            }

            return this._cachedVerts;
        }
    }
}

/// Describes a circle which can be rendered to the screen.
class CircleShape : ITransformable
{
    enum DEFAULT_TRIANGLE_COUNT = 40;
    alias VertBuffer = VertexBuffer!(BufferFeatures.FullUploadSubData);

    private
    {
        Transform     _transform;
        Circle        _area;
        Buffer!Vertex _verts;
        Buffer!Vertex _transformedVerts;
        VertBuffer    _buffer;
        size_t        _triangleCount;
        Colour        _colour;

        @safe
        void recalcVerts()
        {
            import std.math : PI, cos, sin;
            enum TWO_PI = 2.0f * PI;

            this._verts.length = 0;
            this._transformedVerts.length = 0;

            // TODO: Optimise vert usage by using a custom VertexBuffer
            //       instead of letting the renderer do it for us.
            foreach(i; 0..this._triangleCount + 1)
            {
                this._verts ~= Vertex(vec2(0), vec2(0), this._colour);
                this._verts ~= (this._verts.length < 2) ? Vertex(vec2(0), vec2(0), this._colour) : this._verts[$-3];
                this._verts ~= Vertex(
                    vec2(
                        this._area.radius * cos(i * TWO_PI / this._triangleCount),
                        this._area.radius * sin(i * TWO_PI / this._triangleCount)
                    ), 
                    vec2(0), 
                    this._colour
                );
                this._verts ~= Vertex(vec2(0), vec2(0), this._colour);
            }

            this._transformedVerts ~= this._verts[0..$];
        }
    }

    public
    {
        ///
        this(vec2 position, float radius, Colour colour = Colour.red, size_t triangleCount = DEFAULT_TRIANGLE_COUNT)
        {
            this._verts            = new Buffer!Vertex();
            this._transformedVerts = new Buffer!Vertex();
            this._triangleCount    = triangleCount;
            this.position          = position;
            this.radius            = radius;
            this.colour            = colour;
        }

        /// Returns: The radius of this circle.
        @property @safe @nogc
        inout(float) radius() nothrow inout
        {
            return this._area.radius;
        }

        /// Sets the radius of this circle.
        @property @safe
        void radius(float rad)
        {
            this._area.radius = rad;
            this.recalcVerts();
            this._transform.markDirty();
        }

        /++
         + Returns:
         +  The position of this object.
         + ++/
        @property @safe @nogc
        const(vec2) position() nothrow const
        {
            return this._transform.translation;
        }

        /++
         + Sets the position of the transformable object.
         +
         + Params:
         +  pos = The position to set the object at.
         + ++/
        @property @safe @nogc
        void position(vec2 pos) nothrow
        {
            this._area.centerPos = pos;
            this._transform.translation = pos;
            this._transform.markDirty();
        }

        /++
         + Sets the rotation of the transformable object.
         +
         + Params:
         +  angle = The rotation to set the object at.
         + ++/
        @property @safe @nogc
        void rotation(AngleDegrees angle) nothrow
        {
            this._transform.rotation = angle;
            this._transform.markDirty();
        }

        /++
         + Sets the scale of the transformable object (default 1).
         +
         + Params:
         +  amount = The amount to scale it by.
         + ++/
        @property @safe @nogc
        void scale(vec2 amount) nothrow
        {
            this._transform.scale = amount;
            this._transform.markDirty();
        }

        /++
         + Returns:
         +  The amount to scale it by.
         + ++/
        @property @safe @nogc
        const(vec2) scale() nothrow const
        {
            return this._transform.scale;
        }

        /++
         + Returns:
         +  The origin of this object.
         + ++/
        @property @safe @nogc
        const(vec2) origin() nothrow const
        {
            return this._transform.origin;
        }

        /++
         + Sets the origin of the transformable object.
         +
         + Params:
         +  point = The point to set the object's origin to.
         + ++/
        @property @safe @nogc
        void origin(vec2 point) nothrow
        {
            this._transform.origin = point;
            this._transform.markDirty();
        }

        /// Returns: The colour of this rectangle (the filling, not the borders)
        @property @safe @nogc
        const(Colour) colour() nothrow const
        {
            return this._colour;
        }

        /++
         + Sets the colour of this rectangle (the filling, not the borders)
         +
         + Params:
         +  col = The new colour.
         + ++/
        @property @safe @nogc
        void colour(Colour col) nothrow
        {
            foreach(ref vert; this._verts[0..$])
                vert.colour = col;

            foreach(ref vert; this._transformedVerts[0..$])
                vert.colour = col;

            this._colour = col;
            this._transform.markDirty();
        }

        @property
        Vertex[] verts()
        {
            if(this._transform.isDirty)
            {
                this._transformedVerts.length = 0;
                this._transformedVerts ~= this._verts[0..$];
                this._transform.transformVerts(this._transformedVerts[0..$]);
            }

            return this._transformedVerts[0..$];
        }
    }
}