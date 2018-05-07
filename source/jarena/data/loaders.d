///
module jarena.data.loaders;

private
{
    import std.traits, std.experimental.logger, std.typecons;
    import sdlang;
    import jarena.audio, jarena.core, jarena.graphics, jarena.gameplay, jarena.data.serialise;

    /// Let's face it, SceneMultiCache is the only cache that's actually going to be used with the loaders.
    /// So we may as well just keep in sync with that.
    alias LoaderCache = SceneManager.SceneMultiCache;
    
    /// type "{Group}:{Type}"
    struct Group
    {
        string name;
    }

    /// type "{Group}:{Type}"
    struct Type
    {
        string name;
    }

    /// Notes: Mandatory tags must be processed first.
    struct Mandatory{}

    /// Specifies a function which is used to handle a certain tag.
    struct ForTag
    {
        string tagName;
    }

    /// Easy way to get a vector from SDLang.
    @Serialisable
    struct SdlangVector(vect)
    {
        mixin SerialisableInterface;
        
        vect value;
    }
}

/++
 + Enforces that a type is formed correctly as a LoaderExtension.
 +
 + Notes:
 +  If the enforce passes, this template evaluates to `true`.
 +
 +  Otherwise, a `static assert` will fail detailing the issue with `T`.
 +
 + Params:
 +  T        = The type to check
 +  TagType  = The tag type passed to `LoaderExtension` that `T` should be able to handle.
 +  fileType = The @FileType that `T` should specify it's able to handle.
 + ++/
template EnforceLoaderExtensionFor(T, TagType)
{
    enum TName = T.stringof;
    
    static assert(is(T : LoaderExtension!TagType), "The type "~TName~" doesn't inherit from " ~ LoaderExtension!TagType.stringof);
    static assert(hasUDA!(T, Group),               "The type "~TName~" is missing @Group");
    static assert(hasUDA!(T, Type),                "The type "~TName~" is missing @Type");

    enum EnforceLoaderExtensionFor = true;
}

/++
 + Provides functions that can load certain assets from an SDLang file.
 + ++/
class SdlangLoader
{
    import std.typetuple : AliasSeq;
    import std.meta      : allSatisfy;
    import codebuilder;

    // All the extensions to use    
    alias Extensions = AliasSeq!(SpriteAtlasSDL,
                                 AnimationSpriteSheetSDL,
                                 DataFileSDL,
                                 DataListSDL);
    alias ExtensionT = LoaderExtension!Tag;

    // Validate that the extensions are correctly formed.
    enum IsExtension(T) = EnforceLoaderExtensionFor!(T, Tag);
    static assert(allSatisfy!(IsExtension, Extensions));

    private static
    {
        mixin(__genExtensionVars());
    }
    
    public static
    {
        void setup()
        {
            mixin(__genExtensionCtor());
        }

        /++
         + Parses the given SDLang tag.
         +
         + Notes:
         +  The tag must have a `type` tag, and a `name` tag (unless it belongs to the "Data" group of tags).
         +
         +  The `type` is used to determine what kind of data the tag stores, and how to load it in.
         +
         +  The `name` is used to cache the data inside the tag.
         +
         + Params:
         +  tag     = The tag to parse.
         +  path    = Tags are expected to come from files.
         +            This parameter is the path to said file.
         +            It's important that this is correct, as a lot of tags need to use this path for
         +            path resolution.
         +  caches  = Used to cache any loaded data.
         + ++/
        void parseTag(Tag tag, string path, LoaderCache caches)
        {
            import std.path : isAbsolute;
            assert(path.isAbsolute);

            auto tagType = tag.expectTagValue!string("type");
            ExtensionT extension;
            switch(tagType)
            {
                mixin(__genExtensionDispatch()); // Sets 'extension' to the correct one.

                default:
                    throw new Exception("No extension is registered for type: '" ~ tagType ~ "'");
            }
            assert(extension !is null);

            // The data group is a special case - They don't have a name.
            auto isDataExt = (typeid(extension) == typeid(DataFileSDL)
                           || typeid(extension) == typeid(DataListSDL));
            auto name = (isDataExt) ? "Data File" : tag.expectTagValue!string("name");
            extension.updateInternalData(name, tagType, path);

            bool alreadyCached;
            extension.onNewFile(alreadyCached, caches);

            if(!alreadyCached)
            {
                extension.handleTag(tag, caches);
                extension.onEndFile(caches);
            }
        }

        /++
         + An easy way to load a tag from a file, and pass it to `parseTag`.
         + ++/
        void parseFile(string path, LoaderCache caches)
        {
            import std.exception : enforce;
            import std.path      : isAbsolute, buildNormalizedPath;
            import std.file      : getcwd, exists;
            import sdlang.parser : sdlParse = parseFile;

            if(!path.isAbsolute)
                path = buildNormalizedPath(getcwd(), path);
            assert(path.isAbsolute);
            enforce(path.exists, "No file exists at '" ~ path ~ "'");

            SdlangLoader.parseTag(sdlParse(path), path, caches);
        }
    }

