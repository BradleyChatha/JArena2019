/++
 + Publicly imports derelict.opengl, alongside some helpful functions related to OpenGL.
 + ++/
module opengl;

private import jarena.core.maths : uvec2;
public import derelict.opengl, derelict.opengl.versions.gl2x;

/// The version of OpenGL we're targeting.
enum OPENGL_VERSION = uvec2(3, 3);

/// For some reason... these _sometimes_ can be seen but _sometimes_ can't??
enum GL_TRIANGLES = 0x0004;

/// ditto
enum GL_STATIC_DRAW = 0x88E4;

/// ditto
enum GL_DYNAMIC_DRAW = 0x88E8;

/// Contains information about an OpenGL error.
struct GLError
{
    /// The error code.
    GLenum code;

    /// The message about what went wrong.
    string message;
}

private string genErrorCases(GLError[] errors)
{
    import std.format : format;
    string str;

    foreach(error; errors)
        str ~= format("case %s: return GLError(%s, \"%s\");", error.code, error.code, error.message);

    return str;
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
GLError nextGLError() nothrow
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
void checkGLError(int line = __LINE__, 
                  string file = __FILE__,
                  string funcName = __FUNCTION__,
                  string prettyFuncName = __PRETTY_FUNCTION__,
                  string moduleName = __MODULE__)()
{
    debug
    {
        import std.experimental.logger;
        auto next = nextGLError();
        if(next.code != GL_NO_ERROR)
            fatalf!(line, file, funcName, prettyFuncName, moduleName)("[Code:%s | Msg:'%s']", next.code, next.message);
    }
}

/++
 + Contains information about an OpenGL colour format.
 +
 + Notes:
 +  This struct, alongside `getInfoFor` are mostly for internal use, and are likely
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