/++
 + Publicly imports derelict.opengl, alongside some helpful functions related to OpenGL.
 + ++/
module opengl;

private 
{
    import std.typecons : Flag;
    import jarena.core.maths : uvec2;
}
public 
{
    import derelict.opengl, derelict.opengl.versions.gl2x;
}

/// For some reason... these _sometimes_ can be seen but _sometimes_ can't??
enum
{
    GL_TRIANGLES    = 0x0004,
    GL_STATIC_DRAW  = 0x88E4,
    GL_DYNAMIC_DRAW = 0x88E8
}

/// Contains information about an OpenGL error.
struct GLError
{
    /// The error code.
    GLenum code;

    /// The message about what went wrong.
    string message;
}

/++
 + Contains information about an OpenGL colour format.
 +
 + Notes:
 +  This struct, alongside `GL.getInfoFor` are mostly for internal use, and are likely
 +  to be unhelpful.
 + ++/
struct PixelInfo
{
    /// How many bytes make up a pixel with this format.
    uint bytesPerPixel;

    /// The type used to describe to OpenGL what format a buffer holding the pixels
    /// for the colour format is.
    uint bufferType;
}

/// A static class containing useful helper functions for OpenGL
abstract static class GL
{
    import std.experimental.logger;
    import derelict.sdl2.sdl;

    /// The version of OpenGL we're targeting.
    enum VERSION = GLVersion.gl33;

    /// The major number of the OpenGL version.
    enum VERSION_MAJOR = (cast(int)VERSION) / 10;

    /// The minor number of the OpenGL version.
    enum VERSION_MINOR = (cast(int)VERSION) % 10;

    alias DebugContext = Flag!"debug";
    alias DoubleBuffer = Flag!"doubleBuffer";

    private static final
    {
        string genErrorCases(GLError[] errors)
        {
            import std.format : format;
            string str;

            foreach(error; errors)
                str ~= format("case %s: return GLError(%s, \"%s\");", error.code, error.code, error.message);

            return str;
        }
    }

    public static final
    {
        /// Loads OpenGL, before a context is made.
        @trusted
        void preContextLoad()
        {
            trace("Initial OpenGL load...");
            DerelictGL3.load();
        }

        /++
         + Creates a new context for an SDL window.
         + ++/
        @trusted
        SDL_GLContext createContextSDL(SDL_Window* window, 
                                       DebugContext isDebugContext  = DebugContext.no, 
                                       DoubleBuffer useDoubleBuffer = DoubleBuffer.yes)
        {
            import jarena.core.util : checkSDLError;

            assert(window !is null);

            infof("Configuring to use a core OpenGL %s.%s context. DebugContext = %s | DoubleBuffer = %s", 
                  GL.VERSION_MAJOR, GL.VERSION_MINOR, isDebugContext, useDoubleBuffer);

            SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK,  SDL_GL_CONTEXT_PROFILE_CORE);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, GL.VERSION_MAJOR);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, GL.VERSION_MINOR);
            SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER,          useDoubleBuffer ? 1 : 0);
            
            if(isDebugContext)
                SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_DEBUG_FLAG);
            checkSDLError();

            info("Creating OpenGL context");
            return SDL_GL_CreateContext(window);
        }

        /// Reloads OpenGL, after a context is made.
        @trusted
        void postContextLoad()
        {
            import std.format : format;

            trace("Reloading OpenGL");
            DerelictGL3.reload();

            info("Checking that the correct version was loaded");
            if(DerelictGL3.loadedVersion < GL.VERSION)
            {
                throw new Error(format("Derelict was unable to load OpenGL version %s.%s",
                                        GL.VERSION_MAJOR, GL.VERSION_MINOR));
            }
        }

        /++
        + Polls OpenGL for an error message, and returns a `GLError` containing the error code,
        + and a suitable human-readable error message.
        +
        + The error code will be `GL_NO_ERROR` if no error has occured.
        +
        + Returns:
        +  A filled out `GLError`.
        + ++/
        @safe @nogc
        GLError nextError() nothrow
        {
            auto error = ()@trusted{ return glGetError(); }();

            switch(error)
            {
                mixin(genErrorCases([
                    GLError(GL_NO_ERROR,                      "No error has been reported."),
                    GLError(GL_INVALID_ENUM,                  "An illegal enumeration was passed to a function."),
                    GLError(GL_INVALID_OPERATION,             "An illegal set of values was passed to a function."),
                    GLError(GL_OUT_OF_MEMORY,                 "OpenGL could not allocate enough memory for an operation."),
                    GLError(GL_INVALID_FRAMEBUFFER_OPERATION, "An read/write/render operation was attempted on an incomplete frame buffer."),
                    GLError(GL_CONTEXT_LOST,                  "The OpenGL context was lost, likely due to the GPU resetting.")
                ]));

                default:
                    return GLError(GL_NO_ERROR, "An unhandled error code was returned.");
            }
        }

        /++
        + Checks to see if OpenGL has produced an error, and throws an Error 
        + (via `std.experimental.logger.fatalf`) if there was an error.
        +
        + Notes:
        +  The body of this function is wrapped inside of a `debug` statement, so 
        +  any build configuration that ignores `debug` statement code will render this,
        +  function as a no-op.
        +
        +  The hideously long list of template parameters are for `fatalf`.
        + ++/
        void checkForError(int line              = __LINE__, 
                           string file           = __FILE__,
                           string funcName       = __FUNCTION__,
                           string prettyFuncName = __PRETTY_FUNCTION__,
                           string moduleName     = __MODULE__)()
        {
            debug
            {
                import std.experimental.logger;
                auto next = GL.nextError();
                if(next.code != GL_NO_ERROR)
                    fatalf!(line, file, funcName, prettyFuncName, moduleName)("[Code:%s | Msg:'%s']", next.code, next.message);
            }
        }

        /++
        + Returns:
        +  A `PixelInfo` for the given `ColourFormat`.
        + ++/
        PixelInfo getInfoFor(GLenum ColourFormat)()
        {
            // I want a custom error message, which is why I'm not using a contract.
            static assert(ColourFormat == GL_RGBA8 || ColourFormat == GL_RED,
                          "The given ColourFormat is unsupported.\n"~
                          "Supported types: GL_RGBA8; GL_RED");

            // Configure certain data depending on the colour format.
                 static if(ColourFormat == GL_RGBA8)    return PixelInfo(4, GL_RGBA);
            else static if(ColourFormat == GL_RED)      return PixelInfo(1, GL_RED);
            else static assert(false);
        }
    }
}