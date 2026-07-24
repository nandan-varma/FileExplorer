using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Input;
using FileBrowser.Models;
using FileBrowser.Mvvm;
using FileBrowser.Services;

namespace FileBrowser.ViewModels
{
    /// <summary>
    /// Application state and behavior for the main window: navigation history,
    /// the current directory listing, the folder tree, and every file
    /// operation. The view binds to this and never touches the file system,
    /// clipboard, or a process directly.
    /// </summary>
    public sealed class MainViewModel : ObservableObject
    {
        private readonly IFileSystemService _fileSystemService;
        private readonly IFileOperationsService _fileOperationsService;
        private readonly IIconProvider _iconProvider;
        private readonly IClipboardService _clipboardService;
        private readonly ITerminalLauncher _terminalLauncher;
        private readonly IDialogService _dialogService;

        private readonly List<string> _history = new();
        private int _historyIndex = -1;
        private CancellationTokenSource _navigationCts;
        private bool _isSyncingTreeSelection;

        private List<FileSystemItemViewModel> _allItems = new();
        private string _sortColumn = "Name";
        private bool _sortAscending = true;

        private readonly AsyncRelayCommand<string> _navigateCommand;
        private readonly AsyncRelayCommand _backCommand;
        private readonly AsyncRelayCommand _forwardCommand;
        private readonly AsyncRelayCommand _upCommand;
        private readonly AsyncRelayCommand _refreshCommand;
        private readonly AsyncRelayCommand _newFolderCommand;
        private readonly AsyncRelayCommand _newFileCommand;
        private readonly RelayCommand _cutCommand;
        private readonly RelayCommand _copyCommand;
        private readonly AsyncRelayCommand _pasteCommand;
        private readonly AsyncRelayCommand _renameCommand;
        private readonly AsyncRelayCommand _deleteCommand;
        private readonly RelayCommand _propertiesCommand;
        private readonly AsyncRelayCommand<FileSystemItemViewModel> _openCommand;
        private readonly RelayCommand _openTerminalCommand;
        private readonly RelayCommand<string> _sortCommand;

        public MainViewModel(
            IFileSystemService fileSystemService,
            IFileOperationsService fileOperationsService,
            IIconProvider iconProvider,
            IClipboardService clipboardService,
            ITerminalLauncher terminalLauncher,
            IDialogService dialogService)
        {
            _fileSystemService = fileSystemService;
            _fileOperationsService = fileOperationsService;
            _iconProvider = iconProvider;
            _clipboardService = clipboardService;
            _terminalLauncher = terminalLauncher;
            _dialogService = dialogService;

            _navigateCommand = new AsyncRelayCommand<string>(path => NavigateAsync(path));
            _backCommand = new AsyncRelayCommand(BackAsync, () => _historyIndex > 0);
            _forwardCommand = new AsyncRelayCommand(ForwardAsync, () => _historyIndex < _history.Count - 1);
            _upCommand = new AsyncRelayCommand(UpAsync, () => TryGetParent(CurrentPath) != null);
            _refreshCommand = new AsyncRelayCommand(RefreshAsync);
            _newFolderCommand = new AsyncRelayCommand(NewFolderAsync);
            _newFileCommand = new AsyncRelayCommand(NewFileAsync);
            _cutCommand = new RelayCommand(Cut, () => SelectedItems.Count > 0);
            _copyCommand = new RelayCommand(Copy, () => SelectedItems.Count > 0);
            _pasteCommand = new AsyncRelayCommand(PasteAsync);
            _renameCommand = new AsyncRelayCommand(RenameAsync, () => SelectedItems.Count == 1);
            _deleteCommand = new AsyncRelayCommand(DeleteAsync, () => SelectedItems.Count > 0);
            _propertiesCommand = new RelayCommand(ShowProperties, () => SelectedItems.Count == 1);
            _openCommand = new AsyncRelayCommand<FileSystemItemViewModel>(OpenAsync);
            _openTerminalCommand = new RelayCommand(OpenTerminal);
            _sortCommand = new RelayCommand<string>(Sort);

            UpdateHeaderText();
            InitializeTreeRoots();
        }

        // --- Bindable state ----------------------------------------------------

        private string _currentPath = string.Empty;
        public string CurrentPath { get => _currentPath; private set => SetProperty(ref _currentPath, value); }

