using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Editor_CSharp.Serial;

namespace Editor_CSharp.Controls
{
    public class TemplateTreeItem : EditorTreeItemBase
    {
        public TemplateTreeItem(ArchiveObject templateRoot)
        {
            this.ObjectName = templateRoot.Name;
            this.Header = this.ObjectName;
        }
    }
}
