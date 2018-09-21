module jarena.gameplay.scenes.debugs.debug_menu;

private
{
    import jarena.audio, jarena.core, jarena.gameplay, jarena.graphics, jarena.gameplay.scenes;
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

        void onDumpTextures(Button _)
        {
            Systems.renderResources.dumpTextures();
        }

        void onDumpFonts(Button _)
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
            this._list = new StackContainer(MENU_POSITION);
            this._list.colour = MENU_COLOUR;
            super.gui.addChild(this._list);

            this._bding = Systems.assets.get!Sound("Bding");
            this._music = Systems.assets.get!Sound("Debug Music");
            auto font   = Systems.assets.get!Font("Calibri");
            void addButton(string text, Button.OnClickFunc handler)
            {
                this._list.addChild(new SimpleTextButton(
                    new Text(font, text, vec2(0), MENU_TEXT_SIZE),
                    handler
                )).fitToText();
            }
            
            addButton("Dump all Textures", &this.onDumpTextures);
            addButton("Dump all Fonts", &this.onDumpFonts);
            addButton("Sound Test", (_){Systems.audio.play(this._bding);});
            addButton("Music Test", (_){Systems.audio.play(this._music);});
            addButton("Go back", _ => super.manager.swap!MenuScene);
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
