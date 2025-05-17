using System.Windows.Controls;
using CRProjectEditor.ViewModels; // Required for WorldViewModel
using CRProjectEditor.Models;   // Required for Scene
using System.Diagnostics; // For Debug.WriteLine
using System.Windows; // Required for DragDrop andDataObject
using System.Windows.Input; // Required for MouseButtonEventArgs
using System.Windows.Data; // For CollectionViewSource (if used for sorting/filtering DataGrid)

namespace CRProjectEditor.Views
{
    public partial class WorldView : UserControl
    {
        private WorldViewModel _viewModel;
        public WorldView()
        {
            InitializeComponent();
            DataContextChanged += (s, e) =>
            {
                if (e.NewValue is WorldViewModel vm)
                {
                    _viewModel = vm;
                    // Ensure the map subscribes after ViewModel is set
                    if (InteractiveMap != null && InteractiveMap.DataContext == null) // Or if it should always re-sync
                    {
                         // If InteractiveMap's DataContext isn't automatically inherited or set,
                         // and it needs the WorldViewModel, you might need to set it here or ensure binding works.
                         // For now, assuming WorldViewModel properties (like Scenes) are correctly bound to InteractiveMap.
                    }
                }
            };

            // If InteractiveMap is already loaded by the time this constructor runs
            // and its DataContext is this UserControl's DataContext:
            Loaded += (s, e) => {
                if (InteractiveMap != null && _viewModel != null)
                {
                    InteractiveMap.SceneSelected += (selectedScene) =>
                    {
                        if (_viewModel != null) _viewModel.MapSelectedScene = selectedScene;
                    };
                    InteractiveMap.ConnectionRequested += async (sourceScene, targetScene) =>
                    {
                        if (_viewModel != null) await _viewModel.AddConnectionFromMapAsync(sourceScene, targetScene);
                    };
                    InteractiveMap.SceneDroppedOnCanvas += async (sceneType, dropPosition) =>
                    {
                        if (_viewModel != null) await _viewModel.AddNewSceneFromMapAsync(sceneType, dropPosition.X, dropPosition.Y);
                    };
                    InteractiveMap.SceneEditRequested += async (sceneToEdit) =>
                    {
                        if (_viewModel != null) await _viewModel.HandleSceneEditRequestAsync(sceneToEdit);
                    };
                    InteractiveMap.AssetDroppedOnScene += async (targetScene, assetInfo) =>
                    {
                        if (_viewModel != null) await _viewModel.ChangeSceneIdFromAssetAsync(targetScene, assetInfo);
                    };
                }
            };
        }

        private void SceneTemplate_MouseDown(object sender, System.Windows.Input.MouseButtonEventArgs e)
        {
            if (sender is FrameworkElement element && element.DataContext is SceneType sceneType)
            {
                DragDrop.DoDragDrop(element, sceneType, DragDropEffects.Copy);
            }
        }

        private void DataGrid_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (DataContext is WorldViewModel viewModel && e.AddedItems.Count > 0 && e.AddedItems[0] is Scene selectedSceneFromGrid)
            {
                // Prevent re-entrancy or feedback loops if selection is already synced
                if (viewModel.MapSelectedScene != selectedSceneFromGrid)
                {
                    viewModel.MapSelectedScene = selectedSceneFromGrid;
                }
            }
        }

        private void Asset_MouseDown(object sender, MouseButtonEventArgs e)
        {
            if (sender is FrameworkElement element && element.DataContext is AssetDisplayInfo assetInfo)
            {
                System.Diagnostics.Debug.WriteLine($"Asset_MouseDown: Initiating drag for Asset ID {assetInfo.AssetId}");
                DragDrop.DoDragDrop(element, assetInfo, DragDropEffects.Copy); // Or Move, depending on desired behavior
            }
        }

        private void AssetScrollViewer_PreviewMouseWheel(object sender, MouseWheelEventArgs e)
        {
            if (sender is ScrollViewer scrollViewer && !e.Handled)
            {
                scrollViewer.ScrollToVerticalOffset(scrollViewer.VerticalOffset - e.Delta);
                e.Handled = true;
            }
        }
    }
} 