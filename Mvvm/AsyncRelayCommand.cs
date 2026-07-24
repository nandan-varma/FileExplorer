using System;
using System.Threading.Tasks;
using System.Windows.Input;

namespace FileBrowser.Mvvm
{
    /// <summary>
    /// A command backed by an async delegate. Guards against re-entrancy so a
    /// double-click or an impatient extra keypress can't start the same
    /// operation (e.g. a paste or a delete) twice while it's still running.
    /// </summary>
    public sealed class AsyncRelayCommand : ICommand
    {
        private readonly Func<Task> _executeAsync;
        private readonly Func<bool> _canExecute;
        private bool _isExecuting;

        public AsyncRelayCommand(Func<Task> executeAsync, Func<bool> canExecute = null)
        {
            _executeAsync = executeAsync ?? throw new ArgumentNullException(nameof(executeAsync));
            _canExecute = canExecute;
        }

        public event EventHandler CanExecuteChanged
        {
            add => CommandManager.RequerySuggested += value;
            remove => CommandManager.RequerySuggested -= value;
        }

        public bool CanExecute(object parameter) => !_isExecuting && (_canExecute?.Invoke() ?? true);

        public async void Execute(object parameter)
        {
            if (!CanExecute(parameter)) return;
            _isExecuting = true;
            RaiseCanExecuteChanged();
            try
            {
                await _executeAsync();
            }
            finally
            {
                _isExecuting = false;
                RaiseCanExecuteChanged();
            }
        }

        public void RaiseCanExecuteChanged() => CommandManager.InvalidateRequerySuggested();
    }

    /// <summary>Same as <see cref="AsyncRelayCommand"/> but forwards a typed CommandParameter.</summary>
    public sealed class AsyncRelayCommand<T> : ICommand
    {
        private readonly Func<T, Task> _executeAsync;
        private readonly Func<T, bool> _canExecute;
        private bool _isExecuting;

        public AsyncRelayCommand(Func<T, Task> executeAsync, Func<T, bool> canExecute = null)
        {
            _executeAsync = executeAsync ?? throw new ArgumentNullException(nameof(executeAsync));
            _canExecute = canExecute;
        }

        public event EventHandler CanExecuteChanged
        {
            add => CommandManager.RequerySuggested += value;
            remove => CommandManager.RequerySuggested -= value;
        }

        public bool CanExecute(object parameter) => !_isExecuting && (_canExecute?.Invoke((T)parameter) ?? true);

        public async void Execute(object parameter)
        {
            var typed = (T)parameter;
            if (!CanExecute(typed)) return;
            _isExecuting = true;
            RaiseCanExecuteChanged();
            try
            {
                await _executeAsync(typed);
            }
            finally
            {
                _isExecuting = false;
                RaiseCanExecuteChanged();
            }
        }

        public void RaiseCanExecuteChanged() => CommandManager.InvalidateRequerySuggested();
    }
}
