/++
 + Contains the definition of a JArena Vertex, as well as a VertexBufferObject.
 + ++/
module jarena.graphics.vertex;

private
{
    import std.traits;
    import jarena.core, jarena.graphics, jarena.maths;
    import opengl;
}

/// Defines a Vertex.
struct Vertex
{
    /// The position (in pixels for most cases, from the top-left)
    vec2   position;

    /// The texture position (in pixels for most cases, from the top-left)
    vec2   uv;

    /// The colour
    Colour colour;
}

/++
 + The kind of primitive type that the verticies in a buffer store.
 +
 + Notes:
 +  The values of this enum are meant to be passed to functions such as
 +  `glDrawElements` and `glDrawArrays`.
 + ++/
enum VertexDataType : GLenum
{
    /// Every 3 verticies represents a single triangle.
    Triangles = GL_TRIANGLES
}

/// Determines if the given type is a `VertexBufferObject`.
enum isVertexBufferObject(T) = isInstanceOf!(VertexBufferObject, T);

/++
 + A wrapper around an OpenGL VAO/VBO/EBO combo.
 +
 + Usage(FullUpload):
 +  First, call `VertexBufferObject.setup` before the first usage of a buffer.
 +
 +  Second, set what your verticies are in `VertexBufferObject.verts`.
 +
 +  Third, set the indicies in `VertexBufferObject.indicies`.
 +
 +  Fourth, call `VertexBufferObject.upload` to update the VBO with the data in `VertexBufferObject.verts`,
 +  and to update the EBO with the indicies in `VertexBufferObject.indicies`.
 +
 +  Finally, bind the `VertexBufferObject.vao` (or whichever is needed for the certain case) and
 +  call something like `glDrawElements`. Alternatively, use `Renderer.drawBuffer`.
 +
 + Notes:
 +  This struct will automatically setup and enable the vertex attribute pointers
 +  based on what data `VertexT` holds. Currently, there is no way to override this.
 +
 +  This struct is essentially a higher level wrapper around a VAO, and two `BufferObjects` for the VBO and EBO.
 + ++/
