using System.Windows;
using FileBrowser.ViewModels;

namespace FileBrowser.Dialogs
{
    public partial class PropertiesDialog : Window
    {
        public PropertiesDialog(PropertiesDialogViewModel viewModel)
        {
            InitializeComponent();
            DataContext = viewModel;
        }
    }
}