    // Codegen
    private static
    {
        // __ = Boilerplate.
        string __varNameForExtension(E)()
        {
            enum Group = getUDAs!(E, Group)[0].name;
            enum Type  = getUDAs!(E, Type)[0].name;

            return "_" ~ Group ~ "_" ~ Type;
        }
        
        dstring __genExtensionVars()
        {
            auto code = new CodeBuilder();

            foreach(ext; Extensions)
                code.putf("%s %s;", ext.stringof, __varNameForExtension!ext);
            
            return code.data.idup;
        }

        dstring __genExtensionCtor()
        {
            auto code = new CodeBuilder();

            foreach(ext; Extensions)
                code.putf("%s = new %s();", __varNameForExtension!ext, ext.stringof);
            
            return code.data.idup;
        }

        dstring __genExtensionDispatch()
        {
            auto code = new CodeBuilder();

            foreach(ext; Extensions)
            {
                code.putf(`case "%s:%s":`, getUDAs!(ext, Group)[0].name, 
                                           getUDAs!(ext, Type)[0].name);
                code.entab();
                    code.putf("extension = %s;", __varNameForExtension!ext);
                    code.put("break;");
                code.detab();
            }

            return code.data.idup;
        }
    }
}

private abstract class LoaderExtension(TagType)
{
    private final
    {
        string _typeName;  // Something like "Animation:list", "SpriteAtlas:atlas", etc.
        string _assetName; // The 'name' tag.
        string _filePath;  // Path to the file being loaded.

        void updateInternalData(string name, string typeName, string filePath)
        {
            import std.path : isAbsolute;

            assert(name !is null);
            assert(typeName !is null);
            assert(filePath !is null);
            assert(filePath.isAbsolute);
            
            this._typeName  = typeName;
            this._filePath  = filePath;
            this._assetName = name;
        }
    }
    
