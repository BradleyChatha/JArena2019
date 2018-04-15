///
module jarena.core.util;

private
{
    import std.experimental.logger;
    import resusage;
    import derelict.sdl2.sdl;
    import jarena.core.maths;
}

private enum isDLSLVector(T) = isVector!T;
private enum isJArenaRect(T) = (is(T == RectangleF) || is(T == RectangleI)); // TODO : Generic test for rects, instead of a hard coded one

/// Implementation of the `to` function for - DLSL Vector -> SFML Vector
sfVect toSF(sfVect, dlslVect)(dlslVect vect)
if(isSFMLVector!sfVect && isDLSLVector!dlslVect)
{
    static assert(dlslVect.dimension == 2, "Since the SFML vectors we're using are all 2D, we go off the assumption that the DLSL one is also 2D");
    return sfVect(vect.x, vect.y);
}
///
unittest
{
    assert(ivec2(20, 40).toSF!sfVector2i == sfVector2i(20, 40));
}

/// Returns: A verison of `colour` that is suitable for certain OpenGL functions (such as glClear)
float[4] asGLColour()(Colour colour)
{
    float[4] colours;
    float convert(ubyte original)
    {
        return cast(float)original / 255.0f;
    }

    colours[0] = convert(colour.r);
    colours[1] = convert(colour.g);
    colours[2] = convert(colour.b);
    colours[3] = convert(colour.a);
    
    return colours;
}

/++
 + Notes:
 +  If the current platform is not supported, then a `ProcessMemInfo.init` is returned.
 +
 + Returns:
 +  A `ProcessMemInfo` containing the memory usage for this process.
 + ++/
ProcessMemInfo getMemInfo()
{
    version(Windows)
    {
        import core.sys.windows.winbase;
        auto pid = GetCurrentProcessId();

        return processMemInfo(pid);
    }
    else
    {
        return ProcessMemInfo.init;
    }
}

/// Checks to see if SDL has thrown an error.
@trusted
void checkSDLError()
{
    import std.string : fromStringz;

    auto msgPtr = SDL_GetError();
    if(*msgPtr != '\0')
    {
        auto msg = msgPtr.fromStringz;
        SDL_ClearError();
        throw new Exception(msg.idup);
    }
}

// This exists since I don't like the output for the default logger.
/// A custom logger that logs to the console.
final class ConsoleLogger : Logger
{
    import std.datetime;
    
    private
    {
        @safe
        string formatSysTime(SysTime time)
        {
            import std.conv   : to;
            import std.string : rightJustify;
            import std.format : format;

            return format("%s-%s-%s %s:%s:%s:%sms",
                          time.day.to!string.rightJustify(2, '0'),
                          time.month,
                          time.year,

                          time.hour.to!string.rightJustify(2, '0'),
                          time.minute.to!string.rightJustify(2, '0'),
                          time.second.to!string.rightJustify(2, '0'),
                          time.fracSecs.split!"msecs".msecs
                         );
        }
    }
    
    public
    {
        @safe
        this(LogLevel level)
        {
            super(level);
        }

        override void writeLogMsg(ref LogEntry entry)
        {
            import std.algorithm : substitute, map;
            import std.range     : split;
            import std.conv      : to;
            import std.uni       : toUpper;
            import std.stdio     : writefln;

            synchronized(this)
            {
                writefln("[%s](%s$%s:%s)<%s> -> %s",
                        this.formatSysTime(entry.timestamp),
                        entry.file.substitute!("source/",  "", 
                                                "source\\", "",
                                                ".d",       "",
                                                "/",        ".",
                                                "\\",       "."),
                        entry.funcName.split(".")[$-1],
                        entry.line,
                        entry.logLevel.to!string.map!toUpper,
                        entry.msg
                        );
            }
        }
    }
}
