using System.Windows.Controls;
using CRProjectEditor.ViewModels; // Required for WorldViewModel
using CRProjectEditor.Models;   // Required for Scene
using System.Diagnostics; // For Debug.WriteLine
using System.Windows; // Required for DragDrop andDataObject
using System.Windows.Input; // Required for MouseButtonEventArgs

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

                // Subscribe to the new ConnectionRequested event
                InteractiveMap.ConnectionRequested += async (sourceScene, targetScene) =>
                {
                    Debug.WriteLine($"WorldView: InteractiveMap.ConnectionRequested event fired. Source: {sourceScene?.Name ?? "null"}, Target: {targetScene?.Name ?? "null"}");
                    if (sourceScene != null && targetScene != null) // Basic null check before calling VM
                    {
                        await viewModel.AddConnectionFromMapAsync(sourceScene, targetScene);
                    }
                };
                Debug.WriteLine("WorldView: Subscribed to InteractiveMap.ConnectionRequested event.");

                // Subscribe to the SceneDroppedOnCanvas event
                InteractiveMap.SceneDroppedOnCanvas += async (sceneType, logicalPoint) =>
                {
                    Debug.WriteLine($"WorldView: InteractiveMap.SceneDroppedOnCanvas event fired. Type: {sceneType}, Point: ({logicalPoint.X}, {logicalPoint.Y})");
                    await viewModel.AddNewSceneFromMapAsync(sceneType, logicalPoint.X, logicalPoint.Y);
                };
                Debug.WriteLine("WorldView: Subscribed to InteractiveMap.SceneDroppedOnCanvas event.");

                // Subscribe to the SceneEditRequested event
                InteractiveMap.SceneEditRequested += (sceneToEdit) =>
                {
                    Debug.WriteLine($"WorldView: InteractiveMap.SceneEditRequested event fired. Scene to edit: {sceneToEdit?.Name ?? "null"}");
                    if (sceneToEdit != null)
                    {
                        viewModel.HandleSceneEditRequestAsync(sceneToEdit); // Назовем метод так
                    }
                };
                Debug.WriteLine("WorldView: Subscribed to InteractiveMap.SceneEditRequested event.");
            }
            else
            {
                 Debug.WriteLine("WorldView: Could not subscribe to InteractiveMap.SceneSelected. ViewModel or InteractiveMap is null.");
                 if (DataContext == null) Debug.WriteLine("WorldView: DataContext is null.");
                 else Debug.WriteLine($"WorldView: DataContext is of type {DataContext.GetType().Name}");
                 if (InteractiveMap == null) Debug.WriteLine("WorldView: InteractiveMap is null.");
            }
        }

        private void SceneTemplate_MouseDown(object sender, MouseButtonEventArgs e)
        {
            if (sender is FrameworkElement fe && fe.DataContext is SceneType sceneType)
            {
                DragDrop.DoDragDrop(fe, new DataObject(typeof(SceneType).FullName, sceneType), DragDropEffects.Copy);
            }
        }
    }
} 