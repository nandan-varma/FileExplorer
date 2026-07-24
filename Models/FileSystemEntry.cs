using System;
using System.IO;

namespace FileBrowser.Models
{
    /// <summary>
    /// Plain data describing one file or directory. Carries no WPF types so
    /// it can be produced entirely off the UI thread by <c>IFileSystemService</c>.
    /// </summary>
    public sealed class FileSystemEntry
    {
        public string Name { get; init; }
        public string FullPath { get; init; }
        public bool IsDirectory { get; init; }
        public long Size { get; init; }
        public DateTime Created { get; init; }
        public DateTime Modified { get; init; }
        public FileAttributes Attributes { get; init; }
    }
}
