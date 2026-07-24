using System.ComponentModel;
using System.Diagnostics;

namespace FileBrowser.Services
{
    public sealed class TerminalLauncher : ITerminalLauncher
    {
        public bool OpenHere(string path)
        {
            (string FileName, string Arguments)[] candidates =
            {
                ("wt.exe", $"-d \"{path}\""),
                ("pwsh.exe", null),
                ("powershell.exe", null),
                ("cmd.exe", null),
            };

            foreach (var (fileName, arguments) in candidates)
            {
                try
                {
                    Process.Start(new ProcessStartInfo
                    {
                        FileName = fileName,
                        Arguments = arguments ?? string.Empty,
                        WorkingDirectory = path,
                        UseShellExecute = true
                    });
                    return true;
                }
                catch (Win32Exception)
                {
                    // Not installed / not on PATH - try the next shell.
                }
            }

            return false;
        }
    }
}
