/// Contains a test scene.
module jarena.gameplay.scenes.debugs.stress_render_2;
import std.stdio;
import jarena.core, jarena.graphics, jarena.gameplay, jarena.data.loaders, jarena.gameplay.gui, jarena.gameplay.scenes;

@SceneName("Render test #2")
class StressTest_Render2Scene : Scene
{
    const ENTITY_COUNT = 1_000u;

    SpritePool pool;

    public override
    {
        void onInit()
        {
            import std.random;

            SpriteAtlas atlas = Systems.assets.get!SpriteAtlas("Test Atlas");
            this.pool = new SpritePool(atlas.texture, ENTITY_COUNT);
            foreach(i; 0..ENTITY_COUNT)
            {
                import std.conv : to;

                auto xPos = uniform(0, Systems.window.size.x);
                auto yPos = uniform(0, Systems.window.size.y);

                pool.sprites[i].position = vec2(xPos, yPos);
                pool.flagForUpdate(pool.sprites[i]);
            }

            pool.prepareForRender();
            // pool.buffer.applyMapFunc((scope Vertex[] vboData, scope uint[] eboData)
            // {
            //     writeln(vboData);
            //     writeln(eboData);
            // });
        }

        void onSwap(PostOffice office){}

        void onUnswap(PostOffice office){}

        void onUpdate(Duration deltaTime, InputManager input)
        {
            import std.random;

            foreach(i; 0..ENTITY_COUNT)
            {
                pool.sprites[i].position = vec2(uniform(0, Systems.window.size.x), uniform(0, Systems.window.size.y));
                pool.flagForUpdate(pool.sprites[i]);
            }
            pool.prepareForRender();

            super.updateScene(deltaTime);
            super.updateUI(deltaTime);
        }

        void onRender(Window window)
        {
            window.renderer.drawPool(pool);
            super.renderScene(window);
            super.renderUI(window);
        }
    }
}