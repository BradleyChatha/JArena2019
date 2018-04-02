module opengl;

private import jarena.core.maths : uvec2;
public import derelict.opengl;
enum OPENGL_VERSION = uvec2(3, 3);

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

void checkGLError()
{
    import std.format : format;
    auto next = nextGLError();
    if(next.code != GL_NO_ERROR)
        throw new Exception(format("[Code:%s | Msg:'%s']", next.code, next.message));
}
