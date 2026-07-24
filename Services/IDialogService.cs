using FileBrowser.ViewModels;

namespace FileBrowser.Services
{
    /// <summary>
    /// Abstracts modal UI (message boxes, prompts, the Properties window) away
    /// from the view models so they stay free of System.Windows types.
    /// </summary>
    public interface IDialogService
    {
        void ShowWarning(string message, string title);

        bool ConfirmDelete(string message);

        /// <summary>Shows a modal text-entry prompt. Returns null if the user cancelled.</summary>
        string PromptText(string title, string prompt, string defaultValue, bool selectBaseNameOnly);

        void ShowProperties(FileSystemItemViewModel item);
    }
}
