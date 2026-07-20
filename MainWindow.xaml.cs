using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace FileBrowser
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public ImageBrush folderImage = new();
        public List<Button> buttonlist = new();
        public double btnH = 100;
        public double btnW = 100;
        private List<Button> GetDirectories(string direct)
        {
            titlebar.Text = direct;
            var dirs = from dir in Directory.EnumerateDirectories(direct) select dir;
            foreach (int y in Enumerable.Range(0, dirs.Count()))
            {
                Button tempbutton = Button_creator();
                tempbutton.Content = dirs.ElementAt(y);
                buttonlist.Add(tempbutton);
                LayoutRoot.Children.Add(buttonlist.Last());
            }
            details.Text = dirs.Count().ToString();
            return buttonlist;
        }
        private void RenderButtons(List<Button> buttonlist, double _h, double _w)
        {

            double jump = btnW;
            double down = 0;
            foreach (Button tempbutton in buttonlist)
            {
                button_customizer(tempbutton);
                if (jump + 2 * btnW > _w)
                {
                    jump = btnW;
                    down += btnH;
                }
                Canvas.SetLeft(tempbutton, jump);
                Canvas.SetTop(tempbutton, down);
                jump += btnW;
            }
            scrollingbar.Height = _h;
        }
        private void button_click(object sender, RoutedEventArgs e)
        {
            unrenderButtons();
            direct = (sender as Button).Content.ToString();
            RenderButtons(GetDirectories((sender as Button).Content.ToString()), mainwindow.Height, mainwindow.Width);
        }

        private void unrenderButtons()
        {
            foreach (Button butt in buttonlist)
            {
                LayoutRoot.Children.Remove(butt);
            }
            buttonlist.Clear();
        }
        private Button Button_creator()
        {
            return button_customizer(new Button());
        }
        private Button button_customizer(Button tempbutton)
        {
            tempbutton.Width = 90;
            tempbutton.Height = 90;
            tempbutton.Click += button_click;
            tempbutton.Background = folderImage;
            tempbutton.Foreground = Brushes.White;
            tempbutton.BorderThickness = new Thickness(0);
            tempbutton.ContextMenu = RightClickMenu(new ContextMenu());
            return tempbutton;
        }

        public string direct = "D:\\";
        private ContextMenu RightClickMenu(ContextMenu tempContext)
        {
            MenuItem Cpybtn = new MenuItem();
            Cpybtn.Header = "Copy";
            Cpybtn.Click += Cpybtn_Click;
            tempContext.Items.Add(Cpybtn);
            return tempContext;
        }

        private void Cpybtn_Click(object sender, RoutedEventArgs e)
        {
            MessageBox.Show(sender.ToString());
        }

        public MainWindow()
        {
            ContextMenu buttonContext = new ContextMenu();
            folderImage.ImageSource = new BitmapImage(new Uri(@"..\\..\\..\\FileBrowser\\images\\folder.png", UriKind.Relative));
            // D:\github code\FileExplorer\FileExplorer\FileBrowser\images\folder.png
            InitializeComponent();
            titlebar.Text = direct;
            RenderButtons(GetDirectories(direct), mainwindow.Height, mainwindow.Width);
            InitializeFolderTree(direct);
        }

        private void WindowSizeChanged(object sender, SizeChangedEventArgs e)
        {
            double _h = (sender as Window).Height;
            double _w = (sender as Window).Width;

            RenderButtons(GetDirectories(direct), _h, _w);
        }

        // --- Folder tree sidebar -------------------------------------------------
        // Lazily populated: each node starts with a single "Loading..."
        // placeholder child so the expand arrow shows without eagerly
        // enumerating the whole filesystem, and is replaced with the real
        // subfolder list the first time it's expanded.

        private void InitializeFolderTree(string rootPath)
        {
            folderTree.Items.Clear();
            folderTree.Items.Add(CreateFolderTreeItem(rootPath, rootPath));
        }

        private TreeViewItem CreateFolderTreeItem(string path, string headerText)
        {
            var item = new TreeViewItem
            {
                Header = headerText,
                Tag = path,
                Foreground = Brushes.WhiteSmoke
            };
            item.Items.Add(new TreeViewItem { Header = "Loading..." });
            item.Expanded += TreeViewItem_Expanded;
            return item;
        }

        private void PopulateChildren(TreeViewItem parentItem, string path)
        {
            try
            {
                foreach (var dir in Directory.EnumerateDirectories(path))
                {
                    var name = Path.GetFileName(dir);
                    if (string.IsNullOrEmpty(name)) name = dir;
                    parentItem.Items.Add(CreateFolderTreeItem(dir, name));
                }
            }
            catch (UnauthorizedAccessException)
            {
                // Skip folders we don't have permission to list (e.g. System Volume Information).
            }
        }

        private void TreeViewItem_Expanded(object sender, RoutedEventArgs e)
        {
            if (!(sender is TreeViewItem item)) return;

            // Only the placeholder child means this node hasn't been
            // populated yet - replace it with the real subfolder list.
            if (item.Items.Count == 1 &&
                item.Items[0] is TreeViewItem placeholder &&
                placeholder.Header is string text && text == "Loading...")
            {
                item.Items.Clear();
                if (item.Tag is string path)
                {
                    PopulateChildren(item, path);
                }
            }
        }

        private void FolderTree_SelectedItemChanged(object sender, RoutedPropertyChangedEventArgs<object> e)
        {
            if (e.NewValue is TreeViewItem item && item.Tag is string path)
            {
                unrenderButtons();
                direct = path;
                RenderButtons(GetDirectories(path), mainwindow.Height, mainwindow.Width);
            }
        }

        // --- Open Terminal Here ---------------------------------------------------

        private void OpenTerminalHere_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "cmd.exe",
                    WorkingDirectory = direct,
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Could not open a terminal here: {ex.Message}");
            }
        }
    }
}
