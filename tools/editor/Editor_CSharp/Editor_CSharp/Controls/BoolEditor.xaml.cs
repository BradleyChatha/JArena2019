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
using Editor_CSharp.Serial;

namespace Editor_CSharp.Controls
{
    /// <summary>
    /// Interaction logic for BoolEditor.xaml
    /// </summary>
    public partial class BoolEditor : UserControl, IEditorControl
    {
        public FieldDef Def { set; get; }
        public BoolEditor(ViewEditor editor, ArchiveObject value, FieldDef def)
        {
            InitializeComponent();

            this.nullbox.Checked   += (_, __) => this.checkbox.IsEnabled = true;
            this.nullbox.Unchecked += (_, __) => this.checkbox.IsEnabled = false;
            this.nullbox.IsChecked = (def.isNullable) ? value != null
                                                      : true;

            if (value != null)
            {
                this.checkbox.IsChecked = value.ExpectValueAs<bool>(0);
            }
            this.nullbox.Visibility = (def.isNullable) ? Visibility.Visible : Visibility.Hidden;
            this.lblName.Content = def.name;
            this.Def = def;

            this.checkbox.Checked   += (_, __) => editor.UpdateGameClient();
            this.checkbox.Unchecked += (_, __) => editor.UpdateGameClient();
        }

        public ArchiveObject GetObject()
        {
            if(!this.nullbox.IsChecked)
                return null;

            var obj  = new ArchiveObject();
            obj.Name = this.Def.name;
            obj.AddValueAs<bool>(this.checkbox.IsChecked ?? false);
            return obj;
        }
    }
}
