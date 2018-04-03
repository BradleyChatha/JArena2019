/// Contains common code/data structures that don't properly fit into any existing module
module jarena.core.common;

private
{
    import derelict.sdl2.sdl;
    import jarena.graphics;
}

private struct InitProperty
{
    string publicName;
}

private struct CanEdit
{
}

/++
 + A static class containing useful information some classes may need while initialising, but would be cumbersome to actually
 + pass through properly.
 +
 + The data in this class is write-once, as in you can only set the value of each piece of data a single time before it becomes read-only.
 + This should get rid of a large portion of headaches created by such a static class.
 +
 + Certain pieces of data however can be marked as `CanEdit`, which means that a $(B single) pointer to the data can be retrieved,
 + somewhere in the code, which can be used to keep the data up to date.
 +
 + These restrictions are in place to combat the issues related to singleton/singleton-like types.
 + ++/
class InitInfo
{
    import jarena.core.maths;

    private static
    {
        // The bool value is just a dummy
        // What I really care about is being able to do "_windowSize in _locks" as an example.
        bool[string] _locks;
        bool[string] _editLocks;

        @InitProperty("windowSize")
        @CanEdit
        uvec2 _windowSize;

        // The game officially only supports being able to display one window
        // How awful of me.
        @InitProperty("renderResources")
        RendererResources _renderResources;
    }

    public static
    {
        mixin(generateProperties!_windowSize);
        mixin(generateProperties!_renderResources);
    }

    private static dstring generateProperties(alias Var)()
    {
        import std.traits : hasUDA, getUDAs;
        import codebuilder;

        static assert(hasUDA!(Var, InitProperty), "The variable '" ~ Var.stringof ~ "' needs an @InitProperty");        
        auto builder = new CodeBuilder();

        enum PropertyName   = getUDAs!(Var, InitProperty)[0].publicName;
        enum TypeName       = typeof(Var).stringof;
        enum VarName        = Var.stringof; 
        
        // Setter
        builder.putf("void %s(%s value) @safe nothrow", PropertyName, TypeName);
        builder.putScope((_)
        {
            builder.putf("assert((\"%s\" in _locks) is null, \"The value for '%s' has already been set!\");", VarName, VarName);
            builder.putf("_locks[\"%s\"] = false;", VarName);
            builder.putf("%s = value;", VarName);
        });

        // Getter
        builder.putf("%s %s() @safe @nogc nothrow", TypeName, PropertyName);
        builder.putScope((_)
        {
            builder.putf("assert((\"%s\" in _locks) !is null, \"The value for '%s' hasn't been set yet!\");", VarName, VarName);
            builder.putf("return %s;", VarName);
        });

        // Getter [pointer]
        static if(hasUDA!(Var, CanEdit))
        {
            builder.putf("%s* %s_ptr() @safe nothrow", TypeName, PropertyName);
            builder.putScope((_)
            {
                builder.putf("assert((\"%s\" in _editLocks) is null, \"A pointer for '%s' has already been given.\");", VarName, VarName);
                builder.putf("_editLocks[\"%s\"] = false;", VarName);
                builder.putf("return &%s;", VarName);
            });
        }

        return builder.data.idup;
    }
}
