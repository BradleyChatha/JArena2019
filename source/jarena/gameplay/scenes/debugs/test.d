/// Contains a test scene.
module jarena.gameplay.scenes.debugs.test;
import std.stdio;
import jarena.core, jarena.graphics, jarena.gameplay, jarena.data.loaders, jarena.gameplay.gui, jarena.gameplay.scenes;
import jarena.gameplay.scenes.editors.controls;

@SceneName("Test")
class Test : Scene, IPostBox
{
    mixin(IPostBox.generateOnMail!Test);

    StaticObject tahn;
    SpriteAtlas atlas;
    StackContainer gui;
    StackContainer gui2;
    RectangleShape[2] centerLines;
    TextObject someText;
    TextObject inputText;
    SimpleTextBox inputBox;
    ButtonTooltip tooltip;
    EditorButton tooltippedButton;
    EditorScrollBoxContainer scrollbox;
    CircleShape circle;
    RectangleI scissorRect;
    bool useWireframe;
    //GridContainer  grid;

    public override
    {
        void onInit()
        {
            writeln("Window Size: ", Systems.window.size);

            //atlas = new SpriteAtlas(new Texture("Atlas.png"));
            //atlas.register("Tahn", RectangleI(512, 0, 32, 32));
            //atlas.register("TahnBig", RectangleI(256, 0, 256, 256));
            //atlas = SdlangLoader.parseAtlasTag(parseFile("Data/Atlases/test atlas.sdl"), "Test Atlas", "Data/", null, Systems.assets.getCache!Texture);
            atlas = Systems.assets.get!SpriteAtlas("Test Atlas");

            foreach(i; 0..this.centerLines.length)
            {
                this.centerLines[i] = new RectangleShape();
                this.centerLines[i].borderSize = 0;
                this.centerLines[i].colour = Colours.brownBramble;
            }
            this.centerLines[0].area = RectangleF(
                Systems.window.size.x / 2,
                0,
                1,
                Systems.window.size.y
            );
            this.centerLines[1].area = RectangleF(
                0,
                Systems.window.size.y / 2,
                Systems.window.size.x,
                1
            );

            this.tahn = new StaticObject(atlas.makeSprite("Tahn"), vec2(0), 1);
            super.register("Tahn", this.tahn);
            super.register("TahnBig", new StaticObject(atlas.makeSprite("TahnBig")));
            super.register("Jash", new StaticObject(atlas.makeSprite("Jash"), vec2(500, 0), 3));

            //auto info = SdlangLoader.parseSpriteSheetAnimationTag(parseFile("Data/test animation.sdl"), "Data/", "Test Atlas", Systems.assets.);
            auto info = Systems.assets.get!AnimationInfo("Test Animation");
            super.register("AnimatedTahn", new AnimatedObject(new AnimatedSprite(info), vec2(500, 500)));

            this.gui  = new StackContainer(vec2(10, 400), StackContainer.Direction.Vertical, Colour(0,0,0,128));
            this.gui2 = new StackContainer(vec2(80, 400), StackContainer.Direction.Horizontal, Colour.transparent);
            //this.grid = new GridContainer(vec2(1, 570), vec2(200, 100));
            //this.grid.addRow(GridContainer.SizeType.Pixels, 50);
            //this.grid.addRow(GridContainer.SizeType.Pixels, 50);
            //this.grid.addColumn(GridContainer.SizeType.Pixels, 75);
            //this.grid.addColumn(GridContainer.SizeType.Pixels, 75);
            //this.grid.drawGrid = true;

            super.gui.addChild(gui);
            super.gui.addChild(gui2);
            //super.gui.addChild(grid);

            gui.addChild(new TestControl(vec2(0,0), vec2(50, 30), Colour(128, 0, 128, 255)));
            gui.addChild(new TestControl(vec2(0,0), vec2(25, 60), Colour(0, 128, 128, 255)));

            gui2.addChild(new TestControl(vec2(0,0), vec2(50, 30), Colour(128, 0, 128, 255)));
            gui2.addChild(new TestControl(vec2(0,0), vec2(25, 60), Colour(0, 128, 128, 255)));

            auto font = Systems.assets.get!Font("Crackdown");
            this.someText  = new TextObject(font, "A B C D E F G 1 2 3", vec2(0,550), 14, Colour(128, 0, 128, 255));
            this.inputText = new TextObject(font, "", vec2(0, 650), 14, Colour(128, 0, 128, 255));
            super.register("Some random text", this.someText);
            super.register("Changeable text", this.inputText);

            this.inputBox = new SimpleTextBox(new Text(font, "", vec2(0), 14, Colour.black), vec2(0, 250), vec2(200, 50), vec2(2, 20));
            super.gui.addChild(this.inputBox).textInput = "[Text Here]";

            size_t i = 0;
            while(true)
            {
                auto rect = someText.getRectForChar(i);
                if(rect.isNull)
                    break;

                writefln("Char #%s is at %s", i, rect);
                i++;
            }
            
            auto btnText = new Text(font, "Click Me", vec2(0), 14, Colour(255, 255, 255, 255));
            gui.addChild(new SimpleTextButton(btnText, btn => writeln("Button position: ", btn.position)));
            gui.getChild!SimpleTextButton(gui.children.length - 1).fitToText();

            this.tooltip = new ButtonTooltip("Delete(D)", "Allows deletion of memes.\nPlease don't hurt me.\n");
            this.tooltippedButton = new EditorButton(Systems.assets.get!Texture("tex_MouseIcon"), "Test Button", "Please ignore\n");
            this.tooltippedButton.position = vec2(0, 20);
            super.gui.addChild(this.tooltip);
            super.gui.addChild(this.tooltippedButton);

            this.scrollbox = new EditorScrollBoxContainer();
            this.scrollbox.position = vec2(0, 540);
            this.scrollbox.size     = vec2(150, 150);
            foreach(___; 0..10)
            {
                this.scrollbox.addChild(new TestControl(vec2(0), vec2(100, 20), Colour.red));
                this.scrollbox.addChild(new TestControl(vec2(0), vec2(80, 20), Colour.green));
                this.scrollbox.addChild(new TestControl(vec2(0), vec2(40, 20), Colour.blue));
            }
            super.gui.addChild(this.scrollbox);

            this.circle = new CircleShape(vec2(0, -50), 15, Colour.red);
        }

        void onSwap(PostOffice office)
        {
            office.subscribe(Window.Event.MouseWheelMoved, &this.onMouseWheel);
            super.manager.input.listenForText = true;
        }

        void onUnswap(PostOffice office)
        {
            office.unsubscribe(&this.onMouseWheel);
            super.manager.input.listenForText = false;
        }

        void onMouseWheel(PostOffice _, Mail mail)
        {
            auto direction = cast(ValueMail!MouseWheelDirection)mail;
            assert(direction !is null);
            
            if(direction.value == MouseWheelDirection.Up)
                this.someText.charSize = this.someText.charSize + 2;
            else
                this.someText.charSize = this.someText.charSize - 2;
        }

        void onUpdate(Duration deltaTime, InputManager input)
        {
            auto speedHorizontal = vec2(160 * deltaTime.asSeconds, 0);
            auto speedVertical   = vec2(0, 160 * deltaTime.asSeconds);
            auto speedRotate     = 5 * deltaTime.asSeconds;
            
            if(input.textInput.length > 0)
                this.inputText.text.text = input.textInput;

            if(input.isKeyDown(Scancode.D))
                this.tahn.move(speedHorizontal);
            if(input.isKeyDown(Scancode.A))
                this.tahn.move(-speedHorizontal);
            if(input.isKeyDown(Scancode.W))
                this.tahn.move(-speedVertical);
            if(input.isKeyDown(Scancode.S))
                this.tahn.move(speedVertical);

            if(input.wasKeyTapped(Scancode.F1))
                super.manager.swap!MenuScene;

            if(input.isKeyDown(Scancode.E))
                this.tahn.isHidden = true;
            if(input.isKeyDown(Scancode.F))
                this.tahn.isHidden = false;

            if(input.wasKeyTapped(Scancode.J))
            {
                this.atlas.changeSprite(this.tahn, "TahnBig");
                this.tahn.origin = vec2(this.tahn.textureRect.size / ivec2(2));
            }
            if(input.wasKeyTapped(Scancode.K))
            {
                this.atlas.changeSprite(this.tahn, "Tahn");
                this.tahn.origin = vec2(this.tahn.textureRect.size / ivec2(2));
            }

            if(input.wasKeyTapped(Scancode.UP) && !input.wasKeyRepeated(Scancode.UP))
                this.tahn.yLevel = this.tahn.yLevel + 1; // += doesn't work for some reason.
            if(input.wasKeyTapped(Scancode.DOWN) && !input.wasKeyRepeated(Scancode.DOWN))
                this.tahn.yLevel = this.tahn.yLevel - 1;
            if(input.isKeyDown(Scancode.LEFT))
            {
                if(!input.isShiftDown)
                    this.tahn.rotationF = this.tahn.rotation - speedRotate;
                else
                    super.camera.rotation = super.camera.rotation - speedRotate;
            }
            if(input.isKeyDown(Scancode.RIGHT))
            {
                if(!input.isShiftDown)
                    this.tahn.rotationF = this.tahn.rotation + speedRotate;
                else
                    super.camera.rotation = super.camera.rotation + speedRotate;
            }

            if(input.wasKeyTapped(Scancode.G) && !input.wasKeyRepeated(Scancode.G))
            {
                if(gui.children.length == 1)
                    gui2.children[0].parent = gui;
                else
                    gui.children[0].parent = gui2;
            }

            this.tooltip.showing = input.isKeyDown(Scancode.F3);
            if(input.wasKeyTapped(Scancode.F1))
                this.tahn.texture.dispose();

            if(input.wasKeyTapped(Scancode.F2))
            {
                Systems.assets.get!Font("Calibri").dispose();
                Systems.assets.get!Font("Crackdown").dispose();
            }

            if(input.wasKeyTapped(Scancode.F4))
            {
                if(this.scissorRect == RectangleI.init)
                    this.scissorRect = RectangleI(ivec2(input.mousePosition), 200, 200);
                else
                    this.scissorRect = RectangleI.init;
            }
            if(this.scissorRect != RectangleI.init)
                this.scissorRect = RectangleI(ivec2(input.mousePosition), 200, 200);

            if(input.wasKeyTapped(Scancode.F5))
                this.useWireframe = !this.useWireframe;

            if(input.isKeyDown(Scancode.F6))
                super.camera.viewport = RectangleI(0, 0, ivec2(input.mousePosition));

            if(input.wasKeyTapped(Scancode.F7))
                Systems.assets.unloadPackage("Debug");

            this.circle.position = super.camera.screenToWorldPos(input.mousePosition);

            super.camera.center = this.tahn.position + (this.tahn.bounds.size / 2);

            super.updateScene(deltaTime);
            super.updateUI(deltaTime);
        }

        void onRender(Window window)
        {
            window.renderer.scissorRect = this.scissorRect;
            super.renderScene(window);
            window.renderer.drawCircleShape(this.circle);
            window.renderer.scissorRect = RectangleI.init;

            window.renderer.useWireframe = this.useWireframe;
            super.renderUI(window);
            window.renderer.useWireframe = false;

            window.renderer.camera = super.guiCamera;
            foreach(shape; this.centerLines)
                window.renderer.drawRectShape(shape);
        }
    }
}