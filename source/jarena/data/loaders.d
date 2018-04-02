///
module jarena.data.loaders;

private
{
    import std.traits, std.experimental.logger;
    import sdlang;
    import jarena.core, jarena.graphics, jarena.gameplay, jarena.data.serialise;

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

    /// sdlang, xml, json, etc.
    struct FileType
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
    private enum isExtension(T) = is(T : ExtensionT);
    private enum hasGroup(T)    = hasUDA!(T, Group);
    private enum hasType(T)     = hasUDA!(T, Type);
    private enum hasFileType(T) = hasUDA!(T, FileType) && getUDAs!(T, FileType)[0].name == "sdlang";
    static assert(allSatisfy!(isExtension, Extensions), "One of the extensions doesn't inherit from " ~ ExtensionT.stringof);
    static assert(allSatisfy!(hasGroup,    Extensions), "One of the extensions is missing @Group");
    static assert(allSatisfy!(hasType,     Extensions), "One of the extensions is missing @Type");
    static assert(allSatisfy!(hasFileType, Extensions), "One of the extensions is missing @FileType OR it's not set to 'sdlang'");

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

        // Tries to load `atlasName` from cache.
        //      If it fails, and isPath is true.
        //          Use `atlasName` as a path, and load a .sdl file from it.
        //          Look for a 'name' tag in the loaded file, and re-call this function using it as the `atlasName`.
        //      Otherwise, return null.
        SpriteAtlas loadCachedAtlas(LoaderCache atlases, string atlasName, bool isPath = true)
        {
            assert(atlases !is null);
            
            auto cachedAtlas = atlases.get!SpriteAtlas(atlasName, null);
            if(cachedAtlas !is null)
            {
                this.log("Atlas with key of '%s' is cached, returning...", atlasName);
                return cachedAtlas;
            }

            if(isPath)
            {
                this.log("No atlas was cached with the key of '%s', but it is flagged as being a path, attempting to read a name from it to try again.", atlasName);
                auto tag = parseFile(atlasName);
                auto name = tag.getTagValue!string("name");

                if(name !is null)
                {
                    this.log("A name tag was found, attempting to reload the atlas using the name.");
                    return loadCachedAtlas(atlases, name, false);
                }
                else
                    this.log("No name tag was found...");
            }

            super.log("No atlas was cached with the key of '%s', creating a new one...", atlasName);
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
@FileType("sdlang")
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
@FileType("sdlang")
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
            auto path  = super.resolvePath(tag.expectValue!string);
            auto atlas = super.loadCachedAtlas(caches, path);
            if(atlas is null)
            {
                SdlangLoader.parseFile(path, caches);
                atlas = super.loadCachedAtlas(caches, path);
                assert(atlas !is null, "An exception should've been thrown if the atlas hasn't loaded by this point");
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
            this._info.delayPerFrame = GameTime.fromMilliseconds(tag.expectValue!int);
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
@FileType("sdlang")
private final class DataFileSDL : LoaderExtension!Tag
{
    static assert(canCache!(LoaderCache, Font), "LoaderCache can't store Fonts");
    
    mixin ExtensionBoilerplate!Tag;

    private
    {
        struct FileInfo
        {
            string path;    // Path to the file.
            string name;    // Some tags allow you to specify the name to cache the file as.
        }

        
        // Used to parse 'file' and 'glob' tags, getting any useful data from them.
        FileInfo[] getFileInfo(Tag tag)
        {
            FileInfo[] files;
            switch(tag.name)
            {
                case "file":
                    auto path = tag.expectValue!string;
                         path = super.resolvePath(path);

                    files ~= FileInfo(path);
                    break;

                case "namedFile":
                    auto values = tag.values;
                    super.enforcef(values.length == 2, "Expected 2 values for 'namedFile' tag, got %s values instead.", values.length);

                    // [0] = name. [1] = path.
                    auto path = values[1].get!string;
                         path = super.resolvePath(path);

                    files ~= FileInfo(path, values[0].get!string);
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
    }
}

@Group("Data")
@Type("list")
@FileType("sdlang")
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
