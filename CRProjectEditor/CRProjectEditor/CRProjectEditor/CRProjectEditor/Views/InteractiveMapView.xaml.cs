using CRProjectEditor.Models;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.Diagnostics;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using System.ComponentModel; // Required for DesignerProperties
using CRProjectEditor.Tools;
using System.IO; // Added for File.Exists
using System.Windows.Media.Imaging; // Added for BitmapImage

namespace CRProjectEditor.Views
{
    public partial class InteractiveMapView : UserControl
    {
        private Point? lastMousePosition;
        private ScaleTransform scaleTransform;
        private TranslateTransform translateTransform;
        private double wpfRenderScale = 30.0; // Было 30.0

        // Stores pre-calculated, scaled, and offset positions for scene centers
        private Dictionary<int, Point> scenesRenderInfo = new Dictionary<int, Point>();

        private readonly Dictionary<int, FrameworkElement> _sceneMarkers = new Dictionary<int, FrameworkElement>();
        private readonly List<Shape> _connectionLines = new List<Shape>();

        private Point _panLastMousePosition;
        private bool _isPanning = false;
        
        // Fields for marker dragging
        private FrameworkElement? _draggedMarker;
        private Scene? _draggedScene;
        private Point _markerDragStartOffset; // Offset from marker's top-left to mouse click point
        private bool _isDraggingMarker = false;
        // Store lines connected to each scene for easier update during drag
        private Dictionary<int, List<Line>> _sceneAssociatedLines = new Dictionary<int, List<Line>>();

        // Fields for new connection drawing
        private bool _isDrawingConnectionMode = false;
        private Scene? _connectionSourceScene;
        private Line? _tempConnectionLine;

        // Event for requesting a new connection
        public event Action<Scene, Scene>? ConnectionRequested;

        // Event for requesting a new scene to be created
        public event Action<SceneType, Point>? SceneDroppedOnCanvas;

        // Event for requesting a scene to be edited
        public event Action<Scene>? SceneEditRequested; 

        // Event for asset dropped on scene
        public event Action<Scene, AssetDisplayInfo>? AssetDroppedOnScene;

        // Fields for coordinate transformation
        private double _currentRenderMinX;
        private double _currentRenderMinY;
        // private double _currentRenderContentWidth; // Removed as per previous cleanup
        // private double _currentRenderContentHeight; // Removed as per previous cleanup
        // private double _canvasActualWidth; // Removed as per previous cleanup
        // private double _canvasActualHeight; // Removed as per previous cleanup
        private double _currentWpfRenderScale;
        private double _currentOffsetX;
        private double _currentOffsetY;

        // Selected Scene
        private Scene? _selectedScene;
        public Scene? SelectedScene 
        {
            get => _selectedScene;
            private set
            {
                if (_selectedScene != value)
                {
                    // Restore border of previously selected marker
                    if (_selectedScene != null && _sceneMarkers.TryGetValue(_selectedScene.Id, out var prevMarker))
                    {
                        if (prevMarker is Border b) b.BorderBrush = Brushes.DarkSlateGray; // Default border
                    }
                    
                    _selectedScene = value;
                    
                    // Highlight new selected marker
                    if (_selectedScene != null && _sceneMarkers.TryGetValue(_selectedScene.Id, out var currentMarker))
                    {
                         if (currentMarker is Border b) b.BorderBrush = Brushes.Gold; // Highlight border
                    }
                    SceneSelected?.Invoke(_selectedScene);
                }
            }
        }
        public event Action<Scene?>? SceneSelected;

        // Helper to get color for scene type
        private Brush GetSceneTypeBrush(SceneType sceneType)
        {
            switch (sceneType)
            {
                // General
                case SceneType.Town: return Brushes.LightSteelBlue; 
                case SceneType.Castle: return Brushes.SlateGray;
                // Districts
                case SceneType.District: return Brushes.LightSlateGray; 
                // Religious Buildings
                case SceneType.Cathedral: return Brushes.LightGoldenrodYellow; 
                case SceneType.Cloister: return Brushes.Wheat; 
                case SceneType.Cemetery: return Brushes.DarkOliveGreen; 
                case SceneType.Temple: return Brushes.Gold;
                case SceneType.Crypt: return Brushes.DarkSlateGray;
                // Administrative Buildings
                case SceneType.Manor: return Brushes.Tan; 
                case SceneType.Military: return Brushes.IndianRed; 
                // Commercial Buildings
                case SceneType.Blacksmith: return Brushes.DarkGray;
                case SceneType.AlchemistShop: return Brushes.MediumPurple; 
                case SceneType.Warehouse: return Brushes.RosyBrown; 
                case SceneType.Bookstore: return Brushes.NavajoWhite; 
                case SceneType.Shop: return Brushes.Plum; 
                case SceneType.Mine: return Brushes.DimGray;
                // Entertainment Buildings
                case SceneType.Tavern: return Brushes.OrangeRed;
                case SceneType.Brothel: return Brushes.DeepPink; 
                case SceneType.Bathhouse: return Brushes.Turquoise; 
                // Public Spaces
                case SceneType.Square: return Brushes.LightSalmon;
                case SceneType.Docks: return Brushes.SteelBlue; 
                case SceneType.Road: return Brushes.SandyBrown;
                // Natural/Wilderness
                case SceneType.Forest: return Brushes.DarkGreen;
                case SceneType.Cave: return Brushes.SaddleBrown;
                case SceneType.Ruins: return Brushes.Peru;
                // Misc
                case SceneType.House: return Brushes.LightSkyBlue; 
                case SceneType.Dungeon: return Brushes.Indigo;
                default: return Brushes.Gainsboro; 
            }
        }

