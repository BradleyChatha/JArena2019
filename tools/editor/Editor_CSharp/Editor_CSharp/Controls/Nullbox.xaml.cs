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

namespace Editor_CSharp.Controls
{
    /// <summary>
    /// Interaction logic for Nullbox.xaml
    /// </summary>
    public partial class Nullbox : UserControl
    {
        public RoutedEventHandler Checked;
        public RoutedEventHandler Unchecked;

        public Nullbox()
        {
            InitializeComponent();

            this.nullbox.Checked   += (_, __) => { this.Checked?.Invoke(_, __); };
            this.nullbox.Unchecked += (_, __) => { this.Unchecked?.Invoke(_, __); };
        }

        public bool IsChecked
        {
            get { return this.nullbox.IsChecked ?? false; }
            set
            {
                this.nullbox.IsChecked = value;

                if(value)
                    this.Checked?.Invoke(this, null);
                else
                    this.Unchecked?.Invoke(this, null);
            }
        }
    }
}
