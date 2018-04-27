import std.stdio, std.experimental.logger;
import derelict.sdl2.sdl, derelict.freeimage.freeimage, derelict.freetype, derelict.sdl2.mixer;
import jarena.core, jarena.graphics, jarena.gameplay, jarena.data.loaders, jarena.gameplay.gui, jarena.gameplay.scenes;

void main()
{
    sharedLog = new ConsoleLogger(LogLevel.all);

    // The pre-compiled DLL for FreeType is missing some optional symbols we don't care about
    // So this is to tell Derelict that we're fine with missing these select symbols.
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

    /// Load all of the derelict libraries.
    DerelictSDL2.load();
    DerelictSDL2Mixer.load();
    DerelictFI.load();
    DerelictFT.load();

    // Initialise the libraries.
    import std.exception : enforce;
    enforce(SDL_Init(SDL_INIT_EVERYTHING) == 0, "SDL was not able to initialise everything.");
    Mix_Init(0);
    checkSDLError();
    FreeImage_Initialise();

    Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, 2, 2048);
    Mix_SetError("\0".ptr); // Mixer throws an error... but it seems you can safely ignore it.
    checkSDLError();
    scope(exit) Mix_CloseAudio();
    
    // Prepare all of the data loaders.
    SdlangLoader.setup();
    
    // Setup the engine.
    auto engine = new Engine();
    engine.onInit();

    // Register all the scenes, swap to the main one, then start the main game loop.
    engine.scenes.register(new Test());
    engine.scenes.register(new MenuScene());
    engine.scenes.register(new DebugMenuScene());
    engine.scenes.register(new AnimationViewerScene(engine.scenes.cache.getCache!AnimationInfo));
    engine.scenes.register(new SpriteAtlasViewerScene(engine.scenes.cache.getCache!SpriteAtlas));
    engine.scenes.swap!MenuScene;
    //engine.scenes.swap!AnimationViewerScene;
    engine.doLoop();

    SDL_Quit();
}
