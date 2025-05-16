using CRProjectEditor.ViewModels;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using CRProjectEditor.Models; // Required for Scene model

namespace CRProjectEditor.Views
{
    public partial class WorldView : UserControl
    {
        private WorldViewModel viewModel;

        public WorldView()
        {
            InitializeComponent();
            Loaded += WorldView_Loaded;
        }

        private void WorldView_Loaded(object sender, RoutedEventArgs e)
        {
            // Ensure DataContext is WorldViewModel
            if (DataContext is WorldViewModel vm)
            {
                viewModel = vm;
                InteractiveMap.SceneSelected += InteractiveMap_SceneSelected;
                InteractiveMap.ConnectionRequested += InteractiveMap_ConnectionRequested;
                InteractiveMap.SceneDroppedOnCanvas += InteractiveMap_SceneDroppedOnCanvas;
                InteractiveMap.SceneEditRequested += InteractiveMap_SceneEditRequested;
            }
        }

        private void InteractiveMap_SceneSelected(object sender, Scene e)
        {
            if (viewModel != null)
            {
                viewModel.MapSelectedScene = e;
            }
        }

        private async void InteractiveMap_ConnectionRequested(object sender, (Scene sourceScene, Scene targetScene) e)
        {
            if (viewModel != null)
            {
                await viewModel.AddConnectionFromMapAsync(e.sourceScene, e.targetScene);
            }
        }
        
        private void SceneTemplate_MouseDown(object sender, MouseButtonEventArgs e)
        {
            if (sender is FrameworkElement fe && fe.DataContext is SceneType sceneType)
            {
                DragDrop.DoDragDrop(fe, sceneType, DragDropEffects.Copy);
            }
        }

        private async void InteractiveMap_SceneDroppedOnCanvas(object sender, (SceneType type, Point dropPosition) e)
        {
            if (viewModel != null)
            {
                await viewModel.AddNewSceneFromMapAsync(e.type, e.dropPosition.X, e.dropPosition.Y);
            }
        }

        private async void InteractiveMap_SceneEditRequested(object sender, Scene sceneToEdit)
        {
            if (viewModel != null)
            {
                await viewModel.HandleSceneEditRequestAsync(sceneToEdit);
            }
        }

        private void DataGrid_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (viewModel != null && e.AddedItems.Count > 0 && e.AddedItems[0] is Scene selectedScene)
            {
                viewModel.MapSelectedScene = selectedScene;
                // Optionally, if the map doesn't automatically update focus/view based on MapSelectedScene change:
                // InteractiveMap.FocusScene(selectedScene); 
            }
        }
    }
}
