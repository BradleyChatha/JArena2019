module jarena.gameplay.scenes.debug_menu;


private
{
    import jarena.core, jarena.gameplay, jarena.graphics, jarena.gameplay.scenes;
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

        void onDumpTextures(Button _)
        {
            Systems.renderResources.dumpTextures();
        }

        void onDumpFonts(Button _)
        {
            import std.conv : to;
            uint count = 0;
            foreach(font; super.manager.cache.getCache!Font.byValue)
                (cast(Font)font).dumpAllTextures("Font"~count++.to!string); // Casting away const here, but it _should_ be safe to do so in this case.
        }
    }

    public override
    {
        void onInit()
        {
            this._list = new StackContainer(MENU_POSITION);
            this._list.colour = MENU_COLOUR;
            super.gui.addChild(this._list);

            auto font = super.manager.cache.get!Font("Calibri");
            void addButton(string text, Button.OnClickFunc handler)
            {
                this._list.addChild(new SimpleTextButton(
                    new Text(font, text, vec2(0), MENU_TEXT_SIZE),
                    handler
                )).fitToText();
            }

            addButton("Dump all Textures", &this.onDumpTextures);
            addButton("Dump all Fonts", &this.onDumpFonts);
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
