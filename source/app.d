import std.stdio;
import derelict.sfml2.graphics, derelict.sfml2.system, derelict.sfml2.window;
import jarena.core, jarena.graphics, jarena.gameplay, jarena.data.loaders, jarena.gameplay.gui, jarena.gameplay.scenes;

void main()
{
    DerelictSFML2Graphics.load();
    DerelictSFML2System.load();
    DerelictSFML2Window.load();

    auto engine = new Engine();
    engine.onInit();

    engine.scenes.register(new Test());
    engine.scenes.register(new MenuScene());
    engine.scenes.register(new AnimationViewerScene(engine.scenes.cache.getCache!AnimationInfo));
    engine.scenes.swap!MenuScene;
    engine.doLoop();
}
