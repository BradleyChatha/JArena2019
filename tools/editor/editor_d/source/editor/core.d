module editor.core;

private
{
    import core.thread;
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