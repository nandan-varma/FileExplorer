# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Windows file explorer built with C#/WPF (project name `FileBrowser`), replacing Explorer's lack of a folder tree and clunky "open terminal here" flow. Drive/folder tree sidebar (lazily populated), sortable file list with standard file operations, and a one-click terminal launcher `cd`'d into the current folder.

## Commands

This is a Windows-only WPF app (`net8.0-windows`, `UseWPF`) - it cannot be built or run on macOS/Linux; there is no `dotnet` SDK in this environment. Changes must be verified by careful reading, not by compiling. When a human runs it on Windows:

```bash
dotnet build FileBrowser.csproj
dotnet run --project FileBrowser.csproj
```

or open `FileBrowser.sln` in Visual Studio and run (F5).

There is no test project and no lint config in this repo.

## Architecture

Standard MVVM, with a manual composition root (no DI container - the app is small enough that one would add more ceremony than it saves):

```
App.xaml.cs (OnStartup)  -->  constructs services  -->  MainViewModel  -->  MainWindow.DataContext
```

- **`Mvvm/`** - `RelayCommand`/`RelayCommand<T>` (sync) and `AsyncRelayCommand`/`AsyncRelayCommand<T>` (guard re-entrancy while the async body is running) plus `ObservableObject`. All view model commands are built on these; there is no third-party MVVM toolkit.
- **`Services/`** - every OS-facing concern lives behind an interface, called only from view models:
  - `IFileSystemService` - directory enumeration and drive listing. Runs on a background thread and throws `FileSystemAccessException` with a user-facing message on failure.
  - `IIconProvider` (`ShellIconProvider`) - shell icons via `SHGetFileInfo` P/Invoke, cached by extension, safe to call off the UI thread (icons are frozen).
  - `IFileOperationsService` - copy/move/rename/delete/create, also async. Delete goes through `Microsoft.VisualBasic.FileIO.FileSystem` to get real Recycle Bin behavior.
  - `IClipboardService` - cut/copy/paste backed by the **real Windows clipboard** (`CF_HDROP` file-drop list + the "Preferred DropEffect" format), so it round-trips with Explorer, not just with itself.
  - `ITerminalLauncher` - tries `wt.exe`, then `pwsh.exe`, then `powershell.exe`, then `cmd.exe`.
  - `IDialogService` - wraps `MessageBox` and owns showing `InputDialog`/`PropertiesDialog`, keeping `System.Windows` types out of view models.
- **`ViewModels/`**:
  - `MainViewModel` - all app state: navigation history (back/forward/up), the current directory listing, filter/sort, and every file command. Directory loads are cancelled/superseded via a `CancellationTokenSource` per navigation so a slow load can't clobber a newer one.
  - `FolderTreeItemViewModel` - one tree node. Children load lazily on first expand; the in-flight load `Task` is cached so a user click and a programmatic sync-to-path (`MainViewModel` expanding/selecting nodes to match the current folder) never double-load.
  - `FileSystemItemViewModel` - immutable per-row display model; rebuilt wholesale on every directory load rather than mutated in place.
  - `InputDialogViewModel` / `PropertiesDialogViewModel` - back `Dialogs/InputDialog` and `Dialogs/PropertiesDialog`. `PropertiesDialogViewModel` computes folder size asynchronously so opening Properties on a big folder doesn't freeze the dialog.
- **Views** (`MainWindow.xaml`, `Dialogs/*.xaml`) bind to the above; there is no business logic in code-behind. What remains in code-behind is view-only glue with no clean declarative equivalent:
  - The full keyboard shortcut table lives in one `Window_PreviewKeyDown` handler (not XAML `KeyBinding`s) specifically so the "ignore keys while a `TextBox` has focus" guard applies uniformly across every shortcut.
  - Multi-select forwarding (`ListView.SelectedItems` -> `MainViewModel.UpdateSelection(...)`) and right-click selection-preserving logic, since WPF doesn't support binding multi-selection declaratively.
  - Per-row `ContextMenu` commands bind through `PlacementTarget.Tag` (set via the `ListViewItem` style to the ListView's `DataContext`) because a `ContextMenu` is a separate visual tree and doesn't inherit `DataContext` from its `PlacementTarget` automatically.

## Conventions worth preserving

- `Nullable` and `ImplicitUsings` are both disabled in the csproj - don't add nullable annotations or rely on implicit usings; keep explicit `using` blocks per file.
- Keep OS-facing code (file I/O, clipboard, process launch, P/Invoke) inside `Services/` behind an interface - view models should never touch `System.IO`, `System.Windows.Clipboard`, or `Process` directly.
- File/directory operations that can be slow (enumeration, copy, move, delete) should stay `async` and accept a `CancellationToken`.
