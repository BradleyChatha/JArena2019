using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Controls;
using Editor_CSharp.Serial;

namespace Editor_CSharp.Controls
{
    public class UnhandledTreeItem : TreeViewItem, IEditorControl
    {
        public ArchiveObject Obj { get; set; }
        public UnhandledTreeItem(ArchiveObject obj)
        {
            this.Obj = obj;
        }

        public ArchiveObject GetObject()
        {
            return this.Obj;
        }
    }
}
