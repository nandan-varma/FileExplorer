using System.Windows;
using FileBrowser.Services;
using FileBrowser.ViewModels;

namespace FileBrowser
{
    /// <summary>
    /// Composition root: builds the service graph and the main window's view
    /// model by hand. The app is small enough that a DI container would add
    /// more ceremony than it saves - everything here is a plain constructor call.
    /// </summary>
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);

            var mainWindow = new MainWindow();

            IFileSystemService fileSystemService = new FileSystemService();
            IIconProvider iconProvider = new ShellIconProvider();
            IFileOperationsService fileOperationsService = new FileOperationsService();
            IClipboardService clipboardService = new ClipboardService();
            ITerminalLauncher terminalLauncher = new TerminalLauncher();
            IDialogService dialogService = new DialogService(mainWindow);

            mainWindow.DataContext = new MainViewModel(
                fileSystemService,
                fileOperationsService,
                iconProvider,
                clipboardService,
                terminalLauncher,
                dialogService);

            MainWindow = mainWindow;
            mainWindow.Show();
        }
    }
}
