import std.stdio;

import derelict.sfml2.graphics, derelict.sfml2.system, derelict.sfml2.window;

void main()
{
    DerelictSFML2Graphics.load();
    DerelictSFML2System.load();
    DerelictSFML2Window.load();

    // test
    import jarena.core.maths, jarena.core.post, jarena.graphics.window, jarena.graphics.sprite, jarena.core.cache;
    import jarena.core.time;
    auto window = new Window("Test Window", uvec2(860, 720));
    auto office = new PostOffice();
    auto input = new InputManager(office);
    auto cache = new Cache!Texture();
    auto fps = new FPS();

    office.reserveTypes!(Window.Event);
    office.subscribe(Window.Event.Close,
    (po, m)
    {
        window.close();
    });

    cache.add("CacheTest", new Texture("Tahn.png"));
    auto sprite = new Sprite(cache.get("CacheTest"));
    while(window.isOpen)
    {
        fps.onUpdate();
        window.handleEvents(office);

        if(input.isKeyDown(sfKeyD))
            sprite.move(vec2(20, 0));

        if(input.isKeyDown(sfKeyA))
            sprite.move(-vec2(20, 0));

        if(input.isKeyDown(sfKeyEscape))
            window.close();
        
        writefln("Delta Time: %s | FPS: %s", fps.elapsedTime, fps.frameCount);

        window.renderer.clear();
        window.renderer.drawRect(vec2(100, 50), vec2(200, 150));
        window.renderer.drawSprite(sprite);
        window.renderer.displayChanges();
    }
}