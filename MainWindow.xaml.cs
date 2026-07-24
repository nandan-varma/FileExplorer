using System;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using FileBrowser.ViewModels;

namespace FileBrowser
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        private MainViewModel ViewModel => (MainViewModel)DataContext;

        private async void Window_Loaded(object sender, RoutedEventArgs e)
        {
            ViewModel.ItemFocusRequested += SelectItemByPath;
            await ViewModel.InitializeAsync();
        }

        // --- File list interaction -------------------------------------------

        private static FileSystemItemViewModel GetItemFromEventSource(object source)
        {
            var dep = source as DependencyObject;
            while (dep != null && dep is not ListViewItem)
            {
                dep = VisualTreeHelper.GetParent(dep);
            }
            return (dep as ListViewItem)?.DataContext as FileSystemItemViewModel;
        }

        private void FileListView_MouseDoubleClick(object sender, MouseButtonEventArgs e)
        {
            var item = GetItemFromEventSource(e.OriginalSource);
            if (item != null) Execute(ViewModel.OpenCommand, item);
        }

        private void FileListView_PreviewMouseRightButtonDown(object sender, MouseButtonEventArgs e)
        {
            var item = GetItemFromEventSource(e.OriginalSource);
            if (item == null)
            {
                FileListView.SelectedItems.Clear();
            }
            else if (!FileListView.SelectedItems.Contains(item))
            {
                FileListView.SelectedItem = item;
            }
        }

        private void FileListView_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            ViewModel.UpdateSelection(FileListView.SelectedItems.Cast<FileSystemItemViewModel>().ToList());
        }

        private void SelectItemByPath(string path)
        {
            var match = ViewModel.Items.FirstOrDefault(i => string.Equals(i.FullPath, path, StringComparison.OrdinalIgnoreCase));
            if (match == null) return;
            FileListView.SelectedItem = match;
            FileListView.ScrollIntoView(match);
        }

        private void SortHeader_Click(object sender, MouseButtonEventArgs e)
        {
            if (sender is not TextBlock tb || tb.Tag is not string column) return;
            Execute(ViewModel.SortCommand, column);
        }

        private void AddressBar_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Enter) Execute(ViewModel.NavigateCommand, AddressBar.Text.Trim());
        }

        // --- Keyboard shortcuts ------------------------------------------------
        // Kept centralized in code-behind (rather than XAML InputBindings) so the
        // "don't act while a text box has focus" guard applies uniformly - a
        // KeyBinding declared on the Window would otherwise fire even while the
        // user is typing in the address bar or search box.

        private void Window_PreviewKeyDown(object sender, KeyEventArgs e)
        {
            if (Keyboard.FocusedElement is TextBox) return;

            bool ctrl = Keyboard.Modifiers.HasFlag(ModifierKeys.Control);
            bool alt = Keyboard.Modifiers.HasFlag(ModifierKeys.Alt);
            bool shift = Keyboard.Modifiers.HasFlag(ModifierKeys.Shift);

            switch (e.Key)
            {
                case Key.N when ctrl && shift:
                    Execute(ViewModel.NewFolderCommand);
                    e.Handled = true;
                    break;
                case Key.F5:
                    Execute(ViewModel.RefreshCommand);
                    e.Handled = true;
                    break;
                case Key.Back:
                    Execute(ViewModel.UpCommand);
                    e.Handled = true;
                    break;
                case Key.Left when alt:
                    Execute(ViewModel.BackCommand);
                    e.Handled = true;
                    break;
                case Key.Right when alt:
                    Execute(ViewModel.ForwardCommand);
                    e.Handled = true;
                    break;
                case Key.F2:
                    Execute(ViewModel.RenameCommand);
                    e.Handled = true;
                    break;
                case Key.Delete:
                    Execute(ViewModel.DeleteCommand);
                    e.Handled = true;
                    break;
                case Key.C when ctrl:
                    Execute(ViewModel.CopyCommand);
                    e.Handled = true;
                    break;
                case Key.X when ctrl:
                    Execute(ViewModel.CutCommand);
                    e.Handled = true;
                    break;
                case Key.V when ctrl:
                    Execute(ViewModel.PasteCommand);
                    e.Handled = true;
                    break;
                case Key.A when ctrl:
                    FileListView.SelectAll();
                    e.Handled = true;
                    break;
                case Key.F when ctrl:
                    SearchBox.Focus();
                    SearchBox.SelectAll();
                    e.Handled = true;
                    break;
                case Key.Enter when alt:
                    Execute(ViewModel.PropertiesCommand);
                    e.Handled = true;
                    break;
                case Key.Enter:
                    Execute(ViewModel.OpenCommand, FileListView.SelectedItem);
                    e.Handled = true;
                    break;
            }
        }

        private static void Execute(ICommand command, object parameter = null)
        {
            if (command.CanExecute(parameter)) command.Execute(parameter);
        }
    }
}
