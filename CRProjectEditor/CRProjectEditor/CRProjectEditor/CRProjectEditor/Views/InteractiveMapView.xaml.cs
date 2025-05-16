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

namespace CRProjectEditor.Views
{
    public partial class InteractiveMapView : UserControl
    {
        private Point? lastMousePosition;
        private ScaleTransform scaleTransform;
        private TranslateTransform translateTransform;
        private double wpfRenderScale = 30.0; // Changed from 40 to 30 as per user request

        // Stores pre-calculated, scaled, and offset positions for scene centers
        private Dictionary<int, Point> scenesRenderInfo = new Dictionary<int, Point>();

        private readonly Dictionary<int, FrameworkElement> _sceneMarkers = new Dictionary<int, FrameworkElement>();
        private readonly List<Shape> _connectionLines = new List<Shape>();

        private Point _panLastMousePosition;
        private bool _isPanning = false;
        
        private Point _canvasCenter = new Point(0,0); 

        // Fields for marker dragging
        private FrameworkElement? _draggedMarker;
        private Scene? _draggedScene;
        private Point _markerDragStartOffset; // Offset from marker's top-left to mouse click point
        private bool _isDraggingMarker = false;
        // Store lines connected to each scene for easier update during drag
        private Dictionary<int, List<Line>> _sceneAssociatedLines = new Dictionary<int, List<Line>>();

        // Fields for coordinate transformation
        private double _currentRenderMinX;
        private double _currentRenderMinY;
        private double _currentRenderContentWidth;
        private double _currentRenderContentHeight;
        private double _canvasActualWidth;
        private double _canvasActualHeight;
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
                case SceneType.Town: return Brushes.LightSteelBlue; // Changed
                case SceneType.Castle: return Brushes.SlateGray;

                // Districts
                case SceneType.District: return Brushes.LightSlateGray; // Changed

                // Religious Buildings
                case SceneType.Cathedral: return Brushes.LightGoldenrodYellow; // New
                case SceneType.Cloister: return Brushes.Wheat; // New
                case SceneType.Cemetery: return Brushes.DarkOliveGreen; // New
                case SceneType.Temple: return Brushes.Gold;
                case SceneType.Crypt: return Brushes.DarkSlateGray;

                // Administrative Buildings
                case SceneType.Manor: return Brushes.Tan; // New
                case SceneType.Military: return Brushes.IndianRed; // New

                // Commercial Buildings
                case SceneType.Blacksmith: return Brushes.DarkGray;
                case SceneType.AlchemistShop: return Brushes.MediumPurple; // New
                case SceneType.Warehouse: return Brushes.RosyBrown; // New
                case SceneType.Bookstore: return Brushes.NavajoWhite; // New
                case SceneType.Shop: return Brushes.Plum; 
                case SceneType.Mine: return Brushes.DimGray;

                // Entertainment Buildings
                case SceneType.Tavern: return Brushes.OrangeRed;
                case SceneType.Brothel: return Brushes.DeepPink; // New
                case SceneType.Bathhouse: return Brushes.Turquoise; // New

                // Public Spaces
                case SceneType.Square: return Brushes.LightSalmon;
                case SceneType.Docks: return Brushes.SteelBlue; // New (was Port)
                case SceneType.Road: return Brushes.SandyBrown;

                // Natural/Wilderness
                case SceneType.Forest: return Brushes.DarkGreen;
                case SceneType.Cave: return Brushes.SaddleBrown;
                case SceneType.Ruins: return Brushes.Peru;
                
                // Misc
                case SceneType.House: return Brushes.LightSkyBlue; 
                case SceneType.Dungeon: return Brushes.Indigo;

