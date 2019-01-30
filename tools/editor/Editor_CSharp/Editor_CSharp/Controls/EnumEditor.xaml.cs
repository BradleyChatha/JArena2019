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
    /// Interaction logic for EnumEditor.xaml
    /// </summary>
    public partial class EnumEditor : UserControl, IEditorControl
    {
        public FieldDef Def { get; set; }
        public EnumEditor(ViewEditor editor, ArchiveObject obj, FieldDef def)
        {
            InitializeComponent();

            this.Def = def;
            this.label.Content = def.name;

            def.enumOptions.ForEach(e => this.list.Items.Add(e));

            if(obj != null)
                this.list.SelectedIndex = this.list.Items.IndexOf(obj.GetValueAs<string>(0));
            else
                this.list.SelectedIndex = 0;

            this.nullbox.Checked   += (_, __) => this.list.IsEnabled = true;
            this.nullbox.Unchecked += (_, __) => this.list.IsEnabled = false;
            this.nullbox.Visibility = (def.isNullable) ? Visibility.Visible : Visibility.Hidden;
            this.nullbox.IsChecked  = (def.isNullable) ? obj != null : true;

            this.list.SelectionChanged += (_, __) => editor.UpdateGameClient();
        }

        public ArchiveObject GetObject()
        {
            if(!this.nullbox.IsChecked)
                return null;

            var obj = new ArchiveObject();
            obj.Name = this.Def.name;
            obj.AddValueAs<string>((string)this.list.SelectedItem);
            return obj;
        }
    }
}