        private string _addressText = string.Empty;
        public string AddressText { get => _addressText; set => SetProperty(ref _addressText, value); }

        private string _searchText = string.Empty;
        public string SearchText
        {
            get => _searchText;
            set
            {
                if (SetProperty(ref _searchText, value)) ApplyFilterAndSort();
            }
        }

        private bool _isBusy;
        public bool IsBusy { get => _isBusy; private set => SetProperty(ref _isBusy, value); }

        private string _statusText = string.Empty;
        public string StatusText { get => _statusText; private set => SetProperty(ref _statusText, value); }

        private string _nameHeaderText;
        public string NameHeaderText { get => _nameHeaderText; private set => SetProperty(ref _nameHeaderText, value); }

        private string _sizeHeaderText;
        public string SizeHeaderText { get => _sizeHeaderText; private set => SetProperty(ref _sizeHeaderText, value); }

        private string _typeHeaderText;
        public string TypeHeaderText { get => _typeHeaderText; private set => SetProperty(ref _typeHeaderText, value); }

        private string _modifiedHeaderText;
        public string ModifiedHeaderText { get => _modifiedHeaderText; private set => SetProperty(ref _modifiedHeaderText, value); }

        public ObservableCollection<FileSystemItemViewModel> Items { get; } = new();
        public ObservableCollection<FolderTreeItemViewModel> RootFolders { get; } = new();

        public IReadOnlyList<FileSystemItemViewModel> SelectedItems { get; private set; } = Array.Empty<FileSystemItemViewModel>();
        public FileSystemItemViewModel PrimarySelectedItem { get; private set; }

        /// <summary>Raised with the path of a newly created or renamed item so the view can select and scroll to it.</summary>
        public event Action<string> ItemFocusRequested;

        // --- Commands ------------------------------------------------------------

        public ICommand NavigateCommand => _navigateCommand;
        public ICommand BackCommand => _backCommand;
        public ICommand ForwardCommand => _forwardCommand;
        public ICommand UpCommand => _upCommand;
        public ICommand RefreshCommand => _refreshCommand;
        public ICommand NewFolderCommand => _newFolderCommand;
        public ICommand NewFileCommand => _newFileCommand;
        public ICommand CutCommand => _cutCommand;
        public ICommand CopyCommand => _copyCommand;
        public ICommand PasteCommand => _pasteCommand;
        public ICommand RenameCommand => _renameCommand;
        public ICommand DeleteCommand => _deleteCommand;
        public ICommand PropertiesCommand => _propertiesCommand;
        public ICommand OpenCommand => _openCommand;
        public ICommand OpenTerminalCommand => _openTerminalCommand;
        public ICommand SortCommand => _sortCommand;

        // --- Startup -------------------------------------------------------------

        public Task InitializeAsync() => NavigateAsync(_fileSystemService.GetDefaultStartPath());

        // --- Navigation ------------------------------------------------------------

        public async Task NavigateAsync(string rawPath, bool addToHistory = true)
        {
            string path = NormalizePath(rawPath);

            if (!_fileSystemService.DirectoryExists(path))
            {
                _dialogService.ShowWarning($"\"{rawPath}\" could not be found.", "Navigate");
                AddressText = CurrentPath;
                return;
            }

            CurrentPath = path;
            AddressText = path;
            SearchText = string.Empty;

            await LoadDirectoryAsync(path);

            if (addToHistory) PushHistory(path);
            UpdateNavigationState();
            _ = SyncTreeSelectionAsync(path);
        }

        public Task RefreshAsync() => LoadDirectoryAsync(CurrentPath);

        private Task BackAsync()
        {
            if (_historyIndex <= 0) return Task.CompletedTask;
            _historyIndex--;
            return NavigateAsync(_history[_historyIndex], addToHistory: false);
        }

        private Task ForwardAsync()
        {
            if (_historyIndex >= _history.Count - 1) return Task.CompletedTask;
            _historyIndex++;
            return NavigateAsync(_history[_historyIndex], addToHistory: false);
        }

        private Task UpAsync()
        {
            var parent = TryGetParent(CurrentPath);
            return parent != null ? NavigateAsync(parent) : Task.CompletedTask;
        }

        private static string NormalizePath(string rawPath)
        {
            string path = (rawPath ?? string.Empty).TrimEnd();
            if (path.Length == 3 && path[1] == ':') path = path.ToUpperInvariant();
            return path;
        }