                // Removed types like Field, Bridge, River, Lake, Sea, Mountain, Hills, Swamp, Desert, Coast, Gate, Wasteland
                default: return Brushes.Gainsboro; // Default color, slightly different from LightGray
            }
        }

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

            this.Loaded += UserControl_Loaded; // Add Loaded event handler
            MapCanvas.SizeChanged += MapCanvas_SizeChanged; // Add SizeChanged event handler
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

            _currentWpfRenderScale = wpfRenderScale; // Store the scale used for this population
            _canvasActualWidth = MapCanvas.ActualWidth;
            _canvasActualHeight = MapCanvas.ActualHeight;

            _currentRenderMinX = Scenes.Min(s => s.X);
            _currentRenderMinY = Scenes.Min(s => s.Y);
            double maxX = Scenes.Max(s => s.X);
            double maxY = Scenes.Max(s => s.Y);
            
            _currentRenderContentWidth = (maxX - _currentRenderMinX) * _currentWpfRenderScale;
            _currentRenderContentHeight = (maxY - _currentRenderMinY) * _currentWpfRenderScale;

            if (_currentRenderContentWidth == 0) _currentRenderContentWidth = _currentWpfRenderScale; // Avoid division by zero for single point
            if (_currentRenderContentHeight == 0) _currentRenderContentHeight = _currentWpfRenderScale;

            double canvasCenterX = _canvasActualWidth / 2;
            double canvasCenterY = _canvasActualHeight / 2;

            // This offsetX and offsetY are calculated to center the entire group of scaled scenes.
            // scene.X * _currentWpfRenderScale gives position relative to (minX * _currentWpfRenderScale, minY * _currentWpfRenderScale)
            // then this whole block is shifted.
            // Offset to shift the top-left of the scaled content bounding box so that the content center aligns with canvas center.
            double groupScaledMinX = _currentRenderMinX * _currentWpfRenderScale;
            double groupScaledMinY = _currentRenderMinY * _currentWpfRenderScale;

            double calculatedOffsetX = canvasCenterX - (_currentRenderContentWidth / 2) - groupScaledMinX;
            double calculatedOffsetY = canvasCenterY - (_currentRenderContentHeight / 2) - groupScaledMinY;
            
            // Store these for reverse calculation
            // These are the offsets that were ADDED to (scene.X * _currentWpfRenderScale) to get screen coods.
            // So, screenX = (scene.X * _currentWpfRenderScale) + _currentOffsetX; 
            // scene.X = (screenX - _currentOffsetX) / _currentWpfRenderScale;
            // This interpretation makes _currentOffsetX and _currentOffsetY include the minX/minY scaling factor.
            // Let's redefine how we use and store them for clarity in reverse.

            // Let's calculate offsetX and offsetY for the simplified reverse formula:
            // screenX_center = (logicalX_scene * scale) + finalOffsetX
            // logicalX_scene = (screenX_center - finalOffsetX) / scale
            // where finalOffsetX centers the entire scaled range.

            // Offset to align the (0,0) of the logical coordinate system (after scaling) to its screen position
            // such that the entire content block is centered.
            // (logicalX * scale) is the position if (minX, minY) of logical was at (0,0) on screen.
            // We want to shift this so that the center of ( (minX..maxX)*scale ) block is at canvasCenter.
            
            // Storing the translation part that centers the content block
            _currentOffsetX = canvasCenterX - (_currentRenderContentWidth / 2);
            _currentOffsetY = canvasCenterY - (_currentRenderContentHeight / 2);


            foreach (var scene in Scenes)
            {
                // Screen position relative to the top-left of the *scaled content block*
                double relativeScaledX = (scene.X - _currentRenderMinX) * _currentWpfRenderScale;
                double relativeScaledY = (scene.Y - _currentRenderMinY) * _currentWpfRenderScale;

                // Final screen position (center of marker)
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
                _sceneAssociatedLines.Clear(); // Clear associated lines
                return;
            }

            MapCanvas.Children.Clear();
            _sceneMarkers.Clear(); // Clear marker references
            _connectionLines.Clear(); // Clear line references
            _sceneAssociatedLines.Clear(); // Clear associated lines
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
            // _sceneAssociatedLines.Clear(); // Clear previous associations - This should be done in DrawMap or before repopulating

            if (Scenes == null || !scenesRenderInfo.Any())
            {
                Debug.WriteLine($"InteractiveMapView: DrawConnections - Early exit. Scenes is null: {Scenes == null}, or scenesRenderInfo is empty: {!scenesRenderInfo.Any()}.");
                return;
            }

            // Log details about scene connections
            if (Scenes != null)
            {
                int scenesWithConnectionsNotNull = Scenes.Count(s => s.Connections != null);
                int scenesWithActualConnectionsToDraw = Scenes.Count(s => s.Connections != null && s.Connections.Any());
                int totalConnectionsToDraw = Scenes.Where(s => s.Connections != null).SelectMany(s => s.Connections).Count();
                Debug.WriteLine($"InteractiveMapView: DrawConnections (Details) - Total scenes: {Scenes.Count}. Scenes with Connections != null: {scenesWithConnectionsNotNull}. Scenes with Connections.Any(): {scenesWithActualConnectionsToDraw}. Total connection entries: {totalConnectionsToDraw}");
            }
            
            _connectionLines.Clear(); // Clear existing lines from the tracking list (not from canvas yet, DrawMap clears canvas)

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

                    // Avoid drawing a line from a scene to itself if such data exists
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

                    // Associate line with both scenes it connects
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

                Border marker = new Border
                {
                    Width = 150, 
                    Height = 45, 
                    Background = GetSceneTypeBrush(scene.SceneType), 
                    BorderBrush = (_selectedScene != null && _selectedScene.Id == scene.Id) ? Brushes.Gold : Brushes.DarkSlateGray, // Apply selection highlight
                    BorderThickness = new Thickness(1.5), 
                    CornerRadius = new CornerRadius(4),
                    Tag = scene // Store the Scene object in the Tag property for easy access
                };

                // Attach event handlers for dragging
                marker.MouseLeftButtonDown += Marker_MouseLeftButtonDown;
                marker.MouseMove += Marker_MouseMove;
                marker.MouseLeftButtonUp += Marker_MouseLeftButtonUp;

                StackPanel stackPanel = new StackPanel { Orientation = Orientation.Vertical, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
                stackPanel.Children.Add(new TextBlock { Text = scene.Name, FontWeight = FontWeights.Bold, HorizontalAlignment = HorizontalAlignment.Center, TextTrimming = TextTrimming.CharacterEllipsis, MaxWidth = 140 });
                stackPanel.Children.Add(new TextBlock { Text = scene.SceneType.ToString(), FontSize = 10, HorizontalAlignment = HorizontalAlignment.Center });
                marker.Child = stackPanel;
                
                MapCanvas.Children.Add(marker);
                markersAddedToCanvas++;
                _sceneMarkers[scene.Id] = marker; // Store marker reference
                                                
                Canvas.SetLeft(marker, scaledPos.X - marker.Width / 2);
                Canvas.SetTop(marker, scaledPos.Y - marker.Height / 2);
                Panel.SetZIndex(marker, 1); 
            }
            Debug.WriteLine($"InteractiveMapView: DrawMarkers finished. Iterated {scenesIterated} scenes from Scenes coll. Found {scenesFoundInRenderInfo} in scenesRenderInfo. Did NOT find {scenesNotFoundInRenderInfo} in scenesRenderInfo. Added {markersAddedToCanvas} markers to canvas.");
        }

        private void MapCanvas_MouseWheel(object sender, MouseWheelEventArgs e)
        {
            Debug.WriteLine($"InteractiveMapView: OnMouseWheel called. Delta: {e.Delta}");
            Point mousePosition = e.GetPosition(MapCanvas); 
            double zoomFactor = e.Delta > 0 ? 1.1 : 1 / 1.1; 

            // Ensure ZoomTransform and PanTransform are part of the canvas's RenderTransform
            var group = MapCanvas.RenderTransform as TransformGroup;
            if (group == null) 
            {
                group = new TransformGroup();
                group.Children.Add(new ScaleTransform());
                group.Children.Add(new TranslateTransform());
                MapCanvas.RenderTransform = group;
            }
            
            var scale = group.Children.OfType<ScaleTransform>().FirstOrDefault();
            var pan = group.Children.OfType<TranslateTransform>().FirstOrDefault();

            if (scale == null) { scale = new ScaleTransform(); group.Children.Insert(0, scale); }
            if (pan == null) { pan = new TranslateTransform(); group.Children.Insert(1, pan); }


            double newScaleX = scale.ScaleX * zoomFactor;
            double newScaleY = scale.ScaleY * zoomFactor;

            newScaleX = System.Math.Max(0.2, System.Math.Min(newScaleX, 5.0)); 
            newScaleY = System.Math.Max(0.2, System.Math.Min(newScaleY, 5.0));

            double oldOffsetX = pan.X;
            double oldOffsetY = pan.Y;

            pan.X = mousePosition.X - (mousePosition.X - oldOffsetX) * (newScaleX / scale.ScaleX);
            pan.Y = mousePosition.Y - (mousePosition.Y - oldOffsetY) * (newScaleY / scale.ScaleY);
            
            scale.ScaleX = newScaleX;
            scale.ScaleY = newScaleY;
            Debug.WriteLine($"InteractiveMapView: OnMouseWheel - New Scale: ({scale.ScaleX:F2}, {scale.ScaleY:F2}), New Pan: ({pan.X:F2}, {pan.Y:F2})");
        }

        private void MapCanvas_MouseDown(object sender, MouseButtonEventArgs e)
        {
            if (e.OriginalSource == MapCanvas) // Click on empty space
            {
                SelectedScene = null;
                Debug.WriteLine("InteractiveMapView: Clicked on empty canvas space, selection cleared.");
            }
            
            if (e.ChangedButton == MouseButton.Left && !_isDraggingMarker) 
            {
                _panLastMousePosition = e.GetPosition(this); 
                _isPanning = true;
                this.Cursor = Cursors.ScrollAll;
                Debug.WriteLine("InteractiveMapView: OnMouseDown - Panning started.");
            }
        }

        private void MapCanvas_MouseMove(object sender, MouseEventArgs e)
        {
            if (_isPanning)
            {
                Point currentMousePosition = e.GetPosition(this);
                Vector delta = currentMousePosition - _panLastMousePosition;

                var group = MapCanvas.RenderTransform as TransformGroup;
                var pan = group?.Children.OfType<TranslateTransform>().FirstOrDefault();
                if (pan != null)
                {
                    pan.X += delta.X;
                    pan.Y += delta.Y;
                }
                _panLastMousePosition = currentMousePosition;
            }
        }

        private void MapCanvas_MouseUp(object sender, MouseButtonEventArgs e)
        {
            // Debug.WriteLine($"InteractiveMapView: OnMouseUp called. Button: {e.ChangedButton}. IsPanning: {_isPanning}");
            if (e.ChangedButton == MouseButton.Left && _isPanning) // Stop panning if it was active (and not a marker drag release)
            {
                _isPanning = false;
                this.Cursor = Cursors.Arrow;
                Debug.WriteLine("InteractiveMapView: OnMouseUp - Panning stopped.");
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

            // Recalculate render info which includes centering logic based on current canvas size
            PopulateScenesRenderInfo(); // This will re-calculate based on current MapCanvas.ActualWidth/Height

            // Reset pan and zoom transforms to their defaults
            scaleTransform.ScaleX = 1;
            scaleTransform.ScaleY = 1;
            scaleTransform.CenterX = 0; // Reset center of zoom
            scaleTransform.CenterY = 0;
            translateTransform.X = 0;
            translateTransform.Y = 0;
            
            // After PopulateScenesRenderInfo, the coordinates are already centered.
            // So, resetting scale to 1 and translation to 0 should show the centered content.
            // A full redraw is implicitly handled if Scenes data hasn't changed but view needs reset.
            // If an explicit redraw is needed *after* this reset:
            DrawMap(); 
            Debug.WriteLine("InteractiveMapView: ResetAndCenterView finished.");
        }

        private void Marker_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            if (_isPanning) return; 

            var marker = sender as FrameworkElement;
            if (marker != null && marker.Tag is Scene scene)
            {
                // If it's a double click, or some other condition for selection vs drag start can be here
                // For now, any click will select, and also initiate drag possibility.
                SelectedScene = scene; 
                Debug.WriteLine($"InteractiveMapView: Scene ID: {scene.Id} selected by click.");

                _draggedMarker = marker;
                _draggedScene = scene;
                _markerDragStartOffset = e.GetPosition(marker); 
                _isDraggingMarker = true;
                _draggedMarker.CaptureMouse();
                Panel.SetZIndex(_draggedMarker, 100); 
                this.Cursor = Cursors.Hand;
                // Debug.WriteLine($"InteractiveMapView: Marker_MouseLeftButtonDown on Scene ID: {_draggedScene.Id}, Name: {_draggedScene.Name}");
                e.Handled = true; 
            }
        }

        private void Marker_MouseMove(object sender, MouseEventArgs e)
        {
            if (_isDraggingMarker && _draggedMarker != null && _draggedScene != null)
            {
                Point currentMousePositionOnCanvas = e.GetPosition(MapCanvas);
                
                double newLeft = currentMousePositionOnCanvas.X - _markerDragStartOffset.X;
                double newTop = currentMousePositionOnCanvas.Y - _markerDragStartOffset.Y;

                Canvas.SetLeft(_draggedMarker, newLeft);
                Canvas.SetTop(_draggedMarker, newTop);

                // Ensure _draggedMarker is not null before accessing ActualWidth/Height, though already checked by _isDraggingMarker
                if (_draggedMarker == null) return; 

                Point newMarkerCenter = new Point(newLeft + _draggedMarker.ActualWidth / 2, newTop + _draggedMarker.ActualHeight / 2);
                scenesRenderInfo[_draggedScene.Id] = newMarkerCenter; // Update screen position for line drawing

                if (_sceneAssociatedLines.TryGetValue(_draggedScene.Id, out var linesToUpdate))
                {
                    foreach (var line in linesToUpdate)
                    {
                        // One end of the line is the newMarkerCenter.
                        // The other end is the center of the *other* scene this line connects to.
                        // Point otherEndPoint = new Point(); // foundOtherEnd was related to this, removing
                        // bool foundOtherEnd = false; // Variable not used

                        // Determine which scene is the other end of this specific line
                        // This relies on the fact that _sceneAssociatedLines links this line to _draggedScene
                        // So, we need to find which of _draggedScene's connections corresponds to this line.
                        
                        // Iterate through all scenes to find the other end point of the line.
                        // This is not super efficient but clear.
                        foreach(var sceneEntry in scenesRenderInfo)
                        {
                            if(sceneEntry.Key == _draggedScene.Id) continue; // Skip self

                            Point potentialOtherEnd = sceneEntry.Value;
                            // Check if one end of the line matches potentialOtherEnd (within a small tolerance for double comparison)
                            if ((Math.Abs(line.X1 - potentialOtherEnd.X) < 0.01 && Math.Abs(line.Y1 - potentialOtherEnd.Y) < 0.01))
                            {
                                // If X1,Y1 is the other scene, then X2,Y2 must be the dragged scene
                                // otherEndPoint = potentialOtherEnd;
                                // foundOtherEnd = true;
                                line.X2 = newMarkerCenter.X;
                                line.Y2 = newMarkerCenter.Y;
                                break; 
                            }
                            if ((Math.Abs(line.X2 - potentialOtherEnd.X) < 0.01 && Math.Abs(line.Y2 - potentialOtherEnd.Y) < 0.01))
                            {
                                // If X2,Y2 is the other scene, then X1,Y1 must be the dragged scene
                                // otherEndPoint = potentialOtherEnd;
                                // foundOtherEnd = true;
                                line.X1 = newMarkerCenter.X;
                                line.Y1 = newMarkerCenter.Y;
                                break;
                            }
                        }
                        // If foundOtherEnd was false, it means the line was associated with _draggedScene,
                        // but its other endpoint doesn't match any *current* center in scenesRenderInfo (other than _draggedScene itself).
                        // This might happen if the line was to a scene not yet in scenesRenderInfo or an old line.
                        // However, DrawConnections should only create lines between scenes present in scenesRenderInfo.
                    }
                }
                e.Handled = true;
            }
            else if (_isPanning && e.LeftButton == MouseButtonState.Pressed) // Existing canvas panning logic, ensure button is still pressed
            {
                Point currentMousePosition = e.GetPosition(this); // Relative to InteractiveMapView UserControl
                Vector delta = currentMousePosition - _panLastMousePosition;

                var group = MapCanvas.RenderTransform as TransformGroup;
                var pan = group?.Children.OfType<TranslateTransform>().FirstOrDefault();
                if (pan != null)
                {
                    pan.X += delta.X;
                    pan.Y += delta.Y;
                }
                _panLastMousePosition = currentMousePosition;
                 e.Handled = true;
            }
        }

        private void Marker_MouseLeftButtonUp(object sender, MouseButtonEventArgs e)
        {
            if (_isDraggingMarker && _draggedMarker != null && _draggedScene != null)
            {
                _draggedMarker.ReleaseMouseCapture();
                Panel.SetZIndex(_draggedMarker, 1); 
                this.Cursor = Cursors.Arrow;
                // Debug.WriteLine($"InteractiveMapView: Marker_MouseLeftButtonUp for Scene ID: {_draggedScene.Id}");

                // Check if it was a drag or just a click for selection purposes
                Point releasePosition = e.GetPosition(MapCanvas);
                Point initialCanvasPosition = new Point(
                    Canvas.GetLeft(_draggedMarker) + _markerDragStartOffset.X,
                    Canvas.GetTop(_draggedMarker) + _markerDragStartOffset.Y
                );

                // If mouse hasn't moved significantly, it's a click (selection already handled in MouseDown or should be refined here)
                // For now, selection happens on MouseDown. Dragging updates position.
                // The _isDraggingMarker flag correctly distinguishes drag from a click that didn't move.

                double finalMarkerCanvasLeft = Canvas.GetLeft(_draggedMarker);
                double finalMarkerCanvasTop = Canvas.GetTop(_draggedMarker);
                Point finalMarkerScreenCenter = new Point(finalMarkerCanvasLeft + _draggedMarker.ActualWidth / 2, finalMarkerCanvasTop + _draggedMarker.ActualHeight / 2);
                
                scenesRenderInfo[_draggedScene.Id] = finalMarkerScreenCenter; // Ensure final screen position is stored

                // Convert finalMarkerScreenCenter (screen coordinates) back to logical Scene.X, Scene.Y
                if (_currentWpfRenderScale == 0) 
                {
                     Debug.WriteLine("InteractiveMapView: Error - _currentWpfRenderScale is zero, cannot convert coordinates back.");
                }
                else
                {
                    // Reverse the transformation from PopulateScenesRenderInfo:
                    // finalScreenX = ((scene.X - _currentRenderMinX) * _currentWpfRenderScale) + _currentOffsetX;
                    // finalScreenX - _currentOffsetX = (scene.X - _currentRenderMinX) * _currentWpfRenderScale;
                    // (finalScreenX - _currentOffsetX) / _currentWpfRenderScale = scene.X - _currentRenderMinX;
                    // scene.X = ((finalScreenX - _currentOffsetX) / _currentWpfRenderScale) + _currentRenderMinX;

                    double logicalX = ((finalMarkerScreenCenter.X - _currentOffsetX) / _currentWpfRenderScale) + _currentRenderMinX;
                    double logicalY = ((finalMarkerScreenCenter.Y - _currentOffsetY) / _currentWpfRenderScale) + _currentRenderMinY;

                    _draggedScene.X = (int)Math.Round(logicalX);
                    _draggedScene.Y = (int)Math.Round(logicalY);

                    Debug.WriteLine($"InteractiveMapView: Dragged Scene ID: {_draggedScene.Id} to Screen Center: ({finalMarkerScreenCenter.X:F2}, {finalMarkerScreenCenter.Y:F2}). Calculated Logical Coords: (X: {_draggedScene.X}, Y: {_draggedScene.Y})");
                    
                    // TODO: Notify ViewModel that _draggedScene's X, Y have changed so it can enable save or auto-save.
                    // For now, the change is in the Scene object within the ObservableCollection.
                    // The DataGrid should reflect this if it's two-way bound or notified.
                }

                _isDraggingMarker = false;
                _draggedMarker = null;
                _draggedScene = null;
                e.Handled = true;
            }
        }
    }
} 