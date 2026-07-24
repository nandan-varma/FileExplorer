using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FileBrowser.Models;

namespace FileBrowser.Services
{
    public sealed class FileSystemService : IFileSystemService
    {
        public Task<IReadOnlyList<FileSystemEntry>> EnumerateAsync(string path, CancellationToken cancellationToken)
        {
            return Task.Run(() =>
            {
                var entries = new List<FileSystemEntry>();
                try
                {
                    foreach (var dir in Directory.EnumerateDirectories(path))
                    {
                        cancellationToken.ThrowIfCancellationRequested();
                        var info = new DirectoryInfo(dir);
                        entries.Add(new FileSystemEntry
                        {
                            Name = info.Name,
                            FullPath = info.FullName,
                            IsDirectory = true,
                            Modified = SafeGetLastWrite(info),
                            Created = SafeGetCreationTime(info),
                            Attributes = SafeGetAttributes(info),
                        });
                    }

                    foreach (var file in Directory.EnumerateFiles(path))
                    {
                        cancellationToken.ThrowIfCancellationRequested();
                        var info = new FileInfo(file);
                        entries.Add(new FileSystemEntry
                        {
                            Name = info.Name,
                            FullPath = info.FullName,
                            IsDirectory = false,
                            Size = SafeGetLength(info),
                            Modified = SafeGetLastWrite(info),
                            Created = SafeGetCreationTime(info),
                            Attributes = SafeGetAttributes(info),
                        });
                    }
                }
                catch (UnauthorizedAccessException ex)
                {
                    throw new FileSystemAccessException("You don't have permission to view the contents of this folder.", ex);
                }
                catch (IOException ex)
                {
                    throw new FileSystemAccessException(ex.Message, ex);
                }

                return (IReadOnlyList<FileSystemEntry>)entries;
            }, cancellationToken);
        }

        public Task<IReadOnlyList<string>> GetSubdirectoriesAsync(string path, CancellationToken cancellationToken)
        {
            return Task.Run(() =>
            {
                try
                {
                    return (IReadOnlyList<string>)Directory.EnumerateDirectories(path)
                        .OrderBy(Path.GetFileName, StringComparer.OrdinalIgnoreCase)
                        .ToList();
                }
                catch (Exception)
                {
                    // Permissions, special system folders, etc. - the tree just shows no children.
                    return Array.Empty<string>();
                }
            }, cancellationToken);
        }

        public bool DirectoryExists(string path) => Directory.Exists(path);

        public string GetDefaultStartPath()
        {
            string startPath = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            if (!string.IsNullOrEmpty(startPath) && Directory.Exists(startPath)) return startPath;

            return GetReadyDrives().FirstOrDefault()?.RootDirectory.FullName ?? Path.GetTempPath();
        }

        public IReadOnlyList<DriveInfo> GetReadyDrives() =>
            DriveInfo.GetDrives().Where(d => d.IsReady).ToList();

        private static DateTime SafeGetLastWrite(FileSystemInfo info)
        {
            try { return info.LastWriteTime; } catch { return default; }
        }

        private static DateTime SafeGetCreationTime(FileSystemInfo info)
        {
            try { return info.CreationTime; } catch { return default; }
        }

        private static FileAttributes SafeGetAttributes(FileSystemInfo info)
        {
            try { return info.Attributes; } catch { return FileAttributes.Normal; }
        }

        private static long SafeGetLength(FileInfo info)
        {
            try { return info.Length; } catch { return 0; }
        }
    }
}
