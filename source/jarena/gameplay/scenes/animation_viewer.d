module jarena.gameplay.scenes.animation_viewer;

private
{
    import derelict.sfml2.window, derelict.sfml2.graphics;
    import jarena.core, jarena.gameplay, jarena.graphics;
}

final class AnimationViewerScene : Scene
{
    private
    {
        AnimatedObject _sprite;
        AnimationInfo[] _animations;
        size_t _animIndex;

        void changeAnimation()
        {
            if(this._animIndex >= this._animations.length)
                assert(false, "Bug");

            auto next = this._animations[this._animIndex];
            if(this._sprite is null)
            {
                this._sprite = new AnimatedObject(new AnimatedSprite(next));
                super.register("Sprite", this._sprite);
            }

            this._sprite.animation = next;
            this._sprite.position  = vec2((InitInfo.windowSize.x / 2) - (this._sprite.textureRect.size.x / 2),
                                          (InitInfo.windowSize.y / 2) - (this._sprite.textureRect.size.y / 2));
        }
    }

    public
    {
        this(Cache!AnimationInfo animations)
        {
            import std.array : array;
            import std.algorithm : map;
            assert(animations !is null);

            this._animations = animations.values.map!(v => cast(AnimationInfo)v).array;
            super("Animation Viewer");
        }
    }

    public override
    {
        void onInit()
        {
        }

        void onSwap(PostOffice office)
        {
        }

        void onUnswap(PostOffice office)
        {
        }

        void onUpdate(Window window, GameTime deltaTime)
        {
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

            super.updateScene(window, deltaTime);
            super.renderScene(window);
        }
    }
}