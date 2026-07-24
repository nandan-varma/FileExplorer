using System;

namespace FileBrowser.Services
{
    /// <summary>User-facing wrapper for I/O failures encountered while listing a directory.</summary>
    public sealed class FileSystemAccessException : Exception
    {
        public FileSystemAccessException(string message) : base(message)
        {
        }

        public FileSystemAccessException(string message, Exception inner) : base(message, inner)
        {
        }
    }
}
