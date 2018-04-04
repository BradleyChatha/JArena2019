module jarena.graphics.shape;

private
{
    import jarena.core, jarena.graphics;
}

class RectangleShape
{
    private
    {
        Transform  _transform;
        Vertex[4]  _verts; // [0]TopLeft|[1]TopRight|[2]BotLeft|[3]BotRight
    }

    public
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
        const(RectangleF) area() nothrow const
        {
            return RectangleF(this.position, this._verts[3].position);
        }

        ///
        @property @safe @nogc
        void area(RectangleF rect) nothrow
        {
            this.position = rect.position;

            auto posRect = RectangleF(0, 0, vec2(rect.size));
            this._verts[0].position = vec2(0);
            this._verts[1].position = posRect.topRight;
            this._verts[2].position = posRect.botLeft;
            this._verts[3].position = posRect.botRight;
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

        /// Internal use only.
        /// NOTE: These verts will have the model transform already applied
        /// Also: We peform the model transform on the CPU, so we don't have to pass the data to the GPU
        ///       which would (in my beginner mind) make batching impossible.
        @property @safe @nogc
        Vertex[4] verts() nothrow
        {
            Vertex[4] toReturn = this._verts;
            foreach(ref vert; toReturn)
                vert.position = vec2(this._transform.matrix * vec4(vert.position, 0, 1.0));

            return toReturn;
        }
    }
}