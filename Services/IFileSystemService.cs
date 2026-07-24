using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using FileBrowser.Models;

namespace FileBrowser.Services
{
    public interface IFileSystemService
    {
        /// <summary>
        /// Lists the directories and files directly under <paramref name="path"/>.
        /// Runs on a background thread. Throws <see cref="FileSystemAccessException"/>
        /// with a user-friendly message if the folder can't be read.
        /// </summary>
        Task<IReadOnlyList<FileSystemEntry>> EnumerateAsync(string path, CancellationToken cancellationToken);

        /// <summary>
        /// Lists immediate subdirectory paths under <paramref name="path"/>, for
        /// populating the folder tree. Returns an empty list if the folder can't
        /// be enumerated rather than throwing - the tree silently treats such
        /// folders as leaves.
        /// </summary>
        Task<IReadOnlyList<string>> GetSubdirectoriesAsync(string path, CancellationToken cancellationToken);

        bool DirectoryExists(string path);

        /// <summary>The user's home folder, falling back to the first ready drive, then temp.</summary>
        string GetDefaultStartPath();

        IReadOnlyList<DriveInfo> GetReadyDrives();
    }
}
