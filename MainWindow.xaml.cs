using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace FileBrowser
{
    public partial class MainWindow : Window
    {
        private const string TreePlaceholderTag = "__PLACEHOLDER__";

        private readonly ObservableCollection<FileSystemEntry> _entries = new();
        private readonly Stack<string> _backHistory = new();
        private string _currentDirectory = string.Empty;
        private string? _clipboardPath;
        private bool _clipboardIsCut;
        private bool _isSelectingTreePath;
        private Process? _terminalProcess;

        public MainWindow()
        {
            InitializeComponent();
            fileList.ItemsSource = _entries;

            InitializeFolderTree();
            NavigateTo(GetInitialDirectory(), addToBackHistory: false);
        }

        private static string GetInitialDirectory()
        {
            var home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            if (Directory.Exists(home))
            {
                return home;
            }

            return DriveInfo.GetDrives().FirstOrDefault(d => d.IsReady)?.RootDirectory.FullName ?? "C:\\";
        }

        private void InitializeFolderTree()
        {
            folderTree.Items.Clear();
            foreach (var drive in DriveInfo.GetDrives().Where(d => d.IsReady))
            {
                folderTree.Items.Add(CreateTreeItem(drive.RootDirectory.FullName, drive.Name.TrimEnd('\\')));
            }
        }

        private TreeViewItem CreateTreeItem(string path, string header)
        {
            var item = new TreeViewItem
            {
                Header = header,
                Tag = path
            };

            item.Items.Add(new TreeViewItem { Header = "Loading...", Tag = TreePlaceholderTag });
            item.Expanded += TreeItem_Expanded;
            return item;
        }

        private void TreeItem_Expanded(object sender, RoutedEventArgs e)
        {
            if (sender is not TreeViewItem item || item.Tag is not string path)
            {
                return;
            }

            EnsureTreeItemPopulated(item, path);
            e.Handled = true;
        }

        private static bool HasPlaceholder(TreeViewItem item)
        {
            return item.Items.Count == 1 &&
                item.Items[0] is TreeViewItem placeholder &&
                placeholder.Tag is string tag &&
                tag == TreePlaceholderTag;
        }

        private void EnsureTreeItemPopulated(TreeViewItem item, string path)
        {
            if (!HasPlaceholder(item))
            {
                return;
            }

            item.Items.Clear();
            try
            {
                foreach (var directory in Directory.EnumerateDirectories(path).OrderBy(d => d))
                {
                    var name = Path.GetFileName(directory);
                    item.Items.Add(CreateTreeItem(directory, string.IsNullOrEmpty(name) ? directory : name));
                }
            }
            catch (UnauthorizedAccessException)
            {
                statusText.Text = $"Access denied: {path}";
            }
            catch (Exception ex)
            {
                statusText.Text = $"Failed to load tree item: {ex.Message}";
            }
        }

        private void NavigateTo(string path, bool addToBackHistory = true)
        {
            if (!Directory.Exists(path))
            {
                MessageBox.Show($"Directory not found: {path}");
                return;
            }

            var normalizedPath = Path.GetFullPath(path);
            if (!string.Equals(_currentDirectory, normalizedPath, StringComparison.OrdinalIgnoreCase) &&
                addToBackHistory &&
                !string.IsNullOrWhiteSpace(_currentDirectory))
            {
                _backHistory.Push(_currentDirectory);
            }

            _currentDirectory = normalizedPath;
            currentPathText.Text = _currentDirectory;
            backButton.IsEnabled = _backHistory.Count > 0;

            LoadEntries(_currentDirectory);
            SelectTreePath(_currentDirectory);
            SyncTerminalDirectory();
        }

        private void LoadEntries(string directoryPath)
        {
            _entries.Clear();

            try
            {
                var directories = Directory.EnumerateDirectories(directoryPath)
                    .OrderBy(d => d, StringComparer.OrdinalIgnoreCase);
                foreach (var dir in directories)
                {
                    var info = new DirectoryInfo(dir);
                    _entries.Add(new FileSystemEntry
                    {
                        FullPath = dir,
                        Name = info.Name,
                        Type = "Folder",
                        SizeText = string.Empty,
                        ModifiedText = info.LastWriteTime.ToString("yyyy-MM-dd HH:mm"),
                        IsDirectory = true,
                        IconGlyph = "📁"
                    });
                }

                var files = Directory.EnumerateFiles(directoryPath)
                    .OrderBy(f => f, StringComparer.OrdinalIgnoreCase);
                foreach (var file in files)
                {
                    var info = new FileInfo(file);
                    _entries.Add(new FileSystemEntry
                    {
                        FullPath = file,
                        Name = info.Name,
                        Type = info.Extension.TrimStart('.').ToUpperInvariant(),
                        SizeText = FormatFileSize(info.Length),
                        ModifiedText = info.LastWriteTime.ToString("yyyy-MM-dd HH:mm"),
                        IsDirectory = false,
                        IconGlyph = "📄"
                    });
                }

                statusText.Text = $"{_entries.Count} items";
            }
            catch (UnauthorizedAccessException)
            {
                statusText.Text = $"Access denied: {directoryPath}";
            }
            catch (Exception ex)
            {
                statusText.Text = $"Failed to load contents: {ex.Message}";
            }
        }

        private void SelectTreePath(string path)
        {
            var root = Path.GetPathRoot(path);
            if (string.IsNullOrEmpty(root))
            {
                return;
            }

            var rootNode = folderTree.Items.OfType<TreeViewItem>()
                .FirstOrDefault(item => string.Equals((string)item.Tag, root, StringComparison.OrdinalIgnoreCase));
            if (rootNode == null)
            {
                return;
            }

            _isSelectingTreePath = true;
            try
            {
                rootNode.IsExpanded = true;
                EnsureTreeItemPopulated(rootNode, (string)rootNode.Tag);

                var segments = path
                    .Substring(root.Length)
                    .Split(Path.DirectorySeparatorChar, StringSplitOptions.RemoveEmptyEntries);

                var currentNode = rootNode;
                var currentPath = root.TrimEnd(Path.DirectorySeparatorChar);
                foreach (var segment in segments)
                {
                    currentPath = currentPath + Path.DirectorySeparatorChar + segment;
                    var nextNode = currentNode.Items.OfType<TreeViewItem>()
                        .FirstOrDefault(item => item.Tag is string tag && string.Equals(tag, currentPath, StringComparison.OrdinalIgnoreCase));

                    if (nextNode == null)
                    {
                        break;
                    }

                    nextNode.IsExpanded = true;
                    EnsureTreeItemPopulated(nextNode, (string)nextNode.Tag);
                    currentNode = nextNode;
                }

                currentNode.IsSelected = true;
                currentNode.BringIntoView();
            }
            finally
            {
                _isSelectingTreePath = false;
            }
        }

        private static string FormatFileSize(long length)
        {
            string[] units = { "B", "KB", "MB", "GB", "TB" };
            double size = length;
            int unit = 0;

            while (size >= 1024 && unit < units.Length - 1)
            {
                size /= 1024;
                unit++;
            }

            return $"{size:0.##} {units[unit]}";
        }

        private FileSystemEntry? GetSelectedEntry()
        {
            return fileList.SelectedItem as FileSystemEntry;
        }

        private void FileList_MouseDoubleClick(object sender, MouseButtonEventArgs e)
        {
            var selected = GetSelectedEntry();
            if (selected == null)
            {
                return;
            }

            if (selected.IsDirectory)
            {
                NavigateTo(selected.FullPath);
                return;
            }

            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = selected.FullPath,
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Unable to open file: {ex.Message}");
            }
        }

        private void FolderTree_SelectedItemChanged(object sender, RoutedPropertyChangedEventArgs<object> e)
        {
            if (_isSelectingTreePath)
            {
                return;
            }

            if (e.NewValue is TreeViewItem item && item.Tag is string path)
            {
                NavigateTo(path);
            }
        }

        private void BackButton_Click(object sender, RoutedEventArgs e)
        {
            if (_backHistory.Count == 0)
            {
                return;
            }

            var previous = _backHistory.Pop();
            NavigateTo(previous, addToBackHistory: false);
            backButton.IsEnabled = _backHistory.Count > 0;
        }

        private void UpButton_Click(object sender, RoutedEventArgs e)
        {
            var parent = Directory.GetParent(_currentDirectory);
            if (parent != null)
            {
                NavigateTo(parent.FullName);
            }
        }

        private void RefreshButton_Click(object sender, RoutedEventArgs e)
        {
            LoadEntries(_currentDirectory);
        }

        private void NewFolderButton_Click(object sender, RoutedEventArgs e)
        {
            var folderName = PromptForText("New Folder", "Enter folder name:", "New Folder");
            if (string.IsNullOrWhiteSpace(folderName))
            {
                return;
            }

            try
            {
                var targetPath = ResolvePathConflict(_currentDirectory, folderName, isDirectory: true);
                Directory.CreateDirectory(targetPath);
                LoadEntries(_currentDirectory);
                statusText.Text = $"Created folder: {Path.GetFileName(targetPath)}";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Unable to create folder: {ex.Message}");
            }
        }

        private void CopyMenuItem_Click(object sender, RoutedEventArgs e)
        {
            var selected = GetSelectedEntry();
            if (selected == null)
            {
                return;
            }

            _clipboardPath = selected.FullPath;
            _clipboardIsCut = false;
            statusText.Text = $"Copied: {selected.Name}";
        }

        private void CutMenuItem_Click(object sender, RoutedEventArgs e)
        {
            var selected = GetSelectedEntry();
            if (selected == null)
            {
                return;
            }

            _clipboardPath = selected.FullPath;
            _clipboardIsCut = true;
            statusText.Text = $"Cut: {selected.Name}";
        }

        private void PasteMenuItem_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrWhiteSpace(_clipboardPath) || (!File.Exists(_clipboardPath) && !Directory.Exists(_clipboardPath)))
            {
                return;
            }

            try
            {
                var itemName = Path.GetFileName(_clipboardPath.TrimEnd(Path.DirectorySeparatorChar));
                var isDirectory = Directory.Exists(_clipboardPath);
                var destination = ResolvePathConflict(_currentDirectory, itemName, isDirectory);

                if (_clipboardIsCut)
                {
                    if (isDirectory)
                    {
                        Directory.Move(_clipboardPath, destination);
                    }
                    else
                    {
                        File.Move(_clipboardPath, destination);
                    }

                    _clipboardPath = null;
                    _clipboardIsCut = false;
                }
                else if (isDirectory)
                {
                    CopyDirectory(_clipboardPath, destination);
                }
                else
                {
                    File.Copy(_clipboardPath, destination);
                }

                LoadEntries(_currentDirectory);
                statusText.Text = $"Pasted: {Path.GetFileName(destination)}";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Paste failed: {ex.Message}");
            }
        }

        private void RenameMenuItem_Click(object sender, RoutedEventArgs e)
        {
            var selected = GetSelectedEntry();
            if (selected == null)
            {
                return;
            }

            var newName = PromptForText("Rename", "Enter new name:", selected.Name);
            if (string.IsNullOrWhiteSpace(newName) || string.Equals(newName, selected.Name, StringComparison.OrdinalIgnoreCase))
            {
                return;
            }

            try
            {
                var destination = Path.Combine(_currentDirectory, newName);
                if (File.Exists(destination) || Directory.Exists(destination))
                {
                    MessageBox.Show("A file or folder with that name already exists.");
                    return;
                }

                if (selected.IsDirectory)
                {
                    Directory.Move(selected.FullPath, destination);
                }
                else
                {
                    File.Move(selected.FullPath, destination);
                }

                LoadEntries(_currentDirectory);
                statusText.Text = $"Renamed to: {newName}";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Rename failed: {ex.Message}");
            }
        }

        private void DeleteMenuItem_Click(object sender, RoutedEventArgs e)
        {
            var selected = GetSelectedEntry();
            if (selected == null)
            {
                return;
            }

            var result = MessageBox.Show(
                $"Delete '{selected.Name}'?",
                "Confirm Delete",
                MessageBoxButton.YesNo,
                MessageBoxImage.Warning);
            if (result != MessageBoxResult.Yes)
            {
                return;
            }

            try
            {
                if (selected.IsDirectory)
                {
                    Directory.Delete(selected.FullPath, recursive: true);
                }
                else
                {
                    File.Delete(selected.FullPath);
                }

                LoadEntries(_currentDirectory);
                statusText.Text = $"Deleted: {selected.Name}";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Delete failed: {ex.Message}");
            }
        }

        private static string ResolvePathConflict(string destinationDirectory, string itemName, bool isDirectory)
        {
            var baseName = isDirectory ? itemName : Path.GetFileNameWithoutExtension(itemName);
            var extension = isDirectory ? string.Empty : Path.GetExtension(itemName);
            var candidate = Path.Combine(destinationDirectory, itemName);

            if (!File.Exists(candidate) && !Directory.Exists(candidate))
            {
                return candidate;
            }

            var suffix = " - Copy";
            var copyPath = Path.Combine(destinationDirectory, $"{baseName}{suffix}{extension}");
            if (!File.Exists(copyPath) && !Directory.Exists(copyPath))
            {
                return copyPath;
            }

            int copyIndex = 2;
            while (true)
            {
                var numbered = Path.Combine(destinationDirectory, $"{baseName}{suffix} ({copyIndex}){extension}");
                if (!File.Exists(numbered) && !Directory.Exists(numbered))
                {
                    return numbered;
                }

                copyIndex++;
            }
        }

        private static void CopyDirectory(string sourcePath, string destinationPath)
        {
            var source = new DirectoryInfo(sourcePath);
            Directory.CreateDirectory(destinationPath);

            foreach (var file in source.GetFiles())
            {
                file.CopyTo(Path.Combine(destinationPath, file.Name));
            }

            foreach (var subDirectory in source.GetDirectories())
            {
                CopyDirectory(subDirectory.FullName, Path.Combine(destinationPath, subDirectory.Name));
            }
        }

        private string? PromptForText(string title, string prompt, string defaultValue)
        {
            var dialog = new Window
            {
                Title = title,
                Width = 420,
                Height = 170,
                WindowStartupLocation = WindowStartupLocation.CenterOwner,
                Owner = this,
                ResizeMode = ResizeMode.NoResize,
                Background = System.Windows.Media.Brushes.WhiteSmoke
            };

            var root = new Grid { Margin = new Thickness(12) };
            root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

            var promptBlock = new TextBlock { Text = prompt, Margin = new Thickness(0, 0, 0, 8) };
            Grid.SetRow(promptBlock, 0);

            var input = new TextBox { Text = defaultValue, MinWidth = 360 };
            Grid.SetRow(input, 1);

            var buttons = new StackPanel
            {
                Orientation = Orientation.Horizontal,
                HorizontalAlignment = HorizontalAlignment.Right,
                Margin = new Thickness(0, 12, 0, 0)
            };

            var okButton = new Button { Content = "OK", Width = 72, IsDefault = true };
            var cancelButton = new Button { Content = "Cancel", Width = 72, Margin = new Thickness(8, 0, 0, 0), IsCancel = true };

            okButton.Click += (_, _) => dialog.DialogResult = true;
            cancelButton.Click += (_, _) => dialog.DialogResult = false;

            buttons.Children.Add(okButton);
            buttons.Children.Add(cancelButton);
            Grid.SetRow(buttons, 2);

            root.Children.Add(promptBlock);
            root.Children.Add(input);
            root.Children.Add(buttons);
            dialog.Content = root;

            input.Focus();
            input.SelectAll();

            var result = dialog.ShowDialog();
            return result == true ? input.Text.Trim() : null;
        }

        private void OpenTerminalHere_Click(object sender, RoutedEventArgs e)
        {
            EnsureTerminalStarted();
            SyncTerminalDirectory();
            commandInput.Focus();
        }

        private void EnsureTerminalStarted()
        {
            if (_terminalProcess != null && !_terminalProcess.HasExited)
            {
                return;
            }

            var startInfo = new ProcessStartInfo
            {
                FileName = "cmd.exe",
                WorkingDirectory = _currentDirectory,
                RedirectStandardInput = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            _terminalProcess = new Process { StartInfo = startInfo, EnableRaisingEvents = true };
            _terminalProcess.OutputDataReceived += TerminalOutputReceived;
            _terminalProcess.ErrorDataReceived += TerminalOutputReceived;
            _terminalProcess.Exited += (_, _) => AppendTerminalLine("[terminal exited]");

            _terminalProcess.Start();
            _terminalProcess.BeginOutputReadLine();
            _terminalProcess.BeginErrorReadLine();

            AppendTerminalLine($"[terminal started in {_currentDirectory}]");
        }

        private void SyncTerminalDirectory()
        {
            if (_terminalProcess != null && !_terminalProcess.HasExited)
            {
                SendTerminalCommand($"cd /d \"{_currentDirectory}\"");
            }
        }

        private void RunTerminalCommand_Click(object sender, RoutedEventArgs e)
        {
            ExecuteTerminalInput();
        }

        private void CommandInput_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Enter)
            {
                ExecuteTerminalInput();
                e.Handled = true;
            }
        }

        private void ExecuteTerminalInput()
        {
            var command = commandInput.Text.Trim();
            if (string.IsNullOrWhiteSpace(command))
            {
                return;
            }

            EnsureTerminalStarted();
            AppendTerminalLine($"> {command}");
            SendTerminalCommand(command);
            commandInput.Clear();
        }

        private void SendTerminalCommand(string command)
        {
            if (_terminalProcess == null || _terminalProcess.HasExited)
            {
                return;
            }

            _terminalProcess.StandardInput.WriteLine(command);
            _terminalProcess.StandardInput.Flush();
        }

        private void TerminalOutputReceived(object sender, DataReceivedEventArgs e)
        {
            if (string.IsNullOrEmpty(e.Data))
            {
                return;
            }

            AppendTerminalLine(e.Data);
        }

        private void AppendTerminalLine(string line)
        {
            Dispatcher.Invoke(() =>
            {
                terminalOutput.AppendText(line + Environment.NewLine);
                terminalOutput.ScrollToEnd();
            });
        }

        private void Window_Closing(object? sender, CancelEventArgs e)
        {
            if (_terminalProcess == null || _terminalProcess.HasExited)
            {
                return;
            }

            try
            {
                _terminalProcess.StandardInput.WriteLine("exit");
                _terminalProcess.StandardInput.Flush();
                _terminalProcess.WaitForExit(800);
            }
            catch
            {
                // Process can already be gone while closing.
            }

            if (!_terminalProcess.HasExited)
            {
                _terminalProcess.Kill(true);
            }
        }
    }

    public sealed class FileSystemEntry
    {
        public string FullPath { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public string SizeText { get; set; } = string.Empty;
        public string ModifiedText { get; set; } = string.Empty;
        public bool IsDirectory { get; set; }
        public string IconGlyph { get; set; } = string.Empty;
    }
}
