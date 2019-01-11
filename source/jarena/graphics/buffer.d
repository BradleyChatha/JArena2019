module jarena.graphics.buffer;

private
{
    import std.traits;
    import jarena.core, jarena.graphics, jarena.maths;
    import opengl;
}

/++
 + Defines what kind of usage the buffer is for.
 +
 + This is provided during the setup of a buffer.
 + ++/
enum BufferUsageType : GLenum
{
    /// The data doesn't change often, and is used for drawing.
    StaticDraw  = GL_STATIC_DRAW,

    /// The data will probably change every frame/very often, and is used for drawing.
    DynamicDraw = GL_DYNAMIC_DRAW
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
     + Enables the `BufferObject.upload` function, as well as the `BufferObject.data` variable.
     +
     + This is useful for buffers that require their entire set of data to be updated.
     + ++/
    FullUpload = 1 << 0,

    /++
     + Almost identicle to `FullUpload`, except that it changes the way that 
     + `BufferObject.upload` manages the buffer's data. (see it's documentation for details).
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
     + Enables the `BufferObject.applyMapFunc` function.
     +
     + This is useful for code that requires more precise control of how data is uploaded to the GPU.
     + ++/
    CanMapBuffers = 1 << 4,

    /++
     + Enables the `BufferObject.subUpload` function, which is safe wrapper around
     + the glSubBufferData function.
     +
     + This is useful for cases where only a certain buffer/section needs to be updated, instead of the entire thing.
     + ++/
    PartialUploadSubData = 1 << 5
}

/// Flags for `BufferObject.applyMapFunc`.
enum BufferMapFlags
{
    /// The data can only be read from.
    ReadOnly  = GL_READ_ONLY,

    /// The data can only be written to.
    WriteOnly = GL_WRITE_ONLY,

    /// The data can be written to and read from.
    ReadWrite = GL_READ_WRITE
}

/// Determines if the given type is a `BufferObject`.
enum isBufferObject(T) = isInstanceOf!(BufferObject, T);

/++
 + A wrapper around an OpenGL buffer.
 +
 + This is a very low level struct, and higher level interfaces/buffers should be built on top of this.
 +
 + Params:
 +  DataT = The type of data that this buffer deals with. Set to `ubyte` if it's highly specialised.
 + ++/
struct BufferObject(DataT, GLenum GLBufferType, BufferFeatures features)
{
    ///
    alias Features = features;

    ///
    alias DataType = DataT;

    ///
    alias MapFunc = void delegate(scope DataT[] data);

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
        uint            _handle;
        BufferUsageType _useType;

        static if(HasBufferSizes)
            size_t _dataSize; // In bytes

