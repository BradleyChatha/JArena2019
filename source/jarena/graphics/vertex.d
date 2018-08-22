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
 + Defines what different features the buffer is capable of doing.
 +
 + These flags can be ORed together to create custom buffers.
 +
 + The reason that capabilities have to be specified is because the user can then well-define how
 + the buffer is supposed to be used, instead of it having 200 different ways to do things and the user
 + having no clue which ones are being used (hard to debug).
 + ++/
enum BufferFeatures : uint
{
    /++
     + Enables the `VertexBuffer.upload` function, as well as the `VertexBuffer.verts` and
     + `VertexBuffer.indicies` variables.
     +
     + This is useful for buffers that require their entire set of data to be updated.
     + ++/
    FullUpload = 1 << 0,

    /++
     + Almost identicle to `FullUpload`, except that it changes the way that 
     + `VertexBuffer.upload` manages the buffer's data. (see it's documentation for details).
     +
     + Mutually Exclusive:
     +  `BufferFeatures.FullUpload`
     + ++/
    FullUploadSubData = 1 << 1,

    /++
     + Enables the user to be able to manually change the size of the buffer's data.
     +
     + May have strange interactions with other functions that change the data's length.
     + ++/
    MutableSize = 1 << 2,

    /++
     + Same as `MutableSize`, but this disables copying of the old data once the buffer is resized.
     + ++/
    MutableSizeNoCopy = 1 << 3,

    /++
     + Enables the `VertexBuffer.applyMapFunc` function.
     +
     + This is useful for code that requires more precise control of how data is uploaded to the GPU.
     + ++/
    CanMapBuffers = 1 << 4,

    /++
     + Enables the `VertexBuffer.subUpload` function, which is safe wrapper around
     + the glSubBufferData function.
     +
     + This is useful for cases where only a certain buffer/section needs to be updated, instead of the entire thing.
     + ++/
    PartialUploadSubData = 1 << 5
}

/// Determines if the given type is a `VertexBuffer`.
enum isVertexBuffer(T) = isInstanceOf!(VertexBuffer, T);

/++
 + A wrapper around an OpenGL VAO/VBO/EBO combo.
 +
 + Usage(FullUpload):
 +  First, call `VertexBuffer.setup` before the first usage of a buffer.
 +
 +  Second, set what your verticies are in `VertexBuffer.verts`.
 +
 +  Third, set the indicies in `VertexBuffer.indicies`.
 +
 +  Fourth, call `VertexBuffer.upload` to update the VBO with the data in `VertexBuffer.verts`,
 +  and to update the EBO with the indicies in `VertexBuffer.indicies`.
 +
 +  Finally, bind the `VertexBuffer.vao` (or whichever is needed for the certain case) and
 +  call something like `glDrawElements`. Alternatively, use `Renderer.drawBuffer`.
 + ++/
struct VertexBuffer(BufferFeatures features)
{
    ///
    alias Features = features;

    ///
    alias MapFunc = void delegate(scope Vertex[] vboData, scope uint[] eboData);

    mixin(mutuallyExclusive([
        BufferFeatures.FullUploadSubData: [BufferFeatures.FullUpload],
        BufferFeatures.MutableSizeNoCopy: [BufferFeatures.MutableSize]
    ]));

    // Set some flags
    static if(Features & BufferFeatures.FullUploadSubData
           || Features & BufferFeatures.MutableSize
           || Features & BufferFeatures.MutableSizeNoCopy
           || Features & BufferFeatures.CanMapBuffers
           || Features & BufferFeatures.PartialUploadSubData)
    {
        enum HasBufferSizes = true;
    }
    else
    {
        enum HasBufferSizes = false;
    }

