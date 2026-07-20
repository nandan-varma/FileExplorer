# FileExplorer

A minimal Windows file browser built with C# and WPF (project name `FileBrowser`). A folder tree sidebar for navigating deep folder structures at a glance, plus a wrapping grid of folder-icon buttons for the current directory - click either to descend into a folder. A one-click "Open Terminal" button opens `cmd.exe` in the folder you're currently browsing.

This was an early C#/.NET learning project — the first time working with WPF and XAML — built to get comfortable with the framework rather than to replace Windows Explorer outright.

## What it does

- Folder tree sidebar, lazily populated - each node loads its subfolders only the first time it's expanded, rather than walking the whole filesystem upfront
- Lists subdirectories of the current folder as clickable buttons, laid out in a wrapping grid that re-flows on window resize
- Clicking a folder button, or a node in the tree sidebar, navigates into that folder
- "Open Terminal" button launches `cmd.exe` with its working directory set to the folder currently being browsed
- Right-click context menu with a "Copy" item (currently just confirms the click - no clipboard operation wired up yet)

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

- C# + WPF (XAML)
- .NET 5.0
