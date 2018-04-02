module jarena.gameplay.scenes.spriteatlas_viewer;

private
{
    import derelict.sfml2.window, derelict.sfml2.graphics;
    import jarena.core, jarena.gameplay, jarena.graphics;
}

@SceneName("Sprite Atlas Viewer")
final class SpriteAtlasViewerScene : ViewerScene
{
    import std.format   : format;
    import std.typecons : Tuple, Flag;
        
    private
    {
        alias Increment   = Flag!"goingRight";
        alias ShowAll     = Flag!"showAll";
        alias AtlasInfo   = Tuple!(SpriteAtlas,   "atlas",          // The atlas
                                   string[],      "spriteNames",    // The names of every sprite in the atlas
                                   size_t,        "spriteIndex",    // The index of the current sprite name being used.
                                   bool,          "usingSheets",    // Whether we're using sprite frames or sprite sheets.
                                   string[],      "sheetNames",     // The names of every sprite sheet in the atlas.
                                   size_t,        "sheetIndex",     // The index of the current sprite sheet name being used.
                                   size_t,        "frameIndex");    // The index of the current frame, for the current sprite sheet, being used.
        alias FrameInfo   = Tuple!(RectangleI, "frameRect",
                                   string,     "name",
                                   size_t,     "frameIndex",
                                   size_t,     "maxIndex");
        
        const GUI_BACKGROUND_COLOUR = Colours.azure;
        const TEXT_CHAR_SIZE        = 18;
        const TEXT_COLOUR           = Colours.bianca;

        // Stuff
        StaticObject    _sprite;
        AtlasInfo[]     _atlases;
        size_t          _currentAtlasIndex;
        
        // GUI stuff
        SimpleLabel _labelAtlasData;
        SimpleLabel _labelAtlasIndex;

        /++
         + Changes the current sprite and atlas, based off of _currentAtlasIndex, and
         + currentAtlas.spriteIndex, .sheetIndex, .frameIndex, and .usingSheets
         +
         + If `showAll` is yes, then the entire atlas is shown at once.
         + ++/
        void changeSprite(ShowAll showAll = ShowAll.no)
        {
            auto sheetCount = this.currentAtlas.sheetNames.length;
            auto spriteCount = this.currentAtlas.spriteNames.length;
            
            // Bug checking
            if(this._currentAtlasIndex >= this._atlases.length)
                assert(false, format("Out of Bounds. Max: %s", this._atlases.length));
            if(this.currentAtlas.sheetIndex >= sheetCount && sheetCount != 0)
                assert(false, format("Bug. SheetNameCount: %s", sheetCount));
            if(this.currentAtlas.spriteIndex >= spriteCount && spriteCount != 0)
                assert(false, format("Bug. SpriteNameCount: %s", spriteCount));

            // Make the sprite if it doesn't exist
            if(this._sprite is null)
            {
                this._sprite = new StaticObject(this.currentAtlas.atlas.texture);
                super.register("Sprite", this._sprite);
            }

            string infoType;
            string infoName;
            string extraInfo;
            
            if(showAll)
            {
                infoType = "Atlas";
                infoName = "Entire Atlas";
                extraInfo = format("Sprite Count: %s\n"~
                                   "Sprite Sheet Count: %s",
                                   this.currentAtlas.spriteNames.length,
                                   this.currentAtlas.sheetNames.length);
                this._sprite.textureRect = RectangleI(0, 0, ivec2(this._sprite.texture.size));
            }
            else if(this.currentAtlas.usingSheets)
            {
                auto frame = this.nextFrame();
                infoType   = "Sprite Atlas Frame";
                infoName   = "Frame from '"~frame.name~"'";
                extraInfo  = format("Frame %s out of %s", frame.frameIndex + 1, frame.maxIndex);
                this._sprite.texture = this.currentAtlas.atlas.texture;
                this._sprite.textureRect = frame.frameRect;
            }
            else
            {
                auto frame = this.nextFrame();
                infoName   = frame.name;
                infoType   = "Sprite";
                extraInfo  = format("Sprite %s out of %s", frame.frameIndex + 1, frame.maxIndex);
                this._sprite.texture = this.currentAtlas.atlas.texture;
                this._sprite.textureRect = frame.frameRect;
            }

            this._sprite.position = (vec2(InitInfo.windowSize) / vec2(2)) -
                                    (this._sprite.bounds.size  / vec2(2));

            this._labelAtlasData.updateTextASCII(format(
                "Type: %s\n"~
                "Name: \"%s\"\n"~
                "\n%s",
                infoType,
                infoName,
                extraInfo
            ));
        }

        FrameInfo nextFrame()
        {
            auto atlasCopy = this.currentAtlas;
            if(atlasCopy.usingSheets)
            {
                auto name  = atlasCopy.sheetNames[atlasCopy.sheetIndex];
                auto sheet = atlasCopy.atlas.getSpriteSheet(name);
                auto frame = sheet.frames[atlasCopy.frameIndex];
                return FrameInfo(frame, name, atlasCopy.frameIndex, sheet.frames.length);
            }
            else
            {
                auto name  = atlasCopy.spriteNames[atlasCopy.spriteIndex];
                auto frame = atlasCopy.atlas.getSpriteRect(name);
                return FrameInfo(frame, name, atlasCopy.spriteIndex, atlasCopy.spriteNames.length);
            }
        }
        
        SimpleLabel makeLabel(Container gui, Font font)
        {
            return gui.addChild(new SimpleLabel(new Text(font, ""d, vec2(0), TEXT_CHAR_SIZE, TEXT_COLOUR)));
        }

        // Tuple is a struct, so use this function anytime you need to update it's data.
        // Don't store the return value in a variable unless you're aware it's a copy, not a reference.
        @property
        ref AtlasInfo currentAtlas()
        {
            return this._atlases[_currentAtlasIndex];
        }

        // Returns: `true` if the value was reset to 0
        bool increment(T, A)(ref T value, const A array)
        {
            value += 1;

            if(value >= array.length)
                value = 0;

            return (value == 0);
        }

        // Returns: `true` if the value was reset to the end of the array
        bool decrement(T, A)(ref T value, const A array)
        {
            if(array.length == 0)
                return true;
            
            if(value == 0)
                value = array.length - 1;
            else
                value -= 1;

            return (value == array.length - 1);
        }

        /++
         + Moves all the relevent indicies to either the right (increment) or the left (decrement)
         + when the `key` is pressed.
         + ++/
        void moveIndex(Increment increment)(Scancode key)
        {
            static if(increment) alias Func = this.increment;
            else                 alias Func = this.decrement;

            // Wrap around to the start/end (increment/!increment) of the avaliable sheets
            void wrapAroundSheets()
            {
                static if(!increment)
                {
                    this.currentAtlas.sheetIndex = this.currentAtlas.sheetNames.length - 1;
                    auto sheet = this.currentAtlas.atlas.getSpriteSheet(this.currentAtlas.sheetNames[this.currentAtlas.sheetIndex]);
                    this.currentAtlas.frameIndex = sheet.frames.length - 1;
                }
                else
                    this.currentAtlas.frameIndex = 0;
            }

            // Wrap around to the start/end (increment/!increment) of the avaliable sprites
            void wrapAroundSprites()
            {
                static if(!increment)
                {
                    this.currentAtlas.spriteIndex = this.currentAtlas.spriteNames.length - 1;
                    this.currentAtlas.sheetIndex  = 0; // Going backwards causes strange things to happen to this number
                }
                else
                    this.currentAtlas.spriteIndex = 0;
            }
                
            if(super.manager.input.wasKeyTapped(key))
            {
                if(super.manager.input.isShiftDown)
                {
                    Func(this._currentAtlasIndex, this._atlases);
                    this.currentAtlas.usingSheets = (this.currentAtlas.spriteNames.length == 0);
                }
                else
                {
                    if(!this.currentAtlas.usingSheets)
                    {
                        auto endOfSprites = Func(this.currentAtlas.spriteIndex, this.currentAtlas.spriteNames);
                        if(endOfSprites)
                        {
                            // Special case
                            if(this.currentAtlas.sheetNames.length == 0)
                            {
                                wrapAroundSprites();
                                this.changeSprite();
                                return;
                            }
                            
                            this.currentAtlas.usingSheets = true;
                            wrapAroundSheets();
                        }
                    }
                    else
                    {
                        auto sheet = this.currentAtlas.atlas.getSpriteSheet(this.currentAtlas.sheetNames[this.currentAtlas.sheetIndex]);
                        auto endOfFrames = Func(this.currentAtlas.frameIndex, sheet.frames);
                        if(endOfFrames)
                        {
                            auto endOfSheets = Func(this.currentAtlas.sheetIndex, this.currentAtlas.sheetNames);
                            if(endOfSheets)
                            {
                                // Special case
                                if(this.currentAtlas.spriteNames.length == 0)
                                {
                                    wrapAroundSheets();
                                    this.changeSprite();
                                    return;
                                }
                            
                                this.currentAtlas.usingSheets = false;
                                wrapAroundSprites();
                            }
                            else
                            {
                                auto nextSheet = this.currentAtlas.atlas.getSpriteSheet(this.currentAtlas.sheetNames[this.currentAtlas.sheetIndex]);
                                static if(increment)
                                    this.currentAtlas.frameIndex = 0;
                                else
                                    this.currentAtlas.frameIndex = nextSheet.frames.length - 1;
                            }
                        }
                    }
                }
                
                this.changeSprite();
            }
        }
    }

