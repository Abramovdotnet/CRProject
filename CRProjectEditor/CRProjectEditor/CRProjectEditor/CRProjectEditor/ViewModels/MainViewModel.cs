using CommunityToolkit.Mvvm.ComponentModel;
using CRProjectEditor.Services;
using CRProjectEditor.ViewModels;
using System.Collections.ObjectModel;
using System.Linq;
using System.Windows;

namespace CRProjectEditor.ViewModels
{
    public partial class MainViewModel : ObservableObject
    {
        private readonly INotificationService _notificationService;

        [ObservableProperty]
        private ObservableObject? _selectedViewModel;

        [ObservableProperty]
        private string _statusMessage = "Ready";

        public ObservableCollection<ObservableObject> TabViewModels { get; }
        public ObservableCollection<ToastNotificationViewModel> ActiveToasts { get; }

        public MainViewModel(INotificationService notificationService)
        {
            _notificationService = notificationService;
            ActiveToasts = new ObservableCollection<ToastNotificationViewModel>();

            TabViewModels = new ObservableCollection<ObservableObject>
            {
                new WorldViewModel(notificationService),
                new NPCsViewModel(notificationService),
                new DialoguesViewModel(),
                new QuestsViewModel(),
                new ItemsViewModel(),
                new AssetViewModel()
            };
            SelectedViewModel = TabViewModels.FirstOrDefault();

            _notificationService.ToastRequested += OnToastRequested;
            _notificationService.StatusUpdated += OnStatusUpdated;
        }

        private void OnToastRequested(ToastNotificationViewModel toastVM)
        {
            Application.Current.Dispatcher.Invoke(() =>
            {
                ActiveToasts.Add(toastVM);
                toastVM.Dismissed += (sender) => Application.Current.Dispatcher.Invoke(() => ActiveToasts.Remove(sender)); 
                _ = toastVM.ShowAsync();
            });
        }

        private void OnStatusUpdated(string message)
        {
            Application.Current.Dispatcher.Invoke(() => StatusMessage = message);
        }
    }
} 