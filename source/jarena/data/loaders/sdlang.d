/// Contains a `Loader` and various `Extensions` for SDLang assets.
module jarena.data.loaders.sdlang;

private
{
    import std.experimental.logger, std.exception, std.format;
    import sdlang;
    import jarena.audio, jarena.core, jarena.graphics, jarena.gameplay, jarena.data.serialise, jarena.data.loaders.core;
}

/++
 + A `Loader` for SDLang.
 +
 + Notes:
 +  This Loader will automatically register all of the premade extensions that this module contains.
 +
 +  "Animation:list" and "Animation:spriteSheet" are registered under `AnimationExtensionSDL`.
 +
 +  "Sprite:atlas" is registered under `SpriteAtlasExtensionSDL`.
 +
 +  "Font", "Sound", and "Texture" are registered under `NamedFileExtensionSDL`.
 +
 +  See the respective classes for their formats.
 +
 + Package_Format:
 +  A package file for SDLang is written as such
 +
 +  ```
 +  type "Package"
 +  name "Whatever"
 +
 +  [files {}]
 +  [namedFiles type="someType" {}]
 +  ```
 +
 + There can be any number of 'files' and 'namedFiles' tags.
 +
 + Subtags:
 +  There are 3 other tags that can be used inside the 'files' and 'namedFiles' tags.
 +
 +  'file', which is formatted as `file "Animations/Some_Thing.sdl"' which is used to list an
 +   SDLang file that needs to be loaded in with an extension.
 +
 +  'namedFile', which is formatted as 'namedFile "Background_Music" "Music/Background.mp3"' which is used
 +   to specify a name for a file who's name can't be determined automatically (so any asset that isn't a .sdl file).
 +
 +   Finally, 'glob', which doesn't even work right now so no documentaiton for it.
 +
 + Files_Tag:
 +  A 'files' tag contains a list of 'file', 'namedFile', and 'glob' tags, which all contain a path
 +  to another SDLang file.
 +
 +  $(B Every) SDLang file that this tag lists must contain a 'type' tag, which corresponds directly with
 +  the type an extension is registered with. For example, an SDLang file with the type of 'Sprite:atlas' will
 +  use the extension registered under the same type name.
 +
 +  Here's an example of this section.
 +
 +  ```
 +  type "Package"
 +  name "Example"
 +
 +  files {
 +      file "Animations/Walk.sdl"
 +      glob "Atlases/*.sdl"
 +  }
 +  ```
 +
 +  Note that the 'namedFile' tag functionally acts as a 'file' tag under this section.
 +
 +  When an extension is used to load in a file from the 'files' tag, the 'data' parameter that is passed will be
 +  the contents of the SDLang file. See `Extension.dataToText` for a bit of help with dealing with the parameter.
 +
 + NamedFiles_Tag:
 +  The 'namedFiles' tag contains an attribute called 'type', which specifies which extension
 +  (which was registered under the same type name) to use to load $(B all) of the files specified in the tag.
 +
 +  Note that 'namedFile' is the only subtag that can be used with this section, as there is no other way of determining
 +  a name for these files.
 +
 +  Here is an example of this section.
 +
 +  ```
 +  type "Package"
 +  name "Example"
 +
 +  // All of these files will be loaded using the 'Sound' extension
 +  namedFiles type="Sound" {
 +      namedFile "HitSound" "Sounds/hit.wav"
 +      namedFile "DeathSound" "Sounds/death.wav"
 +  }
 +
 +  // All of these files will be loaded using the 'Texture' extension
 +  namedFiles type="Texture" {
 +      namedFile "CharacterAtlasTexture" "Textures/characters.png"
 +  }
 +  ```
 +
 +  When an extension is used to load a file under the 'namedFiles' tag, then 'data' is sent as a string[] (casted to a ubyte[])
 +  containing three pieces of information. The name, the path, and the type. There is a helper function called `dataToNamedFileData` to make
 +  it easier to deal with this parameter. 
 + ++/
class LoaderSDL : Loader
{
    import std.file      : readText;
    import std.path      : dirName, buildNormalizedPath, isAbsolute, absolutePath;
    import std.algorithm : splitter, map;

    private
    {
        struct FileInfo
        {
            string path; // Path to the file.
            string name; // Some tags allow you to specify the name to cache the file as.
        }
        
        // Used to parse 'file' and 'glob' tags, getting any useful data from them.
        FileInfo[] getFileInfo(string baseDir, Tag tag)
        {
            FileInfo[] files;

            // Reminder: All paths must either be absolute, or are assumed to be relative to the data file itself.
            switch(tag.name)
            {
                case "file":
                    auto path = tag.expectValue!string;
                         path = buildNormalizedPath(baseDir, tag.expectValue!string);

                    files ~= FileInfo(path);
                    break;

                case "namedFile":
                    auto values = tag.values;
                    enforce(values.length == 2, "Expected 2 values for 'namedFile' tag, got %s values instead.".format(values.length));

                    // [0] = name. [1] = path.
                    auto path = values[1].get!string;
                         path = buildNormalizedPath(baseDir, path);

                    files ~= FileInfo(path, values[0].get!string);
                    break;

                case "glob":
                    warning("Glob searches are not implemented.");
                    /*
                    import std.file : dirEntries, SpanMode;

                    auto glob = tag.expectValue!string;
                    trace("bding");
                    foreach(entry; dirEntries(baseDir, glob, SpanMode.breadth))
                    {
                        FileInfo fi;
                        getParams(fi, tag);
                        fi.path = entry.name;
                        files ~= fi;
                    }*/
                    break;

                default:
                    enforce(false, "Unknown file tag called '%s'.".format(tag.name));
            }

            return files;
        }
    }

    ///
    this()
    {
        auto animExt  = new AnimationExtensionSDL();
        auto namedExt = new NamedFileExtensionSDL();
        super.setExtensionFor("Font",                  namedExt);
        super.setExtensionFor("Sound",                 namedExt);
        super.setExtensionFor("Texture",               namedExt);
        super.setExtensionFor("Sprite:atlas",          new SpriteAtlasExtensionSDL());
        super.setExtensionFor("Animation:list",        animExt);
        super.setExtensionFor("Animation:spriteSheet", animExt);
    }

    public override
    {
        void loadPackage(const(char[]) filePath)
        {
            super.cleanLoadingState();
            tracef("Loading SDL package at path '%s'", filePath);

            auto path       = (filePath.isAbsolute) ? filePath.idup : filePath.idup.absolutePath;
            auto baseDir    = path.dirName;
            auto packageSDL = parseFile(path);

            enforce(packageSDL.expectTagValue!string("type") == "Package");

            auto name = packageSDL.expectTagValue!string("name");
            super.setPackageName(name);

            tracef("Loading SDL package called '%s'", name);

            foreach(tag; packageSDL.tags)
            {
                switch(tag.name)
                {
                    case "type":
                    case "name":
                        break;

                    case "files":
                        infof("Using an SDLang file list.");
                        auto files = tag.tags.map!(t => this.getFileInfo(baseDir, t));

                        foreach(fileArray; files)
                        foreach(file; fileArray)
                        {
                            //infof("Loading asset from path '%s'", file.path);
                            auto contents = readText(file.path);

                            // The first line must always be the type.
                            auto firstLine = contents.splitter('\n').front;
                            auto type      = parseSource(firstLine).expectTagValue!string("type");
                            auto extension = super.getExtensionFor(type);

                            super.addLoadingTask(extension, cast(const(ubyte[]))contents);
                        }
                        break;

                    case "namedFiles":
                        auto type  = tag.expectAttribute!string("type");
                        auto files = tag.tags.map!(t => this.getFileInfo(baseDir, t));
                        infof("Using a list of named files, with type of '%s'", type);

                        auto extension = super.getExtensionFor(type);
                        foreach(fileArray; files)
                        foreach(file; fileArray)
                        {
                           // infof("Loading asset from path '%s'", file.path);
                            auto data = [file.name, file.path, type];
                            super.addLoadingTask(extension, cast(const(ubyte[]))data);
                        }
                        break;

                    default:
                        throw new Exception(tag.name);
                }
            }

            super.doTasks();
            super.finalisePackage();
        }
    }
}

/++
 + An extension that can load in named files for the engine's assets that aren't covered by the
 + other premade extensions.
 + 
 + Notes:
 +  Like the other premade extensions in this module, the `LoaderSDL` class will automatically register
 +  this extension for it's respective data types.
 +
 + Usage:
 +  This extension can handle loading in 'Texture', 'Sound', and 'Font's.
 +
 +  This extension is meant to be used for namedFiles.
 +
 + Example:
 + ```
 + type "Package"
 + name "Example"
 +
 + namedFiles type="Sound" {
 +      namedFile "JumpSound" "Sounds/Jump.wav"
 + }
 + ```
 + ++/
class NamedFileExtensionSDL : LoaderExtension
{
    override Asset[] onLoadAssets(Loader loader, const(ubyte[]) data)
    {
        auto info = data.dataToNamedFileData();
        switch(info.type)
        {
            case "Texture":
                return [Asset(info.name, new Texture(info.path))];

            case "Sound":
                return [Asset(info.name, new DelayedSoundLoad(info.path))];

            case "Font":
                return [Asset(info.name, new Font(info.path))];

            default:
                throw new Exception(info.type);
        }
    }
}

/++
 + An extension that can load in .sdl files that describe a `SpriteAtlas`.
 + 
 + Notes:
 +  Like the other premade extensions in this module, the `LoaderSDL` class will automatically register
 +  this extension for it's respective data types.
 +
 + Usage:
 +  This extension can handle loading in .sdl files of the type 'Sprite:atlas`.
 +
 +  This extension is meant to be used for files (not namedFiles).
 +
 + Example:
 + Package.sdl
 + ```
 + type "Package"
 + name "Example"
 +
 + files {
 +      file "Atlases/Character.sdl"
 + }
 + ```
 +
 + Atlases/Character.sdl
 + ```
 + type "Sprite:atlas"
 + name "atlas_Character"
 + textureRef "texture_CharacterAtlas"
 + 
 + // Any number of 'sprite' tags can be given
 + sprite "Helmet" { // "Helmet" is the name of this sprite.
 +      position 0 0 // The top left corner of the sprite
 +      size 32 32   // The size of the sprite, in pixels.
 + }
 + 
 + // Any number of 'spriteSheet' tags can be given
 + spriteSheet "WalkAnimationSheet" {
 +      position 32, 0
 +      size 64, 64
 +      frameSize 32 32 // How big a single sprite in the sheet is.
 + }
 + ```
 + ++/
