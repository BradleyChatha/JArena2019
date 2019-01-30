using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using Editor_CSharp.Extern;
using Editor_CSharp.Serial;

namespace Editor_CSharp.Controls
{
    /// <summary>
    /// Interaction logic for ViewEditor.xaml
    /// </summary>
    public partial class ViewEditor : UserControl
    {
        public ViewEditor()
        {
            InitializeComponent();
        }

        public void ChangeView(ArchiveObject view)
        {
            this.treeControls.Items.Clear();
            this.viewName.Text = view.ExpectChild("name").ExpectValueAs<string>(0);
            
            foreach(var child in view.Children)
            {
                if(child.Name == "name")
                    continue;

                if(child.Name.StartsWith("template:"))
                {
                    var item = new TemplateTreeItem(child);
                    item.IsExpanded = true;
                    item.Items.Add(this.GenerateTree(child.Children[0]));
                    item.PropertiesTree = this.treeProperties;

                    this.treeControls.Items.Add(item);
                }
                else
                    this.treeControls.Items.Add(this.GenerateTree(child));
            }
        }

        public ArchiveObject CreateViewObject()
        {
            var root = new ArchiveObject();
            var type = new ArchiveObject("type");
            type.AddValueAs("UI:view");
            root.AddChild(type);

            var obj = new ArchiveObject("UI:view");
            foreach(var child in this.treeControls.Items)
            {
                var editor = child as IEditorControl;
                if(editor == null)
                    continue;

                var toAdd = editor.GetObject();
                if(toAdd != null)
                    obj.AddChild(toAdd);
            }

            var name = new ArchiveObject("name");
            name.AddValueAs(this.viewName.Text);
            obj.AddChild(name);

            root.AddChild(obj);
            return root;
        }

        public void UpdateGameClient()
        {
            Editor.ChangeView(this.CreateViewObject());
        }

        private TreeViewItem GenerateTree(ArchiveObject root)
        {
            var name = root.GetChild("name");
            var def  = Editor.GetDefinitionFor(root.Name);
            var item = new ControlTreeItem(def);
            item.Header = $"{root.Name}({((name == null) ? "NO NAME" : name.ExpectValueAs<string>(0))})";
            item.IsExpanded = true;
            item.PropertiesTree = this.treeProperties;

            var notUsed = root.Children.ToList();
            foreach(var binding in def.bindings)
            {
                EditorTreeItemBase parent;
                ArchiveObject bindTarget;

                if(String.IsNullOrWhiteSpace(binding.targetName) || binding.targetName == "DataBinding")
                {
                    parent = item;
                    bindTarget = root;
                }
                else
                {
                    parent = new BindingTreeItem(binding);
                    parent.IsExpanded = true;
                    parent.Header = binding.targetName;
                    parent.PropertiesTree = null;
                    item.Properties.Add(parent);
                    bindTarget = this.FindAndRemoveByName(notUsed, binding.targetName);
                }

                foreach(var field in binding.fields)
                {
                    Action<Object> addToParent = null;
                    ArchiveObject fieldObj = null;
                    if(parent == item)
                    {
                        fieldObj = this.FindAndRemoveByName(notUsed, field.name);
                        addToParent = o => parent.Properties.Add(o);
                    }
                    else if(bindTarget != null)
                        fieldObj = bindTarget.GetChild(field.name);

                    if(parent != item)
                        addToParent = o => parent.Items.Add(o);

                    // I can't use a hashmap because for more complex types (such as arrays), I need to process their additional info first.
                    if (field.inputType == "bool")
                    {
                        addToParent(new BoolEditor(this, fieldObj, field));
                    }
                    else if(field.inputType == "StaticArray" && field.outputType.StartsWith("Vector"))
                    {
                        addToParent(new VectorEditor(this, fieldObj, field));
                    }
                    else if(field.inputType == "StaticArray" && field.outputType.StartsWith("Rectangle"))
                    {
                        addToParent(new RectangleEditor(this, fieldObj, field));
                    }
                    else if(field.inputType == "DynamicArray" && field.inputSubtype == "char")
                    {
                        addToParent(new StringEditor(this, fieldObj, field));
                    }
                    else if(field.inputType == "Enum")
                    {
                        addToParent(new EnumEditor(this, fieldObj, field));
                    }
                    else if(field.inputType == "int"
                         || field.inputType == "float"
                         || field.inputType == "uint")
                    {
                        addToParent(new NumberEditor(this, fieldObj, field));
                    }
                    else
                    {
                        var fieldItem = new UnhandledTreeItem(fieldObj);
                        fieldItem.Header = field.name;
                        fieldItem.ToolTip = $"Unhandled: InputType = '{field.inputType}'. InputSubType = '{field.inputSubtype}'. InputLength = '{field.inputStaticLength}'.";
                        addToParent(fieldItem);
                    }
                }
            }

            foreach(var child in notUsed)
            {
                if(child.Name.StartsWith("property:") || child.Name.StartsWith("AV_")) // "AV_" is a temporary hack until templates are somewhat used
                    continue; // TODO: Support this
                item.Items.Add(this.GenerateTree(child));
            }

            return item;
        }

        private ArchiveObject FindAndRemoveByName(List<ArchiveObject> list, string name)
        {
            for(int i = 0; i < list.Count; i++)
            {
                if(list[i].Name == name)
                {
                    var obj = list[i];
                    list.RemoveAt(i);
                    return obj;
                }
            }
            
            return null;
        }

        private void treeControls_SelectedItemChanged(object sender, RoutedPropertyChangedEventArgs<object> e)
        {
            var item = this.treeControls.SelectedItem as EditorTreeItemBase;
            if(item != null)
                item.ShowProperties();
        }
    }
}
