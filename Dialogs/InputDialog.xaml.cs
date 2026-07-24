using System.Windows;
using System.Windows.Input;
using FileBrowser.ViewModels;

namespace FileBrowser.Dialogs
{
    public partial class InputDialog : Window
    {
        private readonly InputDialogViewModel _viewModel;

        public InputDialog(InputDialogViewModel viewModel)
        {
            InitializeComponent();
            _viewModel = viewModel;
            DataContext = viewModel;

            Loaded += (_, _) =>
            {
                InputBox.Focus();
                InputBox.Select(0, _viewModel.SelectionLength);
            };
        }

        private void InputBox_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Enter) { TryAccept(); e.Handled = true; }
            else if (e.Key == Key.Escape) { DialogResult = false; e.Handled = true; }
        }

        private void OkButton_Click(object sender, RoutedEventArgs e) => TryAccept();

        private void CancelButton_Click(object sender, RoutedEventArgs e) => DialogResult = false;

        private void TryAccept()
        {
            if (_viewModel.TryAccept()) DialogResult = true;
        }
    }
}
