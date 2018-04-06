module opengl;

private import jarena.core.maths : uvec2;
public import derelict.opengl, derelict.opengl.versions.gl2x;
enum OPENGL_VERSION = uvec2(3, 3);

// For some reason... these _sometimes_ can be seen but _sometimes_ can't??
enum GL_TRIANGLES = 0x0004;
enum GL_STATIC_DRAW = 0x88E4;
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

void checkGLError(int line = __LINE__, string file = __FILE__,
        string funcName = __FUNCTION__,
        string prettyFuncName = __PRETTY_FUNCTION__,
        string moduleName = __MODULE__)()
{
    import std.experimental.logger;
    auto next = nextGLError();
    if(next.code != GL_NO_ERROR)
        errorf!(line, file, funcName, prettyFuncName, moduleName)("[Code:%s | Msg:'%s']", next.code, next.message);
}

struct PixelInfo
{
    uint bytesPerPixel;
    uint bufferType;
}

PixelInfo getInfoFor(GLenum ColourFormat)()
{
    // I want a custom error message, which is why I'm not using a contract.
    static assert(ColourFormat == GL_RGBA8 || ColourFormat == GL_RED,
                "The given ColourFormat is unsupported.\n"~
                "Supported types: GL_RGBA8");

    // Configure certain data depending on the colour format.
         static if(ColourFormat == GL_RGBA8)    return PixelInfo(4, GL_RGBA);
    else static if(ColourFormat == GL_RED)      return PixelInfo(1, GL_RED);
    else static assert(false);
}