        // Поля для отслеживания двойного клика
        private DateTime _lastMarkerClickTime = DateTime.MinValue;
        private Point _lastMarkerClickPosition;
        private FrameworkElement? _lastClickedMarker = null;
        private const int DoubleClickTime = 500; // мс, стандартное время для двойного клика Windows

        public InteractiveMapView()
        {
            InitializeComponent();
            Debug.WriteLine("InteractiveMapView: Constructor called.");
            scaleTransform = new ScaleTransform(1, 1);
            translateTransform = new TranslateTransform(0, 0);

            TransformGroup transformGroup = new TransformGroup();
            transformGroup.Children.Add(scaleTransform);
            transformGroup.Children.Add(translateTransform);
            MapCanvas.RenderTransform = transformGroup;

            MapCanvas.MouseWheel += MapCanvas_MouseWheel;
            MapCanvas.MouseMove += MapCanvas_MouseMove;
            MapCanvas.MouseDown += MapCanvas_MouseDown;
            MapCanvas.MouseUp += MapCanvas_MouseUp;

            // Add drag-drop event handlers
            MapCanvas.DragEnter += MapCanvas_DragEnter;
            MapCanvas.DragOver += MapCanvas_DragOver;
            MapCanvas.Drop += MapCanvas_Drop;

            this.Loaded += UserControl_Loaded; 
            MapCanvas.SizeChanged += MapCanvas_SizeChanged; 
        }

        private void UserControl_Loaded(object sender, RoutedEventArgs e)
        {
            Debug.WriteLine("InteractiveMapView: UserControl_Loaded called.");
            DrawMap();
        }

        private void MapCanvas_SizeChanged(object sender, SizeChangedEventArgs e)
        {
            Debug.WriteLine($"InteractiveMapView: MapCanvas_SizeChanged called. New size: {e.NewSize.Width}x{e.NewSize.Height}");
            DrawMap();
        }

        public static readonly DependencyProperty ScenesProperty =
            DependencyProperty.Register("Scenes", typeof(ObservableCollection<Scene>), typeof(InteractiveMapView),
            new PropertyMetadata(null, OnScenesChanged));

        public ObservableCollection<Scene> Scenes
        {
            get { return (ObservableCollection<Scene>)GetValue(ScenesProperty); }
            set { SetValue(ScenesProperty, value); }
        }

        private static void OnScenesChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            InteractiveMapView view = (InteractiveMapView)d;
            Debug.WriteLine("InteractiveMapView: OnScenesChanged called.");
            if (e.OldValue is ObservableCollection<Scene> oldCollection)
            {
                oldCollection.CollectionChanged -= view.Scenes_CollectionChanged;
            }
            if (e.NewValue is ObservableCollection<Scene> newCollection)
            {
                newCollection.CollectionChanged += view.Scenes_CollectionChanged;
                Debug.WriteLine($"InteractiveMapView: OnScenesChanged - New collection has {newCollection.Count} scenes.");
            }
            else
            {
                Debug.WriteLine("InteractiveMapView: OnScenesChanged - New collection is null.");
            }
            view.DrawMap();
        }

        private void Scenes_CollectionChanged(object? sender, NotifyCollectionChangedEventArgs e)
        {
            Debug.WriteLine("InteractiveMapView: Scenes_CollectionChanged called.");
            DrawMap();
        }

        private void PopulateScenesRenderInfo()
        {
            Debug.WriteLine("InteractiveMapView: PopulateScenesRenderInfo called.");
            scenesRenderInfo.Clear();

            Debug.WriteLine("InteractiveMapView: PopulateScenesRenderInfo - Checking Scenes and MapCanvas dimensions.");
            if (Scenes == null || !Scenes.Any() || MapCanvas.ActualWidth == 0 || MapCanvas.ActualHeight == 0) 
            {
                Debug.WriteLine($"InteractiveMapView: PopulateScenesRenderInfo - Condition met to return early. Scenes null: {Scenes == null}, Scenes empty: {Scenes?.Any() == false}, Canvas Width: {MapCanvas.ActualWidth}, Canvas Height: {MapCanvas.ActualHeight}");
                return;
            }
            Debug.WriteLine("InteractiveMapView: PopulateScenesRenderInfo - Proceeding with calculations.");

            _currentWpfRenderScale = wpfRenderScale; 
            
            _currentRenderMinX = Scenes.Min(s => s.X);
            _currentRenderMinY = Scenes.Min(s => s.Y);
            double maxX = Scenes.Max(s => s.X);
            double maxY = Scenes.Max(s => s.Y);
            
            double contentWidth = (maxX - _currentRenderMinX) * _currentWpfRenderScale;
            double contentHeight = (maxY - _currentRenderMinY) * _currentWpfRenderScale;

            if (contentWidth == 0) contentWidth = _currentWpfRenderScale; 
            if (contentHeight == 0) contentHeight = _currentWpfRenderScale;

            _currentOffsetX = (MapCanvas.ActualWidth - contentWidth) / 2.0;
            _currentOffsetY = (MapCanvas.ActualHeight - contentHeight) / 2.0;

            foreach (var scene in Scenes)
            {
                double relativeScaledX = (scene.X - _currentRenderMinX) * _currentWpfRenderScale;
                double relativeScaledY = (scene.Y - _currentRenderMinY) * _currentWpfRenderScale;

                double finalScreenX = relativeScaledX + _currentOffsetX;
                double finalScreenY = relativeScaledY + _currentOffsetY;
                
                scenesRenderInfo[scene.Id] = new Point(finalScreenX, finalScreenY);
            }
            Debug.WriteLine($"InteractiveMapView: PopulateScenesRenderInfo completed. Processed and added {scenesRenderInfo.Count} scenes to scenesRenderInfo. Initial Scenes.Count was {Scenes?.Count ?? 0}. Stored offsetX: {_currentOffsetX}, offsetY: {_currentOffsetY}, minX: {_currentRenderMinX}, minY: {_currentRenderMinY}, scale: {_currentWpfRenderScale}");
        }


