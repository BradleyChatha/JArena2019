module jarena.data.loaders.manager;

private
{
    import std.experimental.logger;
    import jarena.core, jarena.data, jarena.graphics;
}

/// TODO: Document this.
final class AssetManager
{
    private
    {
        Package[string] _packages;
        Cache!Asset     _assets;
    }

    package
    {
        void addPackage(Package pack)
        {
            import std.exception : enforce;

            tracef("Registering package named '%s'", pack.name);
            errorf((pack.name in this._packages) !is null, "Duplicate package name, '%s'.", pack.name);

            foreach(kv; pack.assets.byKeyValue)
                this._assets.add(kv.key, cast(Asset)kv.value);

            destroy(pack.assets);
            this._packages[pack.name] = pack;
        }
    }
    
    public
    {
        ///
        this()
        {
            this._assets = new Cache!Asset();
        }

        /// TODO: Document
        T get(T : Object)(string assetName)
        {
            import std.exception : enforce;

            auto result = this._assets.get(assetName);
            enforce(result != Asset.init, "The asset named '"~assetName~"' does not exist.");

            auto casted = cast(T)result.value;
            assert(casted !is null, "Cannot convert the asset called '"~assetName~"' into a '"~T.stringof~"'");

            return casted;
        }

        /// ditto
        T get(T)(string assetName)
        if(is(T == AnimationInfo))
        {
            return this.get!AnimationInfoClass(assetName);
        }

        /// TODO: Document
        @property
        auto byKeyValueFiltered(T : Object)()
        {
            import std.algorithm : filter, map;

            struct KV
            {
                string key;
                T value;
            }

            return this._assets.byKeyValue.filter!(kv => cast(T)kv.value.value !is null)
                                          .map   !(kv => KV(kv.key, cast(T)kv.value.value));
        }
    }
}