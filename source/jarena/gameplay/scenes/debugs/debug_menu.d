module jarena.gameplay.scenes.debugs.debug_menu;

private
{
    import jarena.audio, jarena.core, jarena.gameplay, jarena.graphics, jarena.gameplay.scenes, jarena.maths;
}

@SceneName("Debug Menu")
final class DebugMenuScene : Scene
{
    enum MENU_POSITION  = vec2(5, 20);
    enum MENU_COLOUR    = Colours.amazon;
    enum MENU_TEXT_SIZE = 18;

    private
    {
        StackContainer _list;
        Sound _bding;
        Sound _music;

        void onDumpTextures(BasicButton _)
        {
            Systems.renderResources.dumpTextures();
        }

        void onDumpFonts(BasicButton _)
        {
            import std.conv : to;
            uint count = 0;
            foreach(font; Systems.assets.byKeyValueFiltered!Font)
                (cast(Font)font.value).dumpAllTextures(font.key); // Casting away const here, but it _should_ be safe to do so in this case.
        }
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

            this._bding = Systems.assets.get!Sound("Bding");
            this._music = Systems.assets.get!Sound("Debug Music");
            auto font   = Systems.assets.get!Font("Calibri");
            void addButton(string text, void delegate(BasicButton) handler)
            {
                auto btn = new BasicButton();
                btn.text.value.font     = font;
                btn.text.value.text     = text;
                btn.text.value.charSize = MENU_TEXT_SIZE;
                btn.size.value.y        = 23;
                btn.horizAlignment      = HorizontalAlignment.Stretch;
                btn.onClick.connect(handler);
                this._list.addChild(btn);
            }
            
            addButton("Dump all Textures", &this.onDumpTextures);
            addButton("Dump all Fonts", &this.onDumpFonts);
            addButton("Sound Test", (_){Systems.audio.play(this._bding);});
            addButton("Music Test", (_){Systems.audio.play(this._music);});
            addButton("Go back", _ => super.manager.swap!MenuScene);
            
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
