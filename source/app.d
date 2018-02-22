import std.stdio;
import derelict.sfml2.graphics, derelict.sfml2.system, derelict.sfml2.window;
import jarena.core, jarena.graphics, jarena.gameplay;

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

            this.tahn = new StaticObject("Tahn.png", vec2(0), 1);
            super.register("Tahn", this.tahn);
            super.register("TahnBig", new StaticObject("TahnBig.png"));
            super.register("Jash", new StaticObject("Jash.jpg", vec2(500, 0), 3));

            super.eventOffice.subscribe(69, (_, __){writeln("Tick");});
            this.timer = new MailTimer(super.eventOffice, new CommandMail(69), GameTime.fromSeconds(3));
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

            if(super.manager.input.isKeyDown(sfKeyUp))
                this.tahn.yLevel = this.tahn.yLevel + 1; // += doesn't work for some reason.
            if(super.manager.input.isKeyDown(sfKeyDown))
                this.tahn.yLevel = this.tahn.yLevel - 1;

            this.timer.onUpdate(deltaTime);

            super.updateScene(window, deltaTime);
            super.renderScene(window);
        }
    }
}