class SpriteAtlasExtensionSDL : LoaderExtension
{
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
    }

    override Asset[] onLoadAssets(Loader loader, const(ubyte[]) data)
    {
        auto text = super.dataAsText(data);
        auto sdl  = parseSource(text.idup);
        auto name = sdl.expectTagValue!string("name");
        infof("Loading SpriteAtlas called '%s'", name);

        auto textureName = sdl.expectTagValue!string("textureRef");
        auto texture     = super.waitForAsset!Texture(loader, textureName);
        auto atlas       = new SpriteAtlas(texture);

        foreach(tag; sdl.tags)
        {
            switch(tag.name)
            {
                case "type":
                case "name":
                case "textureRef":
                    break;

                case "sprite":
                    auto spriteName = tag.expectValue!string;
                    infof("Loading sprite named '%s'", spriteName);

                    auto info = SdlangSprite.createFromSdlTag(tag);
                    atlas.register(spriteName, RectangleI(info.position, info.size));
                    break;

                case "spriteSheet":
                    auto sheetName = tag.expectValue!string;
                    infof("Loading sprite sheet named '%s'", sheetName);

                    auto info = SdlangSpriteSheet.createFromSdlTag(tag);
                    atlas.registerSpriteSheet(sheetName, RectangleI(info.position, info.size), info.frameSize);
                    break;

                default:
                    throw new Exception(tag.name);
            }
        }

        return [Asset(name, atlas)];
    }
}

