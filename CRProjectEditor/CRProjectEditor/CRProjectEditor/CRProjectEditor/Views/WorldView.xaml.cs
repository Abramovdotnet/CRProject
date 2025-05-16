using System.Windows.Controls;
using CRProjectEditor.ViewModels; // Required for WorldViewModel
using CRProjectEditor.Models;   // Required for Scene
using System.Diagnostics; // For Debug.WriteLine

namespace CRProjectEditor.Views
{
    public partial class WorldView : UserControl
    {
        public WorldView()
        {
            InitializeComponent();
            this.Loaded += WorldView_Loaded;
        }

        private void WorldView_Loaded(object sender, System.Windows.RoutedEventArgs e)
        {
            if (DataContext is WorldViewModel viewModel && InteractiveMap != null)
            {
                InteractiveMap.SceneSelected += (selectedScene) =>
                {
                    Debug.WriteLine($"WorldView: InteractiveMap.SceneSelected event fired. Selected scene: {selectedScene?.Name ?? "null"}");
                    viewModel.MapSelectedScene = selectedScene;
                };
                Debug.WriteLine("WorldView: Subscribed to InteractiveMap.SceneSelected event.");
            }
            else
            {
                 Debug.WriteLine("WorldView: Could not subscribe to InteractiveMap.SceneSelected. ViewModel or InteractiveMap is null.");
                 if (DataContext == null) Debug.WriteLine("WorldView: DataContext is null.");
                 else Debug.WriteLine($"WorldView: DataContext is of type {DataContext.GetType().Name}");
                 if (InteractiveMap == null) Debug.WriteLine("WorldView: InteractiveMap is null.");
            }
        }
    }
} 