    public
    {
        this(Cache!SpriteAtlas atlases)
        {
            import std.algorithm : map;
            import std.array     : array;

            this._atlases = atlases.byValue.map!(s => AtlasInfo(
                (cast(SpriteAtlas)s),// Naughty naughty
                s.bySpriteKeys.array, 
                0,
                false,
                s.bySpriteSheetKeys.array,
                0,
                0
            )).array;
        }
    }

    public override
    {
        void onInit()
        {
            super.onInit();
            this._labelAtlasData  = super.makeDataLabel();
            this._labelAtlasIndex = super.makeDataLabel();
        }

        void onUpdate(GameTime deltaTime, InputManager input)
        {
            if(input.wasKeyTapped(Scancode.BACKSPACE))
                super.manager.swap!MenuScene;

            this._labelAtlasIndex.updateTextASCII(format(
                "Atlas %s out of %s", this._currentAtlasIndex + 1, this._atlases.length
            ));

            if(this._atlases.length == 0)
                return;

            this.moveIndex!(Increment.yes)(Scancode.RIGHT);
            this.moveIndex!(Increment.no)(Scancode.LEFT);

            if(input.wasKeyTapped(Scancode.R))
                this.changeSprite(ShowAll.yes);

            super.updateScene(deltaTime);
            super.onUpdate(deltaTime, input);
        }

        void onRender(Window window)
        {
            super.renderScene(window);
            super.onRender(window);
        }

        string instructions()
        {
            return "Left/Right Arrow = Change sprite/frame | Shift+Left/Right Arrow = Change atlas | Backspace = Back to menu";
        }
    }
}
