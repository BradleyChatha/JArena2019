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
        uint stride = cast(uint)Vertex.sizeof; // Normally size_t, but we know we won't ever exceed uint in size
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
    Static  = GL_STATIC_DRAW,
    Dynamic = GL_DYNAMIC_DRAW
}

struct VertexBuffer
{
    private
    {
        uint _vao;
        uint _vbo;
        uint _ebo;
        BufferDataType _dataType;
        BufferDrawType _drawType;

        @nogc
        private void free() nothrow
        {
            glDeleteVertexArrays(1, &this._vao);
            glDeleteBuffers(1, &this._vbo);
            glDeleteBuffers(1, &this._ebo);
        }
    }
    
    public
    {
        Vertex[] verts;
        uint[]  indicies;
        alias verts this;

        /// This type cannot be copied, use `ref` or put it on the heap if needed.
        @disable
        this(this){}

        ~this()
        {
            if(this._vbo > 0)
                this.free();
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
            glBufferData(GL_ARRAY_BUFFER, (Vertex.sizeof * this.verts.length), &this.verts[0], this._drawType);

            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, this._ebo);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, (uint.sizeof * this.indicies.length), &this.indicies[0], this._drawType);
        }
        
        /++
         + Call this to prepare this buffer for actual use.
         + ++/
        @nogc
        void setup(BufferDataType dataType  = BufferDataType.Triangles,
                   BufferDrawType drawType  = BufferDrawType.Dynamic
                  ) nothrow
        {
            // In case this buffer already has been setup.
            if(this._vbo > 0)
                this.free();
                
            // Set our variables
            this._dataType = dataType;
            this._drawType = drawType;

            // Generate the objects
            glGenVertexArrays(1, &this._vao);
            glGenBuffers(1, &this._vbo);
            glGenBuffers(1, &this._ebo);

            // Bind the objects
            glBindVertexArray(this._vao);
            glBindBuffer(GL_ARRAY_BUFFER, this._vbo);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, this._ebo);

            Vertex.setupAtrribPointers();

            // Unbind things
            glBindBuffer(GL_ARRAY_BUFFER, 0);
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
