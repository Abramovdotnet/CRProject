using CRProjectEditor.Models;
using CRProjectEditor.ViewModels;
using System;
using System.Threading.Tasks;

namespace CRProjectEditor.Services
{
    public interface INotificationService
    {
        event Action<ToastNotificationViewModel> ToastRequested;
        event Action<string> StatusUpdated;

        void ShowToast(string message, ToastType type = ToastType.Info, TimeSpan? duration = null);
        void UpdateStatus(string message);
        void ShowDialog(string title, string message, DialogType type = DialogType.Info, Action? onOk = null, Action? onCancel = null);
        Task<bool> ShowConfirmationDialogAsync(string title, string message);
    }

    // Placeholder for ToastNotificationViewModel - will be created later
    // public class ToastNotificationViewModel {}
} 