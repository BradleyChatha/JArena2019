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
    /// Interaction logic for RectangleEditor.xaml
    /// </summary>
    public partial class RectangleEditor : UserControl, IEditorControl
    {
        public FieldDef Def { private set; get; }

        public RectangleEditor(ArchiveObject obj, FieldDef def)
        {
            InitializeComponent();
            this.label.Content = def.name;
            this.Def = def;

            this.x.NumType = def.inputSubtype;
            this.y.NumType = def.inputSubtype;
            this.w.NumType = def.inputSubtype;
            this.h.NumType = def.inputSubtype;

            this.x.label.Content = "X:";
            this.y.label.Content = "Y:";
            this.w.label.Content = "W:";
            this.h.label.Content = "H:";

            var Inputs = new List<UserControl>()
            {
                w, h, x, y
            };
            
            if(obj != null)
            {
                this.x.input.Text = NumberHelper.ConvertValue<Object>(obj.Values[0]).ToString();
                this.y.input.Text = NumberHelper.ConvertValue<Object>(obj.Values[1]).ToString();
                this.w.input.Text = NumberHelper.ConvertValue<Object>(obj.Values[2]).ToString();
                this.h.input.Text = NumberHelper.ConvertValue<Object>(obj.Values[3]).ToString();
            }
            this.nullbox.Checked   += (_, __) => Inputs.ForEach(i => i.IsEnabled = true);
            this.nullbox.Unchecked += (_, __) => Inputs.ForEach(i => i.IsEnabled = false);
            this.nullbox.Visibility = (def.isNullable) ? Visibility.Visible : Visibility.Hidden;
            this.nullbox.IsChecked  = (def.isNullable) ? obj != null : true;
        }

        public ArchiveObject GetObject()
        {
            if(!this.nullbox.IsChecked)
                return null;

            var obj = new ArchiveObject();
            obj.Name = this.Def.name;
            
            (new List<LabeledNumberBox>{ x, y, w, h }).ForEach(b => obj.AddValue(NumberHelper.MakeValue(b.input.Text, this.Def.inputSubtype)));

            return obj;
        }
    }
}
