using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Media;
using FileBrowser.Mvvm;
using FileBrowser.Services;

namespace FileBrowser.ViewModels
{
    public sealed class PropertiesDialogViewModel : ObservableObject
    {
        private string _sizeText = "Calculating...";

        public PropertiesDialogViewModel(FileSystemItemViewModel item)
        {
            Name = item.Name;
            Icon = item.Icon;
            LocationText = Path.GetDirectoryName(item.FullPath);
            ModifiedText = item.Modified == default ? "-" : item.Modified.ToString("F");

            if (item.IsDirectory)
            {
                TypeText = "File folder";
                CreatedText = item.Created == default ? "-" : item.Created.ToString("F");
                AttributesText = DescribeAttributes(item.Attributes);
                _ = CalculateDirectorySizeAsync(item.FullPath);
            }
            else
            {
                TypeText = item.TypeDescription;
                CreatedText = item.Created == default ? "-" : item.Created.ToString("F");
                AttributesText = DescribeAttributes(item.Attributes);
                SizeText = $"{SizeFormatter.Format(item.Size)} ({item.Size:N0} bytes)";
            }
        }

        public string Name { get; }
        public ImageSource Icon { get; }
        public string TypeText { get; }
        public string LocationText { get; }
        public string CreatedText { get; }
        public string ModifiedText { get; }
        public string AttributesText { get; }

        public string SizeText
        {
            get => _sizeText;
            private set => SetProperty(ref _sizeText, value);
        }

        // Recursing a large folder can take a while on spinning disks or network
        // shares - do it off the UI thread so opening Properties never freezes
        // the window the way the original synchronous version did.
        private async Task CalculateDirectorySizeAsync(string path)
        {
            try
            {
                long total = await Task.Run(() => GetDirectorySize(new DirectoryInfo(path)));
                SizeText = SizeFormatter.Format(total);
            }
            catch (Exception)
            {
                SizeText = "Unavailable";
            }
        }

        private static long GetDirectorySize(DirectoryInfo dir)
        {
            long total = 0;
            try
            {
                foreach (var file in dir.EnumerateFiles("*", SearchOption.AllDirectories))
                {
                    total += SafeLength(file);
                }
            }
            catch (UnauthorizedAccessException)
            {
                // Best-effort total; skip folders we can't read.
            }
            return total;
        }

        private static long SafeLength(FileInfo file)
        {
            try { return file.Length; } catch { return 0; }
        }

        private static string DescribeAttributes(FileAttributes attributes)
        {
            var sb = new StringBuilder();
            if (attributes.HasFlag(FileAttributes.ReadOnly)) sb.Append("Read-only ");
            if (attributes.HasFlag(FileAttributes.Hidden)) sb.Append("Hidden ");
            if (attributes.HasFlag(FileAttributes.System)) sb.Append("System ");
            return sb.Length == 0 ? "Normal" : sb.ToString().Trim();
        }
    }
}
