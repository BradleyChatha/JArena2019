/// Contains a class which can be used to access the various systems of the engine.
module jarena.core.systems;

private
{
    import std.traits    : allSatisfy, isSomeString, getSymbolsByUDA, getUDAs, hasUDA;
    import std.typetuple : AliasSeq;
    import derelict.sdl2.sdl;
    import codebuilder;
    import jarena.audio, jarena.core, jarena.data, jarena.gameplay, jarena.graphics;
}

private struct Property
{
    string name;
}

private struct WhitelistModules
{
    string[] modules;

    this(S...)(S mods)
    if(allSatisfy!(isSomeString, S))
    {
        foreach(mod; mods)
            this.modules ~= mod;
    }
}

private struct IsConst{}

/++
 + A static class containing the various systems of the game.
 +
 + Usage:
 +  Each system has a few functions generated for them. A getter, and a setter.
 +
 +  $(B All) systems must be given a value using their setters, and then `Systems.finalise` must be called.
 +
 +  Only then can the getters be used to access these systems.
 +
 + Notes:
 +  Certain systems can be marked with `@WhitelistModules` to limit the use of that system to only certain modules.
 +
 +  Certain systems can be marked `@IsConst` to specify that the generated getter function returns a const reference to the system.
 +  Do note that a mutable reference to the object is stored internally, but is only provided publically as const.
 + ++/
final class Systems
{
    private static final
    {
        // =========
        // = Other =
        // =========
        bool[string] _setFlags; // Used to keep track of which properties have had their value set.
        bool _finalised;        // Used to signal that the data has been finalised.

        // ==============
        // = Properties =
        // ==============
        alias Properties = AliasSeq!(
            _window,
            _renderResources,
            _audio,
            _loaderSDL,
            _assets,
            _scheduler
        );

        @Property("window")
        @IsConst
        Window _window;

        @Property("renderResources")
        @WhitelistModules("jarena.graphics.renderer",
                          "jarena.graphics.sprite",
                          "jarena.gameplay.scenes.debugs.debug_menu",
                          "jarena.gameplay.engine")
        RendererResources _renderResources;

        @Property("audio")
        AudioManager _audio;

        @Property("loaderSdlang")
        LoaderSDL _loaderSDL;

        @Property("assets")
        AssetManager _assets;

        @Property("shortTermScheduler")
        ShortTermScheduler _scheduler;
    }

    public static final
    {
        /++
         + Sets the data inside this class to a finalised state.
         +
         + This checks that all the data have been given values, and it will allow
         + the getter functions to finally be used.
         +
         + Using a getter function before calling this function will cause an assert to fail.
         + ++/
        @safe
        void finalise() nothrow
        {
            static foreach(prop; Properties)
            {
                // The extra scope is so the 'name' variable doesn't get redefined.
                {
                    auto name = getUDAs!(prop, Property)[0].name;
                    if((name in _setFlags) is null)
                        assert(false, "Cannot finalise data - No value for '"~name~"' was set.");
                }
            }

            this._finalised = true;
        }

        static foreach(prop; Properties)
            mixin(generate!prop);
    }

    private static final
    {
        string generate(alias Prop)()
        if(hasUDA!(Prop, Property))
        {
            import std.conv : to;
            auto code = new CodeBuilder();

            // ===================
            // = Get useful data =
            // ===================
            auto varName  = Prop.stringof;
            auto propName = getUDAs!(Prop, Property)[0].name;
            auto typeName = typeof(Prop).stringof;

            static if(hasUDA!(Prop, IsConst))
                typeName = "const(" ~ typeName ~ ")";

            static if(hasUDA!(Prop, WhitelistModules))
                auto allowedModules = getUDAs!(Prop, WhitelistModules)[0].modules;

            // Generate a contract if needed.
            dstring contract;
            static if(hasUDA!(Prop, WhitelistModules))
            {
                import std.algorithm : map, joiner;
                import std.array     : array;

                contract = "if(";
                contract ~= allowedModules.map!(m => "Module == \""~m~"\"")
                                          .joiner(" || ")
                                          .array;
                contract ~= ")";
            }

            // ==========
            // = Setter =
            // ==========
            code.putf("void %s(string Module = __MODULE__)(%s value)",
                      propName, typeName);
            code.put(contract);
            code.putScope((_)
            {
                code.putf("assert(!Systems._finalised, \"Attempted to set the value of '%s' after the data has been finalised.\");", 
                          propName);
                code.putf("assert((\"%s\" in Systems._setFlags) is null, \"Attempted to set the value of '%s' more than once.\");",
                          propName, propName);

                code.putf("Systems._setFlags[\"%s\"] = true;", propName);
                code.putf("Systems.%s = cast(%s)value;", varName, typeof(Prop).stringof); // Cast away const. I know it's bad but it's needed ;(
            });

            // ==========
            // = Getter =
            // ==========
            code.putf("%s %s(string Module = __MODULE__)()", typeName, propName);
            code.put(contract);
            code.putScope((_)
            {
                code.putf("assert(Systems._finalised, \"Attempted to get the value of '%s' before the data has been finalised.\");",
                          propName);
                // The finalisation function will make sure that this property was set a value, so no need to check it here.

                code.putf("return Systems.%s;", varName);
            });

            return code.data.idup.to!string;
        }
    }
}
