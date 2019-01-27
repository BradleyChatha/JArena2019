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
using Editor_CSharp.Controls;
using Editor_CSharp.Extern;
using Editor_CSharp.Serial;
using Microsoft.WindowsAPICodePack.Dialogs;

namespace Editor_CSharp
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        ViewEditor _editor;

        public MainWindow()
        {
            InitializeComponent();

            Jasterialise.RegisterSerialisers();
            Editor.Init();

            this._editor = new ViewEditor();
            this.content.Content = this._editor;
        }

        private void Window_Closed(object sender, EventArgs e)
        {
            Editor.CloseThreads();
        }

        private void menuOpen_Click(object sender, RoutedEventArgs e)
        {
            var dialog              = new CommonOpenFileDialog();
            dialog.Multiselect      = false;
            dialog.EnsurePathExists = true;
            dialog.EnsureFileExists = true;
            var result = dialog.ShowDialog();

            if(result == CommonFileDialogResult.Cancel || result == CommonFileDialogResult.None || String.IsNullOrEmpty(dialog.FileName))
            {
                MessageBox.Show(
                    "Please select a valid file.",
                    "Tsk tsk",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error
                );
                return;
            }

            var obj = Editor.OpenUIFile(dialog.FileName);
            this._editor.ChangeView(obj);
        }
    }
}