        private static string TryGetParent(string path)
        {
            try { return Directory.GetParent(path)?.FullName; }
            catch { return null; }
        }

        private void PushHistory(string path)
        {
            if (_historyIndex < _history.Count - 1)
            {
                _history.RemoveRange(_historyIndex + 1, _history.Count - _historyIndex - 1);
            }
            _history.Add(path);
            _historyIndex = _history.Count - 1;
        }

        private void UpdateNavigationState()
        {
            _backCommand.RaiseCanExecuteChanged();
            _forwardCommand.RaiseCanExecuteChanged();
            _upCommand.RaiseCanExecuteChanged();
        }

        // Cancels a slower, in-flight load when the user navigates again before
        // it finishes, so a stale directory's contents can never clobber a
        // newer one that was requested after it.
        private async Task LoadDirectoryAsync(string path)
        {
            _navigationCts?.Cancel();
            var cts = new CancellationTokenSource();
            _navigationCts = cts;

            IsBusy = true;
            try
            {
                var entries = await _fileSystemService.EnumerateAsync(path, cts.Token);
                cts.Token.ThrowIfCancellationRequested();
                _allItems = await BuildItemViewModelsAsync(entries, cts.Token);
                if (!cts.Token.IsCancellationRequested) ApplyFilterAndSort();
            }
            catch (OperationCanceledException)
            {
                // Superseded by a newer navigation.
            }
            catch (FileSystemAccessException ex)
            {
                _dialogService.ShowWarning(ex.Message, "Navigate");
            }
            finally
            {
                if (_navigationCts == cts) IsBusy = false;
            }
        }

        private Task<List<FileSystemItemViewModel>> BuildItemViewModelsAsync(IReadOnlyList<FileSystemEntry> entries, CancellationToken cancellationToken)
        {
            return Task.Run(() =>
            {
                var list = new List<FileSystemItemViewModel>(entries.Count);
                foreach (var entry in entries)
                {
                    cancellationToken.ThrowIfCancellationRequested();
                    var icon = _iconProvider.GetIcon(entry.FullPath, entry.IsDirectory);
                    var typeDescription = _iconProvider.GetTypeDescription(entry.FullPath, entry.IsDirectory);
                    list.Add(new FileSystemItemViewModel(entry, icon, typeDescription));
                }
                return list;
            }, cancellationToken);
        }

        // --- Filtering, sorting, status --------------------------------------------

        private void ApplyFilterAndSort()
        {
            IEnumerable<FileSystemItemViewModel> query = _allItems;

            string filter = SearchText?.Trim();
            if (!string.IsNullOrEmpty(filter))
            {
                query = query.Where(i => i.Name.Contains(filter, StringComparison.OrdinalIgnoreCase));
            }

            Func<FileSystemItemViewModel, object> keySelector = _sortColumn switch
            {
                "Size" => i => i.Size,
                "Type" => i => i.TypeDescription,
                "Modified" => i => i.Modified,
                _ => i => i.Name
            };

            var ordered = query.OrderBy(i => !i.IsDirectory); // folders first
            ordered = _sortAscending ? ordered.ThenBy(keySelector) : ordered.ThenByDescending(keySelector);

            Items.Clear();
            foreach (var item in ordered) Items.Add(item);

            UpdateStatusText();
        }

        private void Sort(string column)
        {
            if (_sortColumn == column) _sortAscending = !_sortAscending;
            else { _sortColumn = column; _sortAscending = true; }

            UpdateHeaderText();
            ApplyFilterAndSort();
        }

        private void UpdateHeaderText()
        {
            NameHeaderText = "Name" + Arrow("Name");
            SizeHeaderText = "Size" + Arrow("Size");
            TypeHeaderText = "Type" + Arrow("Type");
            ModifiedHeaderText = "Date modified" + Arrow("Modified");

            string Arrow(string column) => column != _sortColumn ? "" : _sortAscending ? "  ▲" : "  ▼";
        }

        private void UpdateStatusText()
        {
            int total = _allItems.Count;
            if (SelectedItems.Count == 0)
            {
                StatusText = $"{total} item{(total == 1 ? "" : "s")}";
                return;
            }

            long size = SelectedItems.Where(i => !i.IsDirectory).Sum(i => i.Size);
            string sizeText = size > 0 ? $" ({SizeFormatter.Format(size)})" : "";
            StatusText = $"{SelectedItems.Count} of {total} selected{sizeText}";
        }

