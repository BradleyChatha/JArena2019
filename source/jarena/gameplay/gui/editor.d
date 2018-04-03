module jarena.gameplay.gui.editor;

private
{
    import std.traits;
    import std.typecons : Flag;
    import jarena.core, jarena.gameplay, jarena.graphics;

    const PANEL_POSITION        = vec2(1, 50);
    const PANEL_COLOUR          = Colours.almondFrost;
    const INSTRUCTION_Y         = 50;
    const INSTRUCTION_X_PAD     = 5;
    const GENERIC_CHAR_SIZE     = 18;
    const GENERIC_FONT_KEY      = "Calibri";
}

/++
 + A container that can be used to edit any UIElement that it is a parent of.
 +
 + This also includes UIElements that are stored within other containers, that are stored in this container.
 + ++/
final class EditorContainer : FreeFormContainer
{
    import std.stdio : writefln, writeln;
       
    private
    {
        struct ExtensionInfo
        {
            Extension info;
            EditorPanelExtension panelExt;
        }

        struct ContainerInfo
        {
            size_t selectedIndex;
            Container object;
        }

        ExtensionInfo[] _extensions;
        ExtensionInfo[] _usedExtensions; // Which ones are currently in use.
        ContainerInfo[] _containerStack; // A stack used to keep track of which containers we're inside of
        StackContainer  _extensionPanel;
        StackContainer  _instructionPanel;
        InputManager    _input;
        bool            _showPanel = true;

        // Updates the list of extensions being used.
        void updateUsedExtensions()
        {
            import std.algorithm : filter;

            char[] instructions = cast(char[])(
                "Controls:\n"~
                "Left/Right Arrow = Select element\n"~
                "Tab = Toggle Editor Panels\n"~
                "Down Arrow = Stop Inspecting children\n"
            );
            if(cast(Container)this.selectedElement !is null)
                instructions ~= "Up Arrow = Inspect children\n";
            
            this._usedExtensions.length = 0;
            foreach(e; this._extensions.filter!(e => e.info.isExtensionObject(this.selectedElement)))
            {
                this._usedExtensions ~= e;
                instructions ~= e.panelExt._instructions;
            }

            auto label = this._instructionPanel.getChild!SimpleLabel("labelText");
            label.updateTextASCII(instructions);

            // Right-align the instruction panel.
            this._instructionPanel.position = vec2(cast(float)InitInfo.windowSize.x - (label.size.x + INSTRUCTION_X_PAD), INSTRUCTION_Y);
        }

        @property
        UI selectedElement(UI : UIElement = UIElement)()
        {
            return this.selectedContainer.getChild!UI(this.selectedIndex);
        }

        @property
        Container selectedContainer()
        {
            return this._containerStack[$-1].object;
        }

        @property
        ref size_t selectedIndex()
        {
            return this._containerStack[$-1].selectedIndex;
        }

        void popContainers()
        {
            // [0] is the default contaienr, so we don't want to pop it.
            if(this._containerStack.length > 1)
                this._containerStack.length -= 1;

            this.updateUsedExtensions();
        }
    }

    public
    {
        /// Determines whether the editor is enabled or not.
        /// If `false`, then it simply acts like a normal `FreeFormContainer`.
        bool canEdit = false;

        /++
         + Sets up the editor.
         +
         + Params:
         +  office = A `PostOffice` which the the editor will listen for key presses on.
         +  cache  = A `MultiCache` that caches certain data the editor may need.
         + ++/
        this(MCache)(PostOffice office, MCache cache)
        if(canCache!(MCache, Font))
        {
            assert(office !is null);

            // Setup UI
            this._extensionPanel = new StackContainer(PANEL_POSITION, StackContainer.Direction.Vertical, PANEL_COLOUR);
            this._instructionPanel = new StackContainer(vec2(0, INSTRUCTION_Y), StackContainer.Direction.Vertical, PANEL_COLOUR);

            auto label = this._instructionPanel.addChild(new SimpleLabel(
                new Text(cache.get!Font(GENERIC_FONT_KEY), ""d, vec2(0), GENERIC_CHAR_SIZE, Colour.white)
            ));
            label.name = "labelText";
            label.updateTextASCII("Press left or right arrow keys");

            // Setup events
            office.subscribe(Window.Event.KeyDown, (_, mail)
            {
                if(!this.canEdit) 
                    return;

                auto key = (cast(ValueMail!SDL_KeyboardEvent)mail).value;
                foreach(ext; this._usedExtensions)
                    ext.panelExt.handleKeyPress(this._input, cast(Scancode)key.keysym.scancode);
            });

            // Register pre-defined extensions
            this.registerExtension(new GenericElementExtension(cache.getCache!Font));
            this.registerExtension(new GenericContainerExtension(cache.getCache!Font));

            // Other
            this._containerStack ~= ContainerInfo(0, this);
        }

        /++
         + Registers an extension with the editor.
         +
         + An extension is used whenever the selected item is compatible with whatever type
         + was given using the `ExtensionFor` UDA.
         +
         + Params:
         +  ext = The extension to register.
         + ++/
        void registerExtension(E : EditorPanelExtension)(E ext)
        {
            import std.experimental.logger;
            
            assert(ext !is null);
            static assert(hasUDA!(E, Extension), E.stringof ~ " doesn't have an @ExtensionFor attached to it.");

            tracef("Registering Editor Extension '%s'", E.stringof);
            
            enum uda = getUDAs!(E, Extension)[0];
            this._extensions ~= ExtensionInfo(uda, ext);
        }
    }

