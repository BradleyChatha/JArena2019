import std.stdio, std.experimental.logger;
import derelict.sdl2.sdl, derelict.freeimage.freeimage;
import jarena.core, jarena.graphics, jarena.gameplay, jarena.data.loaders, jarena.gameplay.gui, jarena.gameplay.scenes;

void main()
{
    sharedLog = new ConsoleLogger(LogLevel.all);

    DerelictSDL2.load();
    DerelictFI.load();
    
    import std.exception : enforce;
    enforce(SDL_Init(SDL_INIT_EVERYTHING) == 0, "SDL was not able to initialise everything.");
    FreeImage_Initialise();
    
    SdlangLoader.setup();
    
    auto engine = new Engine();
    engine.onInit();

    engine.scenes.register(new GLTest());
    engine.scenes.register(new Test());
    engine.scenes.register(new MenuScene());
    engine.scenes.register(new AnimationViewerScene(engine.scenes.cache.getCache!AnimationInfo));
    engine.scenes.register(new SpriteAtlasViewerScene(engine.scenes.cache.getCache!SpriteAtlas));
    //engine.scenes.swap!GLTest;
    engine.scenes.swap!Test;
    engine.doLoop();

    SDL_Quit();
}