        private void DrawMap()
        {
            Debug.WriteLine("InteractiveMapView: DrawMap called.");
            if (DesignerProperties.GetIsInDesignMode(this)) 
            {
                Debug.WriteLine("InteractiveMapView: DrawMap - In Design Mode, returning.");
                return;
            }

            Debug.WriteLine("InteractiveMapView: DrawMap - Checking MapCanvas dimensions.");
            if (MapCanvas.ActualWidth == 0 || MapCanvas.ActualHeight == 0)
            {
                Debug.WriteLine($"InteractiveMapView: DrawMap - Canvas not ready. Width: {MapCanvas.ActualWidth}, Height: {MapCanvas.ActualHeight}. Clearing children and returning.");
                MapCanvas.Children.Clear(); 
                scenesRenderInfo.Clear();   
                _sceneAssociatedLines.Clear(); 
                return;
            }

            MapCanvas.Children.Clear();
            _sceneMarkers.Clear(); 
            _connectionLines.Clear(); 
            _sceneAssociatedLines.Clear(); 
            Debug.WriteLine("InteractiveMapView: DrawMap - Canvas, markers, lines and associated lines cleared.");

            Debug.WriteLine("InteractiveMapView: DrawMap - Checking Scenes collection.");
            if (Scenes == null || !Scenes.Any())
            {
                Debug.WriteLine($"InteractiveMapView: DrawMap - Scenes collection is null or empty. Scenes null: {Scenes == null}, Scenes empty: {Scenes?.Any() == false}. Clearing render info and returning.");
                scenesRenderInfo.Clear();
                return;
            }
            Debug.WriteLine($"InteractiveMapView: DrawMap - Scenes collection has {Scenes.Count} items. Proceeding to populate render info.");

            PopulateScenesRenderInfo(); 
            Debug.WriteLine($"InteractiveMapView: DrawMap - Post PopulateScenesRenderInfo. Scenes.Count: {Scenes?.Count ?? 0}, scenesRenderInfo.Count: {scenesRenderInfo.Count}");


            Debug.WriteLine("InteractiveMapView: DrawMap - Calling DrawConnections.");
            DrawConnections();
            Debug.WriteLine("InteractiveMapView: DrawMap - Calling DrawMarkers.");
            DrawMarkers();
            Debug.WriteLine("InteractiveMapView: DrawMap finished.");
        }


        private void DrawConnections()
        {
            Debug.WriteLine("InteractiveMapView: DrawConnections called.");

            if (Scenes == null || !scenesRenderInfo.Any())
            {
                Debug.WriteLine($"InteractiveMapView: DrawConnections - Early exit. Scenes is null: {Scenes == null}, or scenesRenderInfo is empty: {!scenesRenderInfo.Any()}.");
                return;
            }

            if (Scenes != null)
            {
                int scenesWithConnectionsNotNull = Scenes.Count(s => s.Connections != null);
                int scenesWithActualConnectionsToDraw = Scenes.Count(s => s.Connections != null && s.Connections.Any());
                int totalConnectionsToDraw = Scenes.Where(s => s.Connections != null).SelectMany(s => s.Connections).Count();
                Debug.WriteLine($"InteractiveMapView: DrawConnections (Details) - Total scenes: {Scenes.Count}. Scenes with Connections != null: {scenesWithConnectionsNotNull}. Scenes with Connections.Any(): {scenesWithActualConnectionsToDraw}. Total connection entries: {totalConnectionsToDraw}");
            }
            
            _connectionLines.Clear(); 

            foreach (var scene in Scenes)
            {
                if (scene.Connections == null || !scene.Connections.Any() || !scenesRenderInfo.ContainsKey(scene.Id))
                {
                    if (scene.Connections != null && scene.Connections.Any() && !scenesRenderInfo.ContainsKey(scene.Id))
                    {
                        Debug.WriteLine($"InteractiveMapView: DrawConnections - Source scene {scene.Id} ({scene.Name}) has connections but no render info.");
                    }
                    continue;
                }

                Point sourcePos = scenesRenderInfo[scene.Id];

                foreach (var connection in scene.Connections)
                {
                    int connectedSceneId = connection.ConnectedSceneId;
                    if (!scenesRenderInfo.ContainsKey(connectedSceneId))
                    {
                        Debug.WriteLine($"InteractiveMapView: DrawConnections - Target scene with ID {connectedSceneId} not found in scenesRenderInfo for source {scene.Name} ({scene.Id}). Skipping this connection line.");
                        continue;
                    }

                    Point targetPos = scenesRenderInfo[connectedSceneId];

                    if (sourcePos == targetPos) 
                    {
                        Debug.WriteLine($"InteractiveMapView: DrawConnections - Skipping self-connection for scene {scene.Id} ({scene.Name}).");
                        continue;
                    }

                    Line line = new Line
                    {
                        X1 = sourcePos.X,
                        Y1 = sourcePos.Y,
                        X2 = targetPos.X,
                        Y2 = targetPos.Y,
                        Stroke = Brushes.Red, 
                        StrokeThickness = 2    
                    };
                    MapCanvas.Children.Add(line);
                    _connectionLines.Add(line); 

                    if (!_sceneAssociatedLines.ContainsKey(scene.Id))
                        _sceneAssociatedLines[scene.Id] = new List<Line>();
                    _sceneAssociatedLines[scene.Id].Add(line);

                    if (!_sceneAssociatedLines.ContainsKey(connectedSceneId))
                        _sceneAssociatedLines[connectedSceneId] = new List<Line>();
                    _sceneAssociatedLines[connectedSceneId].Add(line);
                }
            }
            Debug.WriteLine($"InteractiveMapView: DrawConnections finished. Added {_connectionLines.Count} lines to the canvas. {_sceneAssociatedLines.Keys.Count} scenes have associated lines entries.");
        }

