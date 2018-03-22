module jarena.gameplay.scenes.spriteatlas_viewer;

private
{
    import derelict.sfml2.window, derelict.sfml2.graphics;
    import jarena.core, jarena.gameplay, jarena.graphics;
}

@SceneName("Sprite Atlas Viewer")
final class SpriteAtlasViewerScene : Scene
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
        FreeFormContainer _gui;
        StackContainer    _dataGui;
        StackContainer    _instructionGui;
        SimpleLabel       _labelAtlasData;
        SimpleLabel       _labelInstructions;

        /++
         + Changes the current sprite and atlas, based off of _currentAtlasIndex, and
         + currentAtlas.spriteIndex, .sheetIndex, .frameIndex, and .usingSheets
         +
         + If `showAll` is yes, then the entire atlas is shown at once.
         + ++/
        void changeSprite(ShowAll showAll = ShowAll.no)
        {
            // Bug checking
            if(this._currentAtlasIndex >= this._atlases.length)
                assert(false, "Out of bounds");
            if(this.currentAtlas.sheetIndex >= this.currentAtlas.sheetNames.length)
                assert(false, "Bug");
            if(this.currentAtlas.spriteIndex >= this.currentAtlas.spriteNames.length)
                assert(false, "Bug");

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
                return false;
            
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
        void moveIndex(Increment increment)(sfKeyCode key)
        {
            static if(increment)
                alias Func = this.increment;
            else
                alias Func = this.decrement;
                
            if(super.manager.input.wasKeyTapped(key))
            {
                if(super.manager.input.isShiftDown)
                    Func(this._currentAtlasIndex, this._atlases);
                else
                {
                    if(!this.currentAtlas.usingSheets)
                    {
                        auto endOfSprites = Func(this.currentAtlas.spriteIndex, this.currentAtlas.spriteNames);
                        if(endOfSprites)
                        {
                            this.currentAtlas.usingSheets = true;

                            static if(!increment)
                            {
                                this.currentAtlas.sheetIndex = this.currentAtlas.sheetNames.length - 1;
                                auto sheet = this.currentAtlas.atlas.getSpriteSheet(this.currentAtlas.sheetNames[this.currentAtlas.sheetIndex]);
                                this.currentAtlas.frameIndex = sheet.frames.length - 1;
                            }
                            else
                            {
                                this.currentAtlas.frameIndex = 0;
                            }
                        }
                    }
                    else
                    {
                        auto sheet = this.currentAtlas.atlas.getSpriteSheet(this.currentAtlas.sheetNames[this.currentAtlas.sheetIndex]);
                        auto endOfFrames = Func(this.currentAtlas.frameIndex, sheet.frames);

                        if(endOfFrames)
                        {
                            auto endOfSheets = Func(this.currentAtlas.sheetIndex, this.currentAtlas.sheetNames);
                            auto nextSheet = this.currentAtlas.atlas.getSpriteSheet(this.currentAtlas.sheetNames[this.currentAtlas.sheetIndex]);
                            if(endOfSheets)
                            {
                                this.currentAtlas.usingSheets = false;

                                static if(!increment)
                                {
                                    this.currentAtlas.spriteIndex = this.currentAtlas.spriteNames.length - 1;
                                    this.currentAtlas.sheetIndex  = 0; // Going backwards causes strange things to happen to this number
                                }
                                else
                                    this.currentAtlas.spriteIndex = 0;
                            }
                            else
                            {
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
            super();
        }
    }

    public override
    {
        void onInit()
        {
            this._gui = new FreeFormContainer();

            this._dataGui           = new StackContainer(vec2(5, 20));
            this._dataGui.colour    = GUI_BACKGROUND_COLOUR;
            this._gui.addChild(this._dataGui);

            // Setup instruction gui
            this._instructionGui            = new StackContainer(StackContainer.Direction.Horizontal);
            this._instructionGui.colour     = GUI_BACKGROUND_COLOUR;
            this._instructionGui.autoSize   = StackContainer.AutoSize.no;
            this._instructionGui.size       = vec2(InitInfo.windowSize.x, TEXT_CHAR_SIZE * 1.5);
            this._instructionGui.position   = vec2(0, InitInfo.windowSize.y - this._instructionGui.size.y);
            this._gui.addChild(this._instructionGui);

            auto font               = super.manager.cache.get!Font("Calibri");
            this._labelAtlasData    = this.makeLabel(this._dataGui, font);
            this._labelInstructions = this.makeLabel(this._instructionGui, font);
            this._labelInstructions.updateTextASCII(
                "Left/Right Arrow = Change sprite/frame | Shift+Left/Right Arrow = Change atlas | Backspace = Back to menu"
            );
        }

        void onSwap(PostOffice office)
        {
        }

        void onUnswap(PostOffice office)
        {
        }

        void onUpdate(Window window, GameTime deltaTime)
        {
            if(super.manager.input.wasKeyTapped(sfKeyBack))
                super.manager.swap!MenuScene;

            if(this._atlases.length == 0)
                return;

            this.moveIndex!(Increment.yes)(sfKeyRight);
            this.moveIndex!(Increment.no)(sfKeyLeft);

            if(super.manager.input.wasKeyTapped(sfKeyR))
                this.changeSprite(ShowAll.yes);

            super.updateScene(window, deltaTime);
            this._gui.onUpdate(super.manager.input, deltaTime);

            super.renderScene(window);
            this._gui.onRender(window);
        }
    }
}
