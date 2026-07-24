using System;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Media;
using FileBrowser.Mvvm;
using FileBrowser.Services;

namespace FileBrowser.ViewModels
{
    /// <summary>
    /// One node of the folder tree sidebar. Children are populated lazily -
    /// the first expand triggers <see cref="EnsureChildrenLoadedAsync"/>, which
    /// caches its task so concurrent callers (a user click racing a
    /// programmatic sync-to-path) await the same load instead of double-firing.
    /// </summary>
    public sealed class FolderTreeItemViewModel : ObservableObject
    {
        private readonly IFileSystemService _fileSystemService;
        private readonly IIconProvider _iconProvider;
        private readonly Action<FolderTreeItemViewModel> _onSelected;

        private bool _isLoaded;
        private Task _loadTask;
        private bool _isExpanded;
        private bool _isSelected;

        public FolderTreeItemViewModel(
            string path,
            string displayName,
            IFileSystemService fileSystemService,
            IIconProvider iconProvider,
            Action<FolderTreeItemViewModel> onSelected)
        {
            FullPath = path;
            Name = displayName;
            _fileSystemService = fileSystemService;
            _iconProvider = iconProvider;
            _onSelected = onSelected;
            Icon = iconProvider.GetIcon(path, true);
        }

        public string Name { get; }
        public string FullPath { get; }
        public ImageSource Icon { get; }
        public ObservableCollection<FolderTreeItemViewModel> Children { get; } = new();

        public bool IsExpanded
        {
            get => _isExpanded;
            set
            {
                if (SetProperty(ref _isExpanded, value) && value)
                {
                    _ = EnsureChildrenLoadedAsync();
                }
            }
        }

        public bool IsSelected
        {
            get => _isSelected;
            set
            {
                if (SetProperty(ref _isSelected, value) && value)
                {
                    _onSelected?.Invoke(this);
                }
            }
        }

        public Task EnsureChildrenLoadedAsync()
        {
            if (_isLoaded) return Task.CompletedTask;
            return _loadTask ??= LoadChildrenCoreAsync();
        }

        private async Task LoadChildrenCoreAsync()
        {
            var subdirs = await _fileSystemService.GetSubdirectoriesAsync(FullPath, CancellationToken.None).ConfigureAwait(true);

            Children.Clear();
            foreach (var dir in subdirs)
            {
                Children.Add(new FolderTreeItemViewModel(dir, Path.GetFileName(dir), _fileSystemService, _iconProvider, _onSelected));
            }
            _isLoaded = true;
        }
    }
}
