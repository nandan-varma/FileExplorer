using System;
using System.Collections.Concurrent;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace FileBrowser.Services
{
    /// <summary>
    /// Extracts small shell icons for files/folders via the Win32 shell API and
    /// caches them by extension, since repeated lookups for the same file type
    /// would otherwise hit the shell again for every row. Icons are looked up
    /// using a dummy file name with the right extension plus
    /// SHGFI_USEFILEATTRIBUTES, so the shell never touches disk - this works
    /// for nonexistent paths too and is safe to call from a background thread.
    /// </summary>
    public sealed class ShellIconProvider : IIconProvider
    {
        private readonly ConcurrentDictionary<string, ImageSource> _iconCache = new(StringComparer.OrdinalIgnoreCase);

        [StructLayout(LayoutKind.Sequential)]
        private struct SHFILEINFO
        {
            public IntPtr hIcon;
            public int iIcon;
            public uint dwAttributes;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
            public string szDisplayName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 80)]
            public string szTypeName;
        }

        [DllImport("shell32.dll", CharSet = CharSet.Auto)]
        private static extern IntPtr SHGetFileInfo(string pszPath, uint dwFileAttributes, ref SHFILEINFO psfi, uint cbFileInfo, uint uFlags);

        [DllImport("user32.dll")]
        private static extern bool DestroyIcon(IntPtr hIcon);

        private const uint SHGFI_ICON = 0x100;
        private const uint SHGFI_SMALLICON = 0x1;
        private const uint SHGFI_USEFILEATTRIBUTES = 0x10;
        private const uint SHGFI_TYPENAME = 0x400;
        private const uint FILE_ATTRIBUTE_DIRECTORY = 0x10;
        private const uint FILE_ATTRIBUTE_NORMAL = 0x80;

        public ImageSource GetIcon(string path, bool isDirectory)
        {
            string key = isDirectory ? "\0dir" : Path.GetExtension(path)?.ToLowerInvariant() ?? "\0noext";
            if (_iconCache.TryGetValue(key, out var cached)) return cached;

            var info = new SHFILEINFO();
            uint flags = SHGFI_ICON | SHGFI_SMALLICON | SHGFI_USEFILEATTRIBUTES;
            uint attr = isDirectory ? FILE_ATTRIBUTE_DIRECTORY : FILE_ATTRIBUTE_NORMAL;
            string lookup = isDirectory ? "folder" : "file" + key;

            ImageSource result = null;
            IntPtr hIcon = IntPtr.Zero;
            try
            {
                SHGetFileInfo(lookup, attr, ref info, (uint)Marshal.SizeOf(info), flags);
                hIcon = info.hIcon;
                if (hIcon != IntPtr.Zero)
                {
                    var bitmap = Imaging.CreateBitmapSourceFromHIcon(hIcon, Int32Rect.Empty, BitmapSizeOptions.FromEmptyOptions());
                    bitmap.Freeze();
                    result = bitmap;
                }
            }
            finally
            {
                if (hIcon != IntPtr.Zero) DestroyIcon(hIcon);
            }

            return _iconCache.GetOrAdd(key, result);
        }

        public string GetTypeDescription(string path, bool isDirectory)
        {
            if (isDirectory) return "File folder";

            var info = new SHFILEINFO();
            uint flags = SHGFI_TYPENAME | SHGFI_USEFILEATTRIBUTES;
            string ext = Path.GetExtension(path);
            string lookup = "file" + ext;
            SHGetFileInfo(lookup, FILE_ATTRIBUTE_NORMAL, ref info, (uint)Marshal.SizeOf(info), flags);
            return string.IsNullOrWhiteSpace(info.szTypeName)
                ? (string.IsNullOrEmpty(ext) ? "File" : ext.TrimStart('.').ToUpperInvariant() + " File")
                : info.szTypeName;
        }
    }
}