        private void DrawMarkers()
        {
            Debug.WriteLine("InteractiveMapView: DrawMarkers called.");
            if (Scenes == null || !Scenes.Any())
            {
                Debug.WriteLine($"InteractiveMapView: DrawMarkers - Scenes collection is null or empty. Scenes null: {Scenes == null}, Scenes empty: {!Scenes?.Any()}. Returning.");
                return;
            }

            int scenesIterated = 0;
            int markersAddedToCanvas = 0; 
            int scenesFoundInRenderInfo = 0;
            int scenesNotFoundInRenderInfo = 0;

            Debug.WriteLine($"InteractiveMapView: DrawMarkers - Attempting to draw markers for {Scenes.Count} scenes. scenesRenderInfo contains {scenesRenderInfo.Count} entries.");

            foreach (var scene in Scenes)
            {
                scenesIterated++;
                if (!scenesRenderInfo.ContainsKey(scene.Id))
                {
                    Debug.WriteLine($"InteractiveMapView: DrawMarkers - Scene {scene.Name} (ID: {scene.Id}) from Scenes collection NOT FOUND in scenesRenderInfo. Skipping marker.");
                    scenesNotFoundInRenderInfo++;
                    continue;
                }
                scenesFoundInRenderInfo++;

                Point scaledPos = scenesRenderInfo[scene.Id];

                // 1. Create the visual element (Image or colored Border)
                FrameworkElement visualElement;
                string imagePath = GetSceneImagePath(scene);
                bool imageExists = !string.IsNullOrEmpty(imagePath) && File.Exists(imagePath);

                if (imageExists)
                {
                    var image = new Image
                    {
                        Source = new BitmapImage(new Uri(imagePath, UriKind.Absolute)),
                        Width = 100,
                        Height = 40,
                        Stretch = Stretch.Fill
                    };
                    visualElement = image;
                }
                else
                {
                    var colorBlock = new Border
                    {
                        Background = GetSceneTypeBrush(scene.SceneType),
                        Width = 100,
                        Height = 40,
                        CornerRadius = new CornerRadius(3) // Optional rounding for the color block itself
                    };
                    visualElement = colorBlock;
                }

                // 2. Create TextBlocks
                var idTextBlock = new TextBlock
                {
                    Text = scene.Id.ToString(),
                    FontSize = 8,
                    FontWeight = FontWeights.Normal,
                    Foreground = Brushes.WhiteSmoke,
                    VerticalAlignment = VerticalAlignment.Center
                };

                var nameTextBlock = new TextBlock
                {
                    Text = scene.Name,
                    FontWeight = FontWeights.Bold,
                    FontSize = 9,
                    Foreground = Brushes.WhiteSmoke,
                    TextTrimming = TextTrimming.CharacterEllipsis,
                    // MaxWidth will be implicitly handled by parent panel or can be set if needed
                    VerticalAlignment = VerticalAlignment.Center,
                    Margin = new Thickness(4, 0, 0, 0) // Space between ID and Name
                };

                var typeTextBlock = new TextBlock
                {
                    Text = scene.SceneType.ToString(),
                    FontSize = 7,
                    HorizontalAlignment = HorizontalAlignment.Center, // Centered within its own line
                    Foreground = GetSceneTypeBrush(scene.SceneType)
                };

                // 3. Panel for ID and Name (Horizontal)
                var idAndNamePanel = new StackPanel
                {
                    Orientation = Orientation.Horizontal,
                    HorizontalAlignment = HorizontalAlignment.Center // Center this panel
                };
                idAndNamePanel.Children.Add(idTextBlock);
                idAndNamePanel.Children.Add(nameTextBlock);
                
                // 4. Panel for all text content (Vertical: ID+Name line, then Type line)
                var textContentStack = new StackPanel
                {
                    Orientation = Orientation.Vertical,
                    HorizontalAlignment = HorizontalAlignment.Center // Center the block of text
                };
                textContentStack.Children.Add(idAndNamePanel);
                textContentStack.Children.Add(typeTextBlock);

                // 5. Background Border for text (semi-transparent, contains the text)
                var textOverlayBorder = new Border
                {
                    Background = new SolidColorBrush(Color.FromArgb(200, 20, 20, 20)), // Darker semi-transparent
                    Padding = new Thickness(4, 2, 4, 2), // Padding inside the text background
                    HorizontalAlignment = HorizontalAlignment.Stretch, // Stretch across visualElement's width
                    VerticalAlignment = VerticalAlignment.Bottom,    // Align to the bottom of visualElement
                    Child = textContentStack
                    // Optional: CornerRadius for bottom of overlay: new CornerRadius(0,0,2,2)
                };

                // 6. Grid to host visualElement and overlay textOverlayBorder on it
                var contentGrid = new Grid
                {
                    Width = visualElement.Width,  // Should match visualElement's dimensions (e.g., 100)
                    Height = visualElement.Height // e.g., 30
                };
                contentGrid.Children.Add(visualElement);     // Image/Color block (layer 0)
                contentGrid.Children.Add(textOverlayBorder); // Text on semi-transparent background (layer 1)

                // 7. Main markerBorder (for selection, interaction, overall rounded corners)
                var markerBorder = new Border
                {
                    BorderBrush = (_selectedScene != null && _selectedScene.Id == scene.Id) ? Brushes.Gold : Brushes.DarkSlateGray,
                    BorderThickness = new Thickness(1.5),
                    CornerRadius = new CornerRadius(5), // Overall rounding
                    Tag = scene,
                    Padding = new Thickness(1), // Small padding around the contentGrid
                    Background = Brushes.Transparent, // Main border is transparent
                    Child = contentGrid
                };

                // Attach event handlers
                markerBorder.MouseLeftButtonDown += Marker_MouseLeftButtonDown;
                markerBorder.MouseMove += Marker_MouseMove;
                markerBorder.MouseLeftButtonUp += Marker_MouseLeftButtonUp;

                _sceneMarkers[scene.Id] = markerBorder;
                MapCanvas.Children.Add(markerBorder);
                markersAddedToCanvas++;

                // Position using Loaded event for accuracy
                markerBorder.Loaded += (s, e_loaded) => {
                    var loadedMarker = s as FrameworkElement;
                    if (loadedMarker != null && loadedMarker.Tag is Scene loadedSceneTag && scenesRenderInfo.ContainsKey(loadedSceneTag.Id)) {
                        Point centerPos = scenesRenderInfo[loadedSceneTag.Id];
                        Canvas.SetLeft(loadedMarker, centerPos.X - loadedMarker.ActualWidth / 2);
                        Canvas.SetTop(loadedMarker, centerPos.Y - loadedMarker.ActualHeight / 2);
                    }
                };
                Panel.SetZIndex(markerBorder, 1);
            }
            Debug.WriteLine($"InteractiveMapView: DrawMarkers finished. Iterated {scenesIterated} scenes from Scenes coll. Found {scenesFoundInRenderInfo} in scenesRenderInfo. Did NOT find {scenesNotFoundInRenderInfo} in scenesRenderInfo. Added {markersAddedToCanvas} markerBorders to canvas.");
        }

