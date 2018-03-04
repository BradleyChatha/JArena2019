///
module jarena.data.loaders;

/++
 + Provides functions that can load certain assets from an SDLang file.
 + ++/
class SdlangLoader
{
    import jarena.core;
    import jarena.graphics;
    import sdlang;

    private static
    {
        struct FileInfo
        {
            string path;    // Path to the file.
            string baseDir; // Directory the file is in.
        }

        SpriteAtlas loadAtlas(Cache!SpriteAtlas atlases, string atlasName, bool isPath = true)
        {
            import std.experimental.logger : tracef;

            if(atlases !is null)
            {
                auto cachedAtlas = atlases.get(atlasName, null);
                if(cachedAtlas !is null)
                {
                    tracef("Atlas is cached, returning...");
                    return cachedAtlas;
                }

                if(isPath)
                {
                    tracef("No atlas was cached with the key of '%s', but it is flagged as being a path, attempting to read a name from it to try again.", atlasName);
                    auto tag = parseFile(atlasName);
                    auto name = tag.getTagValue!string("name");

                    if(name !is null)
                    {
                        tracef("A name tag was found, attempting to reload the atlas.");
                        return loadAtlas(atlases, name, false);
                    }
                    else
                        tracef("No name tag was found...");
                }

                tracef("No atlas was cached with the key of '%s', creating a new one...", atlasName);
            }
            else
                tracef("The given atlas cache is null, so a new atlas will be loaded...");

            return null;
        }

        FileInfo[] getFileInfo(Tag tag, string baseDir)
        {
            import std.path : buildNormalizedPath, dirName;

            FileInfo[] files;
            switch(tag.name)
            {
                case "file":
                    auto path = tag.expectValue!string;
                    path = baseDir.buildNormalizedPath(path);

                    files ~= FileInfo(path, path.dirName);
                    break;

                default:
                    assert(0, "Bother to make an exception here");
            }

            return files;
        }
    }

