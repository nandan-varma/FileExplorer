namespace FileBrowser.Services
{
    public interface ITerminalLauncher
    {
        /// <summary>
        /// Opens a terminal set to <paramref name="path"/>, preferring Windows
        /// Terminal, then PowerShell 7, then Windows PowerShell, then cmd.
        /// Returns false if none of them could be launched.
        /// </summary>
        bool OpenHere(string path);
    }
}