        private void MapCanvas_MouseWheel(object sender, MouseWheelEventArgs e)
        {
            Debug.WriteLine($"InteractiveMapView: OnMouseWheel called. Delta: {e.Delta}");
            Point mousePosition = e.GetPosition(MapCanvas); 
            double zoomFactor = e.Delta > 0 ? 1.1 : 1 / 1.1; 

            var group = MapCanvas.RenderTransform as TransformGroup;
            if (group == null) 
            {
                // This should ideally not happen if initialized in constructor
                group = new TransformGroup();
                group.Children.Add(new ScaleTransform(1,1,mousePosition.X,mousePosition.Y));
                group.Children.Add(new TranslateTransform());
                MapCanvas.RenderTransform = group;
            }
            
            var scale = group.Children.OfType<ScaleTransform>().FirstOrDefault();
            var pan = group.Children.OfType<TranslateTransform>().FirstOrDefault();

            if (scale == null) { scale = new ScaleTransform(1,1,mousePosition.X,mousePosition.Y); group.Children.Insert(0, scale); }
            if (pan == null) { pan = new TranslateTransform(); group.Children.Insert(1, pan); }

            scale.CenterX = mousePosition.X;
            scale.CenterY = mousePosition.Y;

            double newScaleX = scale.ScaleX * zoomFactor;
            double newScaleY = scale.ScaleY * zoomFactor;

            newScaleX = System.Math.Max(0.2, System.Math.Min(newScaleX, 5.0)); 
            newScaleY = System.Math.Max(0.2, System.Math.Min(newScaleY, 5.0));
            
            scale.ScaleX = newScaleX;
            scale.ScaleY = newScaleY;
            Debug.WriteLine($"InteractiveMapView: OnMouseWheel - New Scale: ({scale.ScaleX:F2}, {scale.ScaleY:F2}), Center: ({scale.CenterX:F2}, {scale.CenterY:F2})");
        }

        private void MapCanvas_MouseDown(object sender, MouseButtonEventArgs e)
        {
            if (e.OriginalSource == MapCanvas) // Click on empty space
            {
                SelectedScene = null;
                Debug.WriteLine("InteractiveMapView: Clicked on empty canvas space, selection cleared.");
            }
            
            // Start panning if left button is pressed, not currently dragging a marker, AND NOT currently drawing a connection
            if (e.ChangedButton == MouseButton.Left && !_isDraggingMarker && !_isDrawingConnectionMode) 
            {
                _panLastMousePosition = e.GetPosition(this); // Use `this` (UserControl) for panning reference
                _isPanning = true;
                this.Cursor = Cursors.ScrollAll;
                MapCanvas.CaptureMouse(); // Capture mouse for panning
                Debug.WriteLine("InteractiveMapView: OnMouseDown - Panning started.");
                e.Handled = true; // Prevent marker click if pan starts
            }
        }

