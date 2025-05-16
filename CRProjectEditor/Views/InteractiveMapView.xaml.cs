using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using CRProjectEditor.Models;
using System.Diagnostics; // For Debug.WriteLine
using System.Windows.Controls.Primitives; // For Thumb (if used for advanced drag)
using CRProjectEditor.ViewModels; // Added for WorldViewModel
using System.ComponentModel; // Added for PropertyChangedEventHandler

namespace CRProjectEditor.Views
{
    public partial class InteractiveMapView : UserControl
    {
        // ... existing fields ...
        private Scene? _selectedScene;
        private WorldViewModel? _viewModel; // Added

        // Events
        public event EventHandler<Scene> SceneSelected;
        public event EventHandler<(Scene sourceScene, Scene targetScene)> ConnectionRequested;
        public event EventHandler<(SceneType type, Point dropPosition)> SceneDroppedOnCanvas;
        public event EventHandler<Scene> SceneEditRequested;


        public static readonly DependencyProperty ScenesProperty =
            DependencyProperty.Register("Scenes", typeof(ObservableCollection<Scene>), typeof(InteractiveMapView), new PropertyMetadata(null, OnScenesChanged));

        public ObservableCollection<Scene> Scenes
        {
            get { return (ObservableCollection<Scene>)GetValue(ScenesProperty); }
            set { SetValue(ScenesProperty, value); }
        }

        public Scene? SelectedScene
        {
            get => _selectedScene;
            set
            {
                if (_selectedScene != value)
                {
                    var oldScene = _selectedScene;
                    _selectedScene = value;
                    HighlightScene(_selectedScene, oldScene);
                    SceneSelected?.Invoke(this, _selectedScene); // This event updates the ViewModel
                }
            }
        }
        // ... existing constructor ...
        public InteractiveMapView()
        {
            InitializeComponent();
            MapCanvas.MouseWheel += MapCanvas_MouseWheel;
            MapCanvas.MouseLeftButtonDown += MapCanvas_MouseLeftButtonDown;
            MapCanvas.MouseMove += MapCanvas_MouseMove;
            MapCanvas.MouseLeftButtonUp += MapCanvas_MouseLeftButtonUp; // Changed from MapCanvas_MouseUp

            // Subscribe to DataContextChanged
            DataContextChanged += OnDataContextChanged;

            this.Loaded += (s, e) => {
                if (Scenes != null)
                {
                    DrawElements(); // Initial draw if scenes are already set
                }
                 // Ensure ViewModel reference is up-to-date on Loaded as well,
                 // as DataContext might be set before Loaded but after constructor.
                if (DataContext is WorldViewModel vm && _viewModel != vm)
                {
                    OnDataContextChanged(this, new DependencyPropertyChangedEventArgs(DataContextProperty, _viewModel, vm));
                }
                else if (DataContext == null && _viewModel != null) // Handle DataContext being set to null
                {
                     OnDataContextChanged(this, new DependencyPropertyChangedEventArgs(DataContextProperty, _viewModel, null));
                }
            };
        }

        private void OnDataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
        {
            if (_viewModel != null)
            {
                _viewModel.PropertyChanged -= ViewModel_PropertyChanged;
            }

            _viewModel = e.NewValue as WorldViewModel;

            if (_viewModel != null)
            {
                _viewModel.PropertyChanged += ViewModel_PropertyChanged;
                // Initial sync from ViewModel to MapView's SelectedScene
                if (this.SelectedScene != _viewModel.MapSelectedScene)
                {
                    this.SelectedScene = _viewModel.MapSelectedScene;
                }
            }
        }

        private void ViewModel_PropertyChanged(object? sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == nameof(WorldViewModel.MapSelectedScene))
            {
                if (_viewModel != null && this.SelectedScene != _viewModel.MapSelectedScene)
                {
                    this.SelectedScene = _viewModel.MapSelectedScene; // This will trigger HighlightScene via its setter
                }
            }
        }


        private static void OnScenesChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            // ... existing code ...
        }

        // ... existing methods like DrawElements, DrawMarkers, DrawConnections, GetSceneTypeBrush ...

        private void HighlightScene(Scene? newSelection, Scene? oldSelection)
        {
            // De-highlight oldSelection
            if (oldSelection != null && oldSelection != newSelection) // Check against newSelection to avoid de-highlighting if it's the same
            {
                var oldMarker = FindMarkerByScene(oldSelection);
                if (oldMarker != null)
                {
                    oldMarker.BorderBrush = GetSceneTypeBrush(oldSelection.SceneType);
                    oldMarker.BorderThickness = new Thickness(2); // Default thickness
                }
            }

            // Highlight newSelection
            if (newSelection != null)
            {
                var newMarker = FindMarkerByScene(newSelection);
                if (newMarker != null)
                {
                    newMarker.BorderBrush = Brushes.Gold; // Highlight color
                    newMarker.BorderThickness = new Thickness(4); // Highlight thickness
                    
                    // Bring to front
                    Panel.SetZIndex(newMarker, _zIndexCounter++);
                }
            }
        }
        
        private Border? FindMarkerByScene(Scene scene)
        {
            if (scene == null) return null;
            foreach (var child in MapCanvas.Children)
            {
                if (child is Border marker && marker.Tag is Scene markerScene && markerScene.Id == scene.Id)
                {
                    return marker;
                }
            }
            return null;
        }

        // ... other event handlers like MapCanvas_MouseWheel, MapCanvas_MouseLeftButtonDown etc. ...
        // Ensure Marker_MouseLeftButtonDown sets this.SelectedScene
        private void Marker_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            // ... (existing logic for drag start or connection drawing start) ...
            
            if (sender is FrameworkElement element && element.Tag is Scene scene)
            {
                 // Prioritize drag/connection initiation over simple selection if modifiers are pressed
                bool isCtrlPressed = Keyboard.IsKeyDown(Key.LeftCtrl) || Keyboard.IsKeyDown(Key.RightCtrl);

                if (isCtrlPressed && e.ClickCount == 1) // Connection drawing
                {
                    // ... (existing connection drawing initiation) ...
                }
                else if (e.ClickCount == 1 && !isCtrlPressed) // Regular selection or drag start
                {
                     // If it's not already selected or if we allow re-selecting to start drag:
                    if (SelectedScene != scene || _draggedMarker == null) // Ensure selection happens if not dragging
                    {
                        SelectedScene = scene; // This triggers highlight and SceneSelected event
                    }
                    // ... (existing drag initiation) ...
                }
                 // Double click logic is handled by Marker_MouseDoubleClick or manual detection
            }
            // ... (e.Handled logic)
        }
// ... existing code ...

    }
}