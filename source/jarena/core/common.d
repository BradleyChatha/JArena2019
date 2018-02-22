/// Contains common code/data structures that don't properly fit into any existing module
module jarena.core.common;

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

        uvec2 _windowSize;
    }

    public static
    {
        mixin(generateProperties("_windowSize", "uvec2", "windowSize"));
    }

    private static dstring generateProperties(string varName, string typeName, string propertyName)
    {
        import codebuilder;

        auto builder = new CodeBuilder();

        // Setter
        builder.putf("void %s(%s value) @safe nothrow", propertyName, typeName);
        builder.putScope((_)
        {
            builder.putf("assert((\"%s\" in _locks) is null, \"The value for '%s' has already been set!\");", varName, varName);
            builder.putf("_locks[\"%s\"] = false;", varName);
            builder.putf("%s = value;", varName);
        });

        // Getter
        builder.putf("const(%s) %s() @safe @nogc nothrow", typeName, propertyName);
        builder.putScope((_)
        {
            builder.putf("assert((\"%s\" in _locks) !is null, \"The value for '%s' hasn't been set yet!\");", varName, varName);
            builder.putf("return %s;", varName);
        });

        return builder.data.idup;
    }
}