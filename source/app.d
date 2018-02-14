import std.stdio;
import derelict.sfml2.graphics, derelict.sfml2.system, derelict.sfml2.window;

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

import jarena.core.maths, jarena.core.post, jarena.graphics.window, jarena.graphics.sprite, jarena.core.cache;
import jarena.core.time, jarena.gameplay.scene;
class Test : Scene, IPostBox
{
    mixin(IPostBox.generateOnMail!Test);

    StaticObject tahn;

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
            this.tahn = new StaticObject("Tahn.png", vec2(0), 1);
            super.register("Tahn", this.tahn);

            // meh, testing code, can't be botehred ot make a variable for it
            super.register("TahnBig", new StaticObject("TahnBig.png"));
        }

        void onSwap(PostOffice office)
        {
        }

        void onUnswap(PostOffice office)
        {
        }

        void onUpdate(Window window, GameTime deltaTime)
        {
            auto speed = vec2(160 * deltaTime.asSeconds, 0);

            if(super.manager.input.isKeyDown(sfKeyD))
                this.tahn.move(speed);
            if(super.manager.input.isKeyDown(sfKeyA))
                this.tahn.move(-speed);

            if(super.manager.input.isKeyDown(sfKeyE) && !super.isRegistered(this.tahn))
                super.register(this.tahn.name, this.tahn);
            if(super.manager.input.isKeyDown(sfKeyF) && super.isRegistered(this.tahn))
                super.unregister(this.tahn);

            super.updateScene(window, deltaTime);
            super.renderScene(window);
        }
    }
}