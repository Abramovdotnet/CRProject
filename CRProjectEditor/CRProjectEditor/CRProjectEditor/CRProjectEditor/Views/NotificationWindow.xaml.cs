using System.Windows;

namespace CRProjectEditor.Views
{
    public partial class NotificationWindow : Window
    {
        public NotificationWindow(string message)
        {
            InitializeComponent();
            Owner = Application.Current.MainWindow; // Устанавливаем владельца для центрирования
            MessageTextBlock.Text = message;
        }

        private void OkButton_Click(object sender, RoutedEventArgs e)
        {
            this.Close();
        }
    }
} 