    protected final
    {
        ///
        void enforcef(T, Params...)(T value, lazy const(char)[] formatStr, lazy Params params)
        {
            import std.exception : enforce;
            import std.format    : format;

            enforce(value, format("%s Error: ", this)
                         ~ format(formatStr, params));
        }

        ///
        void log(int line                = __LINE__, 
                 string file             = __FILE__,
                 string funcName         = __FUNCTION__,
                 string prettyFuncName   = __PRETTY_FUNCTION__,
                 string moduleName       = __MODULE__, Params...)
                (const(char)[] formatStr, Params params)
        {
            import std.format : format;
            
            infof!(line, file, funcName, prettyFuncName, moduleName)("%s %s", this, format(formatStr, params));
        }

        ///
        string resolvePath(string path)
        {
            import std.path : isAbsolute, dirName, buildNormalizedPath;

            return (path.isAbsolute) ? path
                                     : buildNormalizedPath(dirName(this._filePath), path);
        }

        /++
         + This function is used to resolve reference paths and then retrieves them from the loader's cache.
         +
         + Algorithm:
         +  First, if `isRelative` is `Yes.isRelative`, then assume that `path` is relative to the file being loaded, and resolve it to an absolute path.
         +  (Using `resolvePath`)
         +
         +  Second, check to see if this path is already present in `caches` (for type `T`), and if it is, then return
         +  the cached value. Otherwise continue.
         +
         +  Third, parse the file at `path` (if it exists) as an SDLang file, and look for a tag called 'name'.
         +  If the tag doesn't exist, or doesn't contain a string as a value, then return null.
         +  If the file couldn't be parsed as an SDLang file or doesn't exist, return null.
         +  If the tag does exist, then see if the value of the 'name' tag is cached. If it is, return the cached value,
         +  otherwise, return null.
         +
         + Notes:
         +  The convention for using a reference tag inside of an SDLang file is as such
         +  '[name_of_asset_type]Ref'. For example, animations use an 'atlasRef' tag to provide a reference
         +  to the path of which atlas contains the animation frames.
         +
         +  For now, this function is hard coded to only work for SDLang files.
         +
         +  $(B This function does not load in the asset at the given path, it simply retrieves it from the cache)
         +
         +  In most cases, assets aren't cached via their path, but by using the 'name' tag within the asset's file.
         +
         +  Since I feel the use of this function has a large potential for headaches and "bugs", it will litter
         +  the log with detail of everything it's doing to provide an easy way to see what's going "wrong".
         +
         + Params:
         +  caches      = The cache of the loader being used.
         +  path        = The path of the file to get the cached value of.
         +  isRelative  = If `Yes.isRelative`, then the `path` given is relative to the file being loaded.
         +                Otherwise, `No.isRelative` implies it is an absolute path already.
         +
         + Returns:
         +  Either the cached value, or `null`.
         + ++/
        T loadReferencePath(T)(LoaderCache caches, string path, Flag!"isRelative" isRelative = Yes.isRelative)
        {
            import std.file : exists;
            assert(caches !is null);

            // Step #1
            if(isRelative)
            {
                this.log("Resolving path '%s'", path);
                path = this.resolvePath(path);
            }
            this.log("Using path '%s'", path);

            // Step #2
            auto cached = caches.get!T(path, null);
            if(cached !is null)
            {
                this.log("The asset was cached already, returning cached value");
                return cached;
            }
            this.log("The asset hasn't been cached via it's path, attempting to load the path as an SDLang file.");

            // Step #3
            if(!path.exists)
            {
                this.log("The path doesn't point to an existing file, returning null.");
                return null;
            }

            Tag tag;
            try tag = parseFile(path);
            catch(SDLangException ex)
            {
                this.log("Unable to load the file as an SDLang file, returning null.\nError: %s", ex.msg);
                return null;
            }

            this.log("The file was parsed successfully, checking for a 'name' tag now.");
            auto nameTag = tag.getTag("name");
            if(nameTag is null)
            {
                this.log("The file does not contain a 'name' tag, cannot continue, returning null.");
                return null;
            }

            this.log("Name tag found, checking to see if it contains a string value, and then performing a cache check.");
            if(nameTag.values.length == 0)
            {
                this.log("The name tag contains no values, returning null.");
                return null;
            }

            auto nameValue = nameTag.values[0];
            if(nameValue.peek!string is null)
            {
                this.log("The value of the name tag isn't a string, returning null.");
                return null;
            }

            auto name = nameValue.get!string;
            this.log("Checking the cache for '%s'", name);

            cached = caches.get!T(name, null);
            if(cached !is null)
            {
                this.log("The name was found, returning cached value.");
                return cached;
            }
            this.log("The name wasn't found, returning null.");
            return null;
        }
        
        ///
        @property
        string name()
        {
            return this._assetName;
        }
    }

