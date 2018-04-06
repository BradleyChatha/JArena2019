import std.stdio, std.experimental.logger;
import derelict.sdl2.sdl, derelict.freeimage.freeimage, derelict.freetype;
import jarena.core, jarena.graphics, jarena.gameplay, jarena.data.loaders, jarena.gameplay.gui, jarena.gameplay.scenes;

void main()
{
    sharedLog = new ConsoleLogger(LogLevel.all);

    DerelictFT.missingSymbolCallback = (symbol)
    {
        import derelict.util.exception;

        if(symbol == "FT_Stream_OpenBzip2" 
        || symbol == "FT_Get_CID_Registry_Ordering_Supplement" 
        || symbol == "FT_Get_CID_Is_Internally_CID_Keyed" 
        || symbol == "FT_Get_CID_From_Glyph_Index" )
            return ShouldThrow.No;
        else
            return ShouldThrow.Yes;
    };

    DerelictSDL2.load();
    DerelictFI.load();
    DerelictFT.load();

    import std.exception : enforce;
    enforce(SDL_Init(SDL_INIT_EVERYTHING) == 0, "SDL was not able to initialise everything.");
    FreeImage_Initialise();
    
    SdlangLoader.setup();
    
    auto engine = new Engine();
    engine.onInit();

    engine.window.renderer.useWireframe = false;

    engine.scenes.register(new GLTest());
    engine.scenes.register(new Test());
    engine.scenes.register(new MenuScene());
    engine.scenes.register(new AnimationViewerScene(engine.scenes.cache.getCache!AnimationInfo));
    engine.scenes.register(new SpriteAtlasViewerScene(engine.scenes.cache.getCache!SpriteAtlas));
    engine.scenes.swap!MenuScene;
    //engine.scenes.swap!AnimationViewerScene;
    engine.doLoop();

    SDL_Quit();
}
