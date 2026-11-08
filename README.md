# FileExplorer

Windows Explorer always bothered me: deep folder navigation is awkward without a persistent tree, and opening a terminal in the current directory takes too many steps. This project is a C#/.NET + WPF replacement focused on those gaps.

## Features

- **Tree view navigation** for full folder hierarchy browsing (lazy-loaded for performance).
- **Integrated terminal** inside the app that runs `cmd.exe` in the current directory.
- **Standard file operations**:
  - Create folder
  - Copy / Cut / Paste
  - Rename
  - Delete
- **File list with metadata** (name, type, size, modified time) and double-click to open files or enter folders.
- **Navigation controls**: Back, Up, Refresh, and path bar.

## Requirements

- Windows
- .NET 5.0 (`net5.0-windows`)
- WPF (`UseWPF`)

## Getting started

Open `FileBrowser.sln` in Visual Studio and run, or:

```bash
dotnet run --project FileBrowser.csproj
```

## Built with

- C#
- .NET 5.0
- WPF (XAML)
