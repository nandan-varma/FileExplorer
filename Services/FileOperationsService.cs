using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.VisualBasic.FileIO;

namespace FileBrowser.Services
{
    public sealed class FileOperationsService : IFileOperationsService
    {
        public Task<IReadOnlyList<string>> TransferIntoAsync(IReadOnlyList<string> sourcePaths, string destDir, bool move, CancellationToken cancellationToken)
        {
            return Task.Run(() =>
            {
                var errors = new List<string>();
                string normalizedDest = destDir.TrimEnd(Path.DirectorySeparatorChar);

                foreach (var source in sourcePaths)
                {
                    cancellationToken.ThrowIfCancellationRequested();
                    string name = Path.GetFileName(source.TrimEnd(Path.DirectorySeparatorChar));
                    try
                    {
                        if (move && string.Equals(Path.GetDirectoryName(source), normalizedDest, StringComparison.OrdinalIgnoreCase))
                        {
                            // Moving into the same folder is a no-op.
                            continue;
                        }

                        bool isDir = Directory.Exists(source);
                        string dest = GetUniqueDestinationPath(destDir, name);

                        if (isDir)
                        {
                            if (move) Directory.Move(source, dest);
                            else CopyDirectoryRecursive(source, dest, cancellationToken);
                        }
                        else
                        {
                            if (move) File.Move(source, dest);
                            else File.Copy(source, dest);
                        }
                    }
                    catch (Exception ex) when (ex is not OperationCanceledException)
                    {
                        errors.Add($"{name}: {ex.Message}");
                    }
                }

                return (IReadOnlyList<string>)errors;
            }, cancellationToken);
        }

        private static void CopyDirectoryRecursive(string sourceDir, string destDir, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            Directory.CreateDirectory(destDir);
            foreach (var file in Directory.EnumerateFiles(sourceDir))
            {
                cancellationToken.ThrowIfCancellationRequested();
                File.Copy(file, Path.Combine(destDir, Path.GetFileName(file)));
            }
            foreach (var dir in Directory.EnumerateDirectories(sourceDir))
            {
                CopyDirectoryRecursive(dir, Path.Combine(destDir, Path.GetFileName(dir)), cancellationToken);
            }
        }

        public string GetUniqueDestinationPath(string destDir, string name)
        {
            string candidate = Path.Combine(destDir, name);
            if (!File.Exists(candidate) && !Directory.Exists(candidate)) return candidate;

            string baseName = Path.GetFileNameWithoutExtension(name);
            string ext = Path.GetExtension(name);
            int i = 2;
            string next;
            do
            {
                next = Path.Combine(destDir, $"{baseName} ({i}){ext}");
                i++;
            } while (File.Exists(next) || Directory.Exists(next));
            return next;
        }

        public Task<IReadOnlyList<string>> DeleteToRecycleBinAsync(IReadOnlyList<string> paths, CancellationToken cancellationToken)
        {
            return Task.Run(() =>
            {
                var errors = new List<string>();
                foreach (var path in paths)
                {
                    cancellationToken.ThrowIfCancellationRequested();
                    try
                    {
                        if (Directory.Exists(path))
                        {
                            FileSystem.DeleteDirectory(path, UIOption.OnlyErrorDialogs, RecycleOption.SendToRecycleBin);
                        }
                        else if (File.Exists(path))
                        {
                            FileSystem.DeleteFile(path, UIOption.OnlyErrorDialogs, RecycleOption.SendToRecycleBin);
                        }
                    }
                    catch (Exception ex) when (ex is not OperationCanceledException)
                    {
                        errors.Add($"{Path.GetFileName(path)}: {ex.Message}");
                    }
                }
                return (IReadOnlyList<string>)errors;
            }, cancellationToken);
        }

        public void Rename(string path, string newName)
        {
            bool isDir = Directory.Exists(path);
            string dir = Path.GetDirectoryName(path);
            string dest = Path.Combine(dir!, newName);
            if (isDir) Directory.Move(path, dest);
            else File.Move(path, dest);
        }

        public Task<string> CreateFolderAsync(string parentDir, string name)
        {
            return Task.Run(() =>
            {
                string fullPath = GetUniqueDestinationPath(parentDir, name);
                Directory.CreateDirectory(fullPath);
                return fullPath;
            });
        }

        public Task<string> CreateFileAsync(string parentDir, string name)
        {
            return Task.Run(() =>
            {
                string fullPath = GetUniqueDestinationPath(parentDir, name);
                File.Create(fullPath).Dispose();
                return fullPath;
            });
        }

        public void OpenWithShellAssociation(string path)
        {
            Process.Start(new ProcessStartInfo { FileName = path, UseShellExecute = true });
        }
    }
}
