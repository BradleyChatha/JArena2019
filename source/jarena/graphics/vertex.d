module jarena.graphics.vertex;

private
{
    import std.traits;
    import jarena.core, jarena.graphics;
    import opengl;
}

struct Vertex
{
    vec2   position;
    vec2   uv;
    Colour colour; // Internally: ubyte[4]

    /++
     + Calls `glVertexAttribPointer` to setup the attributes of a vertex array.
     +
     + $(B Only) call this during the creation of a new VAO/VBO that contain only Verticies of this type.
     +
     + As a note, it also enables the attributes.
     + ++/
    @nogc
    static void setupAtrribPointers() nothrow
    {
        auto stride = Vertex.sizeof;
        glVertexAttribPointer(0, 2, GL_FLOAT,         GL_FALSE, stride, null);
        glVertexAttribPointer(1, 2, GL_FLOAT,         GL_FALSE, stride, cast(void*)(2 * float.sizeof));
        glVertexAttribPointer(2, 4, GL_UNSIGNED_BYTE, GL_TRUE,  stride, cast(void*)(4 * float.sizeof)); // GL_TRUE means 128 = 0.5, 255 = 1.0f, etc. automatically

        foreach(i; 0..3)
            glEnableVertexAttribArray(i);
    }
}

enum BufferDataType : GLenum
{
    Triangles = GL_TRIANGLES
}

enum BufferDrawType : GLenum
{
    Static = GL_STATIC_DRAW
}

enum isFixedVertexBuffer(T) = isInstanceOf!(FixedVertexBuffer, T);
struct FixedVertexBuffer(size_t vertCount, size_t indexCount)
{
    private
    {
        uint _vao;
        uint _vbo;
        uint _ebo;
        BufferDataType _dataType;
        BufferDrawType _drawType;
    }
    
    public
    {
        Vertex[vertCount] verts;
        uint[indexCount]  indicies;
        alias verts this;

        /// This type cannot be copied, use `ref` or put it on the heap if needed.
        @disable
        this(this){}

        ~this()
        {
            if(this._vbo > 0)
            {
                glDeleteVertexArrays(1, &this._vao);
                glDeleteBuffers(1, &this._vbo);
                glDeleteBuffers(1, &this._ebo);
            }
        }

        /++
         + Updates the buffer's VBO to reflect the current data in `verts` and 'indicies'.
         +
         + Notes:
         +  This function $(B must) be called for any changes made to `verts` and `indicies` to become visible.
         + ++/
        @nogc
        void update() nothrow
        {
            glBindBuffer(GL_ARRAY_BUFFER, this._vbo);
            glBufferData(GL_ARRAY_BUFFER, (Vertex.sizeof * vertCount), &this.verts[0], this._drawType);

            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, this._ebo);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, (uint.sizeof * indexCount), &this.indicies[0], this._drawType);
        }
        
        /++
         + Call this to prepare this buffer for actual use.
         + ++/
        @nogc
        void setup(
                   Vertex[vertCount] vertData  = typeof(verts).init,
                   uint[indexCount]  indexData = typeof(indicies).init,
                   BufferDataType     dataType  = BufferDataType.Triangles,
                   BufferDrawType     drawType  = BufferDrawType.Static
                  ) nothrow
        {
            // Set our variables
            this._dataType = dataType;
            this._drawType = drawType;
            this.verts     = vertData;
            this.indicies  = indexData;

            // Generate the objects
            glGenVertexArrays(1, &this._vao);
            glGenBuffers(1, &this._vbo);
            glGenBuffers(1, &this._ebo);

            // Bind the VAO
            glBindVertexArray(this._vao);

            // Update the data in our VBO and EBO (they are left bound afterwards)
            this.update();

            Vertex.setupAtrribPointers();

            // Unbind things
            glBindVertexArray(0);
            glBindBuffer(GL_ARRAY_BUFFER, 0);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        }

        @property @safe @nogc
        uint vao() nothrow const
        {
            return this._vao;
        }

        @property @safe @nogc
        uint vbo() nothrow const
        {
            return this._vbo;
        }

        @property @safe @nogc
        uint ebo() nothrow const
        {
            return this._ebo;
        }

        @property @safe @nogc
        BufferDataType dataType() nothrow const
        {
            return this._dataType;
        }

        @property @safe @nogc
        BufferDrawType drawType() nothrow const
        {
            return this._drawType;
        }
    }
}
