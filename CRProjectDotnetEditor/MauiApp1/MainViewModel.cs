using CommunityToolkit.Mvvm.ComponentModel;

namespace MauiApp1; // Or MauiApp1.ViewModels if you prefer to keep it there

public partial class MainViewModel : ObservableObject
{
    public MainViewModel()
    {
    }
    // This ViewModel is now mostly empty.
    // It can be used for app-wide logic if needed in the future,
    // or removed if AppShell directly handles all navigation and no global VM is needed.
} 