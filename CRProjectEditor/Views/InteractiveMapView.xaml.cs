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
                Debug.WriteLine($"[InteractiveMapView.SelectedScene SETTER] Trying to set from '{_selectedScene?.Name ?? "null"}' to '{value?.Name ?? "null"}'");
                if (_selectedScene != value)
                {
                    var oldScene = _selectedScene;
                    _selectedScene = value;
                    Debug.WriteLine($"[InteractiveMapView.SelectedScene SETTER] Successfully set to '{_selectedScene?.Name ?? "null"}'. Invoking HighlightScene.");
                    HighlightScene(_selectedScene, oldScene);
                    SceneSelected?.Invoke(this, _selectedScene);
                }
                else
                {
                    Debug.WriteLine($"[InteractiveMapView.SelectedScene SETTER] Value did not change. Current: '{_selectedScene?.Name ?? "null"}'");
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
            Debug.WriteLine("[InteractiveMapView CONSTRUCTOR] Initialized and subscribed to DataContextChanged.");

            this.Loaded += (s, e) => {
                Debug.WriteLine("[InteractiveMapView LOADED] Event triggered.");
                if (Scenes != null)
                {
                    DrawElements(); // Initial draw if scenes are already set
                }
                 // Ensure ViewModel reference is up-to-date on Loaded as well,
                 // as DataContext might be set before Loaded but after constructor.
                if (DataContext is WorldViewModel vm && _viewModel != vm)
                {
                    Debug.WriteLine("[InteractiveMapView LOADED] DataContext is WorldViewModel, _viewModel differs. Calling OnDataContextChanged.");
                    OnDataContextChanged(this, new DependencyPropertyChangedEventArgs(DataContextProperty, _viewModel, vm));
                }
                else if (DataContext == null && _viewModel != null) // Handle DataContext being set to null
                {
                    Debug.WriteLine("[InteractiveMapView LOADED] DataContext is null, _viewModel is not. Calling OnDataContextChanged.");
                     OnDataContextChanged(this, new DependencyPropertyChangedEventArgs(DataContextProperty, _viewModel, null));
                }
                else
                {
                    Debug.WriteLine($"[InteractiveMapView LOADED] DataContext type: {DataContext?.GetType().Name ?? "null"}, _viewModel is {(_viewModel == null ? "null" : "not null")}, No immediate OnDataContextChanged call needed from Loaded.");
                }
            };
        }

        private void OnDataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
        {
            Debug.WriteLine($"[InteractiveMapView.OnDataContextChanged] Triggered. Old ViewModel: {_viewModel?.GetHashCode() ?? 0}, New ViewModel: {e.NewValue?.GetHashCode() ?? 0}");

            if (_viewModel != null)
            {
                Debug.WriteLine("[InteractiveMapView.OnDataContextChanged] Unsubscribing PropertyChanged from old ViewModel.");
                _viewModel.PropertyChanged -= ViewModel_PropertyChanged;
            }

            _viewModel = e.NewValue as WorldViewModel;

            if (_viewModel != null)
            {
                Debug.WriteLine("[InteractiveMapView.OnDataContextChanged] Subscribing PropertyChanged to new ViewModel.");
                _viewModel.PropertyChanged += ViewModel_PropertyChanged;
                Debug.WriteLine($"[InteractiveMapView.OnDataContextChanged] Initial sync check: this.SelectedScene ('{this.SelectedScene?.Name ?? "null"}') vs _viewModel.MapSelectedScene ('{_viewModel.MapSelectedScene?.Name ?? "null"}')");
                if (this.SelectedScene != _viewModel.MapSelectedScene)
                {
                    Debug.WriteLine("[InteractiveMapView.OnDataContextChanged] Initial sync: this.SelectedScene differs from _viewModel.MapSelectedScene. Setting this.SelectedScene.");
                    this.SelectedScene = _viewModel.MapSelectedScene;
                }
            }
            else
            {
                Debug.WriteLine("[InteractiveMapView.OnDataContextChanged] New ViewModel is null.");
            }
        }

        private void ViewModel_PropertyChanged(object? sender, PropertyChangedEventArgs e)
        {
            Debug.WriteLine($"[InteractiveMapView.ViewModel_PropertyChanged] Property '{e.PropertyName}' changed.");
            if (e.PropertyName == nameof(WorldViewModel.MapSelectedScene))
            {
                Debug.WriteLine($"[InteractiveMapView.ViewModel_PropertyChanged] MapSelectedScene changed in ViewModel. Current MapView.SelectedScene: '{this.SelectedScene?.Name ?? "null"}', ViewModel.MapSelectedScene: '{_viewModel?.MapSelectedScene?.Name ?? "null"}'");
                if (_viewModel != null && this.SelectedScene != _viewModel.MapSelectedScene)
                {
                    Debug.WriteLine("[InteractiveMapView.ViewModel_PropertyChanged] MapView.SelectedScene differs from ViewModel.MapSelectedScene. Updating MapView.SelectedScene.");
                    this.SelectedScene = _viewModel.MapSelectedScene;
                }
                else
                {
                     Debug.WriteLine("[InteractiveMapView.ViewModel_PropertyChanged] MapView.SelectedScene is SAME as ViewModel.MapSelectedScene OR ViewModel is null. No update to MapView.SelectedScene.");
                }
            }
        }


        private static void OnScenesChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            var view = (InteractiveMapView)d;
            Debug.WriteLine($"[InteractiveMapView.OnScenesChanged] Scenes collection changed. New count: {view.Scenes?.Count ?? 0}");
            if (e.OldValue is ObservableCollection<Scene> oldScenes)
            {
                oldScenes.CollectionChanged -= view.OnScenesCollectionChanged;
            }
            if (e.NewValue is ObservableCollection<Scene> newScenes)
            {
                newScenes.CollectionChanged += view.OnScenesCollectionChanged;
            }
            if (view.IsLoaded) view.DrawElements(); // Ensure IsLoaded before drawing
        }

        private void OnScenesCollectionChanged(object? sender, System.Collections.Specialized.NotifyCollectionChangedEventArgs e)
        {
            Debug.WriteLine("[InteractiveMapView.OnScenesCollectionChanged] Scenes collection internally changed.");
             if (this.IsLoaded) DrawElements(); // Ensure IsLoaded before drawing
        }

        // ... existing methods like DrawElements, DrawMarkers, DrawConnections, GetSceneTypeBrush ...

        private void HighlightScene(Scene? newSelection, Scene? oldSelection)
        {
            Debug.WriteLine($"[InteractiveMapView.HighlightScene] Highlighting: '{newSelection?.Name ?? "null"}'. De-highlighting: '{oldSelection?.Name ?? "null"}'.");
            // De-highlight oldSelection
            if (oldSelection != null && oldSelection != newSelection) // Check against newSelection to avoid de-highlighting if it's the same
            {
                var oldMarker = FindMarkerByScene(oldSelection);
                if (oldMarker != null)
                {
                    Debug.WriteLine($"[InteractiveMapView.HighlightScene] De-highlighting marker for '{oldSelection.Name}'.");
                    oldMarker.BorderBrush = GetSceneTypeBrush(oldSelection.SceneType);
                    oldMarker.BorderThickness = new Thickness(2); // Default thickness
                }
                else
                { 
                    Debug.WriteLine($"[InteractiveMapView.HighlightScene] Old marker for '{oldSelection.Name}' NOT found for de-highlighting.");
                }
            }

            // Highlight newSelection
            if (newSelection != null)
            {
                var newMarker = FindMarkerByScene(newSelection);
                if (newMarker != null)
                {
                    Debug.WriteLine($"[InteractiveMapView.HighlightScene] Highlighting marker for '{newSelection.Name}'.");
                    newMarker.BorderBrush = Brushes.Gold; // Highlight color
                    newMarker.BorderThickness = new Thickness(4); // Highlight thickness
                    
                    // Bring to front
                    Panel.SetZIndex(newMarker, _zIndexCounter++);
                }
                else
                {
                    Debug.WriteLine($"[InteractiveMapView.HighlightScene] New marker for '{newSelection.Name}' NOT found for highlighting.");
                }
            }
        }
        
        private Border? FindMarkerByScene(Scene scene)
        {
            if (scene == null) 
            {
                Debug.WriteLine("[InteractiveMapView.FindMarkerByScene] Scene parameter is null.");
                return null;
            }
            Debug.WriteLine($"[InteractiveMapView.FindMarkerByScene] Searching for marker for scene ID: {scene.Id}, Name: {scene.Name}");
            foreach (var child in MapCanvas.Children)
            {
                if (child is Border marker && marker.Tag is Scene markerScene && markerScene.Id == scene.Id)
                {
                    Debug.WriteLine($"[InteractiveMapView.FindMarkerByScene] Found marker for scene ID: {scene.Id}");
                    return marker;
                }
            }
            Debug.WriteLine($"[InteractiveMapView.FindMarkerByScene] Marker NOT found for scene ID: {scene.Id}");
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