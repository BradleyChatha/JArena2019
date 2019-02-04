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
    public partial class StringEditor : UserControl, IEditorControl
    {
        public FieldDef Def { set; get; }

        public StringEditor(ViewEditor editor, ArchiveObject obj, FieldDef def)
        {
            InitializeComponent();

            this.Def = def;

            if(obj != null)
                this.input.Text = obj.GetValueAs<string>(0);

            this.label.Content      = def.name;
            this.nullbox.Checked   += (_, __) => this.input.IsEnabled = true;
            this.nullbox.Unchecked += (_, __) => this.input.IsEnabled = false;
            this.nullbox.Checked   += (_, __) => editor.UpdateGameClient();
            this.nullbox.Unchecked += (_, __) => editor.UpdateGameClient();
            this.nullbox.Visibility = (def.isNullable) ? Visibility.Visible : Visibility.Hidden;
            this.nullbox.IsChecked  = (def.isNullable) ? obj != null : true;

            if(def.outputType != "Font")
                this.input.TextChanged += (_, __) => editor.UpdateGameClient();
            else
            {
                this.input.IsEnabled = false;
                this.nullbox.IsEnabled = false;
                this.input.Background = Brushes.Yellow;
                this.label.Content = $"{def.name}(Disabled)";
                this.label.ToolTip = "Fonts are causing a few issues, so currently the editor won't support changing them.";
            }
        }

        public ArchiveObject GetObject()
        {
            if (!this.nullbox.IsChecked)
                return null;

            var obj = new ArchiveObject();
            obj.Name = this.Def.name;
            obj.AddValueAs<string>(this.input.Text);
            return obj;
        }
    }
}
