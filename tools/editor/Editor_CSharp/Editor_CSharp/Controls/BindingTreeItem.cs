using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Controls;
using Editor_CSharp.Serial;

namespace Editor_CSharp.Controls
{
    public class BindingTreeItem : TreeViewItem, IEditorControl
    {
        public BindingDef Def { get; set; }
        public BindingTreeItem(BindingDef def)
        {
            this.Def = def;
        }

        public ArchiveObject GetObject()
        {
            var obj = new ArchiveObject();
            obj.Name = this.Def.targetName;
            foreach (var child in this.Items)
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
