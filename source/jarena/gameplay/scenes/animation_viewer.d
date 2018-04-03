module jarena.gameplay.scenes.animation_viewer;

private
{
    import jarena.core, jarena.gameplay, jarena.graphics;
}

@SceneName("Animation Viewer")
final class AnimationViewerScene : ViewerScene
{
    private
    {
        AnimatedObject  _sprite;
        AnimationInfo[] _animations;
        size_t          _animIndex;

        // GUI stuff
        SimpleLabel _labelAnimData;
        SimpleLabel _labelChangingData;

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
                       next.delayPerFrame.total!"msecs", 
                       next.repeat,
                       next.spriteSheet.rows,
                       next.spriteSheet.columns,
                       next.spriteSheet.columns * next.spriteSheet.rows
                      )
            );
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
        }
    }

    public override
    {
        void onInit()
        {
            super.onInit();
            this._labelAnimData     = super.makeDataLabel();
            this._labelChangingData = super.makeDataLabel();
        }

        void onUpdate(Duration deltaTime, InputManager input)
        {
            import std.format : format;

            if(input.wasKeyTapped(Scancode.BACKSPACE))
                super.manager.swap!MenuScene;

            if(this._animations.length == 0)
                return;

            if(input.wasKeyTapped(Scancode.RIGHT))
            {
                this._animIndex += 1;

                if(this._animIndex >= this._animations.length)
                    this._animIndex = 0;

                this.changeAnimation();
            }

            if(input.wasKeyTapped(Scancode.LEFT))
            {
                if(this._animIndex == 0)
                    this._animIndex = this._animations.length - 1;
                else
                    this._animIndex -= 1;

                this.changeAnimation();
            }

            if(input.isKeyDown(Scancode.R) && this._sprite !is null)
            {
                if(input.isShiftDown && input.wasKeyTapped(Scancode.R)) // wasKeyTapped is used give it a better behavoiouroiuouoru
                {
                    auto animPtr = &this._animations[this._animIndex];
                    animPtr.repeat = !animPtr.repeat;
                    this.changeAnimation(); // This is to update the animation data in the sprite.
                }
                else
                    this._sprite.restart();
            }

            if(input.wasKeyTapped(Scancode.EQUALS)
            || input.wasKeyTapped(Scancode.MINUS))
            {
                auto multiplier = (input.wasKeyTapped(Scancode.EQUALS)) ? 1 : -1;
                auto amount = 1;

                     if(input.isControlDown) amount = 5;
                else if(input.isShiftDown)   amount = 10;
                else if(input.isAltDown)     amount = 50;

                this._animations[this._animIndex].delayPerFrame += (amount * multiplier).msecs;
                this.changeAnimation(); // This is to update the animation data in the sprite.
            }

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
            return "Left/Right Arrow: Change Animation | R: Restart [shift = Toggle repeating] | Backspace: Back to menu\n"~
                   "+/- = Increase/Decrease Frame delay by 1 [ctrl = +/- 5] [shift = +/- 10] [alt = +/- 50]";
        }
    }
}
