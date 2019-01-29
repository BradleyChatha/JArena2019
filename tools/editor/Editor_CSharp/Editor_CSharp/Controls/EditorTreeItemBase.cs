using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Controls;
using Editor_CSharp.Serial;

namespace Editor_CSharp.Controls
{
    public abstract class EditorTreeItemBase : TreeViewItem, IEditorControl
    {
        public List<Object> Properties     { get; private set; }
        public TreeView     PropertiesTree { get; set; }
        public string       ObjectName     { get; protected set; }

        public EditorTreeItemBase()
        {
            this.Properties = new List<Object>();
        }

        public void ShowProperties()
        {
            if(this.PropertiesTree == null)
                return;

            this.PropertiesTree.Items.Clear();
            this.Properties.ForEach(p => this.PropertiesTree.Items.Add(p));
        }

        public ArchiveObject GetObject()
        {
            var obj = new ArchiveObject();
            obj.Name = this.ObjectName;
            foreach (var child in this.Items)
            {
                var editor = child as IEditorControl;
                if (editor == null)
                    continue;

                var toAdd = editor.GetObject();
                if (toAdd != null)
                    obj.AddChild(toAdd);
            }
            foreach (var child in this.Properties)
            {
                var editor = child as IEditorControl;
                if (editor == null)
                    continue;

                var toAdd = editor.GetObject();
                if (toAdd != null)
                    obj.AddChild(toAdd);
            }

            return obj;
        }
    }
}
