using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace FileBrowser.Services
{
    public interface IFileOperationsService
    {
        /// <summary>
        /// Copies or moves each source path into <paramref name="destDir"/>, resolving
        /// name collisions the way Explorer does ("name (2).ext"). Continues past
        /// per-item failures and returns "name: reason" for each one that failed.
        /// </summary>
        Task<IReadOnlyList<string>> TransferIntoAsync(IReadOnlyList<string> sourcePaths, string destDir, bool move, CancellationToken cancellationToken);

        /// <summary>Sends each path to the Recycle Bin, returning "name: reason" for failures.</summary>
        Task<IReadOnlyList<string>> DeleteToRecycleBinAsync(IReadOnlyList<string> paths, CancellationToken cancellationToken);

        void Rename(string path, string newName);

        Task<string> CreateFolderAsync(string parentDir, string name);

        Task<string> CreateFileAsync(string parentDir, string name);

        string GetUniqueDestinationPath(string destDir, string name);

        void OpenWithShellAssociation(string path);
    }
}
