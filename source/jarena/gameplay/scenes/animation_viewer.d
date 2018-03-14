module jarena.gameplay.scenes.animation_viewer;

private
{
    import derelict.sfml2.window, derelict.sfml2.graphics;
    import jarena.core, jarena.gameplay, jarena.graphics;
}

@SceneName("Animation Viewer")
final class AnimationViewerScene : Scene
{
    private
    {
        const GUI_BACKGROUND_COLOUR = colour(128, 64, 128, 255);
        const TEXT_CHAR_SIZE        = 18;
        const TEXT_COLOUR           = colour(255, 255, 255, 255);

        AnimatedObject  _sprite;
        AnimationInfo[] _animations;
        size_t          _animIndex;

        // GUI stuff
        FreeFormContainer _gui;
        StackContainer    _dataGui;
        StackContainer    _instructionGui;
        SimpleLabel       _labelAnimData;
        SimpleLabel       _labelChangingData;
        SimpleLabel       _labelInstructions;

        void changeAnimation()
        {
            import std.format : format;

            if(this._animIndex >= this._animations.length)
                assert(false, "Bug");

            auto next = this._animations[this._animIndex];
            if(this._sprite is null)
            {
                this._sprite = new AnimatedObject(new AnimatedSprite(next));
                super.register("Sprite", this._sprite);
            }

            this._sprite.animation = next;
            this._sprite.position  = vec2((InitInfo.windowSize.x / 2) - (this._sprite.bounds.size.x / 2),
                                          (InitInfo.windowSize.y / 2) - (this._sprite.bounds.size.y / 2));

            this._labelAnimData.updateTextASCII(
                format("Animation Name: %s\n"~
                       "Delay Per Frame: %sms\n"~
                       "Repeats: %s\n"~
                       "Rows: %s\n"~
                       "Columns: %s\n"~
                       "Frame Count: %s",
                       next.name, 
                       next.delayPerFrameMS, 
                       next.repeat,
                       next.spriteSheet.rows,
                       next.spriteSheet.columns,
                       next.spriteSheet.columns * next.spriteSheet.rows
                      )
            );
        }

        SimpleLabel makeLabel(Container gui, Font font)
        {
            return gui.addChild(new SimpleLabel(new Text(font, ""d, vec2(0), TEXT_CHAR_SIZE, TEXT_COLOUR)));
        }
    }

    public
    {
        this(Cache!AnimationInfo animations)
        {
            import std.array : array;
            import std.algorithm : map;
            assert(animations !is null);

            this._animations = animations.byValue.map!(v => cast(AnimationInfo)v).array;
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
            this._labelAnimData     = this.makeLabel(this._dataGui, font);
            this._labelChangingData  = this.makeLabel(this._dataGui, font);
            this._labelInstructions = this.makeLabel(this._instructionGui, font);
            this._labelInstructions.updateTextASCII(
                "Left Arrow: Previous Animation | Right Arrow: Next Animation | R: Restart"
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
            import std.format : format;

            if(super.manager.input.wasKeyTapped(sfKeyBack))
                super.manager.swap!MenuScene;

            if(this._animations.length == 0)
                return;

            if(super.manager.input.wasKeyTapped(sfKeyRight))
            {
                this._animIndex += 1;

                if(this._animIndex >= this._animations.length)
                    this._animIndex = 0;

                this.changeAnimation();
            }

            if(super.manager.input.wasKeyTapped(sfKeyLeft))
            {
                if(this._animIndex == 0)
                    this._animIndex = this._animations.length - 1;
                else
                    this._animIndex -= 1;

                this.changeAnimation();
            }

            if(super.manager.input.isKeyDown(sfKeyR) && this._sprite !is null)
                this._sprite.restart();

            if(this._sprite !is null)
            {
                auto sheet = this._sprite.animation.spriteSheet;
                auto currentFrameNumber = (this._sprite.currentFrame.y * sheet.columns) + this._sprite.currentFrame.x;

                this._labelChangingData.updateTextASCII(format(
                    "Finished: %s\n"~
                    "Current Frame: %s (%s)", 
                    this._sprite.finished,
                    this._sprite.currentFrame, currentFrameNumber));
            }

            super.updateScene(window, deltaTime);
            this._gui.onUpdate(super.manager.input, deltaTime);

            super.renderScene(window);
            this._gui.onRender(window);
        }
    }
}