/++
 + Publicly imports derelict.opengl, alongside some helpful functions related to OpenGL.
 + ++/
module opengl;

private 
{
    import std.typecons : Flag;
    import jarena.maths.maths : uvec2;

    import derelict.opengl.extensions.khr;
}
public 
{
    import derelict.opengl;
}

mixin glFreeFuncs!(GL.VERSION);

/// For some reason... these _sometimes_ can be seen but _sometimes_ can't??
enum
{
    GL_TRIANGLES    = 0x0004,
    GL_STATIC_DRAW  = 0x88E4,
    GL_DYNAMIC_DRAW = 0x88E8,
    GL_CONTEXT_LOST = 0x0507
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
    enum VERSION = GLVersion.gl43;

    /// The major number of the OpenGL version.
    enum VERSION_MAJOR = (cast(int)VERSION) / 10;

    /// The minor number of the OpenGL version.
    enum VERSION_MINOR = (cast(int)VERSION) % 10;

    alias DebugContext = Flag!"debug";
    alias DoubleBuffer = Flag!"doubleBuffer";
    alias Blacklist    = Flag!"enabled";

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
         +
         + Params:
         +  window          = The handle for the SDL window.
         +  isDebugContext  = If `DebugContext.yes`, then the context is created with the debug flag set.
         +  useDoubleBuffer = If `DoubleBuffer.yes`, then double buffering is used.
         +
         + Returns:
         +  The created context.
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
            if(DerelictGL3.contextVersion < GL.VERSION)
            {
                throw new Error(format("Derelict was unable to load OpenGL version %s.%s . Loaded = %s",
                                        GL.VERSION_MAJOR, GL.VERSION_MINOR, DerelictGL3.contextVersion));
            }
        }

        /// Enables OpenGL debug logging.
        ///
        /// If the OpenGL version isn't OpenGL 4.3 then this function is no-op
        void debugLogEnable()
        {
            trace("Enabling the OpenGL debug log.");

            if(GL.VERSION < GLVersion.gl43)
            {
                warning("The current version of OpenGL doesn't support the 'KHR_debug' extension");
                return;
            }

            static if(GL.VERSION >= GLVersion.gl43)
            {
                glEnable(GL_DEBUG_OUTPUT);
                glDebugMessageCallback(&GL.debugLogFunction, null);
                //GL.debugLogFilter(GL_DEBUG_SOURCE_API, GL_DEBUG_TYPE_ERROR, GL_DONT_CARE, Blacklist.no);

                uint id = 131185;
                glDebugMessageControl(GL_DEBUG_SOURCE_API, GL_DEBUG_TYPE_OTHER, GL_DONT_CARE, 1, &id, 0);

                GL.checkForError();
            }
        }

        /// Sets the filter for OpenGL's logger. https://www.khronos.org/opengl/wiki/Debug_Output#Logging
        ///
        /// If the OpenGL version isn't OpenGL 4.3 then this function is no-op
        void debugLogFilter(GLenum source, GLenum type, GLenum severity, Blacklist blacklist = Blacklist.no)
        {
            static if(GL.VERSION >= GLVersion.gl43)
            {
                infof("Setting log filter to (S:%s | T:%s | SEV:%s | BLACKLIST:%s)", source, type, severity, blacklist);
                glDebugMessageControl(source, type, severity, 0, null, blacklist ? 0 : 1);
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

    // Debug log functions
    static if(GL.VERSION >= GLVersion.gl43)
    private static final
    {
        string debugSourceToString(GLenum source) nothrow
        {
            switch(source)
            {
                case GL_DEBUG_SOURCE_API:              return "API";
                case GL_DEBUG_SOURCE_WINDOW_SYSTEM:    return "WIN-SYS";
                case GL_DEBUG_SOURCE_SHADER_COMPILER:  return "SHADER";
                case GL_DEBUG_SOURCE_THIRD_PARTY:      return "3rdPARTY";
                case GL_DEBUG_SOURCE_APPLICATION:      return "USER";
                case GL_DEBUG_SOURCE_OTHER:            return "OTHER";
                default:                               return "UNKNOWN";
            }
        }

        string debugTypeToString(GLenum type) nothrow
        {
            switch(type)
            {
                case GL_DEBUG_TYPE_ERROR:               return "ERROR";
                case GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR: return "DEPRECATION";
                case GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:  return "UB";
                case GL_DEBUG_TYPE_PORTABILITY:         return "PORTABILITY";
                case GL_DEBUG_TYPE_PERFORMANCE:         return "PERF";
                case GL_DEBUG_TYPE_MARKER:              return "MARKER";
                case GL_DEBUG_TYPE_PUSH_GROUP:          return "PUSH";
                case GL_DEBUG_TYPE_POP_GROUP:           return "POP";
                case GL_DEBUG_TYPE_OTHER:               return "OTHER";
                default:                                return "UNKNOWN";
            }
        }

        LogLevel debugSeverityToLogLevel(GLenum severity) nothrow
        {
            switch(severity)
            {
                case GL_DEBUG_SEVERITY_HIGH:   return LogLevel.fatal;
                case GL_DEBUG_SEVERITY_MEDIUM: return LogLevel.warning;

                case GL_DEBUG_SEVERITY_LOW:
                case GL_DEBUG_SEVERITY_NOTIFICATION:
                    return LogLevel.info;

                default: return LogLevel.trace;
            }
        }

        extern(System) void debugLogFunction(GLenum source,
                                             GLenum type,
                                             uint id,
                                             GLenum severity,
                                             GLsizei length,
                                             const char* message,
                                             const void* userParam
                                            ) nothrow
        {
            import std.format    : format;
            import std.exception : assumeWontThrow;

            auto sourceStr  = GL.debugSourceToString(source);
            auto typeStr    = GL.debugTypeToString(type);
            auto logLevel   = GL.debugSeverityToLogLevel(severity);
            auto messageStr = message[0..length];

            log(logLevel,
              format("<From:%s Type:%s ID:%s> %s",
                     sourceStr, typeStr, id, messageStr).assumeWontThrow
            ).assumeWontThrow;
        }
    }
}