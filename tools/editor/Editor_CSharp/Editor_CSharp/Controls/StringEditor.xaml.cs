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
    /// Interaction logic for StringEditor.xaml
    /// </summary>
    public partial class StringEditor : UserControl
    {
        public FieldDef Def { set; get; }

        public StringEditor(ArchiveObject obj, FieldDef def)
        {
            InitializeComponent();

            this.Def = def;

            if(obj != null)
                this.input.Text = obj.GetValueAs<string>(0);

            this.label.Content      = def.name;
            this.nullbox.Checked   += (_, __) => this.input.IsEnabled = true;
            this.nullbox.Unchecked += (_, __) => this.input.IsEnabled = false;
            this.nullbox.Visibility = (def.isNullable) ? Visibility.Visible : Visibility.Hidden;
            this.nullbox.IsChecked  = (def.isNullable) ? obj != null : true;
        }
    }
}
