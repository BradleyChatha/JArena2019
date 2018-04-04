module jarena.graphics.shader;

private
{
    import jarena.core, jarena.graphics;
    import opengl;
}
/// Code for the default vertex shader.
immutable string defaultVertexShader   = cast(string)import("shaders/default.vert");

/// Code for the textured fragment shader. (Draws the texture multiplied by the vertex colour)
immutable string texturedFragmentShader = cast(string)import("shaders/textured.frag");

/// Code for the coloured fragment shader. (Only draws the vertex colour, no textures)
immutable string colouredFragmentShader = cast(string)import("shaders/coloured.frag");

/// A high-level wrapper over an OpenGL shader program.
class Shader
{
    private
    {
        uint _handle;
    }

    public
    {
        /++
         + Compiles a vertex shader, and a fragment shader, and then links them into a shader program.
         +
         + Notes:
         +  This function will only allocate GC memory in the event of a compilation/linking error.
         +
         + Params:
         +  vertexCode   = The code for the vertex shader.
         +  fragmentCode = The code for the fragment shader.
         + ++/
        this(string vertexCode, string fragmentCode)
        {
            import std.exception : enforce;
            import std.experimental.logger;

            const(uint) compile(string code, bool vertex = true)
            {
                auto type = (vertex) ? GL_VERTEX_SHADER : GL_FRAGMENT_SHADER;
                uint handle;

                auto codeLength = code.length;
                auto codePtr    = code.ptr;

                handle = glCreateShader(type);
                glShaderSource(handle, 1, cast(const(char*)*)&codePtr, cast(const int*)&codeLength);
                glCompileShader(handle);

                int success;
                char[512] compileLog;
                glGetShaderiv(handle, GL_COMPILE_STATUS, &success);
                if(!success)
                {
                    int length;
                    glGetShaderInfoLog(handle, cast(uint)compileLog.length, &length, compileLog.ptr);
                    
                    errorf("Error compiling %s shader: %s", (vertex) ? "Vertex" : "Fragment", compileLog[0..length]);
                    return 0;
                }

                return handle;
            }

            // Compile shaders
            auto vertex   = compile(vertexCode);
            auto fragment = compile(fragmentCode, false);

            scope(exit)
            {
                if(vertex > 0)
                    glDeleteShader(vertex);

                if(fragment > 0)
                    glDeleteShader(fragment);
            }

            enforce(vertex > 0,   "Unable to compile vertex shader");
            enforce(fragment > 0, "Unable to compile fragment shader");

            // Attempt the link the program.
            auto handle = glCreateProgram();
            glAttachShader(handle, vertex);
            glAttachShader(handle, fragment);
            glLinkProgram(handle);

            int success;
            char[512] log;
            glGetProgramiv(handle, GL_LINK_STATUS, &success);
            if(!success)
            {
                int length;
                glGetProgramInfoLog(handle, cast(uint)log.length, &length, log.ptr);
                
                throw new Exception("Error linking shader program: " ~ log[0..length].idup);
            }

            this._handle = handle;
        }

        ~this()
        {
            if(this._handle != 0)
                glDeleteShader(this.handle);
        }

        /++
         + Use this shader for rendering.
         + ++/
        @nogc
        void use() nothrow
        {
            glUseProgram(this.handle);
        }

        /++
         + Finds the location of a specificly named uniform.
         +
         + Notes:
         +  This function only allocates GC memory in the event of something going wrong.
         +
         + Params:
         +  uniName = The name of the uniform the get the location of.
         + ++/
        int uniformLocation(const char[] uniName)
        {
            import std.experimental.logger;

            assert(uniName.length < 64);
            char[64] buffer;
            buffer[0..uniName.length] = uniName;
            buffer[uniName.length]    = '\0';

            auto loc = glGetUniformLocation(this.handle, buffer.ptr);
            errorf(loc == -1, "Unable to find uniform named '%s'", uniName);

            return loc;
        }

        /++
         + Sets the value of a uniform variable in the shader.
         +
         + Notes:
         +  $(RED The shader must currently be in use (via `Shader.use`) before calling this function.)
         +
         + Params:
         +  location = The location of the uniform to change.
         +  data     = The data to set the uniform to.
         + ++/
        void setUniform(T)(const int location, T data)
        {
                 static if(is(T == float))  glUniform1f(location, data);
            else static if(is(T == int))    glUniform1i(location, data);
            else static if(is(T == vec2))   glUniform2f(location, data.x, data.y);
            else static if(is(T == vec3))   glUniform3f(location, data.x, data.y, data.z);
            else static if(is(T == mat4))   glUniformMatrix4fv(location, 1, GL_FALSE, data.ptr);
            else static if(is(T == Colour)) glUniform4f(location, data.r, data.g, data.b, data.a);
            else static assert(false, "Unsupported uniform value: " ~ T.stringof);
        }

        /++
         + A helper function to use a uniform's name instead of it's location.
         + ++/
        void setUniform(T)(const char[] name, T data)
        {
            this.setUniform!T(this.uniformLocation(name), data);
        }

        /++
         + Returns:
         +  The shader's handle.
         + ++/
        @safe @nogc
        inout(uint) handle() nothrow pure inout
        out(h)
        {
            assert(h > 0, "Attempted to use a null shader");
        }
        body
        {
            return this._handle;
        }
    }
}
