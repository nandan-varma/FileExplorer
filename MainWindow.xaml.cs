using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
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
        public ImageBrush folderImage = new ImageBrush();
        public List<Button> buttonlist = new List<Button>();
        public List<Thread> threadlist = new List<Thread>();
        public double btnH = 100;
        public double btnW = 100;
        private void renderButtons(string direct)
        {

            titlebar.Text = direct;
            var dirs = from dir in Directory.EnumerateDirectories(direct) select dir;
            int items = 0;
            foreach (int y in Enumerable.Range(0, dirs.Count()))
            {
                Button tempbutton = Button_creator();
                tempbutton.Content = dirs.ElementAt(y);
                buttonlist.Add(tempbutton);
                LayoutRoot.Children.Add(buttonlist.Last());
                items++;
            }
            details.Text = items.ToString();
        }
        private void RerenderButtons(double _h, double _w)
        {
            double jump = btnW;
            double down = 0;
            var dirs = from dir in Directory.EnumerateDirectories(direct) select dir;
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
            renderButtons((sender as Button).Content.ToString());
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

        public string direct = "D:\\test";
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
            folderImage.ImageSource = new BitmapImage(new Uri("D:\\github code\\FileExplorer\\FileExplorer\\FileBrowser\\images\\folder.png"));
            InitializeComponent();
            titlebar.Text = direct;
            renderButtons(direct);
        }

        private void Window_SizeChanged(object sender, SizeChangedEventArgs e)
        {
            RerenderButtons((sender as Window).Height, (sender as Window).Width);

        }
    }
}
