module editor.core;

private
{
    import core.thread;
    import std.exception;
    import jaster.serialise;
    import jarena.core, jarena.gameplay, jarena.data;
    import editor.scene;
}

struct ExceptionInfo
{
    string message;
    string stackTrace;
}

static class Editor
{
    enum ActionType
    {
        None,
        ChangeView
    }

    union ActionValue
    {
        ArchiveObject changeViewValue;
    }

    struct Action
    {
        ActionType  type;
        ActionValue value;
    }

    private static __gshared
    {
        ThreadID    _engineThread;
        Engine      _engine;
        EditorScene _scene;
        Action[]    _actions;
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
                this._scene = new EditorScene();
                this._engine.scenes.register!EditorScene(this._scene);
                this._engine.scenes.swap!EditorScene();
            }
        }

        void update()
        {
            try
            {
                synchronized
                {
                    if(this._engine is null)
                        return;

                    foreach(action; _actions)
                    {
                        final switch(action.type) with(ActionType)
                        {
                            case None: break;

                            case ChangeView:
                                this._scene.changeView(action.value.changeViewValue);
                                break;
                        }
                    }

                    _actions.length = 0;

                    enforce(Thread.getThis().id == this._engineThread, "Update was called outside of the engine thread.");
                    this._engine.onUpdate();
                }
            }
            catch(Throwable ex)
            {
                // I only catch errors since I need to get the message first.
                import std.format, core.sys.windows.winuser, std.string;

                MessageBoxA(null, format("Reason: %s\nTrace:\n%s", ex.msg, ex.info.toString()).toStringz, null, MB_ICONERROR);

                throw ex;
            }
        }

        void changeView(ArchiveObject obj)
        {
            Action act;
            act.type = ActionType.ChangeView;
            act.value.changeViewValue = obj;

            synchronized this._actions ~= act;
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
    catch(Throwable ex)
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
                Editor.changeView(child);
                binary.root.addChild(child);
                (*data) = cast(ubyte[])binary.saveToMemory();   
                return;
            }
        }

        throw new Exception("The file at '"~pathD.idup~"' does not contain a top-level 'UI:view' tag.");
    });
}

void jengine_editor_getDefinition(char* controlName, uint nameLength, ubyte[]* data, ubyte[]* onError)
{
    errorWrapper(onError, ()
    {
        auto nameD  = controlName[0..nameLength];
        auto def    = DataBinder.getDefinitionFor(nameD.idup);
        auto binary = new ArchiveBinary();
        Serialiser.serialise!(DataBinder.ControlDef)(def, binary.root);
        (*data) = cast(ubyte[])binary.saveToMemory();
    });
}

void jengine_editor_saveFile(char* path, uint pathLength, ubyte[] data, ubyte[]* onError)
{
    errorWrapper(onError, ()
    {
        auto pathD  = path[0..pathLength];
        auto binary = new ArchiveBinary();
        auto sdl    = new ArchiveSDL();
        binary.loadFromMemory(data);

        foreach(val; binary.root.values)
            sdl.root.addValue(val);
        foreach(prop; binary.root.attributes)
            sdl.root.setAttribute(prop.name, prop.value);
        foreach(child; binary.root.children)
            sdl.root.addChild(child);

        sdl.saveToFile(pathD);
    });
}

void jengine_editor_changeView(ubyte[] data, ubyte[]* onError)
{
    errorWrapper(onError, ()
    {
        auto binary = new ArchiveBinary();
        binary.loadFromMemory(data);

        foreach(child; binary.root.children)
        {
            if(child.name == "UI:view")
                Editor.changeView(child);
        }
    });
}