    public final
    {
        override string toString()
        {
            import std.format : format;
            return format(`[Asset "%s" of type %s]`, this._assetName, this._typeName);
        }
    }

    // Override these as needed
    public
    {
        /++
         + Called whenever a new file is being loaded by this extension.
         +
         + Use this as an oppurtunity to reset internal state.
         +
         + Set `isCached` to true if `super.name` points to an already cached asset, and it will
         + stop attempting to load in the asset.
         + ++/
        void onNewFile(ref bool isCached, LoaderCache caches){}

        /++
         + Called whenever a file is finished being parsed by this extension.
         +
         + Use this if the extension is unable to cache it's data during an earlier point.
         + ++/
        void onEndFile(LoaderCache caches){}
        
        /// Should only be generated by `ExtensionBoilerplate`
        void handleTag(TagType tag, LoaderCache caches);
    }
}

private mixin template ExtensionBoilerplate(TagType)
{
    import codebuilder;
    alias ThisType = typeof(this);

    override void handleTag(TagType tag, LoaderCache caches)
    {
        try
        {
            super.log("Parsing tag from path '%s'", super._filePath);
            mixin(__genCases());
        }
        catch(TagNotFoundException ex)
        {
            super.enforcef(false, ex.msg);
        }
    }

    // Here lies a dragon's nest.
    private static dstring __genCases() // __ = Boilerplate.
    {
        import std.format : format;
        auto code    = new CodeBuilder();
        auto switch_ = new CodeBuilder(); // To handle the switch statement

        // Start the code for the switch statement
        // Note, the code for the switch statement is placed *after* the code for the mandatory tags.
        // But some of the code needs to be written outside of the loop.
        switch_.put("foreach(childTag; tag.tags)\n{");
        switch_.entab();
        switch_.put("switch(childTag.name)");
        switch_.put("{");
        switch_.entab();

        // Generate the code for the handlers.
        string[] tagsToIgnore;
        foreach(memberName; __traits(allMembers, ThisType))
        {
            mixin(format("alias FuncAlias = ThisType.%s;", memberName));
            static if(isFunction!FuncAlias && hasUDA!(FuncAlias, ForTag))
            {
                enum TagName     = getUDAs!(FuncAlias, ForTag)[0].tagName;
                enum IsMandatory = hasUDA!(FuncAlias, Mandatory);

                static if(IsMandatory)
                {
                    tagsToIgnore ~= TagName;
                    code.putf("this.%s(tag.expectTag(\"%s\"), caches);", memberName, TagName);
                }
                else
                {
                    switch_.putf(`case "%s":`, TagName);
                    switch_.entab();
                        switch_.putf("this.%s(childTag, caches);", memberName);
                        switch_.put("break;");
                    switch_.detab();
                }
            }
        }

        // Finish off the switch statement.
        foreach(name; tagsToIgnore)
            switch_.putf(`case "%s":`, name);
        switch_.put(`case "type":`);
        switch_.put(`case "name":`);
            switch_.put("\tbreak;");
        
        switch_.put(`default:`);
        switch_.entab();
            switch_.put(`super.enforcef(false, "Unknown tag '%s'", childTag.name);`);
            switch_.put("break;");
        switch_.detab();
        
        switch_.detab();
        switch_.put("}");
        switch_.detab();
        switch_.put("}");

        // Put the switch statement *after* the mandatory code.
        code.put(switch_.data);
        return code.data.idup;
    }
}

@Group("SpriteAtlas")
@Type("atlas")
private final class SpriteAtlasSDL : LoaderExtension!Tag
{
    static assert(canCache!(LoaderCache, SpriteAtlas), "LoaderCache can't store SpriteAtlases");
    static assert(canCache!(LoaderCache, Texture),     "LoaderCache can't store Textures");

    mixin ExtensionBoilerplate!Tag;
    
