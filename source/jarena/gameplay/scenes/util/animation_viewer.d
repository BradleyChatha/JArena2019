module jarena.gameplay.scenes.util.animation_viewer;

private
{
    import std.algorithm, std.format;
    import jarena.core, jarena.gameplay, jarena.graphics, jarena.maths, jarena.data;
}

@SceneName("Animation Viewer Scene")
final class AnimationViewerScene : Scene
{
    enum CAMERA_SPEED = 200;

    private
    {
        struct SizeT
        {
            alias value this;
            size_t value;
        }

        StackContainer  _instructionPanel;
        ViewContainer   _view;
        AnimationInfo[] _info;
        Property!size_t _currentInfoIndex;
        AnimatedSprite  _sprite;

        void changeAnimation(size_t index)
        {
            this._currentInfoIndex = index;
            this._sprite.animation = this.currentInfo;
            this._sprite.position = (vec2(Systems.window.size) / 2) - (this._sprite.bounds.size / 2);
        }

        void refreshData()
        {
            import std.array : array;
            this._info             = Systems.assets.byKeyValueFiltered!AnimationInfo.map!(kv => kv.value).array;
            this._currentInfoIndex = 0;
            
            if(this._sprite is null && this._info.length > 0)
                this._sprite = new AnimatedSprite(this._info[0]);

            // Repopulate the list.
            auto list = super.gui.getDeepChild!StackContainer("panelList");
            while(list.children.length > 1)
                list.removeChild(1);

            foreach(i, info; this._info)
            {
                auto btn = DataBinder.factoryTemplate!BasicButton("AV_ListButton");
                btn.text.value.text = info.name;
                btn.tag = new StructWrapperAsset!SizeT(SizeT(i)); // StructWrapperAsset is used since it's a convinent wrapper around a struct.
                btn.onClick.connect((b) => this.changeAnimation(b.tagAs!(StructWrapperAsset!SizeT).value));
                list.addChild(btn);
            }

            if(this._info.length > 0)
                this.changeAnimation(0);
        }

        void onRefreshInfo(Property!size_t)
        {
            auto text = super.gui.getDeepChild!BasicLabel("lblData1");
            text.text.value.text = format(
                "Name: %s\n"
               ~"Frame Delay: %sms\n"
               ~"Repeating: %s\n"
               ~"Rows: %s\n"
               ~"Columns: %s\n"
               ~"Frame Count: %s\n"
               ~"Animation Time: %sms",
                this.currentInfo.name,
                this.currentInfo.delayPerFrame.total!"msecs",
                this.currentInfo.repeat,
                this.currentInfo.spriteSheet.rows,
                this.currentInfo.spriteSheet.columns,
                this.currentInfo.spriteSheet.rows * this.currentInfo.spriteSheet.columns,
                (this.currentInfo.delayPerFrame * (this.currentInfo.spriteSheet.rows * this.currentInfo.spriteSheet.columns)).total!"msecs"
            );
            text.onInvalidate.emit();
        }

        @property
        ref AnimationInfo currentInfo()
        {
            return this._info[this._currentInfoIndex.value];
        }
    }

    this()
    {
        this._currentInfoIndex = new Property!size_t();
        this._currentInfoIndex.onValueChanged.connect(&this.onRefreshInfo);
    }

    public override
    {
        void onSwap(PostOffice office){}
        void onUnswap(PostOffice office){}

        void onInit()
        {
            this._view = super.gui.addChild(Systems.assets.get!ViewContainer("AnimationViewer_View"));
            this.refreshData();
        }

        void onUpdate(Duration deltaTime, InputManager input)
        {
            auto cameraSpeed = CAMERA_SPEED * deltaTime.asSeconds;

            if(input.isKeyDown(Scancode.W))
                this.camera.move(vec2(0, -cameraSpeed));
            if(input.isKeyDown(Scancode.S))
                this.camera.move(vec2(0, cameraSpeed));
            if(input.isKeyDown(Scancode.A))
                this.camera.move(vec2(-cameraSpeed, 0));
            if(input.isKeyDown(Scancode.D))
                this.camera.move(vec2(cameraSpeed, 0));

            if(input.wasKeyTapped(Scancode.L))
            {
                auto panel      = super.gui.getDeepChild!UIBase("panelList");
                panel.isVisible = !panel.isVisible.value;
            }

            if(input.wasKeyTapped(Scancode.R))
            {
                if(input.isShiftDown)
                {
                    this.currentInfo.repeat = !this.currentInfo.repeat;
                    this.changeAnimation(this._currentInfoIndex.value);
                }
                else
                    this.camera.reset(RectangleF(0, 0, vec2(Systems.window.size)));
            }

            this.onRefreshInfo(null);

            super.updateUI(deltaTime);
            super.updateScene(deltaTime);
            this._sprite.onUpdate(deltaTime);
        }

        void onRender(Window window)
        {
            window.renderer.drawSprite(this._sprite);
            super.renderUI(window);
            super.renderScene(window);
        }
    }
}