    override
    {
        public void onUpdate(InputManager input, Duration deltaTime)
        {
            this._input = input;
            
            if(!this.canEdit)
                super.onUpdate(input, deltaTime);

            // In case the container has lost children since we last indexed into it.
            while(this.selectedIndex >= this.selectedContainer.children.length)
            {
                if(this.selectedContainer.children.length == 0)
                {
                    if(this.selectedContainer == this)
                        break;
                    else
                        this.popContainers();
                }
                else
                    this.selectedIndex = (this.selectedContainer.children.length == 0) ? 0 : this.selectedContainer.children.length - 1;
            }

            auto childCount = this.selectedContainer.children.length;
            
            if(childCount == 0 || !this.canEdit)
                return;

            if(input.wasKeyTapped(Scancode.UP))
            {
                auto container = cast(Container)this.selectedElement;
                if(container !is null && container.children.length > 0)
                {
                    this._containerStack ~= ContainerInfo(0, container);
                    this.updateUsedExtensions();
                }
            }

            if(input.wasKeyTapped(Scancode.DOWN))
                this.popContainers();

            if(input.wasKeyTapped(Scancode.RIGHT))
            {
                this.selectedIndex += 1;
                if(this.selectedIndex >= childCount)
                    this.selectedIndex = 0;

                this.updateUsedExtensions();
            }

            if(input.wasKeyTapped(Scancode.LEFT))
            {
                if(this.selectedIndex == 0)
                    this.selectedIndex = childCount - 1;
                else
                    this.selectedIndex -= 1;

                this.updateUsedExtensions();
            }

            if(input.wasKeyTapped(Scancode.TAB))
                this._showPanel = !this._showPanel;

            this._extensionPanel.clear();
            foreach(ext; this._usedExtensions)
                ext.panelExt.onUpdate(this._extensionPanel, this.selectedElement);
        }

        public void onRender(Window window)
        {
            super.onRender(window);
            
            if(this.selectedContainer.children.length > 0 && this.canEdit)
            {
                auto selected = this.selectedElement;
                window.renderer.drawRect(selected.position, selected.size, Colour(240, 230, 140, 128));
            }

            if(this.canEdit && this._showPanel)
            {
                this._extensionPanel.onRender(window);
                this._instructionPanel.onRender(window);
            }
        }
    }
}

/++
 + A UDA that is attached to an `EditorPanelExtension` (pro note - use @`ExtensionFor`)
 + to inform the editor which type of `UIElement` it handles.
 +
 + Notes:
 +  A single `UIElement` may be compatible with many different extensions.
 +
 +  For example, imagine the class `SimpleButton`. It inherits from `UIElement`,
 +  `Control`, and `Button`. This means for example, that an extension that works for
 +  `UIElement` will be used for `SimpleButton` (and any UIElement in general), and
 +  another extension that works solely on a `SimpleButton` will also be used.
 + ++/
struct Extension
{
    private bool function(UIElement) isExtensionObject;

    /++
     + Used to setup the (private) data of an `Extension`.
     +
     + Params:
     +  T = The type that inherits from `UIElement` (in some way) that the extension has been written for.
     + ++/   
    static Extension For(T : UIElement)()
    {
        return Extension((UIElement e) => (cast(T)e) !is null);
    }
}

/// A UDA-friendly way to call `Extension.For`, please use this as directly using Extension.For doesn't work.
enum ExtensionFor(T) = Extension.For!T;

