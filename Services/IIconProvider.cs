using System.Windows.Media;

namespace FileBrowser.Services
{
    public interface IIconProvider
    {
        /// <summary>
        /// Gets the small shell icon for a file or folder. Safe to call from a
        /// background thread - the returned <see cref="ImageSource"/> is frozen.
        /// </summary>
        ImageSource GetIcon(string path, bool isDirectory);

        string GetTypeDescription(string path, bool isDirectory);
    }
}
