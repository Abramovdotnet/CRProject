using CommunityToolkit.Mvvm.ComponentModel;
using CRProjectEditor.Models;
using System;
using System.Threading.Tasks;
using System.Windows.Input; // Required for ICommand if we add a close button

namespace CRProjectEditor.ViewModels
{
    public partial class ToastNotificationViewModel : ObservableObject
    {
        [ObservableProperty]
        private string _message;

        [ObservableProperty]
        private ToastType _type;

        [ObservableProperty]
        private bool _isVisible;

        public TimeSpan Duration { get; }
        public event Action<ToastNotificationViewModel>? Dismissed;

        public ToastNotificationViewModel(string message, ToastType type, TimeSpan duration)
        {
            _message = message;
            _type = type;
            Duration = duration;
            _isVisible = false; // Start as not visible, will be set by service/manager
        }

        public async Task ShowAsync()
        {
            IsVisible = true;
            await Task.Delay(Duration);
            IsVisible = false;
            Dismissed?.Invoke(this);
        }

        // Optional: Command to dismiss manually if we add a close button
        // public ICommand DismissCommand { get; }
        // private void Dismiss()
        // {
        // IsVisible = false;
        // Dismissed?.Invoke(this);
        // }
    }
} 