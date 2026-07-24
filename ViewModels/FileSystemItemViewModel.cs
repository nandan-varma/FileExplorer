using System;
using System.Windows.Media;
using FileBrowser.Models;
using FileBrowser.Services;

namespace FileBrowser.ViewModels
{
    /// <summary>
    /// Display-ready wrapper around a <see cref="FileSystemEntry"/>. Instances
    /// are immutable and rebuilt wholesale on every directory load, so there's
    /// no need for change notification here.
    /// </summary>
    public sealed class FileSystemItemViewModel
    {
        public FileSystemItemViewModel(FileSystemEntry entry, ImageSource icon, string typeDescription)
        {
            Name = entry.Name;
            FullPath = entry.FullPath;
            IsDirectory = entry.IsDirectory;
            Size = entry.Size;
            Modified = entry.Modified;
            Created = entry.Created;
            Attributes = entry.Attributes;
            Icon = icon;
            TypeDescription = typeDescription;
        }

        public string Name { get; }
        public string FullPath { get; }
        public bool IsDirectory { get; }
        public long Size { get; }
        public DateTime Modified { get; }
        public DateTime Created { get; }
        public System.IO.FileAttributes Attributes { get; }
        public ImageSource Icon { get; }
        public string TypeDescription { get; }

        public string SizeDisplay => IsDirectory ? string.Empty : SizeFormatter.Format(Size);
        public string ModifiedDisplay => Modified == default ? string.Empty : Modified.ToString("g");
    }
}
