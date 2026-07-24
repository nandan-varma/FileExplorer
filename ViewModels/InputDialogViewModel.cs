using System.IO;
using System.Linq;
using FileBrowser.Mvvm;

namespace FileBrowser.ViewModels
{
    public sealed class InputDialogViewModel : ObservableObject
    {
        private string _text;
        private string _errorMessage;

        public InputDialogViewModel(string title, string prompt, string defaultValue, bool selectBaseNameOnly)
        {
            Title = title;
            Prompt = prompt;
            _text = defaultValue ?? string.Empty;

            SelectionLength = _text.Length;
            if (selectBaseNameOnly && _text.Length > 0)
            {
                string ext = Path.GetExtension(_text);
                if (!string.IsNullOrEmpty(ext) && ext.Length < _text.Length)
                {
                    SelectionLength = _text.Length - ext.Length;
                }
            }
        }

        public string Title { get; }
        public string Prompt { get; }
        public int SelectionLength { get; }

        public string Text
        {
            get => _text;
            set => SetProperty(ref _text, value);
        }

        public string ErrorMessage
        {
            get => _errorMessage;
            private set => SetProperty(ref _errorMessage, value);
        }

        /// <summary>Validates the current text and, if it's acceptable, returns true and clears any error.</summary>
        public bool TryAccept()
        {
            string text = (Text ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(text))
            {
                ErrorMessage = "Name cannot be empty.";
                return false;
            }

            var invalid = Path.GetInvalidFileNameChars();
            var badChars = text.Where(invalid.Contains).Distinct().ToArray();
            if (badChars.Length > 0)
            {
                ErrorMessage = "Name contains invalid characters: " + string.Join(" ", badChars);
                return false;
            }

            Text = text;
            ErrorMessage = null;
            return true;
        }
    }
}
