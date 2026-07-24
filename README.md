# FileExplorer

Windows Explorer always bothered me. No tree view for navigating deep folder structures, and opening a terminal in the current directory required too many steps. I built a replacement that fixed both.

## Features

- **Tree view** that shows the full folder hierarchy at a glance - rooted at every drive on the machine, lazily populated so it never walks the filesystem upfront, and kept in sync with the folder you're browsing.
- **Integrated terminal** that opens already `cd`'d into the current directory - Windows Terminal if it's installed, falling back to PowerShell then `cmd.exe`.
- **All standard file operations**: New Folder, New File, Cut/Copy/Paste (backed by the real Windows clipboard, so it interoperates with Explorer), Rename, Delete (to the Recycle Bin, with confirmation), and Properties - from the toolbar, right-click menus, and keyboard shortcuts.
- Sortable, searchable file listing with shell icons, size, type, and last-modified date.
- Back/Forward history, Up a level, Refresh, and an editable address bar.
- Keyboard shortcuts: `Backspace`/`Alt+Left`/`Alt+Right` navigate, `F5` refresh, `Ctrl+X/C/V` cut/copy/paste, `F2` rename, `Delete` delete, `Ctrl+A` select all, `Ctrl+F` focus search, `Ctrl+Shift+N` new folder, `Enter` open, `Alt+Enter` properties.

## Built with

- C# / .NET 8
- WPF / XAML, using an MVVM architecture: view models own all app state and behavior, a small service layer wraps every OS-facing concern (file system, shell icons, file operations, clipboard, terminal launch, dialogs), and the views are thin XAML bindings with no business logic in code-behind.
- Directory loads, file transfers, and deletes run off the UI thread and are cancellable, so browsing a slow or huge folder never freezes the window.

## Getting started

Open `FileBrowser.sln` in Visual Studio and run, or:

```bash
dotnet run --project FileBrowser.csproj
```

## Requirements

- Windows 10/11
- .NET 8.0 (`net8.0-windows`)