    public static
    {
        /++
         + Parses an SDLang `Tag` that contains data about a sprite atlas, and loads in an atlas using the given data.
         +
         + Notes:
         +  The path used to load the texture is a normalised path built from `baseDirectory` and the texture path in the `tag`.
         +  For example, if the `baseDirectory` was `./data/atlases/` and the texture path was "../textures/texture.png`
         +  then the final path would be "./data/textures/texture.png".
         +
         +  It is $(B heavily) recommended that all paths that reference other files are kept relative to the directory
         +  where the atlas' .sdl file is, in order for certain data resolution features to work.
         +
         +  The 'name' tag in the given `tag` will be refferred to as `atlasName`.
         +
         +  If `atlases` is not `null`, then it is first checked to see if it contains an atlas with the key of `atlasName`.
         +  If an atlas is found (or if the cache is `null`), then it is returned with no modifications, otherwise the function proceeds to create a new atlas.
         +  Once the new atlas is created, it is cached under the key of `atlasName`.
         +
         +  If `textures` is not null, then it is first checked to see if it contains a texture with the key of the final texture path.
         +  If a texture is found, it is used as-is. Otherwise, if no texture is found (or the cache is null) it will be loaded in.
         +  Once the new texture is loaded in, it is cached under the key of the final texture path.
         +
         + Format:
         +  ```
         +  texture "path_to_texture/relative_to_baseDirectory.png" // Mandatory
         +  name "Atlas name here" // Mandatory
         +
         +  // Any number of 'sprite' and 'spriteSheet' tags can be added
         +  sprite "name_of_sprite" {
         +      position 0 0 // x, y. The top-left corner of the sprite's first pixel. Mandatory
         +      size 0 0     // width, height. The size of the sprite. Mandatory
         +  }
         +
         +  spriteSheet "name_of_sheet" {
         +      position 0 0    // x, y. The top-left corner of the sprite sheet. Mandatory
         +      size 0 0        // width, height. The size of the sheet. Mandatory
         +      frameSize 0 0   // width, height. The size of a single frame in the sheet. Mandatory
         +  }
         +  ```
         +
         + Params:
         +  tag = The SDLang tag to parse.
         +  atlasName = The name of the atlas (see notes).
         +  baseDirectory = The directory to act as the base for the texture path (see notes).
         +  atlases = A cache of `SpriteAtlas`es (see notes).
         +  textures = A cache of `Texture`s (see notes).
         +
         + Returns:
         +  The parsed/cached `SpriteAtlas`.
         + ++/
        SpriteAtlas parseAtlasTag(Tag tag, 
                                  string baseDirectory = null, 
                                  Cache!SpriteAtlas atlases = null, 
                                  Cache!Texture textures = null)
        {
            // Here be a very long-tailed dragon.
            import std.algorithm : filter, all, map;
            import std.range     : takeExactly;
            import std.exception : enforce;
            import std.path      : buildNormalizedPath;
            import std.format    : format;
            import std.file      : getcwd;
            import std.experimental.logger : tracef;
            enforce(tag !is null, "Cannot parse a null tag");

            if(baseDirectory is null)
                baseDirectory = getcwd();

            // The texture path may be something like "../texture.png", so it needs to be normalised.
            auto texturePath = tag.expectTagValue!string("texture");
                 texturePath = buildNormalizedPath(baseDirectory, texturePath);

            tracef("Loading sprite atlas using the texture at '%s'", texturePath);

            auto atlasName = tag.expectTagValue!string("name");
            tracef("atlasName = '%s'", atlasName);

            // Look through the caches for the atlas.
            auto cached = SdlangLoader.loadAtlas(atlases, atlasName, false);
            if(cached !is null)
                return cached;

            // Load the texture.
            Texture texture;
            if(textures !is null)
            {
                texture = textures.get(texturePath, null);
                if(texture is null)
                {
                    tracef("Texture is not cached, calling loadOrGet...");
                    texture = textures.loadOrGet(texturePath);
                }
                else
                    tracef("Texture was cached");
            }
            else
            {
                tracef("Null was passed for the Texture Cache, so an uncached texture will be loaded");
                texture = new Texture(texturePath);
            }

            int[2] getInts(Tag tag)
            {
                enforce(tag.values.all!(v => v.type == typeid(int)), 
                        "[%s] All values of the '%s' tag must be integers.".format(tag.location, tag.name));

                int[2] ints;
                auto range = tag.values.map!(v => v.get!int).takeExactly(2);
                ints[0] = range[0];
                ints[1] = range[1];
                return ints;
            }

            // Begin to create the new atlas.
            auto atlas = new SpriteAtlas(texture);

            // Load in basic sprite info.
            foreach(spriteTag; tag.tags.filter!(t => t.name == "sprite"))
            {
                auto name = spriteTag.expectValue!string;
                auto posTag = spriteTag.expectTag("position");
                auto sizeTag = spriteTag.expectTag("size");

                auto position = getInts(posTag);
                auto size = getInts(sizeTag);
                auto frame = RectangleI(position[0], position[1], size[0], size[1]);
                atlas.register(name, frame);
            }

            // Load in sprite sheets
            foreach(sheetTag; tag.tags.filter!(t => t.name == "spriteSheet"))
            {
                auto name = sheetTag.expectValue!string;
                auto posTag = sheetTag.expectTag("position");
                auto sizeTag = sheetTag.expectTag("size");
                auto frameTag = sheetTag.expectTag("frameSize");

                auto position = getInts(posTag);
                auto size = getInts(sizeTag);
                auto frameSize = getInts(frameTag);
                auto frame = RectangleI(position[0], position[1], size[0], size[1]);
                atlas.registerSpriteSheet(name, frame, ivec2(frameSize[0], frameSize[1]));
            }

            if(atlases !is null)
                atlases.add(atlasName, atlas);

            return atlas;
        }

        /++
         + Parses a tag containing information about a sprite sheet based animation.
         +
         + Notes:
         +  The `name` tag inside of the given `tag` will be reffered to as `animationName`.
         +
         +  If `animations` is not `null`, and it contains an animation called `animationName`, then
         +  that animation is returned. Otherwise one is loaded in and then cached under `animationName`.
         +
         +  If `baseDirectory` is `null`, then it defaults to the current working directory.
         +  See `parseSpriteAtlasTag` for a better description of this parameter.
         +
         +  If `atlasName` is `null`, then it is set to the normalised path of "baseDirectory/atlasRef".
         +  Where 'atlasRef' is the value of the 'atlasRef' tag in the given `tag`.
         +
         +  If `atlases` is not `null`, then an atlas under `atlasName` will be looked for.
         +  If no atlas is found, then `parseSpriteAtlasTag` is called using the normalised path
         +  of "baseDirectory/atlasRef", with the appropriate parameters forwarded.
         +
         + Format:
         + ```
         +  name "Name of animation" // Name of the animation. Mandatory.
         +  atlasRef "path_to_atlas_definition.sdl" // Path to the .sdl file defining the atlas that has the animation sheet. Mandatory. Relative to baseDirectory.
         +  spriteSheetRef "name_of_sheet_in_atlas" // The name of the animation sprite sprite sheet inside of the referenced atlas. Mandatory.
         +  frameDelayMS 0 // In milliseconds, how much time to wait before advancing between frames.
         +  repeat true // Whether the animation should repeat itself once it's finished.
         + ```
         +
         + Params:
         +  tag = The tag to parse.
         +  baseDirectory = The directory to act as the base for the atlas path (see notes).
         +  animations = A cache of animations.
         +  atlasName = The name of the atlas to use (see notes).
         +  atlases = A cache of atlases.
         +  texutres = A cache of textures. (used only if an atlas needs to be loaded in with `parseSpriteAtlasTag`).
         +
         + Returns:
         +  The parsed animation.
         + ++/
        AnimationInfo parseSpriteSheetAnimationTag(Tag tag,
                                                   string baseDirectory = null, 
                                                   Cache!AnimationInfo animations = null, 
                                                   string atlasName = null,
                                                   Cache!SpriteAtlas atlases = null,
                                                   Cache!Texture textures = null)
        {
            import std.exception : enforce;
            import std.path      : buildNormalizedPath;
            import std.format    : format;
            import std.file      : getcwd;
            import std.experimental.logger : trace, tracef;

            auto animationName = tag.expectTagValue!string("name");
            if(animations !is null)
            {
                tracef("Checking to see if the animation called '%s' is already cached...", animationName);
                auto cachedAni = animations.get(animationName);
                if(cachedAni != AnimationInfo.init)
                {
                    trace("The animation was cached, returning...");
                    return cachedAni;
                }
                else
                    trace("The animation is not cached, so a new animation will be loaded in");
            }
            else
                trace("The animation cache is null, so a new animation will be loaded in");

            // Load in the atlas.
            if(baseDirectory is null)
                baseDirectory = getcwd();

            auto atlasPath = tag.expectTagValue!string("atlasRef");
                 atlasPath = buildNormalizedPath(baseDirectory, atlasPath);

            tracef("Loading sprite atlas from it's .sdl definition at path: %s", atlasPath);

            if(atlasName is null)
                atlasName = atlasPath;

            tracef("atlasName = %s", atlasName);

            auto atlas = SdlangLoader.loadAtlas(atlases, atlasName);
            if(atlas is null)
                atlas = SdlangLoader.parseAtlasTag(parseFile(atlasPath), baseDirectory, atlases, textures);

            // Find the sprite sheet
            auto sheetName = tag.expectTagValue!string("spriteSheetRef");
            tracef("Animation is using sprite sheet called '%s'", sheetName);
            auto sheet = atlas.getSpriteSheet(sheetName);

            // Load in the extra animation info
            auto frameDelayMS = tag.expectTagValue!int("frameDelayMS");
            auto repeat = tag.expectTagValue!bool("repeat");

            tracef("The animation %s and has a frame delay of %sms", repeat ? "is repeating" : "does not repeat", frameDelayMS);

            auto animation = AnimationInfo(animationName, sheet, frameDelayMS, repeat);
            if(animations !is null)
                animations.add(animationName, animation);

            return animation;
        }

        /// ditto
        AnimationInfo parseSpriteSheetAnimationTag(Multi_Cache)(Tag tag, 
                                                                string baseDirectory = null, 
                                                                string atlasName = null,
                                                                Multi_Cache cache = null)
        if(isMultiCache!Multi_Cache)
        {
            Cache!AnimationInfo animations;
            Cache!SpriteAtlas atlases;
            Cache!Texture textures;

            if(cache !is null)
            {
                static if(canCache!(Multi_Cache, AnimationInfo))
                    animations = cache.getCache!AnimationInfo;

                static if(canCache!(Multi_Cache, SpriteAtlas))
                    atlases = cache.getCache!SpriteAtlas;

                static if(canCache!(Multi_Cache, Texture))
                    textures = cache.getCache!Texture;
            }

            return SdlangLoader.parseSpriteSheetAnimationTag(tag, baseDirectory, animations, atlasName, atlases, textures);
        }

        /++
         + Loads a list of files from a data file (hard coded to "Data/data.sdl" right now).  
         + ++/
        void parseDataListFile(Cache!AnimationInfo animations,
                               Cache!SpriteAtlas atlases,
                               Cache!Texture textures)
        {
            import std.algorithm : each;
            import std.experimental.logger : tracef;

            auto baseDir = "Data/";
            auto dataTag = parseFile("Data/data.sdl");
            auto animTag = dataTag.expectTag("animations");
            auto atlasTag = dataTag.expectTag("atlases");

            FileInfo[] atlasFiles;
            FileInfo[] animFiles;

            animTag.tags.each!(t => animFiles ~= SdlangLoader.getFileInfo(t, baseDir));
            atlasTag.tags.each!(t => atlasFiles ~= SdlangLoader.getFileInfo(t, baseDir));

            foreach(info; animFiles)
            {
                SdlangLoader.parseSpriteSheetAnimationTag(
                    parseFile(info.path),
                    info.baseDir,
                    animations,
                    null,
                    atlases,
                    textures
                );
            }

            foreach(info; atlasFiles)
            {
                SdlangLoader.parseAtlasTag(
                    parseFile(info.path),
                    info.baseDir,
                    atlases,
                    textures
                );
            }
        }
    }
}