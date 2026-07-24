using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows;

namespace FileBrowser.Services
{
    public sealed class ClipboardService : IClipboardService
    {
        // The "Preferred DropEffect" clipboard format is the same mechanism
        // Explorer uses to distinguish a cut from a copy on the clipboard: a
        // 4-byte little-endian DragDropEffects value alongside the file list.
        private const string PreferredDropEffectFormat = "Preferred DropEffect";

        public void SetFiles(IReadOnlyList<string> paths, bool cut)
        {
            var fileList = new StringCollection();
            fileList.AddRange(paths.ToArray());

            var data = new DataObject();
            data.SetFileDropList(fileList);

            var effect = cut ? DragDropEffects.Move : DragDropEffects.Copy;
            using var effectStream = new MemoryStream(BitConverter.GetBytes((int)effect));
            data.SetData(PreferredDropEffectFormat, effectStream);

            SetClipboardDataWithRetry(data);
        }

        public ClipboardFiles GetFiles()
        {
            if (!TryGetContainsFileDropList()) return ClipboardFiles.Empty;

            var files = TryGetFileDropList();
            if (files.Count == 0) return ClipboardFiles.Empty;

            bool isCut = false;
            if (TryGetData(PreferredDropEffectFormat) is MemoryStream stream)
            {
                var bytes = new byte[4];
                stream.Position = 0;
                if (stream.Read(bytes, 0, bytes.Length) == bytes.Length)
                {
                    var effect = (DragDropEffects)BitConverter.ToInt32(bytes, 0);
                    isCut = effect.HasFlag(DragDropEffects.Move);
                }
            }

            return new ClipboardFiles(files, isCut);
        }

        public void Clear()
        {
            try { Clipboard.Clear(); } catch (COMException) { /* clipboard momentarily owned elsewhere */ }
        }

        // Clipboard.SetDataObject can throw COMException(CLIPBRD_E_CANT_OPEN) if
        // another process briefly holds the clipboard - a couple of quick
        // retries clears up nearly all of those without bothering the user.
        private static void SetClipboardDataWithRetry(DataObject data)
        {
            for (int attempt = 0; attempt < 3; attempt++)
            {
                try
                {
                    Clipboard.SetDataObject(data, true);
                    return;
                }
                catch (COMException) when (attempt < 2)
                {
                    Thread.Sleep(50);
                }
            }
        }

        private static bool TryGetContainsFileDropList()
        {
            try { return Clipboard.ContainsFileDropList(); }
            catch (COMException) { return false; }
        }

        private static IReadOnlyList<string> TryGetFileDropList()
        {
            try { return Clipboard.GetFileDropList().Cast<string>().ToList(); }
            catch (COMException) { return Array.Empty<string>(); }
        }

        private static object TryGetData(string format)
        {
            try { return Clipboard.ContainsData(format) ? Clipboard.GetData(format) : null; }
            catch (COMException) { return null; }
        }
    }
}