    private
    {
        uint _vao;
        uint _vbo;
        uint _ebo;
        BufferDataType _dataType;
        BufferDrawType _drawType;

        static if(HasBufferSizes)
        {
            // Both are in bytes.
            size_t _vboSize;
            size_t _eboSize;
        }

        @nogc
        void free() nothrow
        {
            glDeleteVertexArrays(1, &this._vao);
            glDeleteBuffers(1, &this._vbo);
            glDeleteBuffers(1, &this._ebo);
        }

        static dstring mutuallyExclusive(BufferFeatures[][BufferFeatures] exlusivity)
        {
            import codebuilder;
            auto builder = new CodeBuilder();
            foreach(feature, exclusiveWith; exlusivity)
            {
                foreach(exclusiveFeature; exclusiveWith)
                {
                    builder.putf("static assert(!((Features & BufferFeatures.%s) && (Features & BufferFeatures.%s)), `BufferFeatures.%s cannot be used alongside BufferFeatures.%s`);",
                                 feature, exclusiveFeature, feature, exclusiveFeature);
                }
            }
            return builder.data.idup;
        }
    }
    
    public
    {
        static if(Features & BufferFeatures.FullUpload || Features & BufferFeatures.FullUploadSubData)
        {
            /// The verticies contained in this buffer.
            Vertex[] verts;

            /// The indicies contained in this buffer.
            uint[]   indicies;
        }

        /// This type cannot be copied, use `ref` or put it on the heap if needed.
        @disable
        this(this){}

        ~this()
        {
            if(this._vbo > 0)
                this.free();
        }

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
         +  is (previousSize * 2) or the size of the `VertexBuffer.verts`/`VertexBuffer.indicies` array, whichever is bigger.
         +
         +  When data needs to be uploaded, but the buffer itself doesn't need to resize, then `glBufferSubData` is used to
         +  upload the data into the start of the VBO and EBO. This means we can reuse the memory that OpenGL has already
         +  allocated for us, saving the cost of allocation. However this still has the issue of the verticies and indicies both being
         +  uploaded all at once, which will cause a slowdown with big datasets. Do note that the old data may not be completely
         +  overridden, so make sure your `VertexBuffer.indicies` doesn't directly point to them.
         + ++/
        static if(Features & BufferFeatures.FullUpload)
        void upload()
        {
            glBindBuffer(GL_ARRAY_BUFFER, this._vbo);
            glBufferData(GL_ARRAY_BUFFER, (Vertex.sizeof * this.verts.length), &this.verts[0], this._drawType);

            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, this._ebo);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, (uint.sizeof * this.indicies.length), &this.indicies[0], this._drawType);