        /// <summary>Called by the view whenever the list's multi-selection changes.</summary>
        public void UpdateSelection(IReadOnlyList<FileSystemItemViewModel> selectedItems)
        {
            SelectedItems = selectedItems ?? Array.Empty<FileSystemItemViewModel>();
            PrimarySelectedItem = SelectedItems.Count > 0 ? SelectedItems[0] : null;

            UpdateStatusText();
            _cutCommand.RaiseCanExecuteChanged();
            _copyCommand.RaiseCanExecuteChanged();
            _deleteCommand.RaiseCanExecuteChanged();
            _renameCommand.RaiseCanExecuteChanged();
            _propertiesCommand.RaiseCanExecuteChanged();
        }

        private List<string> SelectedPaths() => SelectedItems.Select(i => i.FullPath).ToList();

        // --- File operations ----------------------------------------------------

        private async Task NewFolderAsync()
        {
            string suggested = Path.GetFileName(_fileOperationsService.GetUniqueDestinationPath(CurrentPath, "New folder"));
            string name = _dialogService.PromptText("New folder", "Folder name:", suggested, selectBaseNameOnly: false);
            if (string.IsNullOrEmpty(name)) return;

            try
            {
                string fullPath = await _fileOperationsService.CreateFolderAsync(CurrentPath, name);
                await RefreshAsync();
                ItemFocusRequested?.Invoke(fullPath);
            }
            catch (Exception ex)
            {
                _dialogService.ShowWarning($"Could not create folder: {ex.Message}", "New folder");
            }
        }

        private async Task NewFileAsync()
        {
            string suggested = Path.GetFileName(_fileOperationsService.GetUniqueDestinationPath(CurrentPath, "New Text Document.txt"));
            string name = _dialogService.PromptText("New file", "File name:", suggested, selectBaseNameOnly: true);
            if (string.IsNullOrEmpty(name)) return;

            try
            {
                string fullPath = await _fileOperationsService.CreateFileAsync(CurrentPath, name);
                await RefreshAsync();
                ItemFocusRequested?.Invoke(fullPath);
            }
            catch (Exception ex)
            {
                _dialogService.ShowWarning($"Could not create file: {ex.Message}", "New file");
            }
        }

        private void Cut()
        {
            var paths = SelectedPaths();
            if (paths.Count == 0) return;
            _clipboardService.SetFiles(paths, cut: true);
            StatusText = $"Cut {paths.Count} item{(paths.Count == 1 ? "" : "s")}";
        }

        private void Copy()
        {
            var paths = SelectedPaths();
            if (paths.Count == 0) return;
            _clipboardService.SetFiles(paths, cut: false);
            StatusText = $"Copied {paths.Count} item{(paths.Count == 1 ? "" : "s")}";
        }

        private async Task PasteAsync()
        {
            var clipboard = _clipboardService.GetFiles();
            if (clipboard.Paths.Count == 0) return;

            IsBusy = true;
            try
            {
                var errors = await _fileOperationsService.TransferIntoAsync(clipboard.Paths, CurrentPath, clipboard.IsCut, CancellationToken.None);
                if (clipboard.IsCut) _clipboardService.Clear();
                await RefreshAsync();

                if (errors.Count > 0)
                {
                    _dialogService.ShowWarning("Some items could not be pasted:\n\n" + string.Join("\n", errors), "Paste");
                }
            }
            finally
            {
                IsBusy = false;
            }
        }

        private async Task RenameAsync()
        {
            var item = PrimarySelectedItem;
            if (SelectedItems.Count != 1 || item == null) return;

            string newName = _dialogService.PromptText("Rename", "New name:", item.Name, selectBaseNameOnly: true);
            if (string.IsNullOrEmpty(newName) || newName == item.Name) return;

            try
            {
                _fileOperationsService.Rename(item.FullPath, newName);
                string newPath = Path.Combine(Path.GetDirectoryName(item.FullPath), newName);
                await RefreshAsync();
                ItemFocusRequested?.Invoke(newPath);
            }
            catch (Exception ex)
            {
                _dialogService.ShowWarning($"Could not rename: {ex.Message}", "Rename");
            }
        }

