///
module jarena.data.loaders.core;

private
{
    import core.thread : Fiber;
    import std.traits, std.experimental.logger, std.typecons;
    import jarena.core, jarena.gameplay.scene;

    /++
    Capabilities of the new loader:
        - New data structure
        
            - Previously, loading in assets was rather 'loose'. You'd pass any file to the loader and it'll figure out
              the correct extension to use, which would then cache it into a cache you passed through.

            - This meant that you'd pass in the "Data:file" file, and in the user code just use the cache hoping that
              everything was loaded in properly.

            - I wish to remedy this, in creating a formal structure for how data is read in and stored.

            - Data is now stored within 'packages', which represent a formal 'package' of assets.

            - Similar to the old "Data:file" file, packages have a master 'Package' file, listing all of the assets
              making up the package, as well as other metadata (such as the name of the package).

            - Multiple packages can be loaded, and more interestingly they can be unloaded.

            - There will be a new system added to the engine called `AssetManager` (preferrably accessed as Systems.assets).

            - Loaders provide the functionality of loading in packages, while the AssetManager provides the functionality of
              accessing the data and other information about these packages. This distinction is important, as it allows
              packages to be defined in various other forms (via different loaders + extension sets) while keeping a unified,
              and seperate interface for accessing the actual data of these packages.

            - The AssetManager contains an internal cache of `Object`s, representing all of the assets that have been loaded
              by the various registered packages. It will then provide a templated interface to easily, and safely convert each
              `Object` into the desired, original class.
                
                - It is more likely that instead of directly storing an `Object` in the cache, the manager stores
                  a struct/class containing both the `Object` as well as various metadata about the asset.

                - Packages will also contain this kind of asset cache, but it is only for the loading process and is short lived (see below).
                  Packages however, will still retain an array of strings, representing the names of all of it's assets.

            - Whenever a new package is fully loaded, it is handed over to the AssetManager.
                - The AssetManager will then move all loaded assets into it's internal cache.
                  The asset cache inside of the package is then destroyed, as it is no longer needed and is just using up memory.

            - Whenever a package is set to be unloaded, the AssetManager is informed of which package to unload.
                - The AssetManager will go over an array of strings in the Package, which contains the names of all assets it has loaded.
                  It will then look up these strings in it's cache, and first of all retrieve it from the cache, before removing it.

                [Likely won't be implemented at first]
                - The object is retrieved from the cache first, as the manager will then check to see if it inherits from certain
                  classes/interfaces, as well as to check if it has certain flags set which define how it handles being unloaded.

                - In cases where there isn't a defined behaviour for unloading the object, it is simply removed from the cache.
                  This means the manager will no longer provide it to any code asking for it.
                  However, this also means any existing references to the object will:
                    - #1, prevent the GC from destroying it as there are still references to it, meaning it's memory will still be used.
                    - #2, it can still be used despite the package being 'unloaded', which makes the word 'unloading' a bit of a loose term.

                    - The object cannot be told to be destroyed manually, as then unusual 'Object access violation' errors may be thrown
                      when old references to the object are used.

        - Extensions can be registered and used at runtime, instead of relying on a compile-time list of them.
        
            - This will fix a giant hurdle in making this engine easily reusable for future projects, since my plan
              is to seperate the engine code from the game code, as I really like this engine (I also really hate parts of it,
              but those can be fixed :)).

            - Names are unique. Two packages cannot create an asset with the same name.

            - I do recognise however, that this will lower the performance of loading in assets. My counter to that however is that
              there is little chance I'll make a game that has unacceptably bad load times with this system.

            - I also recognise that certain features of the new loader will make more use of the GC than the previous version.
              While it's a band-aid fix, the loader should force a GC collection after it has loaded in a package.

        - Instead of referencing file paths, assets must now use names that all other files provide.
          For example, a SpriteAtlas will register by the name of "atlas_PlayerCharacter", and an animation file
          will reference it by that name.

            - This gets rid of the headache of trying to make sure all of these paths are correct, and the very annoying issue
              of trying to determine if an asset has already been loaded in just by going off it's file path.

            - This adds an extra issue, without telling the loader what the file path of the asset is, it has no way of loading in
              any referenced assets that haven't been cached yet. My solution is described under 'fiber-based loading'.

        - Fiber-based loading system. An extention's loading process is handled inside of a fiber.

            - This allows an easy way for the loader the pause the loading of assets, suited to an extention's need.

            - For example, imagine that an animation file is loaded in, and references "atlas_Explosion", but the file that contains
              that atlas hasn't been loaded in yet. The extension can flag that it should only continue loading once an asset with that name
              has been loaded.

            - It will be defined that two assets that reference eachother is an error. e.g "asset_One" referencing "asset_Two", which
              then also references "asset_One" again, is an error. 'error' in this case meaning an exception is thrown, not D's `Error` class.

            - Imagine that there is a extension for Animations, and that there are two animations to load in. The first animation has to go on pause
              because of a missing asset, while the second animation can be loaded in while the first is paused. How does the extension handle it's internal
              state when it has to load in one asset, while another asset is mid-way through being loaded?
                - My answer to this is, the loader has functionality to store 'UserState' objects, which are defined by extensions.
                  Then, anytime an asset needs to be loaded, the extension tells the loader to create a UserState for the extension, which is
                  bound to the asset it is currently loading in.
    ++/
}

