module jarena.gameplay.scenes.util.animation_viewer;

private
{
    import jarena.core, jarena.gameplay, jarena.graphics, jarena.maths;
}

@SceneName("Animation Viewer Scene")
final class AnimationViewerScene : Scene
{
    private
    {
        StackContainer _instructionPanel;
        ViewContainer  _view;
    }

    public override
    {
        void onSwap(PostOffice office){}
        void onUnswap(PostOffice office){}

        void onInit()
        {
            this._view = super.gui.addChild(Systems.assets.get!ViewContainer("AnimationViewer_View"));
        }

        void onUpdate(Duration deltaTime, InputManager input)
        {
            super.updateUI(deltaTime);
            super.updateScene(deltaTime);
        }

        void onRender(Window window)
        {
            super.renderUI(window);
            super.renderScene(window);
        }
    }
}