    private
    {
        @Serialisable
        struct SdlangSprite
        {
            mixin SerialisableInterface;
            
            ivec2 position;
            ivec2 size;
        }

        @Serialisable
        struct SdlangSpriteSheet
        {
            mixin SerialisableInterface;

            ivec2 position;
            ivec2 size;
            ivec2 frameSize;
        }
        
        SpriteAtlas _atlas;
    }

    public
    {
        override void onNewFile(ref bool isCached, LoaderCache caches)
        {
            this._atlas = null;
            isCached = caches.getCache!SpriteAtlas.hasKey(super.name);
        }
        
        @ForTag("textureRef")
        @Mandatory
        void handleTexture(Tag tag, LoaderCache caches)
        {
            import std.file : exists;
            
            auto textureFile = super.resolvePath(tag.expectValue!string);
            super.enforcef(textureFile.exists, "Texture reference at path '%s' doesn't exist.", textureFile);
            super.log("Using texture at path '%s'", textureFile);

            auto texture = caches.loadOrGet(textureFile);
            this._atlas  = new SpriteAtlas(texture);
            caches.add(super.name, this._atlas);
        }

        @ForTag("sprite")
        void handleSprite(Tag tag, LoaderCache caches)
        {
            auto name = tag.expectValue!string;

            super.log("Parsing sprite called '%s'", name);
            auto sprite = SdlangSprite.createFromSdlTag(tag);

            auto frame = RectangleI(sprite.position, sprite.size);
            this._atlas.register(name, frame);
        }

        @ForTag("spriteSheet")
        void handleSpriteSheet(Tag tag, LoaderCache caches)
        {
            auto name = tag.expectValue!string;

            super.log("Parsing spriteSheet called '%s'", name);
            auto sheet = SdlangSpriteSheet.createFromSdlTag(tag);

            auto frame = RectangleI(sheet.position, sheet.size);
            this._atlas.registerSpriteSheet(name, frame, sheet.frameSize);
        }
    }
}

@Group("Animation")
@Type("spriteSheet")
private final class AnimationSpriteSheetSDL : LoaderExtension!Tag
{
    static assert(canCache!(LoaderCache, AnimationInfo), "LoaderCache can't store Animations");

    mixin ExtensionBoilerplate!Tag;

    private
    {
        SpriteAtlas   _atlas;
        AnimationInfo _info;
    }
    
    public
    {
        override void onNewFile(ref bool isCached, LoaderCache caches)
        {
            this._atlas = null;
            this._info  = AnimationInfo.init;

            this._info.name = super.name;

            isCached = caches.getCache!AnimationInfo.hasKey(super.name);
        }
        
        override void onEndFile(LoaderCache caches)
        {
            caches.add(super.name, this._info);
        }

        @ForTag("atlasRef")
        @Mandatory
        void handleAtlasRef(Tag tag, LoaderCache caches)
        {
            auto path  = this.resolvePath(tag.expectValue!string);
            auto atlas = super.loadReferencePath!SpriteAtlas(caches, path, No.isRelative);
            if(atlas is null)
            {
                SdlangLoader.parseFile(path, caches);
                atlas = super.loadReferencePath!SpriteAtlas(caches, path, No.isRelative);
                super.enforcef(atlas !is null, "Unable to load the animation, as the atlas it's referencing could not be loaded.");
            }

            this._atlas = atlas;
        }

        @ForTag("spriteSheetRef")
        @Mandatory
        void handleSpriteSheetRef(Tag tag, LoaderCache caches)
        {
            auto name = tag.expectValue!string;
            super.log("Using sprite sheet called '%s'", name);

            this._info.spriteSheet = this._atlas.getSpriteSheet(name);
        }

        @ForTag("frameDelayMS")
        @Mandatory
        void handleFrameDelayMS(Tag tag, LoaderCache caches)
        {
            this._info.delayPerFrame = tag.expectValue!int.msecs;
            super.log("The animation has a frame delay of '%s'", this._info.delayPerFrame);
        }

        @ForTag("repeat")
        @Mandatory
        void handleRepeat(Tag tag, LoaderCache caches)
        {
            this._info.repeat = tag.expectValue!bool;
            super.log("Repeating Animation? = %s", this._info.repeat);
        }
    }
}

