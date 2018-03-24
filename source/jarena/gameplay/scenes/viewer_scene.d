module jarena.gameplay.scenes.viewer_scene;

private
{
    import jarena.core, jarena.gameplay, jarena.graphics;

    const DEFAULT_FONT_KEY      = "Calibri";
    const GUI_BACKGROUND_COLOUR = Colours.azure;
    const TEXT_CHAR_SIZE        = 18;
    const TEXT_COLOUR           = Colours.bianca;
}

/++
 + A base class that contains a basic GUI setup (with some helper functions)
 + for any viewer/debug scene.
 + ++/
abstract class ViewerScene : Scene
{
    private
    {
        StackContainer _dataPanel;
        StackContainer _instructionPanel;

        SimpleLabel makeLabel(Container gui, Font font)
        {
            return gui.addChild(new SimpleLabel(new Text(font, ""d, vec2(0), TEXT_CHAR_SIZE, TEXT_COLOUR)));
        }
    }

    protected
    {
        /++
         + Creates a new label in the scene's data panel, and returns it.
         + ++/
        SimpleLabel makeDataLabel(string fontKey = DEFAULT_FONT_KEY)
        {
            return this.makeLabel(this._dataPanel, super.manager.cache.get!Font(fontKey));
        }

        override void onSwap(PostOffice office){}
        override void onUnswap(PostOffice office){}
    }

    protected abstract
    {
        override void onInit()
        {
            // Setup data panel
            this._dataPanel        = new StackContainer(vec2(5, 20));
            this._dataPanel.colour = GUI_BACKGROUND_COLOUR;
            super.gui.addChild(this._dataPanel);

            // Setup instruction panel
            this._instructionPanel        = new StackContainer(StackContainer.Direction.Horizontal);
            this._instructionPanel.colour = GUI_BACKGROUND_COLOUR;
            super.gui.addChild(this._instructionPanel);

            auto instLabel = this.makeLabel(this._instructionPanel, super.manager.cache.get!Font(DEFAULT_FONT_KEY));
            instLabel.updateTextASCII(this.instructions);
            
            this._instructionPanel.autoSize = StackContainer.AutoSize.no;
            this._instructionPanel.size     = vec2(InitInfo.windowSize.x, this._instructionPanel.size.y);
            this._instructionPanel.position = vec2(0, InitInfo.windowSize.y - this._instructionPanel.size.y);
        }

        override void onUpdate(GameTime deltaTime)
        {
            super.updateUI(deltaTime);
        }

        override void onRender(Window window)
        {
            super.renderUI(window);
        }
        
        /// Returns: A string containing instructions on how to control the scene.
        string instructions();
    }
}
