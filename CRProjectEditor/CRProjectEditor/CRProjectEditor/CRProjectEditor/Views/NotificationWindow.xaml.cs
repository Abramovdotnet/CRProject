using CRProjectEditor.Models; // Added for DialogType
using System.Windows;

namespace CRProjectEditor.Views
{
    public partial class NotificationWindow : Window
    {
        public string DialogTitle { get; set; }
        public string Message { get; set; }

        public Visibility OkButtonVisibility { get; private set; } = Visibility.Collapsed;
        public Visibility CancelButtonVisibility { get; private set; } = Visibility.Collapsed;
        public Visibility YesButtonVisibility { get; private set; } = Visibility.Collapsed;
        public Visibility NoButtonVisibility { get; private set; } = Visibility.Collapsed;

        // Конструктор для старой версии, если где-то используется напрямую (будет удален позже)
        public NotificationWindow(string message) : this("Уведомление", message, DialogType.Info) {}

        public NotificationWindow(string title, string message, DialogType dialogType)
        {
            InitializeComponent();
            Owner = Application.Current.MainWindow;
            DialogTitle = title;
            Message = message;
            Title = DialogTitle; // Set window title
            // MessageTextBlock.Text = Message; // Will be bound in XAML

            SetupButtons(dialogType);
            DataContext = this; // Set DataContext for bindings
        }

        private void SetupButtons(DialogType dialogType)
        {
            switch (dialogType)
            {
                case DialogType.Info:
                case DialogType.Error:
                    OkButtonVisibility = Visibility.Visible;
                    break;
                case DialogType.Confirmation:
                case DialogType.Warning:
                    OkButtonVisibility = Visibility.Visible;
                    CancelButtonVisibility = Visibility.Visible;
                    break;
                // TODO: Add cases for Yes/No and Yes/No/Cancel if DialogType is extended
            }
        }

        private void OkButton_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = true;
            Close();
        }

        private void CancelButton_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
            Close();
        }

        private void YesButton_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = true; // Or a custom result if needed
            Close();
        }

        private void NoButton_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = false; // Or a custom result if needed
            Close();
        }
    }
} 