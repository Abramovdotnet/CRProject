using CRProjectEditor.Models;
using CRProjectEditor.ViewModels;
using CRProjectEditor.Views;
using System;
using System.Windows;

namespace CRProjectEditor.Services
{
    public class NotificationService : INotificationService
    {
        public event Action<ToastNotificationViewModel>? ToastRequested;
        public event Action<string>? StatusUpdated;

        public void ShowToast(string message, ToastType type = ToastType.Info, TimeSpan? duration = null)
        {
            var toastDuration = duration ?? TimeSpan.FromSeconds(5); // Default duration if not provided
            var toastVM = new ToastNotificationViewModel(message, type, toastDuration);
            ToastRequested?.Invoke(toastVM);
        }

        public void UpdateStatus(string message)
        {
            StatusUpdated?.Invoke(message);
        }

        public void ShowDialog(string title, string message, DialogType type = DialogType.Info, Action? onOk = null, Action? onCancel = null)
        {
            Application.Current.Dispatcher.Invoke(() => // Ensure UI operations on UI thread
            {
                var dialog = new NotificationWindow(title, message, type)
                {
                    Owner = Application.Current.MainWindow,
                    WindowStartupLocation = WindowStartupLocation.CenterOwner
                };

                var result = dialog.ShowDialog();

                if (result == true)
                {
                    onOk?.Invoke();
                }
                else // Catches false (Cancel/No) and null (closed via X button, usually treated as Cancel)
                {
                    onCancel?.Invoke();
                }
            });
        }
    }
} 