/++
 + Some libraries may have $(I issues) (read: crashes) when loading data within a fiber.
 +
 + To get around this, the extension loading the data can return this class, which should function
 + almost identically to the normal `LoaderExtension.onLoadAssets` function, except that it will instead be ran outside
 + of a fiber, preventing any of these strange crashes.
 +
 + $(B Beware) that `LoaderExtension.waitForAsset` $(B cannot) be used inside of the loading function, as it's
 + functionality relies on fibers. To get around this, all calls to this function should be made $(I before) returning
 + an object of this type (so it's all done in a fiber). If the loading function given to this object requires a call to `waitForAssets` 
 + to properly function, then it is deemed unsupported by the loading system and unfortunately, a work around will have to be found.
 + ++/
class DelayedLoadAsset
{
    alias FuncT = PackageAsset[] delegate();

    /// The function that loads in the assets.
    FuncT loadFunc;

    ///
    this(FuncT loadFunc)
    {
        assert(loadFunc !is null);

        this.loadFunc = loadFunc;
    }
}

/++
 + This class is wrapped around a struct, and has special support in the `AssetManager`.
 +
 + Anytime a struct needs to be loaded as an asset, use this class instead of a custom one.
 + ++/
class StructWrapperAsset(T)
if(is(T == struct))
{
    alias value this;
    T value;

    this()(T value)
    {
        this.value = value;
    }
}

package struct Package
{
    string name;
    Cache!PackageAsset assets;
}

/++
 + Contains information about an asset.
 + ++/
struct PackageAsset
{
    /// The name of the asset. Must be unique between packages.
    string name;

    /// The asset itself. Must not be null.
    Object value;
}

/++
 + The base class of a loader.
 +
 + The loader is responsible for parsing package files, and loading in the assests a package contains.
 +
 + The way a loader loads in assets is through `Extension`s, which are what provide the functionality of loading in assets.
 +
 + Loaders will create a new Fiber for every asset it wants to load in, which is used as the main mechanic around 
 + dependency resolution. For example, if a SpriteAtlas needs a certain texture, but that texture hasn't been loaded yet,
 + then the extenion that is loading the SpriteAtlas will tell the loader to pause it's Fiber until the texture has been loaded.
 + ++/
abstract class Loader
{
    /// Debug information that loaders can provide so exceptions are given more informative messages.
    struct DebugInfo
    {
        /// The name/file path/some kind of identifying info of the asset.
        string assetName;
    }

    private final
    {
        /// Information about a loading process.
        struct LoadingInfo
        {
            /// Mostly just for debug output.
            int id;

            /// The extension being used.
            LoaderExtension extension;

            /// The fiber being used for loading.
            Fiber fiber;

            /// Debug info about the loading process.
            DebugInfo debugInfo;
        }

        /// Information about a loading task that is waiting for a certain asset.
        struct OnHold_WaitingForAsset
        {
            LoadingInfo info;
            string assetName;
        }
        
        // Variables for extensions
        LoaderExtension[string] _extensions;

        // Variables for loading
        LoadingInfo    _currentTask;
        LoadingInfo[]  _loadingList;
        PackageAsset[] _lastResult; // After a fiber is done loading, it will set this to the result.
        Package        _currentPackage;
        Object         _lastLoadedAsset; // Used for waitForAsset.

        // Waiting lists
        string[]                 _loadedAssets; // Used to clean up the _waitingForAssetList
        OnHold_WaitingForAsset[] _waitingForAssetList;

        void executeTask(LoadingInfo task)
        {
            // Execute the task
            this._currentTask = task;
            auto thrown       = task.fiber.call(Fiber.Rethrow.yes);
            this._currentTask = LoadingInfo.init;
            assert(thrown is null, "Not handled yet.");

            // Then do stuff depending on it's state.
            if(task.fiber.state == Fiber.State.HOLD)
                info("The task was put on hold.");
            else if(task.fiber.state == Fiber.State.TERM)
            {
                // It finished loading, and _lastResult was set.
                infof("The task finished, with %s assets loaded. Adding them to the current package.", 
                      this._lastResult.length);

                foreach(asset; this._lastResult)                    
                    this.onAssetLoad(asset);
            }
            else // EXEC
                assert(false, "It's still somehow running?");
        }

        void onAssetLoad(PackageAsset asset)
        {
            if(this._currentPackage.assets is null)
                this._currentPackage.assets = new Cache!PackageAsset();

            // Perform the delayed loading
            auto delayed = (cast(DelayedLoadAsset)asset.value);
            if(delayed !is null)
            {
                info("Performing delayed load.");
                foreach(delayedAsset; delayed.loadFunc())
                    this.onAssetLoad(delayedAsset);

                return;
            }

            this._currentPackage.assets.add(asset.name, asset);

            // Wake up any fibers that were waiting on this asset, and then mark the fibers to be removed from
            // the waiting list.
            foreach(task; this._waitingForAssetList)
            {
                if(task.assetName == asset.name)
                {
                    infof("Waking up task #%s, as the asset called '%s' was added.",
                          task.info.id, task.assetName);

                    this._loadedAssets ~= task.assetName;

                    this._lastLoadedAsset = asset.value;
                    this.executeTask(task.info);
                }
            }
        }

        /////////////////////////
        /// Waiting functions ///
        /////////////////////////
        Object waitForAsset(LoaderExtension extension, string assetName)
        {
            if(this._currentTask == LoadingInfo.init)
                assert(false, "This function was called outside a loading task.");

            assert(extension == this._currentTask.extension, "This function was called with the wrong extension.");

            // Check if it's already cached.
            if(this._currentPackage.assets !is null)
            {
                auto cached = this._currentPackage.assets.get(assetName);
                if(cached != PackageAsset.init)
                {
                    infof("No need to wait for asset '%s' as it's already cached.", assetName);
                    return cached.value;
                }   
            }

            // Otherwise add it to the waiting list.
            infof("Placing task on hold, as it is waiting for an asset named '%s'", assetName);
            this._waitingForAssetList ~= OnHold_WaitingForAsset(
                this._currentTask, assetName
            );

            // The asserts make sure this function is only being ran during a loading task, which is in it's own Fiber.
            // So this should be fine.
            Fiber.yield(); // When this Fiber is resumed, _lastLoadedAsset will be set to the asset that it was waiting for.
            return this._lastLoadedAsset;
        }
    }

    protected final
    {
        /++
         + Cleans the variables used to keep track of the state of loading a package.
         +
         + It's recommended that this function is called at the start of `Loader.loadPackage` to reducse
         + the risk of left-over state causing bugs.
         + ++/
        void cleanLoadingState()
        {
            this._loadingList         = null;
            this._lastResult          = null;
            this._currentPackage      = Package.init;
            this._currentTask         = LoadingInfo.init;
            this._waitingForAssetList = null;
            this._loadedAssets        = null;
        }

        /++
         + Adds a task to load in assets from a piece of data.
         +
         + Notes:
         +  `Loader.doTasks` must be called before the task is actually performed.
         +
         + Params:
         +  extension = The extension to use to load in the data.
         +  data      = The data to load in.
         +  debugInfo = Debug information about the data being loaded in. Used mostly for pretty exception messages.
         + ++/
        void addLoadingTask(LoaderExtension extension, const(ubyte[]) data, DebugInfo debugInfo = DebugInfo.init)
        {
            assert(extension !is null);

            LoadingInfo info;
            info.extension = extension;
            info.fiber     = new Fiber((){this._lastResult = extension.onLoadAssets(this, data);});
            info.id        = cast(int)this._loadingList.length; // The cast is fine for this case.
            info.debugInfo = debugInfo;

            infof("Created loading task #%s for extension '%s' with data with of length '%s'.",
                  info.id, extension, data.length);

            this._loadingList ~= info;
        }

        /++
         + Performs all added tasks.
         +
         + Notes:
         +  There is currently no way to reset a select few internal variables that this function uses, without
         +  dumping all the currently loaded progress. So only call this function *After* adding in every loading task
         +  that will be needed.
         +
         +  After all tasks have been executed (but not finished). If any tasks that are still waiting for something
         +  are still listed, then an exception is thrown as it means that whatever they're waiting for will never happen.
         +
         +  This exception should prevent the package from being finalised.
         + ++/
        void doTasks()
        {
            trace("Executing tasks");

            string[] debugLoadedAssets;
            foreach(taskI, task; this._loadingList)
            {
                // Execute the task
                infof("Executing task #%s, with extension '%s'.", task.id, task.extension);

                // Catch any exceptions, and gather up enough information for a nice looking exception.
                try 
                    this.executeTask(task);
                catch(Exception ex)
                {
                    import std.algorithm : map, filter, canFind;
                    import std.array     : array;

                    PackageLoadFailedException.Info info;
                    info.loadedNames = debugLoadedAssets;
                    info.failedInfo  = task.debugInfo;
                    info.waitingInfo = this._waitingForAssetList.map!(waiting => PackageLoadFailedException.WaitingInfo(waiting.info.debugInfo, waiting.assetName))
                                                                .array;
                    info.loadedInfo  = this._loadingList[0..taskI].filter!(task => !this._waitingForAssetList.canFind!"a.info == b"(task))
                                                                  .map!(task => task.debugInfo)
                                                                  .array;
                    info.notExecutedInfo = (taskI == this._loadingList.length - 1) ? null : this._loadingList[taskI+1..$].map!(task => task.debugInfo).array;
                    info.trace = ex.info.toString();

                    throw new PackageLoadFailedException(info, ex.message.idup);
                }

                // Then clean up the waiting list
                foreach(loadedAsset; this._loadedAssets)
                {
                    for(size_t i = 0; i < this._waitingForAssetList.length; i++)
                    {
                        if(this._waitingForAssetList[i].assetName == loadedAsset)
                        {
                            this._waitingForAssetList.removeAt(i);
                            i -= 1;
                        }
                    }
                }
                debugLoadedAssets ~= this._loadedAssets;
                this._loadedAssets.length = 0;
            }

            // If any dependencies weren't resolved, then throw an exception.
            if(this._waitingForAssetList.length > 0)
            {
                import std.algorithm : joiner, map, uniq;
                import std.array     : array;

                errorf("The following dependencies were not found, so the package cannot be loaded: %s",
                       this._waitingForAssetList.map!(a => a.assetName).uniq.joiner(", "));
            }
        }

        /++
         + Sets the name of the package that is being loaded in.
         +
         + Notes:
         +  If the name is not set by the time `Loader.finalisePackage` is called, then an assert is failed.
         +
         + Params:
         +  name = The name to give the package.
         + ++/
        void setPackageName(string name)
        {
            this._currentPackage.name = name;
        }

        /++
         + Finalises the package.
         +
         + This will pass the package over to the `AssetManager`, and then call `Loader.cleanLoadingState`.
         + 
         + Notes:
         +  This function forces a GC collection to clean up the memory used from loading.
         +
         +  `Loader.setPackageName` must be called before this, otherwise an assert fails.
         + ++/
        void finalisePackage()
        {
            import core.memory : GC;

            if(this._currentPackage.name is null)
                assert(false, "The package's name was not set before finalisation.");

            Systems.assets.addPackage(this._currentPackage);
            trace("Package finalised.");
            this.cleanLoadingState(); // Reminder: Do this AFTER passing it to the AssetManager.
            GC.collect();
        }
    }

    public abstract
    {
        /++
         + Loads the package at the given file path.
         +
         + Implemenation_Notes:
         +  It is recommended to call `Loader.cleanLoaderState` before anything else, just in case the old state was left over.
         +
         +  The loader should then load in the file at `filePath` and begin parsing the file.
         +
         +  When the loader has identified an asset that needs loading, it should use `getExtensionFor` alongside any type
         +  information stored in the file to identify which extension should be used.
         +
         +  A call to `Loader.addLoadingTask` should then be made using all the information the loader has for this asset.
         +
         +  Repeat as many times as neccessary, then called `Loader.doTasks` to perform the actual loading.
         +
         +  Finally, call `Loader.finalisePackage` to send the package to the `AssetManager`.
         + ++/
        void loadPackage(const(char[]) filePath);
    }

    public final
    {
        /++
         + Sets an extension for a certain data type.
         +
         + Notes:
         +  Extensions are what provide the functionality for loading in data.
         +
         +  How the `type` is used and what it means is defined by each loader.
         +
         + Params:
         +  type      = A string representing the type of data this extension can load.
         +  extension = The extension to register.
         + ++/
        void setExtensionFor(string type, LoaderExtension extension)
        {
            assert(extension !is null, "The extension is null.");
            assert(type !is null, "The type is null.");
            assert((type in this._extensions) is null, "There is already an extension registered for '"~type~"'");

            this._extensions[type] = extension;
        }

        /++
         + Throws:
         +  `Exception` if there is no extension registered for `type`.
         +
         + Params:
         +  type = The type of data that the extension loads.
         +
         + Returns:
         +  The extension for a certain type of data.
         + ++/
        LoaderExtension getExtensionFor(string type)
        {
            import std.exception : enforce;

            auto ptr = (type in this._extensions);
            enforce(ptr !is null, "There is no extension registered for type '"~type~"'");
            return *ptr;
        }
    }
}

/++
 + Defines an extension.
 +
 + Extensions are what provide the functionality for `Loader`s to load in various game assets.
 +
 + It is up to each `Loader` to define the way extensions are used.
 + ++/
abstract class LoaderExtension
{
    protected
    {
        /++
         + Called whenever the extension is used to load in assets.
         +
         + Notes:
         +  The contents of `data` are dependent on the loader. As all extensions
         +  should only be written for a certain loader, this is a non-issue.
         +
         +  An array must be returned, as there is a possibility the `data` can contain multiple assets.
         +
         +  The code in this function is ran in a Fiber exclusive to the loading of assets from `data`.
         +
         + Params:
         +  loader = The loader that is using this extension.
         +  data   = The data that the loader has given to this extension.
         +
         + Returns:
         +  An array of all the assets that could be loaded from the given data.
         + ++/
        PackageAsset[] onLoadAssets(Loader loader, const(ubyte[]) data);

        /++
         + A helper function to easily check and treat the given data as valid UTF-8 text.
         +
         + Params:
         +  data = The data that the loader has given to this extension.
         +
         + Returns:
         +  `data` casted to a char[], but only after checking that it's valid UTF-8.
         + ++/
        final const(char[]) dataAsText(return const(ubyte[]) data)
        {
            import std.utf : validate;

            auto text = cast(const(char[]))data;
            validate(text);
            return text;
        }

        /++
         + Instructs the loader to pause the current loading task until an asset
         + with a certain name is loaded in.
         +
         + Params:
         +  T         = The type to cast the PackageAsset to.
         +  loader    = The loader that is using this extension.
         +  assetName = The name of the asset to wait for.
         +
         + Returns:
         +  The asset that was loaded in.
         + ++/
        final T waitForAsset(T : Object)(Loader loader, string assetName)
        {
            assert(loader !is null);
            return cast(T)loader.waitForAsset(this, assetName);
        }
    }
}

/// An exception thrown by a `Loader` when it fails to load in a package.
/// For now, throwing this exception can only be done internally (since there's no way to gather the `PackageLoadFailedException.Info` from the outside).
class PackageLoadFailedException : Exception
{
    struct WaitingInfo
    {
        Loader.DebugInfo info;
        string assetName;

        string toString()
        {
            import std.format : format;
            return format("\"%s\" needed by %s", this.assetName, this.info);
        }
    }

    struct Info
    {
        // Loaded assets.
        // On wait assets.
        // File that failed.
        string[]            loadedNames;
        Loader.DebugInfo[]  loadedInfo;
        WaitingInfo[]       waitingInfo;
        Loader.DebugInfo[]  notExecutedInfo;
        Loader.DebugInfo    failedInfo;
        string              trace;
    }

    Info info;

    this(Info info, string reason, string file = __FILE__, int line = __LINE__)
    {
        import std.array     : appender;
        import std.format    : format;
        import std.algorithm : map, joiner;
        import std.conv      : to;
        this.info = info;

        auto output = appender!(char[]);
        output.put("Uncaught exception while loading package.\n");
        output.put("FAILED:\n");
        output.put("\tInfo: %s\n".format(this.info.failedInfo));
        output.put("\tReason: %s\n".format(reason));
        output.put("\tTRACE:\n%s".format(this.info.trace));
        output.put("LOADED(Debug Info):\n\t");
        output.put(this.info.loadedInfo.map!(to!string).joiner("\n\t"));
        output.put("\nLOADED(Asset Names):\n\t");
        output.put(this.info.loadedNames.joiner("\n\t"));
        output.put("\nWAITING:\n\t");
        output.put(this.info.waitingInfo.map!(to!string).joiner("\n\t"));
        output.put("\nNOT YET RAN:\n\t");
        output.put(this.info.notExecutedInfo.map!(to!string).joiner("\n\t"));

        super(output.data.idup, file, line);
    }
}