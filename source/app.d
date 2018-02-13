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
    auto scenes = new SceneManager(office);

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

    Sprite tahn;
    bool moveLeft = false;
    bool moveRight = false;

    public
    {
        this()
        {
            super("Test");
        }

        // temp, InputManager currently doesn't get passed to a Scene
        @MailBox(Window.Event.KeyDown)
        void onKeyDown(PostOffice o, ValueMail!sfKeyEvent m)
        {
            if(m.value.code == sfKeyD)
                this.moveRight = true;
            if(m.value.code == sfKeyA)
                this.moveLeft = true;
        }

        @MailBox(Window.Event.KeyUp)
        void onKeyUp(PostOffice o, ValueMail!sfKeyEvent m)
        {
            if(m.value.code == sfKeyD)
                this.moveRight = false;
            if(m.value.code == sfKeyA)
                this.moveLeft = false;
        }
    }

    public override
    {
        void onInit()
        {
            this.tahn = new Sprite(new Texture("Tahn.png"));
            super.registerSprite(this.tahn, 1);

            // meh, testing code, can't be botehred ot make a variable for it
            super.registerSprite(new Sprite(new Texture("TahnBig.png")), 0);
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

            if(moveRight)
                this.tahn.move(speed);
            if(moveLeft)
                this.tahn.move(-speed);
        }
    }
}