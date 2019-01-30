using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using Editor_CSharp.Serial;

namespace Editor_CSharp.Controls
{
    interface IEditorControl
    {
        ArchiveObject GetObject();
    }
}
