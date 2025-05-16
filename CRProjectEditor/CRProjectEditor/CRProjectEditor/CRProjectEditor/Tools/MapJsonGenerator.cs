using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Numerics;
using System.Text.Json;
using System.Text.Json.Serialization;
using CRProjectEditor.Models; // Добавляем using для моделей

namespace CRProjectEditor.Tools
{
    public class MapJsonGenerator
    {
        private readonly List<Scene> _scenes;
        private readonly Vector2 _markerSizeOnScreen; // Using Vector2 for size (Width, Height)
        private readonly float _mapCoordinateScale;
        private readonly float _baseDistancePerTravelTimeUnit;

        private Dictionary<int, Scene> _scenesById = new Dictionary<int, Scene>();

        public MapJsonGenerator(List<Scene> scenes, Vector2 markerSizeOnScreen, float mapCoordinateScale, float baseDistancePerTravelTimeUnit = 2.0f)
        {
            _scenes = scenes;
            _markerSizeOnScreen = markerSizeOnScreen;
            _mapCoordinateScale = mapCoordinateScale;
            _baseDistancePerTravelTimeUnit = baseDistancePerTravelTimeUnit;
            
            foreach (var scene in _scenes)
            {
                _scenesById[scene.Id] = scene;
                scene.IsPlaced = false; // Ensure all scenes start as not placed
            }
        }

        public void GenerateCoordinates()
        {
            if (!_scenes.Any()) return;

            var scenesToPlace = new Queue<Scene>(_scenes.Where(s => s.Connections.Any() || !_scenes.Any(other => other.Connections.Any(c => c.ConnectedSceneId == s.Id))));
            var placedScenes = new List<Scene>();

            Scene? firstScene = _scenes.FirstOrDefault();
            if (firstScene == null) return;

            // Place the first scene (or a root scene)
            firstScene.Point = Vector2.Zero;
            firstScene.IsPlaced = true;
            placedScenes.Add(firstScene);
            
            Queue<Scene> processQueue = new Queue<Scene>();
            processQueue.Enqueue(firstScene);

            while(processQueue.Any())
            {
                var currentScene = processQueue.Dequeue();

                foreach (var connection in currentScene.Connections)
                {
                    if (_scenesById.TryGetValue(connection.ConnectedSceneId, out var neighbor) && !neighbor.IsPlaced)
                    {
                        PlaceSceneNearAnchor(neighbor, currentScene, connection.TravelTime);
                        neighbor.IsPlaced = true;
                        placedScenes.Add(neighbor);
                        processQueue.Enqueue(neighbor);
                    }
                }
                // Check for scenes connected TO this one, if they haven't been placed yet
                foreach (var potentialParentScene in _scenes.Where(s => !s.IsPlaced && s.Connections.Any(c => c.ConnectedSceneId == currentScene.Id)))
                {
                    var connectionToCurrent = potentialParentScene.Connections.First(c => c.ConnectedSceneId == currentScene.Id);
                    PlaceSceneNearAnchor(potentialParentScene, currentScene, connectionToCurrent.TravelTime); // Placing potentialParent relative to current
                    potentialParentScene.IsPlaced = true;
                    placedScenes.Add(potentialParentScene);
                    processQueue.Enqueue(potentialParentScene);
                }
            }

            // Handle disconnected components (basic placement)
            float nextX = placedScenes.Any() ? placedScenes.Max(s => s.Point.X + _markerSizeOnScreen.X / _mapCoordinateScale) + 20 : 0;
            foreach (var scene in _scenes.Where(s => !s.IsPlaced))
            {
                scene.Point = new Vector2(nextX, 0);
                scene.IsPlaced = true;
                placedScenes.Add(scene);
                nextX += _markerSizeOnScreen.X / _mapCoordinateScale + 20; // Simple linear placement for disconnected
                // Optionally, queue these up to try and connect them to the main graph if desired
            }

            // Update original scene objects X and Y from calculated Points
            foreach (var scene in _scenes)
            {
                scene.X = (int)Math.Round(scene.Point.X);
                scene.Y = (int)Math.Round(scene.Point.Y);
            }
        }