        static dstring mutuallyExclusive(BufferFeatures[][BufferFeatures] exlusivity)
        {
            import jaster.serialise.builder;
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
            DataT[] data; /// The data that should be uploaded into the buffer.

        /// This type cannot be copied, use `ref` or put it on the heap if needed.
        @disable
        this(this){}

        ~this()
        {
            if(this._handle > 0)
                this.free();
        }

        @nogc
        void free() nothrow
        {
            if(this._handle > 0)
            {
                glDeleteBuffers(1, &this._handle);
                this._handle = 0;
            }
        }

        /++
         + Uploads the buffer's data(GPU side) to reflect the current data in the `data` array (CPU side).
         +
         + Notes:
         +  This function is only enabled with `BufferFeatures.FullUpload` or `BufferFeatures.FullUploadSubData`.
         +
         +  This function $(B must) be called for any changes made to `data` to become visible
         +  on the GPU side of things.
         +
         +  The buffers are left bound afterwards.
         +
         + FullUpload:
         +  If `BufferFeatures.FullUpload` is used, then `glBufferData` is used to update the data, meaning that the GPU will allocate
         +  a new chunk of memory for the new data, and that the data will be uploaded all at once. These two things
         +  together can cause a slowdown if used too often, with too much data.
         +
         + FullUploadSubData:
         +  If `BufferFeatures.FullUploadSubData` is used, then the data on the GPU side is made a larger size, and
         +  `glBufferSubData` is used to upload the data. The size of the VBO is changed using `glBufferData`.
         +
         +  When data needs to be uploaded, but the buffer itself doesn't need to resize, then `glBufferSubData` is used to
         +  upload the data into the start of the GPU side data. This means we can reuse the memory that OpenGL has already
         +  allocated for us, saving the cost of allocation. However this still has the issue of the data being
         +  uploaded all at once, which will cause a slowdown with big datasets. Do note that the old data may not be completely
         +  overridden.
         + ++/
        static if(Features & BufferFeatures.FullUpload)
        void upload()
        {
            glBindBuffer(GLBufferType, this._handle);
            glBufferData(GLBufferType, (DataT.sizeof * this.data.length), &this.data[0], this._useType);

            static if(HasBufferSizes)
                this._dataSize = (DataT.sizeof * this.data.length);

            GL.checkForError();
        }

        /// ditto
        static if(Features & BufferFeatures.FullUploadSubData)
        void upload()
        {
            static void uploadBuffer(uint bufferName, GLenum bufferType, BufferUsageType drawType, void[] toUpload, ref size_t currentSize)
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

            uploadBuffer(this._handle, GLBufferType, this._useType, this.data, this._dataSize);

            GL.checkForError();
        }

        /++
         + Maps the data from the GPU side (using `glMapBuffer`), slices them so they're D-friendly, and then passes
         + the slices into the given function which can read/write to the slices as wanted.
         +
         + The changes made to the data in the slices will be uploaded into the GPU.
         +
         + Notes:
         +  Of course, appending to these slices will cause them to be allocated into a new array, since
         +  these aren't GC-owned pointers. (among other things)
         +
         + Params:
         +  flags   = Various flags to apply to the mapped data.
         +  mapFunc = The function that is applied to the mapped data.
         + ++/
        static if(Features & BufferFeatures.CanMapBuffers)
        void applyMapFunc(BufferMapFlags flags, scope MapFunc mapFunc)
        {
            glBindBuffer(GLBufferType, this.handle);

            auto data = (cast(DataT*)glMapBuffer(GLBufferType, flags))[0..this._dataSize / DataT.sizeof];

            scope(exit)
            {
                glUnmapBuffer(GLBufferType);
                GL.checkForError();
            }

            mapFunc(data);
            GL.checkForError();
        }

        /++
         + Uploads the given data to a portion of the GPU side data.
         +
         + Notes:
         +  This function does not support resizing the buffer, and will fail an assert when
         +  an attempt to write past it is made.
         +
         +  This function is enabled by `BufferFeatures.PartialUploadSubData`.
         +
         + Params:
         +  start = The start offset to start writing to.
         +  data  = The data to write, the amount to write is determined by the slice's length.
         + ++/
        static if(Features & BufferFeatures.PartialUploadSubData)
        void subUpload(const size_t start, DataT[] data)
        {
            // Set some of the variables we need.
            auto bufferType = GLBufferType;
            auto bufferName = this._handle;
            auto bufferSize = this._dataSize;

            if(data.length == 0)
                return;

            // Make sure we're in range
            auto dataSizeBytes = (DataT.sizeof * data.length);
            auto startInBytes  = (DataT.sizeof * start);
            if((startInBytes + dataSizeBytes) > bufferSize)
            {
                import std.format;
                assert(false, format("Attmpted to write outside of the OpenGL buffer.\n"
                                   ~ "Start: %s (%s b) | Data: %s (%s b) | Buffer: %s b",
                                      start, startInBytes, data.length, dataSizeBytes, bufferSize));
            }

            // Then upload the data
            glBindBuffer(bufferType, bufferName);
            glBufferSubData(bufferType, startInBytes, dataSizeBytes, &data[0]);
            GL.checkForError();
        }
        
        /++
         + Call this to prepare this buffer for actual use.
         +
         + Params:
         +  useType         = How this buffer is going to be used.
         +  additionalSetup = A function which can be called to perform additional setup of the buffer object.
         + ++/
        void setup(BufferUsageType       useType         = BufferUsageType.DynamicDraw,
                   scope void delegate() additionalSetup = null
                  )
        {
            // In case this buffer already has been setup.
            if(this._handle > 0)
                this.free();
                
            // Set our variables
            this._useType = useType;

            // Generate the objects
            glGenBuffers(1, &this._handle);

            // Bind the objects
            glBindBuffer(GLBufferType, this._handle);

            if(additionalSetup !is null)
                additionalSetup();
                
            GL.checkForError();
        }

        /// Binds this buffer object to it's respective OpenGL buffer type.
        @nogc
        void bind() nothrow
        {
            glBindBuffer(GLBufferType, this._handle);
        }

        /// Returns: The name/handle of this buffer
        @property @safe @nogc
        uint handle() nothrow const
        {
            return this._handle;
        }

        /// Returns: The `BufferUsageType` of this buffer.
        @property @safe @nogc
        BufferUsageType useType() nothrow const
        {
            return this._useType;
        }

        /// Returns: The size, in bytes, of the buffer's data on the GPU side.
        static if(HasBufferSizes)
        @property @safe @nogc
        size_t dataSizeBytes() nothrow const
        {
            return this._dataSize;
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
                glBufferData(bufferType, cast(uint)newSize, null, this.useType);
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
             + Sets the size of the data on the GPU side, in bytes
             +
             + Notes:
             +  Changing the size requires that the current data in the buffer is copied from the GPU into a temp buffer,
             +  the buffer being given a new chunk of data for the size, and then the old data being copied back over.
             +
             +  If the size is lower than before, the trailing data is simply left out.
             +
             +  Data copying can be disabled entirely by using `BufferFeatures.MutableSizeNoCopy` instead. However,
             +  that means all the data must be copied over as the buffer will be filled with whatever the driver decides
             +  (which is probably whatever was being used in that memory beforehand).
             +
             + Assertions:
             +  `newSize` must be a multiple of `DataT.sizeof`.
             +
             + Params:
             +  newSize = The new size of the buffer's data.
             + ++/
            @property
            void dataSizeBytes(size_t newSize)
            {
                assert(newSize <= uint.max, "OpenGL doesn't seem to support anything bigger than uint.");
                if(newSize % DataT.sizeof != 0)
                    assert(false, "Mis-aligned size.");

                this.resizeBuffer(this._handle, GLBufferType, newSize, this._dataSize);
            }
        }
    }
}