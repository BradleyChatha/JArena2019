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
    engine.scenes.register(new AnimationViewerScene(engine.scenes.cache.getCache!AnimationInfo));
    engine.scenes.swap!Test;
    engine.doLoop();
}

@SceneName("Test")
class Test : Scene, IPostBox
{
    mixin(IPostBox.generateOnMail!Test);

    StaticObject tahn;
    SpriteAtlas atlas;
    StackContainer gui;
    StackContainer gui2;

    public
    {
        this()
        {
            super();
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
            //atlas = SdlangLoader.parseAtlasTag(parseFile("Data/Atlases/test atlas.sdl"), "Test Atlas", "Data/", null, super.manager.cache.getCache!Texture);
            atlas = super.manager.cache.get!SpriteAtlas("Test Atlas");

            this.tahn = new StaticObject(atlas.makeSprite("Tahn"), vec2(0), 1);
            super.register("Tahn", this.tahn);
            super.register("TahnBig", new StaticObject(atlas.makeSprite("TahnBig")));
            super.register("Jash", new StaticObject(atlas.makeSprite("Jash"), vec2(500, 0), 3));

            //auto info = SdlangLoader.parseSpriteSheetAnimationTag(parseFile("Data/test animation.sdl"), "Data/", "Test Atlas", super.manager.cache);
            auto info = super.manager.cache.get!AnimationInfo("Test Animation");
            super.register("AnimatedTahn", new AnimatedObject(new AnimatedSprite(info), vec2(500, 500)));

            this.gui  = new StackContainer(vec2(10, 400), StackContainer.Direction.Vertical, colour(0,0,0,128));
            this.gui2 = new StackContainer(vec2(80, 400), StackContainer.Direction.Horizontal, colour(64,64,64,128));

            gui.addChild(new TestControl(vec2(0,0), vec2(50, 30), colour(128, 0, 128, 255)));
            gui.addChild(new TestControl(vec2(0,0), vec2(25, 60), colour(0, 128, 128, 255)));

            gui2.autoSize = gui2.AutoSize.no;
            gui2.addChild(new TestControl(vec2(0,0), vec2(50, 30), colour(128, 0, 128, 255)));
            gui2.addChild(new TestControl(vec2(0,0), vec2(25, 60), colour(0, 128, 128, 255)));

            auto font = super.manager.cache.get!Font("Crackdown");
            super.register("Some random text", new TextObject(font, "A B C D E F G 1 2 3"d, vec2(0,550), 14, colour(128, 0, 128, 255), 0));
            
            auto btnText = new Text(font, "Click Me"d, vec2(0), 14, colour(255, 255, 255, 255));
            gui.addChild(new SimpleButton(btnText, btn => writeln("Button position: ", btn.position)));
            gui.getChild!SimpleButton(gui.children.length - 1).fitToText();
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

            if(super.manager.input.wasKeyTapped(sfKeyP))
                super.manager.swap!AnimationViewerScene;

            if(super.manager.input.isKeyDown(sfKeyE))
                this.tahn.isHidden = true;
            if(super.manager.input.isKeyDown(sfKeyF))
                this.tahn.isHidden = false;

            if(super.manager.input.wasKeyTapped(sfKeyJ))
                this.atlas.changeSprite(this.tahn, "TahnBig");
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

            super.updateScene(window, deltaTime);
            this.gui.onUpdate(super.manager.input, deltaTime);
            super.renderScene(window);
            this.gui2.onRender(window);
            this.gui.onRender(window);
        }
    }
}