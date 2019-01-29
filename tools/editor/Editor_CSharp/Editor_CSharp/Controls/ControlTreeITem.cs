using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Controls;
using Editor_CSharp.Serial;

namespace Editor_CSharp.Controls
{
    public class ControlTreeItem : EditorTreeItemBase
    {
        public ControlDef Def { get; set; }
        public ControlTreeItem(ControlDef def)
        {
            this.Def = def;
            this.ObjectName = def.name;
        }
    }
}
