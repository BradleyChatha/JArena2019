/++
 + Contains the definition of a JArena vertex, as well as a VertexBuffer.
 + ++/
module jarena.graphics.vertex;

private
{
    import std.traits;
    import jarena.core, jarena.graphics;
    import opengl;
}

/// Defines a vertex.
struct Vertex
{
    /// The position (in pixels for most cases, from the top-left)
    vec2   position;

    /// The texture position (in pixels for most cases, from the top-left)
    vec2   uv;

    /// The colour
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

/++
 + The kind of primitive type that the verticies in a buffer store.
 +
 + Notes:
 +  The values of this enum are meant to be passed to functions such as
 +  `glDrawElements` and `glDrawArrays`.
 + ++/
enum BufferDataType : GLenum
{
    /// Every 3 verticies represents a single triangle.
    Triangles = GL_TRIANGLES
}

/++
 + Defines how often the data in a buffer changes.
 +
 + Notes:
 +  While it's unlikely to be used directly outside of buffers, these values are meant
 +  for use with functions such as `glBufferData`.
 + ++/
enum BufferDrawType : GLenum
{
    /// The data doesn't change often.
    Static  = GL_STATIC_DRAW,

    /// The data will probably change every frame/very often.
    Dynamic = GL_DYNAMIC_DRAW
}

/++
 + A wrapper around an OpenGL VAO/VBO/EBO combo.
 +
 + Usage:
 +  First, call `VertexBuffer.setup` before the first usage of a buffer.
 +
 +  Second, set what your verticies are in `VertexBuffer.verts`.
 +
 +  Third, set the indicies in `VertexBuffer.indicies`.
 +
 +  Fourth, call `VertexBuffer.update` to update the VBO with the data in `VertexBuffer.verts`,
 +  and to update the EBO with the indicies in `VertexBuffer.indicies`.
 +
 +  Finally, bind the `VertexBuffer.vao` (or whichever is needed for the certain case) and
 +  call something like `glDrawElements`. Alternatively, use `Renderer.drawBuffer`.
 + ++/
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
        void free() nothrow
        {
            glDeleteVertexArrays(1, &this._vao);
            glDeleteBuffers(1, &this._vbo);
            glDeleteBuffers(1, &this._ebo);
        }
    }
    
    public
    {
        /// The verticies contained in this buffer.
        Vertex[] verts;

        /// The indicies contained in this buffer.
        uint[]   indicies;

        /// This type cannot be copied, use `ref` or put it on the heap if needed.
        @disable
        this(this){}

        ~this()
        {
            if(this._vbo > 0)
                this.free();
        }

        /++
         + Updates the buffer's VBO and EBO to reflect the current data in `verts` and 'indicies'.
         +
         + Notes:
         +  This function $(B must) be called for any changes made to `verts` and `indicies` to become visible
         +  on the GPU side of things.
         +
         +  The buffers are left bound afterwards.
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

        /// Returns: The name of this buffer's VAO
        @property @safe @nogc
        uint vao() nothrow const
        {
            return this._vao;
        }

        /// Returns: The name of this buffer's VBO
        @property @safe @nogc
        uint vbo() nothrow const
        {
            return this._vbo;
        }

        /// Returns: The name of this buffer's EBO
        @property @safe @nogc
        uint ebo() nothrow const
        {
            return this._ebo;
        }

        /// Returns: The `BufferDataType` of this buffer.
        @property @safe @nogc
        BufferDataType dataType() nothrow const
        {
            return this._dataType;
        }

        /// Returns: The `BufferDrawType` of this buffer.
        @property @safe @nogc
        BufferDrawType drawType() nothrow const
        {
            return this._drawType;
        }
    }
}
