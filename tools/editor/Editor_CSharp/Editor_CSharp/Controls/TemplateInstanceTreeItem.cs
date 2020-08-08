using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Editor_CSharp.Serial;

namespace Editor_CSharp.Controls
{
    public class TemplateInstanceTreeItem : EditorTreeItemBase
    {
        private TemplateInfo       _info;
        private EditorTreeItemBase _editor;

        public TemplateInstanceTreeItem(TemplateInfo template, EditorTreeItemBase controlEditor)
        {
            this.ObjectName = template.rootObj.Name.Split(':').Last();
            this.Header     = this.ObjectName;
            
            foreach(var item in controlEditor.Properties)
                this.Properties.Add(item);

            this._editor = controlEditor;
            this._info   = template;
        }

        public override ArchiveObject GetObject()
        {
            var obj  = this._editor.GetObject();
            obj.Name = this.ObjectName;

            return obj;
        }
    }
}
