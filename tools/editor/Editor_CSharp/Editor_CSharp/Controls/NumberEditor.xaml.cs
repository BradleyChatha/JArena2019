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
using Editor_CSharp.Util;

namespace Editor_CSharp.Controls
{
    /// <summary>
    /// Interaction logic for NumberEditor.xaml
    /// </summary>
    public partial class NumberEditor : UserControl
    {
        public FieldDef Def { set; get; }
        public NumberEditor(ArchiveObject obj, FieldDef def)
        {
            InitializeComponent();

            this.label.Content = def.name;

            if(obj != null)
                this.input.input.Text = NumberHelper.ConvertValue<Object>(obj.Values[0]).ToString();

            this.input.label.Content = null;
            this.nullbox.Checked    += (_, __) => this.input.IsEnabled = true;
            this.nullbox.Unchecked  += (_, __) => this.input.IsEnabled = false;
            this.nullbox.Visibility  = (def.isNullable) ? Visibility.Visible : Visibility.Hidden;
            this.nullbox.IsChecked   = (def.isNullable) ? obj != null : true;
        }
    }
}
