import std.stdio, std.experimental.logger;
import jarena.core, jarena.graphics, jarena.gameplay, jarena.data.loaders, jaster.serialise, jarena.gameplay.scenes;

version(unittest){}
else
{
void main()
{
    sharedLog = new ConsoleLogger(LogLevel.all);

    // Setup the engine.
    auto engine = new Engine();
    engine.onInitLibraries();
    engine.onInit();

    // Register all the scenes, swap to the main one, then start the main game loop.
    engine.scenes.register(new Test());
    engine.scenes.register(new MenuScene());
    engine.scenes.register(new DebugMenuScene());
    engine.scenes.register(new JoshyClickerScene());
    engine.scenes.register(new AnimationViewerScene());
    //engine.scenes.register(new StressTest_Render1Scene());
    engine.scenes.register(new StressTest_Render2Scene());
    engine.scenes.swap!MenuScene;
    //engine.scenes.swap!AnimationViewerScene;
    engine.doLoop();
}
}