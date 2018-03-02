module jarena.data.loaders;

/++
 + Provides functions that can load certain assets from an SDLang file.
 + ++/
class SdlangLoader
{
    import jarena.core;
    import jarena.graphics;
    import sdlang;

    public static
    {
        /++
         + Parses an SDLang `Tag` that contains data about a sprite atlas, and loads in an atlas using the given data.
         +
         + Notes:
         +  The path used to load the texture is a normalised path built from `baseDirectory` and the texture path in the `tag`.
         +  For example, if the `baseDirectory` was `./data/atlases/` and the texture path was "../texture/texture.png`
         +  then the final path would be "./data/texture/texture.png".
         +
         +  If `atlasName` is `null`, then it is set to the same value as the noramlised texture path.
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
         +
         +  // Any number of 'sprite' tags can be added
         +  sprite "name_of_sprite" {
         +      position 0, 0 // x, y. The top-left corner of the sprite's first pixel. Mandatory
         +      size 0, 0     // width, height. The size of the sprite. Mandatory
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
        SpriteAtlas parseAtlasTag(Tag tag, string atlasName = null, string baseDirectory = null, Cache!SpriteAtlas atlases = null, Cache!Texture textures = null)
        {
            // Here be a very long-tailed dragon.
            import std.algorithm : filter, all, map;
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

            if(atlasName is null)
                atlasName = texturePath;

            tracef("atlasName = '%s'", atlasName);

            // Look through the caches for the atlas.
            if(atlases !is null)
            {
                auto cachedAtlas = atlases.get(atlasName, null);
                if(cachedAtlas !is null)
                {
                    tracef("Atlas is cached, returning...");
                    return cachedAtlas;
                }
                tracef("No atlas was cached with the key of '%s', creating a new one...", atlasName);
            }
            else
                tracef("The given atlas cache is null, so a new atlas will be loaded...");

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

            // Begin to create the new atlas.
            auto atlas = new SpriteAtlas(texture);

            // Load in basic sprite info.
            foreach(spriteTag; tag.tags.filter!(t => t.name == "sprite"))
            {
                auto name = spriteTag.expectValue!string;
                auto posTag = spriteTag.expectTag("position");
                auto sizeTag = spriteTag.expectTag("size");

                int[2] getInts(Tag tag)
                {
                    enforce(tag.values.all!(v => v.type == typeid(int)), 
                            "[%s] All values of the '%s' tag must be integers.".format(tag.location, tag.name));

                    int[2] ints;
                    auto range = tag.values.map!(v => v.get!int);
                    ints[0] = range.front;
                    range.popFront();
                    ints[1] = range.front;
                    return ints;
                }

                auto position = getInts(posTag);
                auto size = getInts(sizeTag);
                auto frame = RectangleI(position[0], position[1], size[0], size[1]);

                tracef("Registering sprite called '%s', with frame of %s", name, frame);
                atlas.register(name, frame);
            }

            if(atlases !is null)
                atlases.add(atlasName, atlas);

            return atlas;
        }
    }
}