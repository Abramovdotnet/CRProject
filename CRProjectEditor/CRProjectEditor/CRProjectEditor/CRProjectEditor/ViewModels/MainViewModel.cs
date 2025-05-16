using CommunityToolkit.Mvvm.ComponentModel;
using System.Collections.ObjectModel;
using System.Linq;

namespace CRProjectEditor.ViewModels
{
    public partial class MainViewModel : ObservableObject
    {
        [ObservableProperty]
        private ObservableObject? _selectedViewModel;

        public ObservableCollection<ObservableObject> TabViewModels { get; }

        public MainViewModel()
        {
            TabViewModels = new ObservableCollection<ObservableObject>
            {
                new WorldViewModel(),
                new NPCsViewModel(),
                new DialoguesViewModel(),
                new QuestsViewModel(),
                new ItemsViewModel()
            };
            SelectedViewModel = TabViewModels.FirstOrDefault();
        }
    }
} 