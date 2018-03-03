import std.stdio;
import derelict.sfml2.graphics, derelict.sfml2.system, derelict.sfml2.window;
import jarena.core, jarena.graphics, jarena.gameplay, jarena.data.loaders, jarena.gameplay.gui;

void main()
{
    DerelictSFML2Graphics.load();
    DerelictSFML2System.load();
    DerelictSFML2Window.load();

    // test
    auto window = new Window("Test Window", uvec2(860, 720));
    auto office = new PostOffice();
    auto input = new InputManager(office);
    auto fps = new FPS();
    auto scenes = new SceneManager(office, input);

    InitInfo.windowSize = window.size;

    office.reserveTypes!(Window.Event);
    office.subscribe(Window.Event.Close,
    (po, m)
    {
        window.close();
    });

    scenes.register(new Test());
    scenes.swap("Test");
    while(window.isOpen)
    {
        fps.onUpdate();
        input.onUpdate();
        window.handleEvents(office);

        if(input.isKeyDown(sfKeyEscape))
            window.close();
        
        //writefln("Delta Time: %s | FPS: %s", fps.elapsedTime, fps.frameCount);

        window.renderer.clear();
        scenes.onUpdate(window, fps.elapsedTime);
        window.renderer.drawRect(vec2(100, 50), vec2(200, 150));
        window.renderer.displayChanges();
    }
}

class Test : Scene, IPostBox
{
    mixin(IPostBox.generateOnMail!Test);

    StaticObject tahn;
    MailTimer timer;
    SpriteAtlas atlas;
    StackContainer gui;
    StackContainer gui2;

    public
    {
        this()
        {
            super("Test");
        }
    }

    public override
    {
        void onInit()
        {
            writeln("Window Size: ", InitInfo.windowSize);

            //atlas = new SpriteAtlas(new Texture("Atlas.png"));
            //atlas.register("Tahn", RectangleI(512, 0, 32, 32));
            //atlas.register("TahnBig", RectangleI(256, 0, 256, 256));

            import sdlang;
            atlas = SdlangLoader.parseAtlasTag(parseFile("test atlas.sdl"), "Test Atlas", null, null, super.manager.commonTextures);

            this.tahn = new StaticObject(atlas.makeSprite("Tahn"), vec2(0), 1);
            super.register("Tahn", this.tahn);
            super.register("TahnBig", new StaticObject(atlas.makeSprite("TahnBig")));
            super.register("Jash", new StaticObject(atlas.makeSprite("Jash"), vec2(500, 0), 3));

            super.eventOffice.subscribe(69, (_, __){writeln("Tick");});
            this.timer = new MailTimer(super.eventOffice, new CommandMail(69), GameTime.fromSeconds(3));

            this.gui  = new StackContainer(vec2(10, 400));
            this.gui2 = new StackContainer(vec2(80, 400), StackContainer.Direction.Horizontal);

            new TestControl(vec2(0,0), vec2(50, 30), colour(128, 0, 128, 255)).parent = gui;
            new TestControl(vec2(0,0), vec2(25, 60), colour(0, 128, 128, 255)).parent = gui;

            new TestControl(vec2(0,0), vec2(50, 30), colour(128, 0, 128, 255)).parent = gui2;
            new TestControl(vec2(0,0), vec2(25, 60), colour(0, 128, 128, 255)).parent = gui2;
        }

        void onSwap(PostOffice office)
        {
        }

        void onUnswap(PostOffice office)
        {
        }

        void onUpdate(Window window, GameTime deltaTime)
        {
            auto speedHorizontal = vec2(160 * deltaTime.asSeconds, 0);
            auto speedVertical   = vec2(0, 160 * deltaTime.asSeconds);

            if(super.manager.input.isKeyDown(sfKeyD))
                this.tahn.move(speedHorizontal);
            if(super.manager.input.isKeyDown(sfKeyA))
                this.tahn.move(-speedHorizontal);
            if(super.manager.input.isKeyDown(sfKeyW))
                this.tahn.move(-speedVertical);
            if(super.manager.input.isKeyDown(sfKeyS))
                this.tahn.move(speedVertical);

            if(super.manager.input.isKeyDown(sfKeyE))
                this.tahn.isHidden = true;
            if(super.manager.input.isKeyDown(sfKeyF))
                this.tahn.isHidden = false;

            if(super.manager.input.wasKeyTapped(sfKeyJ))
                this.atlas.changeSprite(this.tahn, "Jash");
            if(super.manager.input.wasKeyTapped(sfKeyK))
                this.atlas.changeSprite(this.tahn, "Tahn");

            if(super.manager.input.wasKeyTapped(sfKeyUp) && !super.manager.input.wasKeyRepeated(sfKeyUp))
                this.tahn.yLevel = this.tahn.yLevel + 1; // += doesn't work for some reason.
            if(super.manager.input.wasKeyTapped(sfKeyDown) && !super.manager.input.wasKeyRepeated(sfKeyDown))
                this.tahn.yLevel = this.tahn.yLevel - 1;

            if(super.manager.input.wasKeyTapped(sfKeyG) && !super.manager.input.wasKeyRepeated(sfKeyG))
            {
                if(gui.children.length == 1)
                    gui2.children[0].parent = gui;
                else
                    gui.children[0].parent = gui2;
            }

            this.timer.onUpdate(deltaTime);

            super.updateScene(window, deltaTime);
            super.renderScene(window);
            this.gui.onRender(window);
            this.gui2.onRender(window);
        }
    }
}