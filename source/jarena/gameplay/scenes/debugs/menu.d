/// Contains the main menu for the game.
module jarena.gameplay.scenes.debugs.menu;

private
{
    import std.typetuple;
    import jarena.core, jarena.gameplay, jarena.graphics, jarena.gameplay.scenes, jarena.maths;

    const TEXT_SIZE = 18;
    const TEXT_COLOUR = Colours.rockSalt;
    const BUTTON_SIZE = vec2(80, 40);
    const BUTTON_COLOUR = Colours.azure;
    const MENU_POSITION = vec2(5, 20);
    const MENU_COLOUR = Colours.amazon;
}

@SceneName("Menu")
final class MenuScene : Scene
{
    private
    {
        alias SCENES = TypeTuple!(Test,
                                  DebugMenuScene,
                                  AnimationViewerScene,
                                  JoshyClickerScene,
                                  StressTest_Render1Scene,
                                  StressTest_Render2Scene);

        StackContainer _list;
    }

    public override
    {
        void onInit()
        {
            this._list                       = new StackContainer();
            this._list.direction             = StackContainer.Direction.Vertical;
            this._list.margin.value.position = MENU_POSITION;
            this._list.background.colour     = MENU_COLOUR;
            this._list.autoSize              = StackContainer.AutoSize.yes;
            super.gui.addChild(this._list);

            auto font = Systems.assets.get!Font("Calibri");
            foreach(item; SCENES)
            {
                auto btn                = new BasicButton();
                btn.text.value.font     = font;
                btn.text.value.text     = SceneName.getFrom!item;
                btn.text.value.charSize = TEXT_SIZE;
                btn.text.value.colour   = TEXT_COLOUR;
                btn.size.value.y        = BUTTON_SIZE.y;
                btn.shape.value.colour  = BUTTON_COLOUR;
                btn.horizAlignment      = HorizontalAlignment.Stretch;
                btn.onClick.connect(_ => super.manager.push!item);

                this._list.addChild(btn);
            }
            
            this._list.autoSize = StackContainer.AutoSize.no;
            this._list.size.value.x = 250;
            this._list.size.onValueChanged.emit(this._list.size);
        }

        void onSwap(PostOffice office)
        {
        }

        void onUnswap(PostOffice office)
        {
        }

        void onUpdate(Duration deltaTime, InputManager input)
        {
            super.updateScene(deltaTime);
            super.updateUI(deltaTime);
        }

        void onRender(Window window)
        {
            super.renderScene(window);
            super.renderUI(window);
        }
    }
}