        private void MapCanvas_MouseMove(object sender, MouseEventArgs e)
        {
            if (_isPanning && e.LeftButton == MouseButtonState.Pressed) // Panning logic
            {
                Point currentMousePosition = e.GetPosition(this); // Relative to UserControl
                Vector delta = currentMousePosition - _panLastMousePosition;

                var group = MapCanvas.RenderTransform as TransformGroup;
                var pan = group?.Children.OfType<TranslateTransform>().FirstOrDefault();
                if (pan != null)
                {
                    pan.X += delta.X;
                    pan.Y += delta.Y;
                }
                _panLastMousePosition = currentMousePosition;
                // No e.Handled = true here for now, to see if it conflicts or is needed.
            }
            else if (_isDrawingConnectionMode && _connectionSourceScene != null && _tempConnectionLine != null)
            {
                // This executes when mouse is captured by MapCanvas during connection drawing
                Point currentMousePositionOnCanvas = e.GetPosition(MapCanvas);
                _tempConnectionLine.X2 = currentMousePositionOnCanvas.X;
                _tempConnectionLine.Y2 = currentMousePositionOnCanvas.Y;
                e.Handled = true; // Consume event as we are actively drawing the connection line
            }
            // Marker dragging is handled by Marker_MouseMove when mouse is captured by marker
        }

        private void MapCanvas_MouseUp(object sender, MouseButtonEventArgs e)
        {
            if (e.ChangedButton == MouseButton.Left)
            {
                if (_isPanning) 
                {
                    _isPanning = false;
                    MapCanvas.ReleaseMouseCapture(); // Release mouse capture for panning
                    this.Cursor = Cursors.Arrow;
                    Debug.WriteLine("InteractiveMapView: OnMouseUp - Panning stopped.");
                    e.Handled = true; 
                }

                // Check for connection drawing completion AFTER checking for panning stop
                // This is because mouse capture is on MapCanvas for both, but panning might have higher priority on MouseDown
                if (_isDrawingConnectionMode && _connectionSourceScene != null && _tempConnectionLine != null)
                {
                    MapCanvas.Children.Remove(_tempConnectionLine);
                    // Check if mouse was captured by MapCanvas before releasing. Should be true if _isDrawingConnectionMode is true.
                    if (MapCanvas.IsMouseCaptured) 
                    {
                         MapCanvas.ReleaseMouseCapture();
                    }
                    this.Cursor = Cursors.Arrow;

                    Point releasePosition = e.GetPosition(MapCanvas);
                    Scene? targetScene = null;

                    // Find if released over another marker
                    foreach (var kvp in _sceneMarkers)
                    {
                        // Ensure source scene is not null before accessing Id, and it's a different marker
                        if (kvp.Value == null || (_connectionSourceScene != null && kvp.Key == _connectionSourceScene.Id)) 
                            continue;

                        Rect markerBounds = new Rect(Canvas.GetLeft(kvp.Value), Canvas.GetTop(kvp.Value), kvp.Value.ActualWidth, kvp.Value.ActualHeight);
                        if (markerBounds.Contains(releasePosition))
                        {
                            if (kvp.Value.Tag is Scene sceneFromTag)
                            {
                                targetScene = sceneFromTag;
                                break;
                            }
                        }
                    }

                    if (targetScene != null && _connectionSourceScene != null) // Double check _connectionSourceScene
                    {
                        Debug.WriteLine($"InteractiveMapView: Connection requested from {_connectionSourceScene.Name} to {targetScene.Name}");
                        ConnectionRequested?.Invoke(_connectionSourceScene, targetScene);
                    }
                    else
                    {
                        Debug.WriteLine("InteractiveMapView: Connection drawing cancelled - no target or source scene was null.");
                    }

                    // Reset drawing connection state
                    _isDrawingConnectionMode = false;
                    _connectionSourceScene = null;
                    _tempConnectionLine = null;
                    e.Handled = true;
                }
            }
        }
        
        public void ResetAndCenterView()
        {
            Debug.WriteLine("InteractiveMapView: ResetAndCenterView called.");
            if (Scenes == null || !Scenes.Any() || MapCanvas.ActualWidth == 0 || MapCanvas.ActualHeight == 0)
            {
                Debug.WriteLine("InteractiveMapView: ResetAndCenterView - Cannot center, conditions not met.");
                scaleTransform.ScaleX = 1;
                scaleTransform.ScaleY = 1;
                translateTransform.X = 0;
                translateTransform.Y = 0;
                return;
            }

            PopulateScenesRenderInfo(); 

            scaleTransform.ScaleX = 1;
            scaleTransform.ScaleY = 1;
            scaleTransform.CenterX = 0; 
            scaleTransform.CenterY = 0;
            translateTransform.X = 0;
            translateTransform.Y = 0;
            
            DrawMap(); 
            Debug.WriteLine("InteractiveMapView: ResetAndCenterView finished.");
        }

        private void Marker_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            var marker = sender as FrameworkElement;
            if (marker == null || !(marker.Tag is Scene scene)) return;

            Point currentClickPosition = e.GetPosition(this); // Позиция относительно UserControl
            DateTime currentClickTime = DateTime.Now;

            // Проверка на двойной клик
            if (_lastClickedMarker == marker && (currentClickTime - _lastMarkerClickTime).TotalMilliseconds < DoubleClickTime && 
                Math.Abs(currentClickPosition.X - _lastMarkerClickPosition.X) < 5 && // Небольшой допуск на смещение мыши
                Math.Abs(currentClickPosition.Y - _lastMarkerClickPosition.Y) < 5)
            {
                // Это двойной клик
                _lastMarkerClickTime = DateTime.MinValue; // Сбрасываем время, чтобы следующий клик не считался тройным
                _lastClickedMarker = null;
                
                Debug.WriteLine($"InteractiveMapView: Double-click detected on Scene ID: {scene.Id}");
                SceneEditRequested?.Invoke(scene);
                e.Handled = true;
                return; // Важно выйти, чтобы не началась логика перетаскивания/соединения
            }
            else
            {
                // Это одиночный клик (или первый клик двойного)
                _lastMarkerClickTime = currentClickTime;
                _lastMarkerClickPosition = currentClickPosition;
                _lastClickedMarker = marker;
            }

