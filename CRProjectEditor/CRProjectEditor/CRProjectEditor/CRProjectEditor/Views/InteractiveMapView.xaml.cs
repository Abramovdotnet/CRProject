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

        private void Scenes_CollectionChanged(object sender, NotifyCollectionChangedEventArgs e)
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

            double minX = Scenes.Min(s => s.X);
            double maxX = Scenes.Max(s => s.X);
            double minY = Scenes.Min(s => s.Y);
            double maxY = Scenes.Max(s => s.Y);

            // Effective width/height of the scene content after wpfRenderScale
            double scenesContentWidth = (maxX - minX) * wpfRenderScale;
            double scenesContentHeight = (maxY - minY) * wpfRenderScale;
            
            // If there's only one scene or all scenes are at the same point,
            // ensure content width/height is not zero to avoid division by zero or tiny scales.
            // Use a nominal size (e.g., wpfRenderScale itself) for a single point.
            if (scenesContentWidth == 0) scenesContentWidth = wpfRenderScale;
            if (scenesContentHeight == 0) scenesContentHeight = wpfRenderScale;


            double canvasCenterX = MapCanvas.ActualWidth / 2;
            double canvasCenterY = MapCanvas.ActualHeight / 2;

            double scaledMinX = minX * wpfRenderScale;
            double totalScaledContentWidth = (maxX - minX) * wpfRenderScale;
            double totalScaledContentHeight = (maxY - minY) * wpfRenderScale;

            double offsetX = canvasCenterX - (totalScaledContentWidth / 2) - scaledMinX;
            double offsetY = canvasCenterY - (totalScaledContentHeight / 2) - (minY * wpfRenderScale);

            foreach (var scene in Scenes)
            {
                double scaledX = scene.X * wpfRenderScale + offsetX;
                double scaledY = scene.Y * wpfRenderScale + offsetY;
                scenesRenderInfo[scene.Id] = new Point(scaledX, scaledY);
            }
            Debug.WriteLine($"InteractiveMapView: PopulateScenesRenderInfo completed. Processed and added {scenesRenderInfo.Count} scenes to scenesRenderInfo. Initial Scenes.Count was {Scenes?.Count ?? 0}.");
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
                return;
            }

            MapCanvas.Children.Clear();
            Debug.WriteLine("InteractiveMapView: DrawMap - Canvas cleared.");

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
                        Stroke = Brushes.Red, // Keep red for visibility during debugging
                        StrokeThickness = 2    // Keep thicker for visibility
                    };
                    MapCanvas.Children.Add(line);
                    _connectionLines.Add(line); // Track the line
                    // Debug.WriteLine($"InteractiveMapView: DrawConnections - Added line from {scene.Id} ({sourcePos.X},{sourcePos.Y}) to {connectedSceneId} ({targetPos.X},{targetPos.Y})");
                }
            }
            Debug.WriteLine($"InteractiveMapView: DrawConnections finished. Added {_connectionLines.Count} lines to the canvas.");
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
                    BorderBrush = Brushes.DarkSlateGray,
                    BorderThickness = new Thickness(1.5), 
                    CornerRadius = new CornerRadius(4)   
                };

                StackPanel stackPanel = new StackPanel { Orientation = Orientation.Vertical, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
                stackPanel.Children.Add(new TextBlock { Text = scene.Name, FontWeight = FontWeights.Bold, HorizontalAlignment = HorizontalAlignment.Center, TextTrimming = TextTrimming.CharacterEllipsis, MaxWidth = 140 });
                stackPanel.Children.Add(new TextBlock { Text = scene.SceneType.ToString(), FontSize = 10, HorizontalAlignment = HorizontalAlignment.Center });
                marker.Child = stackPanel;
                
                MapCanvas.Children.Add(marker);
                markersAddedToCanvas++;
                                                
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
            Debug.WriteLine($"InteractiveMapView: OnMouseDown called. Button: {e.ChangedButton}");
            if (e.ChangedButton == MouseButton.Left)
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
            Debug.WriteLine($"InteractiveMapView: OnMouseUp called. Button: {e.ChangedButton}");
            if (e.ChangedButton == MouseButton.Left)
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
    }
} 