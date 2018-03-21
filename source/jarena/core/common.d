/// Contains common code/data structures that don't properly fit into any existing module
module jarena.core.common;

private struct InitProperty
{
    string publicName;
}

/++
 + A static class containing useful information some classes may need while initialising, but would be cumbersome to actually
 + pass through properly.
 +
 + The data in this class is write-once, as in you can only set the value of each piece of data a single time before it becomes read-only.
 + This should get rid of a large portion of headaches created by such a static class.
 + ++/
class InitInfo
{
    import jarena.core.maths;

    private static
    {
        // The bool value is just a dummy
        // What I really care about is being able to do "_windowSize in _locks" as an example.
        bool[string] _locks;

        @InitProperty("windowSize")
        uvec2 _windowSize;
    }

    public static
    {
        mixin(generateProperties!_windowSize);
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
        builder.putf("const(%s) %s() @safe @nogc nothrow", TypeName, PropertyName);
        builder.putScope((_)
        {
            builder.putf("assert((\"%s\" in _locks) !is null, \"The value for '%s' hasn't been set yet!\");", VarName, VarName);
            builder.putf("return %s;", VarName);
        });

        return builder.data.idup;
    }
}
