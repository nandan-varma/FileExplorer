using System.Windows;
using FileBrowser.Dialogs;
using FileBrowser.ViewModels;

namespace FileBrowser.Services
{
    public sealed class DialogService : IDialogService
    {
        private readonly Window _owner;

        public DialogService(Window owner)
        {
            _owner = owner;
        }

        public void ShowWarning(string message, string title) =>
            MessageBox.Show(_owner, message, title, MessageBoxButton.OK, MessageBoxImage.Warning);

        public bool ConfirmDelete(string message) =>
            MessageBox.Show(_owner, message, "Delete", MessageBoxButton.YesNo, MessageBoxImage.Question) == MessageBoxResult.Yes;

        public string PromptText(string title, string prompt, string defaultValue, bool selectBaseNameOnly)
        {
            var viewModel = new InputDialogViewModel(title, prompt, defaultValue, selectBaseNameOnly);
            var dialog = new InputDialog(viewModel) { Owner = _owner };
            return dialog.ShowDialog() == true ? viewModel.Text : null;
        }

        public void ShowProperties(FileSystemItemViewModel item)
        {
            var viewModel = new PropertiesDialogViewModel(item);
            new PropertiesDialog(viewModel) { Owner = _owner }.ShowDialog();
        }
    }
}
