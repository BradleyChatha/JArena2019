module editor.scene;

private
{
    import core.sys.windows.winuser;
    import jarena.core, jarena.data, jarena.graphics, jarena.gameplay, jarena.maths;
}

@SceneName("Editor")
public class EditorScene : Scene
{
    void changeView(ArchiveObject view)
    {
        while(super.gui.children.length > 0)
            super.gui.removeChild(0);

        super.gui.addChild(DataBinder.parseView(view, DataBinder.DuplicateAction.Replace));
    }

    public override
    {
        void onInit()
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

        void onSwap(PostOffice office){}
        void onUnswap(PostOffice office){}
    }
}