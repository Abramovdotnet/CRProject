using CRProjectEditor.Models;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace CRProjectEditor.Tools
{
    // Конфигурация для генерации локации
    public class LocationGenerationConfig
    {
        public string LocationName { get; set; } = "GeneratedLocation";
        public Dictionary<SceneType, int> SceneCounts { get; set; } = new Dictionary<SceneType, int>();
        // Сюда можно добавить больше параметров: плотность связей, точки входа/выхода и т.д.
    }

    public class LocationGenerator
    {
        private int _nextSceneId;
        private Random _random = new Random();

        /// <summary>
        /// Генерирует список сцен на основе конфигурации.
        /// </summary>
        public List<Scene> GenerateLocation(LocationGenerationConfig config)
        {
            _nextSceneId = 1; // ID начинаются с 1 для каждой новой генерации
            var generatedScenes = new List<Scene>();

            if (config == null || config.SceneCounts == null || !config.SceneCounts.Any())
            {
                return generatedScenes; // Нечего генерировать
            }

            // 1. Создаем все сцены согласно конфигурации
            foreach (var kvp in config.SceneCounts)
            {
                SceneType type = kvp.Key;
                int count = kvp.Value;
                for (int i = 0; i < count; i++)
                {
                    var newScene = new Scene
                    {
                        Id = _nextSceneId++,
                        Name = $"{config.LocationName}_{type}_{i + 1}", // Пример имени
                        SceneType = type,
                        Description = $"Автоматически сгенерированная сцена типа {type} для локации {config.LocationName}.",
                        IsIndoor = IsTypicallyIndoor(type), // Базовая логика для определения IsIndoor
                        // X, Y, Point, IsPlaced будут установлены позже MapJsonGenerator'ом
                    };
                    generatedScenes.Add(newScene);
                }
            }

            if (!generatedScenes.Any()) return generatedScenes;

            // 2. Связываем сцены между собой
            ConnectGeneratedScenes(generatedScenes, config);

            return generatedScenes;
        }

        // Определяет, является ли тип сцены обычно внутренним помещением
        private bool IsTypicallyIndoor(SceneType type)
        {
            switch (type)
            {
                case SceneType.House:
                case SceneType.Shop:
                case SceneType.Tavern:
                case SceneType.Blacksmith:
                case SceneType.Temple:
                case SceneType.Castle: // Предполагаем, что в основном это внутренние части
                case SceneType.Dungeon:
                case SceneType.Cave:
                case SceneType.Crypt:
                case SceneType.Mine:
                    return true;
                default:
                    return false;
            }
        }

        // Логика связывания сгенерированных сцен
        private void ConnectGeneratedScenes(List<Scene> scenes, LocationGenerationConfig config)
        {
            if (scenes.Count < 2) return; // Недостаточно сцен для связывания

            // SceneType.Town и SceneType.District исключены из списка хабов.
            var hubTypes = new[] { SceneType.Square, SceneType.Tavern }; 
            List<Scene> potentialHubs = scenes.Where(s => hubTypes.Contains(s.SceneType)).ToList();
            
            Scene? mainHub = null;
            if (potentialHubs.Any())
            {
                mainHub = potentialHubs[_random.Next(potentialHubs.Count)];
            }
            else
            {
                mainHub = scenes.First(); // Если хабов нет, берем первую сцену
            }

            List<Scene> connectedScenes = new List<Scene> { mainHub };
            List<Scene> scenesToConnect = scenes.Where(s => s.Id != mainHub.Id).ToList();

            foreach (var scene in scenesToConnect)
            {
                Scene connectToNode;
                if (mainHub != null && _random.NextDouble() < 0.7 && connectedScenes.Contains(mainHub))
                {
                    connectToNode = mainHub;
                }
                else
                {
                     connectToNode = connectedScenes[_random.Next(connectedScenes.Count)];
                }
               
                AddBidirectionalConnection(scene, connectToNode, 1.0 + Math.Round(_random.NextDouble(), 2));
                if (!connectedScenes.Contains(scene))
                {
                    connectedScenes.Add(scene);
                }
            }

            int additionalConnections = Math.Max(0, scenes.Count / 5);
            for (int i = 0; i < additionalConnections; i++)
            {
                if (scenes.Count < 2) break;
                Scene sceneA = scenes[_random.Next(scenes.Count)];
                Scene sceneB = scenes[_random.Next(scenes.Count)];
                
                if (sceneA.Id != sceneB.Id && !AreAlreadyConnected(sceneA, sceneB.Id))
                {
                    AddBidirectionalConnection(sceneA, sceneB, 1.0 + Math.Round(_random.NextDouble(), 2));
                }
            }
        }
        
        private void AddBidirectionalConnection(Scene scene1, Scene scene2, double travelTime)
        {
            if (!AreAlreadyConnected(scene1, scene2.Id))
            {
                scene1.Connections.Add(new SceneConnection { ConnectedSceneId = scene2.Id, TravelTime = travelTime });
            }
            if (!AreAlreadyConnected(scene2, scene1.Id))
            {
                 scene2.Connections.Add(new SceneConnection { ConnectedSceneId = scene1.Id, TravelTime = travelTime });
            }
        }

        private bool AreAlreadyConnected(Scene sourceScene, int targetSceneId)
        {
            return sourceScene.Connections.Any(c => c.ConnectedSceneId == targetSceneId);
        }

        /// <summary>
        /// Сохраняет список сцен в JSON файл, перезаписывая его.
        /// </summary>
        public void SaveScenesToFile(List<Scene> scenes, string filePath)
        {
            try
            {
                var options = new JsonSerializerOptions
                {
                    WriteIndented = true,
                    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
                    Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) } 
                };
                string jsonString = JsonSerializer.Serialize(scenes, options);
                File.WriteAllText(filePath, jsonString);
                Console.WriteLine($"Успешно сохранено {scenes.Count} сцен в файл: {filePath}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка при сохранении сцен в файл: {ex.Message}");
            }
        }
    }
} 