        private async Task DeleteAsync()
        {
            var paths = SelectedPaths();
            if (paths.Count == 0) return;

            string message = paths.Count == 1
                ? $"Are you sure you want to move \"{Path.GetFileName(paths[0])}\" to the Recycle Bin?"
                : $"Are you sure you want to move these {paths.Count} items to the Recycle Bin?";
            if (!_dialogService.ConfirmDelete(message)) return;

            IsBusy = true;
            try
            {
                var errors = await _fileOperationsService.DeleteToRecycleBinAsync(paths, CancellationToken.None);
                await RefreshAsync();

                if (errors.Count > 0)
                {
                    _dialogService.ShowWarning("Some items could not be deleted:\n\n" + string.Join("\n", errors), "Delete");
                }
            }
            finally
            {
                IsBusy = false;
            }
        }

        private void ShowProperties()
        {
            if (PrimarySelectedItem != null && SelectedItems.Count == 1)
            {
                _dialogService.ShowProperties(PrimarySelectedItem);
            }
        }

        private Task OpenAsync(FileSystemItemViewModel item)
        {
            item ??= PrimarySelectedItem;
            if (item == null) return Task.CompletedTask;

            if (item.IsDirectory) return NavigateAsync(item.FullPath);

            try
            {
                _fileOperationsService.OpenWithShellAssociation(item.FullPath);
            }
            catch (Exception ex)
            {
                _dialogService.ShowWarning($"Could not open \"{item.Name}\": {ex.Message}", "Open");
            }
            return Task.CompletedTask;
        }

        private void OpenTerminal()
        {
            if (!_terminalLauncher.OpenHere(CurrentPath))
            {
                _dialogService.ShowWarning("Could not find a terminal application to launch.", "Open Terminal");
            }
        }

        // --- Folder tree sidebar ----------------------------------------------------

        private void InitializeTreeRoots()
        {
            foreach (var drive in _fileSystemService.GetReadyDrives())
            {
                RootFolders.Add(new FolderTreeItemViewModel(
                    drive.RootDirectory.FullName, DriveLabel(drive), _fileSystemService, _iconProvider, OnTreeItemSelected));
            }
        }

        private static string DriveLabel(DriveInfo drive)
        {
            string name = drive.RootDirectory.FullName.TrimEnd('\\');
            try
            {
                string label = drive.VolumeLabel;
                return string.IsNullOrWhiteSpace(label) ? $"{name} (Local Disk)" : $"{name} ({label})";
            }
            catch
            {
                return name;
            }
        }

        private void OnTreeItemSelected(FolderTreeItemViewModel item)
        {
            if (_isSyncingTreeSelection) return;
            _ = NavigateAsync(item.FullPath);
        }

        // Keeps the tree in sync with the active folder: expands and selects
        // the chain of nodes leading to it. Guarded by _isSyncingTreeSelection
        // so setting IsSelected on those nodes doesn't loop back into another
        // navigation.
        private async Task SyncTreeSelectionAsync(string path)
        {
            _isSyncingTreeSelection = true;
            try
            {
                string root = Path.GetPathRoot(path);
                if (string.IsNullOrEmpty(root)) return;

                var current = RootFolders.FirstOrDefault(i => string.Equals(i.FullPath, root, StringComparison.OrdinalIgnoreCase));
                if (current == null) return;

                current.IsExpanded = true;
                await current.EnsureChildrenLoadedAsync();

                string relative = path.Substring(root.Length).Trim('\\');
                if (relative.Length > 0)
                {
                    string accumulated = root;
                    foreach (var segment in relative.Split(Path.DirectorySeparatorChar, StringSplitOptions.RemoveEmptyEntries))
                    {
                        accumulated = Path.Combine(accumulated, segment);
                        var next = current.Children.FirstOrDefault(c => string.Equals(c.FullPath, accumulated, StringComparison.OrdinalIgnoreCase));
                        if (next == null) { current = null; break; }

                        next.IsExpanded = true;
                        await next.EnsureChildrenLoadedAsync();
                        current = next;
                    }
                }

                if (current != null) current.IsSelected = true;
            }
            catch
            {
                // Best-effort tree sync; navigation itself has already succeeded.
            }
            finally
            {
                _isSyncingTreeSelection = false;
            }
        }
    }
}
