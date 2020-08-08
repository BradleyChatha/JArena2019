using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Controls;
using Editor_CSharp.Serial;

namespace Editor_CSharp.Controls
{
    public class BindingTreeItem : EditorTreeItemBase
    {
        public BindingDef Def { get; set; }
        public BindingTreeItem(BindingDef def)
        {
            this.Def = def;
            this.ObjectName = def.targetName;
        }
    }
}