struct VertexBufferObject(VertexT, BufferFeatures features)
if(isType!VertexT)
{
    ///
    alias Features = features;

    ///
    alias VertexType = VertexT;

    ///
    alias MapFunc = void delegate(scope VertexT[] vboData, scope uint[] eboData);

    private
    {
        uint _vao;
        VertexDataType _dataType;
        BufferObject!(Vertex, GL_ARRAY_BUFFER,         features) _vbo;
        BufferObject!(uint,   GL_ELEMENT_ARRAY_BUFFER, features) _ebo;

        @nogc
        void free() nothrow
        {
            glDeleteVertexArrays(1, &this._vao);
            this._vbo.free();
            this._ebo.free();
        }
    }
    
    public
    {
        ~this()
        {
            if(this._vao > 0)
                this.free();
        }

        static if(Features & BufferFeatures.FullUpload || Features & BufferFeatures.FullUploadSubData)
        {
           /++
            + Uploads the buffer's VBO and EBO (GPU side) to reflect the current data in `verts` and 'indicies' (CPU[kinda, I guess] side).
            +
            + Notes:
            +  This function is only enabled with `BufferFeatures.FullUpload` or `BufferFeatures.FullUploadSubData`.
            +
            +  This function $(B must) be called for any changes made to `verts` and `indicies` to become visible
            +  on the GPU side of things.
            +
            +  The buffers are left bound afterwards.
            +
            + FullUpload:
            +  If `BufferFeatures.FullUpload` is used, then `glBufferData` is used to update both the VBO and EBO, meaning that the GPU will allocate
            +  a new chunk of memory for the new data, and that the data will be uploaded all at once. These two things
            +  together can cause a slowdown if used too often, with too much data.
            +
            + FullUploadSubData:
            +  If `BufferFeatures.FullUploadSubData` is used, then the VBO and EBO (on the GPU) is made a larger size, and
            +  `glBufferSubData` is used to upload the data. The size of the VBO is changed using `glBufferData` where the size
            +  is (previousSize * 2) or the size of the `VertexBufferObject.verts`/`VertexBufferObject.indicies` array, whichever is bigger.
            +
            +  When data needs to be uploaded, but the buffer itself doesn't need to resize, then `glBufferSubData` is used to
            +  upload the data into the start of the VBO and EBO. This means we can reuse the memory that OpenGL has already
            +  allocated for us, saving the cost of allocation. However this still has the issue of the verticies and indicies both being
            +  uploaded all at once, which will cause a slowdown with big datasets. Do note that the old data may not be completely
            +  overridden, so make sure your `VertexBufferObject.indicies` doesn't directly point to them.
            + ++/
            void upload()
            {
                this._vbo.upload();
                this._ebo.upload();
            }

            @property @safe @nogc
            ref inout(Vertex[]) verts() nothrow inout
            {
                return this._vbo.data;
            }

            @property @safe @nogc
            ref inout(uint[]) indicies() nothrow inout
            {
                return this._ebo.data;
            }
        }

        /++
         + Maps the EBO and VBO data (using `glMapBuffer`), slices them so they're D-friendly, and then passes
         + the slices into the given function which can read/write to the slices as wanted.
         +
         + The changes made to the data in the slices will be uploaded into the GPU(At least that's what I think mapping does).
         +
         + Notes:
         +  Of course, appending to these slices will cause them to be allocated into a new array, since
         +  these aren't GC-owned pointers. (among other things)
         +
         + Params:
         +  mapFunc = The function that is applied to the mapped data.
         + ++/
        static if(Features & BufferFeatures.CanMapBuffers)
        void applyMapFunc(BufferMapFlags flags, scope MapFunc mapFunc)
        {
            assert(false, "Not implemented");
        }

        /++
         + Uploads the given data to a portion of the VBO/EBO.
         +
         + Notes:
         +  The buffer being uploaded to is determined by `T`, which can be one of either
         +  `VertexT` (For the VBO) and `uint` (For the EBO).
         +
         +  This function does not support resizing the buffer, and will fail an assert when
         +  an attempt to write past it is made.
         +
         + Params:
         +  start = The start offset to start writing to.
         +  data  = The data to write, the amount to write is determined by the slice's length.
         + ++/
        static if(Features & BufferFeatures.PartialUploadSubData)
        void subUpload(T)(const size_t start, T[] data)
        if(is(T == VertexT) || is(T == uint))
        {
            static if(is(T == VertexT))
                this._vbo.subUpload(start, data);
            else
                this._ebo.subUpload(start, data);
        }
        
        /++
         + Call this to prepare this buffer for actual use.
         + ++/
        void setup(VertexDataType  dataType  = VertexDataType.Triangles,
                   BufferUsageType useType   = BufferUsageType.DynamicDraw
                  )
        {                
            // Set our variables
            this._dataType = dataType;

            // Generate the objects
            glGenVertexArrays(1, &this._vao);
            glBindVertexArray(this._vao);

            this._vbo.setup(useType);
            this._ebo.setup(useType);

            // Setup the vertex attribs.
            uint attribCount = 0;
            static foreach(field; VertexT.tupleof)
            {{
                alias FType = typeof(field);

                static if(!isSomeFunction!FType)
                {
                    // Data that needs to be set per type.
                    int    size;
                    GLenum type;
                    bool   normalised;
                    uint   stride = VertexT.sizeof;
                    uint   offset = field.offsetof;

                    // Set the data depending on the type.
                    static if(is(FType == vec2))
                    {
                        size       = 2;
                        type       = GL_FLOAT;
                        normalised = false;
                    }
                    else static if(is(FType == Colour))
                    {
                        size       = 4;
                        type       = GL_UNSIGNED_BYTE;
                        normalised = true;
                    }
                    else static assert(false, "Unsupported vertex data type: " ~ FType.stringof);

                    glVertexAttribPointer(attribCount, size, type, normalised, stride, cast(void*)offset);
                    glEnableVertexAttribArray(attribCount++);
                }
            }}

            // Unbind things
            glBindBuffer(GL_ARRAY_BUFFER, 0);
            GL.checkForError();
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
            return this._vbo.handle;
        }

        /// Returns: The name of this buffer's EBO
        @property @safe @nogc
        uint ebo() nothrow const
        {
            return this._ebo.handle;
        }

        /// Returns: The `VertexDataType` of this buffer.
        @property @safe @nogc
        VertexDataType dataType() nothrow const
        {
            return this._dataType;
        }

        /// Returns: The `BufferUsageType` of this buffer.
        @property @safe @nogc
        BufferUsageType useType() nothrow const
        {
            return this._vbo.useType;
        }

        static if(typeof(_vbo).HasBufferSizes)
        {
            /// Returns: The size, in bytes, of the VBO's data.
            @property @safe @nogc
            size_t vboSizeBytes() nothrow const
            {
                return this._vbo.dataSizeBytes;
            }

            /// Returns: The size, in bytes, of the EBO's data.
            @property @safe @nogc
            size_t eboSizeBytes() nothrow const
            {
                return this._ebo.dataSizeBytes;
            }
        }

        static if(Features & BufferFeatures.MutableSize
               || Features & BufferFeatures.MutableSizeNoCopy)
        {
            /++
             + Sets the size of the VBO's data, in bytes
             +
             + Notes:
             +  Changing the size requires that the current data in the VBO is copied from the GPU into a temp buffer,
             +  the VBO being given a new chunk of data for the size, and then the old data being copied back over.
             +
             +  If the size is lower than before, the trailing data is simply left out.
             +
             +  Data copying can be disabled entirely by using `BufferFeatures.MutableSizeNoCopy` instead. However,
             +  that means all the data must be copied over as the buffer will be filled with whatever the driver decides
             +  (which is probably whatever was being used in that memory beforehand).
             +
             + Params:
             +  newSize = The new size of the VBO's data.
             + ++/
            @property
            void vboSizeBytes(size_t newSize)
            {
                this._vbo.dataSizeBytes = newSize;
            }

            /// ditto
            @property
            void eboSizeBytes(size_t newSize)
            {
                this._ebo.dataSizeBytes = newSize;
            }
        }
    }
}

/// A `VertexBufferObject` for the basic `Vertex` struct.
alias VertexBuffer(BufferFeatures features) = VertexBufferObject!(Vertex, features);