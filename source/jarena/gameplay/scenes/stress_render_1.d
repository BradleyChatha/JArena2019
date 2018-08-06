/// Contains a test scene.
module jarena.gameplay.scenes.stress_render_1;
import std.stdio;
import jarena.core, jarena.graphics, jarena.gameplay, jarena.data.loaders, jarena.gameplay.gui, jarena.gameplay.scenes;

@SceneName("Render test #1")
class StressTest_Render1Scene : Scene
{
    const ENTITY_COUNT = 5_000u;

    public override
    {
        void onInit()
        {
            import std.random;

            SpriteAtlas atlas = Systems.assets.get!SpriteAtlas("Test Atlas");
            foreach(i; 0..ENTITY_COUNT)
            {
                import std.conv : to;

                auto xPos = uniform(0, Systems.window.size.x);
                auto yPos = uniform(0, Systems.window.size.y);

                super.register(i.to!string, new StaticObject(atlas.texture, vec2(xPos, yPos)));
            }
        }

        void onSwap(PostOffice office){}

        void onUnswap(PostOffice office){}

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