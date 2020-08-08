using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Editor_CSharp.Serial;

namespace Editor_CSharp.Controls
{
    public class PropertyTreeItem : EditorTreeItemBase
    {
        private ArchiveObject _obj;

        public PropertyTreeItem(ArchiveObject propObj)
        {
            this._obj       = propObj;
            this.ObjectName = propObj.Name;
            this.Header     = this.ObjectName;
        }

        public override ArchiveObject GetObject()
        {
            return this._obj;
        }
    }
}
