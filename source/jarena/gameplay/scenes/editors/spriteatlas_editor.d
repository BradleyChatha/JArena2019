module jarena.gameplay.scenes.editors.spriteatlas_editor;

private
{
    import jarena.core, jarena.data, jarena.gameplay, jarena.graphics, jarena.gameplay.scenes.editors.controls;

    enum TOOL_LIST_POSITION             = vec2(0, 20);
    enum TOOL_LIST_FILL                 = Colour(128, 128, 128, 128);
    enum WINDOW_LIST_POSITION           = vec2(371, 5);
    enum CAMERA_SPEED                   = 200;
    enum ATLAS_PICKER_POSITION          = vec2(648, 7);
    enum ATLAS_PICKER_SIZE              = vec2(210, 731);
    enum ATLAS_PICKER_BUTTON_POSITION   = vec2(0, 400);
    enum SELECTION_RECTANGLE_COLOUR     = Colour(248, 221, 92, 128);
    enum ZOOM_STEP                      = 0.10;
}

@SceneName("Sprite Atlas Editor")
class SpriteAtlasEditorScene : Scene
{
    import std.range : drop, walkLength;

    private
    {
        alias RectMode = EditorRectangle!SpriteMeta.Mode;
        alias SpriteRect = EditorRectangle!SpriteMeta;

        enum WindowType
        {
            AtlasPicker,
            SpriteInfo
        }

        struct SpriteMeta
        {
            SpriteAtlas atlas;
            string spriteName;
        }

        struct GuiWindow
        {
            int group;
            UIElement element;
            EditorButton button;
            bool isActive;

            T as(T)()
            {
                return cast(T)this.element;
            }
        }

        // GUI
        StackContainer         _toolList;
        StackContainer         _windowList;
        RectMode               _mode;
        EditorButton[Scancode] _hotkeyMap;
        GuiWindow[WindowType]  _windows;

        // Everything regarding the sprite atlas.
        SpriteAtlas     _atlas;
        Sprite          _atlasSprite; // Atlases don't have functionality to draw their entire texture, so we just make a sprite for it.
        size_t          _spriteCount;
        SpriteRect[]    _spriteRects;
        SpriteRect      _selectedSpriteRect;

        // etc.
        vec2 _lastMousePos;

        void addToolButton(Texture image, string name, string description, Scancode hotkey, RectMode mode)
        {
            this._hotkeyMap[hotkey] = this._toolList.addChild(new EditorButton(image, name, description ~ "\n", 
                                      (Button btn)
                                      {
                                          (cast(EditorButton)btn).isSelected = true;
                                          this._mode = mode;
                                          foreach(h, b; this._hotkeyMap)
                                          {
                                              if(b != btn)
                                                b.isSelected = false;
                                          }
                                          foreach(rect; this._spriteRects)
                                            rect.mode = mode;
                                      }));
        }

        bool isMouseOverGUI(InputManager input)
        {
            foreach(child; super.gui.children)
            {
                if(RectangleF(child.position, child.size).contains(input.mousePosition))
                    return true;
            }

            return false;
        }

        void showWindow(WindowType type)
        {
            if(this._windows[type].isActive)
                return;

            foreach(_, ref window; this._windows)
            {
                if(window.group == this._windows[type].group && window != this._windows[type])
                {
                    if(window.button is null)
                        window.isActive = false;
                    else if(window.button.isSelected)
                        window.button.onClick()(window.button);
                }
            }

            this._windows[type].isActive = true;
            super.gui.addChild(this._windows[type].element);
        }

        void hideWindow(WindowType type)
        {
            if(!this._windows[type].isActive)
                return;

            this._windows[type].isActive = false;
            this._windows[type].element.parent = null;
        }

        void toggleWindow(WindowType type)
        {
            if(this._windows[type].isActive)
                this.hideWindow(type);
            else
                this.showWindow(type);
        }

        void loadAtlas(SpriteAtlas atlas)
        {
            assert(atlas !is null);

            this._atlas                = atlas;
            this._atlasSprite          = new Sprite(atlas.texture);
            this._atlasSprite.position = (vec2(Systems.window.size) / vec2(2)) - (vec2(atlas.texture.size) / vec2(2));
            this._spriteCount          = atlas.bySpriteKeys.walkLength;
            super.camera.center        = (vec2(Systems.window.size) / vec2(2));

            foreach(rect; this._spriteRects)
                super.unregister(rect);
            this._spriteRects.length = 0;

            foreach(kvp; atlas.bySpriteKeyValue)
            {
                import std.conv : to;
                auto rect = new SpriteRect(super.camera,
                                           RectangleF(vec2(kvp.value.position) + vec2(this._atlasSprite.position), vec2(kvp.value.size)), 
                                           SELECTION_RECTANGLE_COLOUR,
                                           this._atlasSprite.bounds,
                                           SpriteMeta(atlas, kvp.key));
                rect.onSelect = &this.onSpriteRectSelected;
                rect.onChange = &this.onSpriteRectChanged;
                rect.mode = this._mode;
                this._spriteRects ~= rect;
                super.register(this._spriteRects.length.to!string, rect);
            }

            this._windows[WindowType.SpriteInfo].as!EditorSpriteInfo.useAtlas(atlas);
        }

        void updateSelectedSprite()
        {
            auto spriteRect = this._selectedSpriteRect;
            this._windows[WindowType.SpriteInfo].as!EditorSpriteInfo.useSprite(spriteRect.metadata.spriteName);

            foreach(rect; this._spriteRects)
                rect.yLevel = 1;

            spriteRect.yLevel = 2;
        }

        void onSpriteRectSelected(SpriteRect rect)
        {
            this._selectedSpriteRect = rect;
            this.updateSelectedSprite();
        }
        
        void onSpriteRectChanged(SpriteRect editRect)
        {
            auto atlas = editRect.metadata.atlas;
            atlas.unregister(editRect.metadata.spriteName);
            RectangleF rect = editRect.shape.area;
            rect.position = rect.position - this._atlasSprite.position;
            atlas.register(editRect.metadata.spriteName, RectangleI(rect));
            this.updateSelectedSprite();
        }

        void onModifySprite(SpriteAtlas atlas, string spriteName)
        {
            import std.algorithm : countUntil;

            assert(atlas == this._atlas);
            this._selectedSpriteRect.shape.area = RectangleF(atlas.getSpriteRect(spriteName));
            this._selectedSpriteRect.shape.position = this._selectedSpriteRect.shape.position + this._atlasSprite.position;
            this.updateSelectedSprite();
        }

        void onUpdateHotkeys(InputManager input)
        {
            foreach(hotkey, button; this._hotkeyMap) 
            {
                if(input.wasKeyTapped(hotkey))
                    button.onClick()(button);
            }

            if(input.wasKeyTapped(Scancode.F5))
            {
                auto picker = this._windowList.getChild!EditorButton("Atlas Picker");
                picker.onClick()(picker);
            }

            if(input.wasKeyTapped(Scancode.F6))
            {
                auto info = this._windowList.getChild!EditorButton("Sprite Info");
                info.onClick()(info);
            }
        }

        void onUpdateInput(Duration deltaTime, InputManager input)
        {
            // Camera movement.
            auto camSpeed = CAMERA_SPEED * deltaTime.asSeconds;
            if(input.isKeyDown(Scancode.LEFT))
                super.camera.move(vec2(-camSpeed, 0));
            if(input.isKeyDown(Scancode.RIGHT))
                super.camera.move(vec2(camSpeed, 0));
            if(input.isKeyDown(Scancode.UP))
                super.camera.move(vec2(0, -camSpeed));
            if(input.isKeyDown(Scancode.DOWN))
                super.camera.move(vec2(0, camSpeed));
        }

        void onUpdateMouse(InputManager input)
        {
            // If the mouse is over any of the GUI, then don't bother trying to process it.
            if(this.isMouseOverGUI(input))
                return;

            if(input.wheelDelta != 0 && input.isShiftDown && this._mode != RectMode.Resize)
                super.camera.scale = super.camera.scale + (vec2(ZOOM_STEP) * vec2(-input.wheelDelta));

            if(input.isMouseButtonDown(MouseButton.Middle))
                super.camera.move(-(vec2(input.mousePosition) - vec2(this._lastMousePos)));

            this._lastMousePos = input.mousePosition;
        }
    }

