module editor.core;

private
{
    import core.thread;
    import std.exception;
    import jaster.serialise;
    import jarena.core, jarena.gameplay, jarena.data;
}

struct ExceptionInfo
{
    string message;
    string stackTrace;
}

static class Editor
{
    private static __gshared
    {
        ThreadID _engineThread;
        Engine   _engine;

    }

    public static
    {
        void init()
        {
            synchronized 
            {
                if(this._engineThread != ThreadID.init)
                    return;

                this._engineThread = Thread.getThis.id;
                this._engine       = new Engine();
                this._engine.onInitLibraries();
                this._engine.onInit();
            }
        }

        void update()
        {
            synchronized
            {
                if(this._engine is null)
                    return;

                enforce(Thread.getThis().id == this._engineThread, "Update was called outside of the engine thread.");
                this._engine.onUpdate();
            }
        }

        ubyte[] serialise(T)(T value)
        {
            auto archive = new ArchiveBinary();
            Serialiser.serialise(value, archive.root);

            return cast(ubyte[])archive.saveToMemory();
        }
    }
}

void errorWrapper(ubyte[]* onError, void delegate() func)
{
    try func();
    catch(Exception ex)
    {
        if(onError !is null)
            (*onError) = Editor.serialise(ExceptionInfo(ex.msg, ex.info.toString()));
    }
}

extern(C) export:

void jengine_editor_init(ubyte[]* onError)
{
    errorWrapper(onError,
    (){
        Editor.init();
    });
}

void jengine_editor_update(ubyte[]* onError)
{
    errorWrapper(onError,
    (){
        enforce(!Systems.window.isClosed, "The game window has been closed.");

        Editor.update();   
    });
}

void jengine_editor_openUIFile(char* path, uint pathLength, ubyte[]* data, ubyte[]* onError)
{
    errorWrapper(onError, ()
    {
        import std.file : exists;

        auto pathD = path[0..pathLength];
        enforce(pathD.exists, "The path doesn't exist.");

        auto sdl    = new ArchiveSDL();
        auto binary = new ArchiveBinary();

        sdl.loadFromFile(pathD);
        foreach(child; sdl.root.children)
        {
            // We only support singular ones per file for now.
            if(child.name == "UI:view")
            {
                binary.root.addChild(child);
                (*data) = cast(ubyte[])binary.saveToMemory();   
                return;
            }
        }

        throw new Exception("The file at '"~pathD.idup~"' does not contain a top-level 'UI:view' tag.");
    });
}