///
module jarena.core.util;

private
{
    import std.experimental.logger;
    import resusage;
    import derelict.sdl2.sdl;
    import jarena.maths;
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

        @safe @nogc
        Colour colourFromLevel(LogLevel level) nothrow
        {
            final switch(level) with(LogLevel)
            {
                case all:       return Colour(255, 255, 255);
                case trace:     return Colour(128, 128, 128);
                case info:      return Colour(255, 255, 255);
                case warning:   return Colour(255, 204, 0);
                case error:     return Colour(218, 20,  20);
                case critical:  return Colour(109, 10,  10);
                case fatal:     return Colour(54,  5,   5);
                case off:       return Colour(0,   0,   0);
            }

            assert(false);
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
            import std.stdio     : writeln;
            import std.format    : format;

            synchronized(this)
            {
                writeln("[%s](%s$%s:%s)<%s> -> %s".format(
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
                        ).ansiText(this.colourFromLevel(entry.logLevel))
                );
            }
        }
    }
}

///
void enforceAndLogf(int line              = __LINE__, 
                    string file           = __FILE__,
                    string funcName       = __FUNCTION__,
                    string prettyFuncName = __PRETTY_FUNCTION__,
                    string moduleName     = __MODULE__,
                    Args...)
                   (
                       bool condition,
                       const(char)[] formatStr,
                       Args args
                   )
{
    if(!condition)
    {
        import std.format : format;
        auto str = format(formatStr, args);
        errorf(str);
        throw new Exception(str);
    }
}

///
void enforceAndLogf(int line              = __LINE__, 
                    string file           = __FILE__,
                    string funcName       = __FUNCTION__,
                    string prettyFuncName = __PRETTY_FUNCTION__,
                    string moduleName     = __MODULE__,
                    Args...)
                   (
                       const(char)[] formatStr,
                       Args args
                   )
{
    import std.format : format;
    auto str = format(formatStr, args);
    errorf(str);
    throw new Exception(str);
}

/++
 + Creates an ANSI Colour string.
 +
 + Params:
 +  text    = The text to colour.
 +  colour  = The colour to use (alpha has no effect).
 +
 + Returns:
 +  The ANSI string.
 + ++/
@safe
string ansiText(string text, Colour colour)
{
    import std.format;
    return format("\033[38;2;%s;%s;%sm%s\033[0m", colour.r, colour.g, colour.b, text);
}

version(Windows)
{
    static this()
    {
        import core.sys.windows.windows;

        // Enable ANSI support
        DWORD mode;
        HANDLE console;
        console = GetStdHandle(STD_OUTPUT_HANDLE);
        GetConsoleMode(console, &mode);
        SetConsoleMode(console, mode | 0x0004);
    }
}