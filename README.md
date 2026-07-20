# FileExplorer

A minimal Windows file browser built with C# and WPF (project name `FileBrowser`). Click a folder to descend into it; subfolders render as a wrapping grid of folder-icon buttons rather than a list or tree.

This was an early C#/.NET learning project — the first time working with WPF and XAML — built to get comfortable with the framework rather than to replace Windows Explorer outright.

## What it does

- Starts browsing from a fixed root path (`D:\`)
- Lists subdirectories of the current folder as clickable buttons, laid out in a wrapping grid that re-flows on window resize
- Clicking a folder button navigates into it
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
