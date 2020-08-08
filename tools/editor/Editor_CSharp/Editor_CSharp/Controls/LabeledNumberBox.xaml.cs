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
    /// Interaction logic for LabeledNumberBox.xaml
    /// </summary>
    public partial class LabeledNumberBox : UserControl
    {
        public string NumType { set; get; }

        public bool IsFloatingPoint => NumType == "float" || NumType == "double";
        public bool IsUnsigned      => NumType != null && NumType.StartsWith("u");

        /// <summary>
        /// PURELY FOR EDITOR USE.
        /// </summary>
        public LabeledNumberBox()
        {
            InitializeComponent();
        }

        public LabeledNumberBox(string label, string numType)
        {
            InitializeComponent();

            this.NumType = numType;
            this.label.Content = label;
        }

        public T? GetValue<T>() where T : struct, IComparable
        {
            try
            {
                if(typeof(T) == typeof(float)) return ValidateAndConvert<T>((T)(object)float.MinValue, (T)(object)float.MaxValue, s => (T)(object)Convert.ToSingle(s));
            }
            catch(Exception ex)
            {
                this.SetError(ex.Message);
                return null;
            }

            throw new Exception($"The type {typeof(T)} isn't supported.");
        }

        public void SetError(string message)
        {
            this.input.Background = Brushes.Red;
            this.input.ToolTip = message;
        }

        private T? ValidateAndConvert<T>(T min, T max, Converter<string, T> converter) where T : struct, IComparable
        {
            var value = converter(this.input.Text);
            if(value.CompareTo(min) < 0 || value.CompareTo(max) > 0)
                throw new ArgumentOutOfRangeException($"The value is out of bounds. (Min = {min} | Max = {max})");
            
            return value;
        }

        private void input_PreviewKeyDown(object sender, KeyEventArgs e)
        {
            this.input.ToolTip = "";
            this.input.Background = Brushes.White;
            e.Handled = 
            !(
                e.Key == Key.D0
             || e.Key == Key.D1
             || e.Key == Key.D2
             || e.Key == Key.D3
             || e.Key == Key.D4
             || e.Key == Key.D5
             || e.Key == Key.D6
             || e.Key == Key.D7
             || e.Key == Key.D8
             || e.Key == Key.D9
             || (this.IsFloatingPoint && (e.Key == Key.E || e.Key == Key.OemPeriod))
             || e.Key == Key.Back
             || e.Key == Key.Delete
             || e.Key == Key.Left
             || e.Key == Key.Right
             || (!this.IsUnsigned && e.Key == Key.OemMinus && this.input.CaretIndex == 0)
            );
        }
    }
}