            // Если это не двойной клик, продолжаем с существующей логикой одиночного клика
            SelectedScene = scene; 
            Debug.WriteLine($"InteractiveMapView: Scene ID: {scene.Id} selected by single click.");

            if (Keyboard.Modifiers == ModifierKeys.Control && !_isDraggingMarker) 
            {
                // --- Start Drawing Connection ---
                _isDrawingConnectionMode = true;
                _connectionSourceScene = scene;
                
                if (!scenesRenderInfo.TryGetValue(scene.Id, out Point sourceMarkerCenter))
                {
                    Debug.WriteLine($"[ERROR] Marker_MouseLeftButtonDown: Could not get source marker center for scene {scene.Name}");
                    _isDrawingConnectionMode = false; 
                    _connectionSourceScene = null;
                    e.Handled = true; 
                    return;
                }

                _tempConnectionLine = new Line
                {
                    X1 = sourceMarkerCenter.X, Y1 = sourceMarkerCenter.Y,
                    X2 = sourceMarkerCenter.X, Y2 = sourceMarkerCenter.Y, 
                    Stroke = Brushes.DodgerBlue,
                    StrokeThickness = 2,
                    StrokeDashArray = new DoubleCollection { 2, 2 }
                };
                MapCanvas.Children.Add(_tempConnectionLine);
                Panel.SetZIndex(_tempConnectionLine, 50); 
                
                MapCanvas.CaptureMouse(); 
                this.Cursor = Cursors.Cross;
                Debug.WriteLine($"InteractiveMapView: Started drawing connection from {scene.Name}");
                e.Handled = true; 
                return; 
            }
            else if (!_isDrawingConnectionMode && !_isDraggingMarker) 
            {
                // --- Start Marker Drag (existing logic) ---
                _draggedMarker = marker;
                _draggedScene = scene;
                _markerDragStartOffset = e.GetPosition(marker); 
                _isDraggingMarker = true;
                _draggedMarker.CaptureMouse(); 
                Panel.SetZIndex(_draggedMarker, 100); 
                this.Cursor = Cursors.Hand;
                e.Handled = true; 
            }
        }

        private void Marker_MouseMove(object sender, MouseEventArgs e)
        {
            // This is only called when mouse is captured by the marker itself (during _isDraggingMarker)
            if (_isDraggingMarker && _draggedMarker != null && _draggedScene != null && e.LeftButton == MouseButtonState.Pressed)
            {
                Point currentMousePositionOnCanvas = e.GetPosition(MapCanvas);
                
                double newLeft = currentMousePositionOnCanvas.X - _markerDragStartOffset.X;
                double newTop = currentMousePositionOnCanvas.Y - _markerDragStartOffset.Y;

                Canvas.SetLeft(_draggedMarker, newLeft);
                Canvas.SetTop(_draggedMarker, newTop);

                if (_draggedMarker == null) return; 

                Point newMarkerCenter = new Point(newLeft + _draggedMarker.ActualWidth / 2, newTop + _draggedMarker.ActualHeight / 2);
                scenesRenderInfo[_draggedScene.Id] = newMarkerCenter; 

                if (_sceneAssociatedLines.TryGetValue(_draggedScene.Id, out var linesToUpdate))
                {
                    foreach (var line in linesToUpdate)
                    {
                        foreach(var sceneEntry in scenesRenderInfo)
                        {
                            if(sceneEntry.Key == _draggedScene.Id) continue; 

                            Point potentialOtherEnd = sceneEntry.Value;
                            if ((Math.Abs(line.X1 - potentialOtherEnd.X) < 0.01 && Math.Abs(line.Y1 - potentialOtherEnd.Y) < 0.01))
                            { line.X2 = newMarkerCenter.X; line.Y2 = newMarkerCenter.Y; break; }
                            if ((Math.Abs(line.X2 - potentialOtherEnd.X) < 0.01 && Math.Abs(line.Y2 - potentialOtherEnd.Y) < 0.01))
                            { line.X1 = newMarkerCenter.X; line.Y1 = newMarkerCenter.Y; break; }
                        }
                    }
                }
                // e.Handled = true; // Not strictly necessary as mouse is captured by marker
            }
        }

        private void Marker_MouseLeftButtonUp(object sender, MouseButtonEventArgs e)
        {
            // This is only called when mouse is captured by the marker itself (during _isDraggingMarker)
            if (_isDraggingMarker && _draggedMarker != null && _draggedScene != null)
            {
                _draggedMarker.ReleaseMouseCapture(); // Release marker's mouse capture
                Panel.SetZIndex(_draggedMarker, 1); 
                this.Cursor = Cursors.Arrow;

                double finalMarkerCanvasLeft = Canvas.GetLeft(_draggedMarker);
                double finalMarkerCanvasTop = Canvas.GetTop(_draggedMarker);
                Point finalMarkerScreenCenter = new Point(finalMarkerCanvasLeft + _draggedMarker.ActualWidth / 2, finalMarkerCanvasTop + _draggedMarker.ActualHeight / 2);
                
                scenesRenderInfo[_draggedScene.Id] = finalMarkerScreenCenter; 

                if (_currentWpfRenderScale == 0) 
                {
                     Debug.WriteLine("InteractiveMapView: Error - _currentWpfRenderScale is zero, cannot convert coordinates back.");
                }
                else
                {
                    double logicalX = ((finalMarkerScreenCenter.X - _currentOffsetX) / _currentWpfRenderScale) + _currentRenderMinX;
                    double logicalY = ((finalMarkerScreenCenter.Y - _currentOffsetY) / _currentWpfRenderScale) + _currentRenderMinY;

                    _draggedScene.X = (int)Math.Round(logicalX);
                    _draggedScene.Y = (int)Math.Round(logicalY);

                    Debug.WriteLine($"InteractiveMapView: Dragged Scene ID: {_draggedScene.Id} to Screen Center: ({finalMarkerScreenCenter.X:F2}, {finalMarkerScreenCenter.Y:F2}). Calculated Logical Coords: (X: {_draggedScene.X}, Y: {_draggedScene.Y})");
                }

                _isDraggingMarker = false;
                _draggedMarker = null;
                _draggedScene = null;
                // e.Handled = true; // Not strictly necessary as mouse was captured by marker
            }
        }

        // Original PointToLogical - KEEP THIS
        public Point PointToLogical(Point canvasPoint)
        {
            var transformedPointByPanZoom = MapCanvas.RenderTransform.Inverse.Transform(canvasPoint);

            double logicalX = (transformedPointByPanZoom.X - _currentOffsetX) / _currentWpfRenderScale + _currentRenderMinX;
            double logicalY = (transformedPointByPanZoom.Y - _currentOffsetY) / _currentWpfRenderScale + _currentRenderMinY;
            
            return new Point(logicalX, logicalY);
        }
        
        // Original LogicalToPoint - KEEP THIS
        public Point LogicalToPoint(double logicalX, double logicalY)
        {
            double relativeScaledX = (logicalX - _currentRenderMinX) * _currentWpfRenderScale;
            double relativeScaledY = (logicalY - _currentRenderMinY) * _currentWpfRenderScale;

            double finalScreenX = relativeScaledX + _currentOffsetX;
            double finalScreenY = relativeScaledY + _currentOffsetY;

            return new Point(finalScreenX, finalScreenY);
        }

        // Original UpdateAssociatedLines - KEEP THIS
        private void UpdateAssociatedLines(Scene scene, Point newMarkerCenterPosition)
        {
            if (_sceneAssociatedLines.TryGetValue(scene.Id, out var linesToUpdate))
            {
                foreach (var line in linesToUpdate)
                {
                    if (Equals(line.Tag, scene.Id)) // Line starts at this scene
                    {
                        line.X1 = newMarkerCenterPosition.X;
                        line.Y1 = newMarkerCenterPosition.Y;
                    }
                    else // Line ends at this scene
                    {
                        line.X2 = newMarkerCenterPosition.X;
                        line.Y2 = newMarkerCenterPosition.Y;
                    }
                }
            }
        }

        private void MapCanvas_DragEnter(object sender, DragEventArgs e)
        {
            if (e.Data.GetDataPresent(typeof(SceneType).FullName) || 
                e.Data.GetDataPresent(typeof(AssetDisplayInfo).FullName))
            {
                e.Effects = DragDropEffects.Copy;
            }
            else
            {
                e.Effects = DragDropEffects.None;
            }
            e.Handled = true;
        }

        private void MapCanvas_DragOver(object sender, DragEventArgs e)
        {
            if (e.Data.GetDataPresent(typeof(SceneType).FullName) || 
                e.Data.GetDataPresent(typeof(AssetDisplayInfo).FullName))
            {
                e.Effects = DragDropEffects.Copy;
            }
            else
            {
                e.Effects = DragDropEffects.None;
            }
            e.Handled = true;
        }

        private void MapCanvas_Drop(object sender, DragEventArgs e)
        {
            Point dropPositionOnCanvas = e.GetPosition(MapCanvas);

            if (e.Data.GetData(typeof(AssetDisplayInfo).FullName) is AssetDisplayInfo assetInfo)
            {
                Scene? targetScene = FindSceneAtCanvasPoint(dropPositionOnCanvas);
                if (targetScene != null)
                {
                    AssetDroppedOnScene?.Invoke(targetScene, assetInfo);
                    Debug.WriteLine($"InteractiveMapView: Asset ID {assetInfo.AssetId} dropped on Scene ID {targetScene.Id}");
                }
                else
                {
                    Debug.WriteLine($"InteractiveMapView: Asset ID {assetInfo.AssetId} dropped on canvas, but no target scene found.");
                }
                e.Handled = true;
            }
            else if (e.Data.GetData(typeof(SceneType).FullName) is SceneType sceneType)
            {
                Point logicalDropPosition = PointToLogical(dropPositionOnCanvas); 
                SceneDroppedOnCanvas?.Invoke(sceneType, logicalDropPosition);
                e.Handled = true;
            }
        }

        private Scene? FindSceneAtCanvasPoint(Point canvasPoint)
        {
            foreach (var markerEntry in _sceneMarkers.Reverse())
            {
                FrameworkElement marker = markerEntry.Value;
                if (marker.IsVisible)
                {
                    try
                    {
                        GeneralTransform transform = marker.TransformToAncestor(MapCanvas);
                        Rect markerBounds = transform.TransformBounds(new Rect(new Point(0, 0), marker.RenderSize));

                        if (markerBounds.Contains(canvasPoint))
                        {
                            int sceneId = markerEntry.Key;
                            return Scenes?.FirstOrDefault(s => s.Id == sceneId);
                        }
                    }
                    catch (InvalidOperationException ex)
                    {
                        Debug.WriteLine($"[FindSceneAtCanvasPoint] Error transforming marker bounds for scene ID {markerEntry.Key}: {ex.Message}");
                    }
                }
            }
            return null;
        }

        private static string GetSceneImagePath(Scene scene)
        {
            return $"{Constants.SceneAssetsFolderPath}\\location{scene.Id}.imageset\\location{scene.Id}.png";
        }
    }
} 