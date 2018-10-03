module jarena.data.loaders.manager;

private
{
    import std.experimental.logger;
    import jarena.core, jarena.data, jarena.graphics;
}

/++
 + This class is responsible for managing all of the packages and assets loaded into the game.
 +
 + Packages (and in turn, assets) can be loaded into the manager via `Loader`s.
 + ++/
final class AssetManager
{
    private
    {
        Package[string]     _packages;
        Cache!PackageAsset  _assets;
    }

    package
    {
        void addPackage(Package pack)
        {
            tracef("Registering package named '%s'", pack.name);
            enforceAndLogf((pack.name in this._packages) is null, "Duplicate package name, '%s'.", pack.name);

            foreach(kv; pack.assets.byKeyValue)
            {
                assert(kv.value.value !is null, "The asset '"~kv.key~"' has a null value. This is not allowed.");
                this._assets.add(kv.key, cast(PackageAsset)kv.value); // Cast away const.
            }

            this._packages[pack.name] = pack;
        }
    }
    
    public
    {
        ///
        this()
        {
            this._assets = new Cache!PackageAsset();
        }

        /++
         + Attempts to unload the specified package.
         +
         + Notes:
         +  Currently, this function has no protection against an exception being thrown during the unloading
         +  process. This means the manager's data can be left in a weird limbo state.
         +
         + Process:
         +  This function will go over all the assets that belongs to the package, and perform the following operations.
         +
         +  [All] Every asset will be removed from the asset manager's cache, so it can no longer be fetched.
         +
         +  [IDisposable] Any asset castable to `IDisposable` will have it's `dispose` function called.
         +
         +  Furthermore, any refrences made to these assets by the AssetManager will be removed, so it is up
         +  to the GC for when assets are actually properly unloaded. (It's a tricky issue to solve, flat out destroying assets
         +  without causing crashes, so I leave it to the GC.)
         +
         +  This does however mean the objects themselves will still exist, but it no new references to them can be
         +  obtained from the AssetManager, and depending on the object (e.g. if it's `IDisposable`) it will no longer
         +  be useable.
         +
         + Params:
         +  packageName = The name of the package to unload.
         +
         + Returns:
         +  `true` if the package was unloaded. `false` if it wasn't (for example, if the package doesn't exist).
         + ++/
        bool unloadPackage(string packageName)
        {
            tracef("Unloading package '%s'", packageName);

            if((packageName in this._packages) is null)
                return false;

            // Remove the package.
            auto package_ = this._packages[packageName];
            this._packages.remove(packageName);

            // And then it's assets.
            foreach(kvp; package_.assets.byKeyValue)
            {
                auto asset = this._assets.get(kvp.key).value;
                this._assets.remove(kvp.key);

                // Perform the special unloading stuff.
                if(cast(IDisposable)asset !is null)
                    (cast(IDisposable)asset).dispose();
            }

            return true;
        }

        /++
         + Gets an asset that has been loaded in by a package.
         +
         + Assertions:
         +  The cast to `T` must not result in `null`.
         +
         + Params:
         +  T = The type to cast the object to.
         +  assetName = The name of the asset to get.
         + ++/
        T get(T : Object)(string assetName)
        {
            import std.exception : enforce;

            auto result = this._assets.get(assetName);
            enforceAndLogf(result != PackageAsset.init, "The asset named '"~assetName~"' does not exist.");

            auto casted = cast(T)result.value;
            assert(casted !is null, "Cannot convert the asset called '"~assetName~"' into a '"~T.stringof~"'");

            return casted;
        }

        /// ditto
        T get(T)(string assetName)
        if(is(T == struct))
        {
            return this.get!(StructWrapperAsset!T)(assetName);
        }

        /++
         + Returns:
         +  An InputRange of (string key, T value) going over all assets that can be
         +  sucessfully cast to type `T`.
         + ++/
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

        /// ditto
        @property
        auto byKeyValueFiltered(T)()
        if(is(T == struct))
        {
            import std.algorithm : map;
            return this.byKeyValueFiltered!(StructWrapperAsset!T).map!(a => a.value);
        }
    }
}