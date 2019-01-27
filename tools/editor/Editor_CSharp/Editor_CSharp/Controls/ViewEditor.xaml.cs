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
            this.viewName.Text = view.ExpectChild("name").ExpectValueAs<string>(0);
            
            foreach(var child in view.Children)
            {
                if(child.Name == "name" || child.Name.StartsWith("template:"))
                    continue;

                this.tree.Items.Add(this.GenerateTree(child));
            }
        }

        private TreeViewItem GenerateTree(ArchiveObject root)
        {
            var name = root.GetChild("name");
            var def  = Editor.GetDefinitionFor(root.Name);
            var item = new TreeViewItem();
            item.Header = $"{root.Name}({((name == null) ? "NO NAME" : name.ExpectValueAs<string>(0))})";
            item.IsExpanded = true;

            var notUsed = root.Children.ToList();
            foreach(var binding in def.bindings)
            {
                TreeViewItem parent;
                ArchiveObject bindTarget;

                if(String.IsNullOrWhiteSpace(binding.targetName) || binding.targetName == "DataBinding")
                {
                    parent = item;
                    bindTarget = root;
                }
                else
                {
                    parent = new TreeViewItem();
                    parent.IsExpanded = true;
                    parent.Header = binding.targetName;
                    item.Items.Add(parent);
                    bindTarget = this.FindAndRemoveByName(notUsed, binding.targetName);
                }

                foreach(var field in binding.fields)
                {
                    ArchiveObject fieldObj = null;
                    if(parent == item)
                        fieldObj = this.FindAndRemoveByName(notUsed, field.name);
                    else if(bindTarget != null)
                        fieldObj = bindTarget.GetChild(field.name);

                    // I can't use a hashmap because for more complex types (such as arrays), I need to process their additional info first.
                    if (field.inputType == "bool")
                    {
                        parent.Items.Add(new BoolEditor(fieldObj, field));
                    }
                    else if(field.inputType == "StaticArray" && field.outputType.StartsWith("Vector"))
                    {
                        parent.Items.Add(new VectorEditor(fieldObj, field));
                    }
                    else if(field.inputType == "StaticArray" && field.outputType.StartsWith("Rectangle"))
                    {
                        parent.Items.Add(new RectangleEditor(fieldObj, field));
                    }
                    else if(field.inputType == "DynamicArray" && field.inputSubtype == "char")
                    {
                        parent.Items.Add(new StringEditor(fieldObj, field));
                    }
                    else if(field.inputType == "Enum")
                    {
                        parent.Items.Add(new EnumEditor(fieldObj, field));
                    }
                    else if(field.inputType == "int"
                         || field.inputType == "float"
                         || field.inputType == "uint")
                    {
                        parent.Items.Add(new NumberEditor(fieldObj, field));
                    }
                    else
                    {
                        var fieldItem = new Label();
                        fieldItem.Content = field.name;
                        parent.Items.Add(fieldItem);
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
    }
}