    public override
    {
        void onSwap(PostOffice office){}        
        void onUnswap(PostOffice office){}

        void onInit()
        {
            this._toolList          = new StackContainer(StackContainer.Direction.Vertical, TOOL_LIST_FILL);
            this._toolList.position = TOOL_LIST_POSITION;
            this._toolList.autoSize = true;
            super.gui.addChild(this._toolList);

            this._windowList          = new StackContainer(StackContainer.Direction.Horizontal, TOOL_LIST_FILL);
            this._windowList.position = WINDOW_LIST_POSITION;
            this._windowList.autoSize = true;
            super.gui.addChild(this._windowList);
            
            this._windowList.addChild("Atlas Picker", new EditorButton(Systems.assets.get!Texture("tex_MouseIcon"),
                        "Sprite Atlas Picker(F5)",
                        "Opens the Atlas list, allowing you to change\n"
                        ~"which atlas is being edited.\n",
                        (Button _)
                        {
                            auto picker = this._windowList.getChild!EditorButton("Atlas Picker");
                            picker.isSelected = !picker.isSelected;
                            this._windows[WindowType.AtlasPicker].as!EditorAtlasPicker.reloadList();
                            this.toggleWindow(WindowType.AtlasPicker);
                        }));
            this._windowList.addChild("Sprite Info", new EditorButton(Systems.assets.get!Texture("tex_MouseIcon"),
                        "Sprite Info Panel(F6)",
                        "Opens the Sprite Info panel, which displays\n"
                        ~"information about the selected sprite.\n",
                        (Button _)
                        {
                            auto info = this._windowList.getChild!EditorButton("Sprite Info");
                            info.isSelected = !info.isSelected;
                            this.toggleWindow(WindowType.SpriteInfo);
                        }));

            this._windows[WindowType.AtlasPicker] = GuiWindow(0, new EditorAtlasPicker(&this.loadAtlas, ATLAS_PICKER_POSITION, ATLAS_PICKER_SIZE), 
                                                              this._windowList.getChild!EditorButton("Atlas Picker"));
            this._windows[WindowType.SpriteInfo]  = GuiWindow(0, new EditorSpriteInfo(ATLAS_PICKER_POSITION, ATLAS_PICKER_SIZE), 
                                                              this._windowList.getChild!EditorButton("Sprite Info"));

            this._windows[WindowType.SpriteInfo].as!EditorSpriteInfo.onModifySprite = &this.onModifySprite;

            this.addToolButton(Systems.assets.get!Texture("tex_MouseIcon"), 
                               "Select(Q)", 
                               "A basic tool used mostly for selecting things.", 
                               Scancode.Q,
                               RectMode.Select);

           this.addToolButton(Systems.assets.get!Texture("tex_MouseIcon"), 
                               "Move(W)", 
                               "A tool used to move frame rectangles.", 
                               Scancode.W,
                               RectMode.Move);

            this.addToolButton(Systems.assets.get!Texture("tex_MouseIcon"), 
                               "Resize(E)", 
                               "A tool used to resize frame rectangles.", 
                               Scancode.E,
                               RectMode.Resize);
        }

        void onUpdate(Duration deltaTime, InputManager input)
        {
            input.listenForText = true;
            this.onUpdateHotkeys(input);
            this.onUpdateInput(deltaTime, input);
            this.onUpdateMouse(input);
            super.updateScene(deltaTime);
            super.updateUI(deltaTime);
        }

        void onRender(Window window)
        {
            window.renderer.camera = super.camera;
            if(this._atlasSprite !is null)
                window.renderer.drawSprite(this._atlasSprite);
            super.renderScene(window);
            super.renderUI(window);
        }
    }
}