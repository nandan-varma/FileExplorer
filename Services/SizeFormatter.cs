namespace FileBrowser.Services
{
    public static class SizeFormatter
    {
        private static readonly string[] Units = { "B", "KB", "MB", "GB", "TB" };

        public static string Format(long bytes)
        {
            double size = bytes;
            int unit = 0;
            while (size >= 1024 && unit < Units.Length - 1)
            {
                size /= 1024;
                unit++;
            }
            return unit == 0 ? $"{size:0} {Units[unit]}" : $"{size:0.0} {Units[unit]}";
        }
    }
}
