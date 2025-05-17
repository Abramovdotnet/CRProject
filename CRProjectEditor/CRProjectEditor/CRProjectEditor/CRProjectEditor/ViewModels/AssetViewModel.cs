using CommunityToolkit.Mvvm.ComponentModel;
using CRProjectEditor.Models;
using System.Collections.ObjectModel;

namespace CRProjectEditor.ViewModels
{
    public class AssetViewModel : ObservableObject
    {
        public string ViewModelDisplayName => "Assets";

        private ObservableCollection<AssetDisplayInfo> _assets;
        public ObservableCollection<AssetDisplayInfo> Assets
        {
            get => _assets;
            set => SetProperty(ref _assets, value);
        }

        public AssetViewModel()
        {
            LoadAssets();
        }

        private void LoadAssets()
        {
            // Sample Assets - replace with actual data loading logic later
            Assets = new ObservableCollection<AssetDisplayInfo>
            {

            };
        }
    }
} 