@Group("Data")
@Type("file")
private final class DataFileSDL : LoaderExtension!Tag
{
    static assert(canCache!(LoaderCache, Font), "LoaderCache can't store Fonts");
    
    mixin ExtensionBoilerplate!Tag;

    private
    {
        struct FileInfo
        {
            string path;            // Path to the file.
            string name;            // Some tags allow you to specify the name to cache the file as.
            string[string] params;  // Additional parameters.
        }

        
        // Used to parse 'file' and 'glob' tags, getting any useful data from them.
        FileInfo[] getFileInfo(Tag tag)
        {
            FileInfo[] files;

            void getParams(ref FileInfo fi, Tag tag)
            {
                foreach(attrib; tag.attributes)
                {
                    fi.params[attrib.name] = attrib.value.get!string;
                }
            }

            // Reminder: All paths must either be absolute, or are assumed to be relative to the data file itself.
            switch(tag.name)
            {
                case "file":
                    auto path = tag.expectValue!string;
                         path = super.resolvePath(path);

                    files ~= FileInfo(path);
                    getParams(files[$-1], tag);
                    break;

                case "namedFile":
                    auto values = tag.values;
                    super.enforcef(values.length == 2, "Expected 2 values for 'namedFile' tag, got %s values instead.", values.length);

                    // [0] = name. [1] = path.
                    auto path = values[1].get!string;
                         path = super.resolvePath(path);

                    files ~= FileInfo(path, values[0].get!string);
                    getParams(files[$-1], tag);
                    break;

                case "glob":
                    import std.file : dirEntries, SpanMode;
                    import std.path : dirName;

                    auto baseDir = dirName(this._filePath);
                    auto glob    = tag.expectValue!string;
                    foreach(entry; dirEntries(baseDir, glob, SpanMode.breadth))
                    {
                        FileInfo fi;
                        getParams(fi, tag);
                        fi.path = entry.name;
                        files ~= fi;
                    }
                    break;

                default:
                    super.enforcef(false, "Unknown file tag called '%s'", tag.name);
            }

            return files;
        }

        void handleFiles(Tag tag, void delegate(FileInfo) handler)
        {
            import std.algorithm : map;
            foreach(fileArr; tag.tags.map!(t => this.getFileInfo(t)))
            {
                foreach(file; fileArr)
                    handler(file);
            }
        }
    }

    public
    {
        @ForTag("animations")
        void handleAnimations(Tag tag, LoaderCache caches)
        {
            this.handleFiles(tag, fi => SdlangLoader.parseFile(fi.path, caches));
        }

        @ForTag("atlases")
        void handleAtlases(Tag tag, LoaderCache caches)
        {
            this.handleFiles(tag, fi => SdlangLoader.parseFile(fi.path, caches));
        }

        @ForTag("fonts")
        void handleFonts(Tag tag, LoaderCache caches)
        {
            this.handleFiles(tag, (fi)
            {
                super.log("Loading font from '%s'", fi.path);
                caches.add(fi.name, new Font(fi.path));
            });
        }

        @ForTag("sounds")
        void handleAudio(Tag tag, LoaderCache caches)
        {
            this.handleFiles(tag, (fi)
            {
                super.log("Loading sound from '%s'", fi.path);
                auto shouldStream = fi.params.get("stream", null);
                caches.add(fi.name, new Sound(fi.path, cast(Flag!"streaming")(shouldStream == "yes")));
            });
        }
    }
}

@Group("Data")
@Type("list")
private final class DataListSDL : LoaderExtension!Tag
{
    mixin ExtensionBoilerplate!Tag;

    public
    {
        @ForTag("value")
        void handleValue(Tag tag, LoaderCache caches)
        {
            SdlangLoader.parseTag(tag, super._filePath, caches);
        }
    }
}