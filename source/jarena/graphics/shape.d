module jarena.graphics.shape;

private
{
    import jarena.core, jarena.graphics;
}

class RectangleShape
{
    private final
    {
        Transform    _transform;
        uint         _borderSize;
        Vertex[4]    _verts; // [0]TopLeft|[1]TopRight|[2]BotLeft|[3]BotRight
        Vertex[4*4]  _borderVerts; // [Per corner][0]TopLeft|[1]TopRight|[2]BotLeft|[3]BotRight
                                   // [0..4] = Top Left Corner|[4..8]TopRight|[8..12]BotLeft|[12..16]BotRight

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
        }
    }

    public final
    {
        ///
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

        ///
        @safe @nogc
        void move(vec2 offset) nothrow
        {
            this._transform.translation += offset;
            this._transform.markDirty();
        }

        ///
        @property @safe @nogc
        const(vec2) position() nothrow const
        {
            return this._transform.translation;
        }

        ///
        @property @safe @nogc
        void position(vec2 pos) nothrow
        {
            this._transform.translation = pos;
            this._transform.markDirty();
        }

        ///
        @property @safe @nogc
        const(vec2) size() nothrow const
        {
            return this._verts[3].position;
        }

        ///
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

        ///
        @property @safe @nogc
        uint borderSize() nothrow const
        {
            return this._borderSize;
        }

        ///
        @property @safe @nogc
        void borderSize(uint siz) nothrow
        {
            if(this._borderSize == siz)
                return;

            this._borderSize = siz;
            this.recalcBorderVerts();
        }

        ///
        @property @safe @nogc
        const(RectangleF) area() nothrow const
        {
            return RectangleF(this.position, this.size);
        }

        ///
        @property @safe @nogc
        void area(RectangleF rect) nothrow
        {
            this.position = rect.position;
            this.size     = rect.size;
        }

        ///
        @property @safe @nogc
        const(Colour) colour() nothrow const
        {
            return this._verts[0].colour;
        }

        ///
        @property @safe @nogc
        void colour(Colour col) nothrow
        {
            foreach(ref vert; this._verts)
                vert.colour = col;
        }

        ///
        @property @safe @nogc
        const(Colour) borderColour() nothrow const
        {
            return this._borderVerts[0].colour;
        }

        ///
        @property @safe @nogc
        void borderColour(Colour col) nothrow
        {
            foreach(ref vert; this._borderVerts)
                vert.colour = col;
        }

        /// Internal use only.
        /// NOTE: These verts will have the model transform already applied
        /// Also: We peform the model transform on the CPU, so we don't have to pass the data to the GPU
        ///       which would (in my beginner mind) make batching impossible.
        @property @safe @nogc
        Vertex[4] verts() nothrow
        {
            Vertex[4] toReturn = this._verts;
            this._transform.transformVerts(toReturn[]);

            return toReturn;
        }

        /// ditto
        @property @safe @nogc
        Vertex[4] borderLeftVerts() nothrow
        {
            Vertex[4] toReturn = 
            [
                this._borderVerts[0..4][0],
                this._borderVerts[0..4][1],
                this._borderVerts[8..12][2],
                this._borderVerts[8..12][3]
            ];
            this._transform.transformVerts(toReturn[]);

            return toReturn;
        }

        /// ditto
        @property @safe @nogc
        Vertex[4] borderBottomVerts() nothrow
        {
            Vertex[4] toReturn = 
            [
                this._borderVerts[8..12][0],
                this._borderVerts[8..12][2],
                this._borderVerts[12..16][1],
                this._borderVerts[12..16][3]
            ];
            this._transform.transformVerts(toReturn[]);

            return toReturn;
        }

        /// ditto
        @property @safe @nogc
        Vertex[4] borderRightVerts() nothrow
        {
            Vertex[4] toReturn = 
            [
                this._borderVerts[4..8][0],
                this._borderVerts[4..8][1],
                this._borderVerts[12..16][2],
                this._borderVerts[12..16][3]
            ];
            this._transform.transformVerts(toReturn[]);

            return toReturn;
        }

        /// ditto
        @property @safe @nogc
        Vertex[4] borderTopVerts() nothrow
        {
            Vertex[4] toReturn = 
            [
                this._borderVerts[0..4][0],
                this._borderVerts[0..4][2],
                this._borderVerts[4..8][1],
                this._borderVerts[4..8][3]
            ];
            this._transform.transformVerts(toReturn[]);

            return toReturn;
        }
    }
}