class AnimationExtensionSDL : LoaderExtension
{
    private
    {
        Asset[] handleTag(Loader loader, Tag sdl)
        {
            auto type = sdl.expectTagValue!string("type");

            switch(type)
            {
                case "Animation:list":
                    return this.onLoadList(loader, sdl);

                case "Animation:spriteSheet":
                    return this.onLoadSpriteSheet(loader, sdl);

                default:
                    throw new Exception(type);
            }
        }

        Asset[] onLoadList(Loader loader, Tag tag)
        {
            Asset[] assets;

            foreach(child; tag.tags)
            {
                switch(child.name)
                {
                    case "value":
                        assets ~= this.handleTag(loader, child);
                        break;

                    case "type":
                        break;

                    default:
                        throw new Exception(child.name);
                }
            }

            return assets;
        }

        Asset[] onLoadSpriteSheet(Loader loader, Tag tag)
        {
            // Read in SDLang data
            auto name = tag.expectTagValue!string("name");
            infof("Loading SpriteSheet animation called '%s'", name);

            auto atlasName       = tag.expectTagValue!string("atlasRef");
            auto spriteSheetName = tag.expectTagValue!string("spriteSheetRef");
            auto frameDelayMS    = tag.expectTagValue!int("frameDelayMS").msecs;
            auto repeat          = tag.expectTagValue!bool("repeat");

            // Get the atlas
            auto atlas = super.waitForAsset!SpriteAtlas(loader, atlasName);
            assert(atlas !is null);

            infof("[Name='%s'|Atlas='%s'|FrameDelay=%s ms|Repeating=%s]",
                  name, atlasName, frameDelayMS, repeat);

            // Then create the object.
            auto info = new AnimationInfoClass();
            info.name          = name;
            info.spriteSheet   = atlas.getSpriteSheet(spriteSheetName);
            info.delayPerFrame = frameDelayMS;
            info.repeat        = repeat;

            return [Asset(name, info)];
        }
    }

    override Asset[] onLoadAssets(Loader loader, const(ubyte[]) data)
    {
        auto text = super.dataAsText(data);
        auto sdl  = parseSource(text.idup);
        return this.handleTag(loader, sdl);
    }
}

struct NamedFileInfoSDL
{
    string name;
    string path;
    string type;
}

/++
 + A helper function for extensions to convert the data passed through
 + into the data sent by namedFile tags.
 +
 + Notes:
 +  $(B Only use this function in extensions that handle namedFile tags)
 +
 + Params:
 +  
 + ++/
NamedFileInfoSDL dataToNamedFileData(const(ubyte[]) data)
{
    auto array = cast(string[])data;
    assert(array.length == 3);
    return NamedFileInfoSDL(array[0], array[1], array[2]);
}