abstract class EditorPanelExtension
{
    private
    {
        alias KeybindFunc = void delegate(InputManager);
        struct Keybind
        {
            string      keyName;
            Scancode    keyCode;
            string      description;
            KeybindFunc func;
        }

        Keybind[] _keybinds;
        string    _instructions;

        void handleKeyPress(InputManager input, Scancode key)
        {
            foreach(bind; this._keybinds)
            {
                if(bind.keyCode == key)
                    bind.func(input);
            }
        }
    }
    
    protected final
    {
        /++
         + Allows extensions to register a keybind.
         +
         + Params:
         +  sfKey       = Which sfKey (`sfKeyA`, `sfKeyF12`, etc.) to bind to.
         +  description = The description of what this keybind does.
         +  func        = The function to call when the key is pressed.
         + ++/
        @safe
        void registerKeybind(alias sfKey)(string description, KeybindFunc func)
        {
            import std.range : split;

            assert(func !is null);
            auto binding = Keybind(
                fullyQualifiedName!sfKey.split(".")[$-1],
                sfKey,
                description,
                func
            );
            this._keybinds ~= binding;

            import std.format;
            this._instructions ~= format("%s = %s", binding.keyName, binding.description);
        }
    }
    
    protected abstract
    {
        /++
         + Called whenever a UIElement that is compatible with this extension is selected,
         + and that the editor is requesting an update to it's on-screen information about it.
         +
         + Notes:
         +  Extensions are expected to use this event to add controls onto the `panel`,
         +  which should display the `selected` item's current data.
         +
         +  Extensions should also use this function to update their internal state to reflect
         +  the `selected` item's data.
         +
         + Params:
         +  panel    = The editor's panel.
         +  selected = The compatible UIElement that was selected.
         + ++/
        void onUpdate(StackContainer panel, UIElement selected);
    }
}

@ExtensionFor!UIElement
private final class GenericElementExtension : EditorPanelExtension
{
    import std.format;
    private
    {
        UIElement _element;
        SimpleLabel _labelPosition;
        SimpleLabel _labelName;
        SimpleLabel _labelSize;
        SimpleLabel _labelColour;
    }

    public
    {
        this(Cache!Font fonts)
        {
            void makeLabel(ref SimpleLabel label)
            {
                label = new SimpleLabel(new Text(fonts.get(GENERIC_FONT_KEY), ""d, vec2(0), GENERIC_CHAR_SIZE, Colour.white));
            }
            
            super.registerKeybind!(Scancode.E)("Moves the selected item to the mouse",(input){
                this._element.position = input.mousePosition - (this._element.size / 2);
                this._labelPosition.updateTextASCII(format("Position: %s", this._element.position));
            });

            makeLabel(this._labelPosition);
            makeLabel(this._labelName);
            makeLabel(this._labelSize);
            makeLabel(this._labelColour);
        }
    }
    
    protected override
    {
        void onUpdate(StackContainer panel, UIElement selected)
        {
            this._element = selected;

            this._labelPosition.updateTextASCII(format("Position: %s", this._element.position));
            this._labelName.updateTextASCII(format("Name: '%s'", this._element.name ? this._element.name : "[NO NAME]"));
            this._labelSize.updateTextASCII(format("Size: %s", this._element.size));
            this._labelColour.updateTextASCII(format("Colour: %s", this._element.colour.toCssString));

            panel.addChild(this._labelName);
            panel.addChild(this._labelPosition);
            panel.addChild(this._labelSize);
            panel.addChild(this._labelColour);
        }
    }
}

@ExtensionFor!Container
private final class GenericContainerExtension : EditorPanelExtension
{
    import std.format;
    private
    {
        Container   _element;
        SimpleLabel _labelChildCount;
    }

    public
    {
        this(Cache!Font fonts)
        {
            void makeLabel(ref SimpleLabel label)
            {
                label = new SimpleLabel(new Text(fonts.get(GENERIC_FONT_KEY), ""d, vec2(0), GENERIC_CHAR_SIZE, Colour.white));
            }

            makeLabel(this._labelChildCount);
        }
    }
    
    protected override
    {
        void onUpdate(StackContainer panel, UIElement selected)
        {
            this._element = cast(Container)selected;
            assert(this._element !is null);
            
            this._labelChildCount.updateTextASCII(format("ChildCount: %s", this._element.children.length));

            panel.addChild(this._labelChildCount);
        }
    }
}