            static if(HasBufferSizes)
            {
                this._vboSize = (Vertex.sizeof * this.verts.length);
                this._eboSize = (uint.sizeof * this.indicies.length);
            }
        }

        /// ditto
        static if(Features & BufferFeatures.FullUploadSubData)
        void upload()
        {
            static void uploadBuffer(uint bufferName, GLenum bufferType, BufferDrawType drawType, void[] toUpload, ref size_t currentSize)
            {
                glBindBuffer(bufferType, bufferName);
                
                // Note: void[].length is in bytes
                if(toUpload.length > currentSize)
                {
                    currentSize = toUpload.length;
                    glBufferData(bufferType, toUpload.length, &toUpload[0], drawType);
                }
                else
                {
                    glBufferSubData(bufferType, 0, toUpload.length, &toUpload[0]);
                }
            }

            uploadBuffer(this._vbo, GL_ARRAY_BUFFER,         this._drawType, this.verts,    this._vboSize);
            uploadBuffer(this._ebo, GL_ELEMENT_ARRAY_BUFFER, this._drawType, this.indicies, this._eboSize);

            GL.checkForError();
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
        void applyMapFunc(scope MapFunc mapFunc)
        {
            glBindBuffer(GL_ARRAY_BUFFER, this._vbo);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, this._ebo);

            auto vboData = (cast(Vertex*)glMapBuffer(GL_ARRAY_BUFFER, GL_READ_WRITE))[0..this._vboSize / Vertex.sizeof];
            auto eboData = (cast(uint*)glMapBuffer(GL_ELEMENT_ARRAY_BUFFER, GL_READ_WRITE))[0..this._eboSize / uint.sizeof];

            scope(exit)
            {
                glUnmapBuffer(GL_ARRAY_BUFFER);
                glUnmapBuffer(GL_ELEMENT_ARRAY_BUFFER);
                GL.checkForError();
            }

            mapFunc(vboData, eboData);
        }

        /++
         + Uploads the given data to a portion of the VBO/EBO.
         +
         + Notes:
         +  The buffer being uploaded to is determined by `T`, which can be one of either
         +  `Vertex` (For the VBO) and `uint` (For the EBO).
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
        if(is(T == Vertex) || is(T == uint))
        {
            // Set some of the variables we need.
            static if(is(T == Vertex))
            {
                auto bufferType = GL_ARRAY_BUFFER;
                auto bufferName = this._vbo;
                auto bufferSize = this._vboSize; // In bytes
            }
            else
            {
                auto bufferType = GL_ELEMENT_ARRAY_BUFFER;
                auto bufferName = this._ebo;
                auto bufferSize = this._eboSize;
            }

            if(data.length == 0)
                return;

            // Make sure we're in range
            auto dataSizeBytes = (T.sizeof * data.length);
            auto startInBytes  = (T.sizeof * start);
            if((startInBytes + dataSizeBytes) > bufferSize)
            {
                import std.format;
                assert(false, format("Attmpted to write outside of the vertex buffer.\n"
                              ~ "Start: %s (%s b) | Data: %s (%s b) | Buffer: %s b",
                                start, startInBytes, data.length, dataSizeBytes, bufferSize));
            }

            // Then upload the data
            glBindBuffer(bufferType, bufferName);
            glBufferSubData(bufferType, startInBytes, dataSizeBytes, &data[0]);
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

        static if(HasBufferSizes)
        {
            /// Returns: The size, in bytes, of the VBO's data.
            @property @safe @nogc
            size_t vboSize() nothrow const
            {
                return this._vboSize;
            }

            /// Returns: The size, in bytes, of the EBO's data.
            @property @safe @nogc
            size_t eboSize() nothrow const
            {
                return this._eboSize;
            }
        }

        static if(Features & BufferFeatures.MutableSize
               || Features & BufferFeatures.MutableSizeNoCopy)
        {
            private void resizeBuffer(uint bufferName, GLenum bufferType, size_t newSize, ref size_t oldSize)
            {
                glBindBuffer(bufferType, bufferName);

                // Copy the old data.
                static if(Features & BufferFeatures.MutableSize)
                {
                    ubyte[] vboCopy;
                    vboCopy.length = oldSize;

                    if(vboCopy.length > 0)
                        glGetBufferSubData(bufferType, 0, vboCopy.length, &vboCopy[0]); 
                }

                // Give the buffer a new size.
                glBufferData(bufferType, cast(uint)newSize, null, this.drawType);
                oldSize = newSize;

                // Copy the data back over.
                static if(Features & BufferFeatures.MutableSize)
                {
                    if(vboCopy.length > 0)
                        glBufferSubData(bufferType, 0, (newSize < vboCopy.length) ? newSize : vboCopy.length, &vboCopy[0]);
                }

                GL.checkForError();
            }

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
            void vboSize(size_t newSize)
            {
                assert(newSize <= uint.max, "OpenGL doesn't seem to support anything bigger than uint.");
                if(newSize % Vertex.sizeof != 0)
                    assert(false, "Mis-aligned size.");

                this.resizeBuffer(this._vbo, GL_ARRAY_BUFFER, newSize, this._vboSize);
            }

            /// ditto
            @property
            void eboSize(size_t newSize)
            {
                assert(newSize <= uint.max, "OpenGL doesn't seem to support anything bigger than uint.");
                if(newSize % uint.sizeof != 0)
                    assert(false, "Mis-aligned size.");

                this.resizeBuffer(this._ebo, GL_ELEMENT_ARRAY_BUFFER, newSize, this._eboSize);
            }
        }
    }
}
