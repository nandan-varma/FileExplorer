using System.Collections.Generic;

namespace FileBrowser.Services
{
    public sealed class ClipboardFiles
    {
        public static readonly ClipboardFiles Empty = new(new List<string>(), false);

        public ClipboardFiles(IReadOnlyList<string> paths, bool isCut)
        {
            Paths = paths;
            IsCut = isCut;
        }

        public IReadOnlyList<string> Paths { get; }
        public bool IsCut { get; }
    }

    /// <summary>
    /// Wraps the Windows clipboard's file-drop format so Cut/Copy/Paste in this
    /// app interoperates with Explorer and other apps, not just with itself.
    /// </summary>
    public interface IClipboardService
    {
        void SetFiles(IReadOnlyList<string> paths, bool cut);

        ClipboardFiles GetFiles();

        void Clear();
    }
}