        private void PlaceSceneNearAnchor(Scene sceneToPlace, Scene anchorScene, double travelTime)
        {
            float targetJsonDistance = (float)travelTime * _baseDistancePerTravelTimeUnit;
            float currentSearchDistance = targetJsonDistance;
            bool placed = false;
            int maxAttemptsPerDistance = 12; // Number of angles to try
            float distanceIncrement = Math.Max(1.0f, _markerSizeOnScreen.X / _mapCoordinateScale / 10); // Increment by a fraction of marker width in JSON units

            while (!placed)
            {
                for (int i = 0; i < maxAttemptsPerDistance; i++)
                {
                    float angle = (float)(i * (2 * Math.PI / maxAttemptsPerDistance));
                    Vector2 potentialPoint = new Vector2(
                        anchorScene.Point.X + (float)(currentSearchDistance * Math.Cos(angle)),
                        anchorScene.Point.Y + (float)(currentSearchDistance * Math.Sin(angle))
                    );

                    sceneToPlace.Point = potentialPoint;
                    if (!CheckCollision(sceneToPlace))
                    {
                        placed = true;
                        break;
                    }
                }

                if (!placed)
                {
                    currentSearchDistance += distanceIncrement; // Increase search radius if no spot found
                    if (currentSearchDistance > targetJsonDistance * 5 && targetJsonDistance > 0) { // Safety break for extreme cases, cap search distance
                         // Fallback: place it somewhere simple if it's too hard, e.g. next to anchor with minimal spacing
                        sceneToPlace.Point = new Vector2(anchorScene.Point.X + _markerSizeOnScreen.X / _mapCoordinateScale , anchorScene.Point.Y);
                        if(CheckCollision(sceneToPlace)) { // one last attempt to shift it slightly if still colliding
                             sceneToPlace.Point = new Vector2(anchorScene.Point.X - _markerSizeOnScreen.X / _mapCoordinateScale , anchorScene.Point.Y);
                        }
                         // if still colliding, it might overlap. Consider further fallback strategies.
                        placed = true; // Force placement
                        Console.WriteLine($"Warning: Could not place scene {sceneToPlace.Id} ('{sceneToPlace.Name}') without potential overlap after extensive search. Forced placement.");
                        break;
                    }
                     if (targetJsonDistance == 0 && currentSearchDistance > _markerSizeOnScreen.X * 3 / _mapCoordinateScale) { // Safety break if travel time is 0
                        sceneToPlace.Point = new Vector2(anchorScene.Point.X + _markerSizeOnScreen.X / _mapCoordinateScale, anchorScene.Point.Y);
                        placed = true;
                        Console.WriteLine($"Warning: Scene {sceneToPlace.Id} ('{sceneToPlace.Name}') has 0 travel time and could not be placed without overlap. Forced placement.");
                        break;
                    }
                }
            }
        }

        private bool CheckCollision(Scene sceneToCheck)
        {
            // Calculate marker rectangle in JSON coordinate space
            // Assumes Point is the center of the marker for collision checking ease
            // Or, adjust if Point is top-left. For this example, let's assume Point is center.
            // Width and Height in JSON units
            float markerWidthInJson = _markerSizeOnScreen.X / _mapCoordinateScale;
            float markerHeightInJson = _markerSizeOnScreen.Y / _mapCoordinateScale;

            float sceneLeft = sceneToCheck.Point.X - markerWidthInJson / 2;
            float sceneRight = sceneToCheck.Point.X + markerWidthInJson / 2;
            float sceneTop = sceneToCheck.Point.Y - markerHeightInJson / 2;
            float sceneBottom = sceneToCheck.Point.Y + markerHeightInJson / 2;

            foreach (var placedScene in _scenes.Where(s => s.IsPlaced && s.Id != sceneToCheck.Id))
            {
                float otherLeft = placedScene.Point.X - markerWidthInJson / 2;
                float otherRight = placedScene.Point.X + markerWidthInJson / 2;
                float otherTop = placedScene.Point.Y - markerHeightInJson / 2;
                float otherBottom = placedScene.Point.Y + markerHeightInJson / 2;

                // Check for overlap (AABB collision)
                if (sceneLeft < otherRight && sceneRight > otherLeft &&
                    sceneTop < otherBottom && sceneBottom > otherTop)
                {
                    return true; // Collision detected
                }
            }
            return false; // No collision
        }

        // Static method to load, process, and save JSON
        public static void ProcessMapFile(string jsonFilePath, Vector2 markerSize, float coordinateScale, float baseDistanceUnit)
        {
            try
            {
                string jsonString = File.ReadAllText(jsonFilePath);
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true, // Helpful if JSON casing varies
                    Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) } // Ensure enums are handled correctly
                };
                List<Scene>? scenes = JsonSerializer.Deserialize<List<Scene>>(jsonString, options);

                if (scenes == null || !scenes.Any())
                {
                    Console.WriteLine("No scenes found or failed to deserialize.");
                    return;
                }

                MapJsonGenerator generator = new MapJsonGenerator(scenes, markerSize, coordinateScale, baseDistanceUnit);
                generator.GenerateCoordinates(); // This updates X and Y in the scene objects

                // Serialize back to JSON with new coordinates
                // We need to convert List<Scene> back to List<Dictionary<string, object>> 
                // if we want to preserve original JSON structure and dynamic properties not in Scene class
                // Or, if the Scene class covers all fields, we can serialize it directly.
                // For simplicity, let's assume direct serialization of List<Scene> is acceptable for now.
                // If not, a custom conversion back to dictionary or JObject list is needed.
                var outputOptions = new JsonSerializerOptions
                {
                    WriteIndented = true,
                    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
                    // Ensure enum values are written as strings
                    Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) } 
                };
                string outputJson = JsonSerializer.Serialize(scenes, outputOptions);
                File.WriteAllText(jsonFilePath, outputJson);
                Console.WriteLine($"Successfully processed and updated {jsonFilePath}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error processing map file: {ex.Message}");
                // Consider more robust error handling/logging for an editor tool
            }
        }
    }
} 