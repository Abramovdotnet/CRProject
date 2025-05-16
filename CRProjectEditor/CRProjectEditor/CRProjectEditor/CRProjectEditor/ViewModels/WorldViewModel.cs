using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CRProjectEditor.Models;
using CRProjectEditor.Tools;
using CRProjectEditor.Views; // Для NotificationWindow
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Numerics; // Для Vector2
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using System.Windows; // Для Application.Current
using System.Windows.Input; // For ICommand

namespace CRProjectEditor.ViewModels
{
    // Вспомогательный класс для настройки количества сцен каждого типа
    public partial class SceneTypeCountSetting : ObservableObject
    {
        public SceneType SceneType { get; }
        public string SceneTypeName => SceneType.ToString();

        [ObservableProperty]
        private int _count;

        public SceneTypeCountSetting(SceneType sceneType, int initialCount = 0)
        {
            SceneType = sceneType;
            _count = initialCount;
        }
    }

    public partial class WorldViewModel : ObservableObject
    {
        public string ViewModelDisplayName => "World";

        private ObservableCollection<Scene> _scenes = new ObservableCollection<Scene>();
        public ObservableCollection<Scene> Scenes
        {
            get => _scenes;
            set => SetProperty(ref _scenes, value);
        }

        [ObservableProperty]
        private string _newLocationName = "НоваяЛокация";

        public ObservableCollection<SceneTypeCountSetting> SceneTypeConfigs { get; }

        [ObservableProperty]
        private int _targetPopulation = 100; // Default population

        public ICommand GenerateLocationCommand { get; }
        public ICommand GenerateCoordinatesCommand { get; }
        public ICommand GenerateLocationForPopulationCommand { get; } // New command

        public WorldViewModel()
        {
            SceneTypeConfigs = new ObservableCollection<SceneTypeCountSetting>();
            foreach (SceneType type in Enum.GetValues(typeof(SceneType)))
            {
                SceneTypeConfigs.Add(new SceneTypeCountSetting(type));
            }

            GenerateLocationCommand = new AsyncRelayCommand(GenerateLocationAndRefreshAsync);
            GenerateCoordinatesCommand = new AsyncRelayCommand(GenerateCoordinatesAndRefreshAsync);
            GenerateLocationForPopulationCommand = new AsyncRelayCommand(GenerateLocationForPopulationAndRefreshAsync); // Initialize new command
            _ = LoadScenesAsync(); 
        }

        private void ShowNotification(string message)
        {
            Application.Current.Dispatcher.Invoke(() =>
            {
                var notificationWindow = new NotificationWindow(message)
                {
                    Owner = Application.Current.MainWindow
                };
                notificationWindow.ShowDialog();
            });
        }

        private async Task LoadScenesAsync()
        {
            try
            {
                if (!File.Exists(Constants.ScenesPath))
                {
                    System.Diagnostics.Debug.WriteLine($"Файл сцен не найден: {Constants.ScenesPath}");
                    App.Current.Dispatcher.Invoke(() => Scenes.Clear());
                    return;
                }

                string jsonString = await File.ReadAllTextAsync(Constants.ScenesPath);
                if (string.IsNullOrWhiteSpace(jsonString))
                {
                    System.Diagnostics.Debug.WriteLine("Файл сцен пуст.");
                    App.Current.Dispatcher.Invoke(() => Scenes.Clear());
                    return;
                }

                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true,
                    Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) }
                };
                var loadedScenes = JsonSerializer.Deserialize<ObservableCollection<Scene>>(jsonString, options);

                App.Current.Dispatcher.Invoke(() =>
                {
                    Scenes = loadedScenes ?? new ObservableCollection<Scene>();
                });
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Ошибка загрузки сцен: {ex.Message}");
                ShowNotification($"Ошибка загрузки сцен: {ex.Message}");
                App.Current.Dispatcher.Invoke(() => Scenes.Clear());
            }
        }

        private async Task GenerateLocationAndRefreshAsync()
        {
            var config = new LocationGenerationConfig
            {
                LocationName = NewLocationName,
                SceneCounts = new Dictionary<SceneType, int>()
            };

            foreach (var typeConfig in SceneTypeConfigs)
            {
                if (typeConfig.Count > 0)
                {
                    config.SceneCounts[typeConfig.SceneType] = typeConfig.Count;
                }
            }

            if (!config.SceneCounts.Any())
            {
                ShowNotification("Не выбрано ни одной сцены для генерации. Укажите количество для хотя бы одного типа сцен.");
                return;
            }

            var generator = new LocationGenerator();
            List<Scene> generatedScenes = generator.GenerateLocation(config);
            generator.SaveScenesToFile(generatedScenes, Constants.ScenesPath);
            ShowNotification($"Локация '{NewLocationName}' успешно сгенерирована и сохранена!\nСцен создано: {generatedScenes.Count}");
            
            await LoadScenesAsync();
        }

        private async Task GenerateCoordinatesAndRefreshAsync()
        {
            if (!Scenes.Any())
            {
                ShowNotification("Нет сцен для генерации координат. Сначала загрузите или сгенерируйте локацию.");
                return;
            }

            // Измененные значения для генератора координат
            Vector2 markerSize = new Vector2(5, 5); // Уменьшим и это, чтобы маркеры были "меньше" в единицах JSON
            float coordinateScale = 1.0f; 
            float baseDistanceUnit = 1.0f; // Значительно уменьшено

            try
            {
                // MapJsonGenerator.ProcessMapFile ожидает путь к файлу.
                // Он сам прочитает, обновит координаты и сохранит.
                MapJsonGenerator.ProcessMapFile(Constants.ScenesPath, markerSize, coordinateScale, baseDistanceUnit);
                ShowNotification("Координаты для текущих сцен успешно сгенерированы и сохранены.");
            }
            catch (Exception ex)
            {
                ShowNotification($"Ошибка при генерации координат: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"Ошибка генерации координат: {ex.Message}");
            }
            
            await LoadScenesAsync(); // Перезагружаем сцены, чтобы увидеть обновленные X, Y
        }

        private async Task GenerateLocationForPopulationAndRefreshAsync()
        {
            if (TargetPopulation <= 0)
            {
                ShowNotification("Целевое население должно быть больше нуля.");
                return;
            }

            int scenesNeeded = (int)Math.Ceiling(TargetPopulation / 30.0);
            if (scenesNeeded == 0) scenesNeeded = 1; // Ensure at least one scene

            var config = new LocationGenerationConfig
            {
                LocationName = $"{NewLocationName}_Pop{TargetPopulation}", // Auto-generate name
                SceneCounts = new Dictionary<SceneType, int>()
            };
            
            List<SceneType> availableTypes = Enum.GetValues(typeof(SceneType)).Cast<SceneType>()
                                                .Where(st => st != SceneType.Generic) 
                                                .ToList();
            Random random = new Random();

            // 1. Обеспечить центральный хаб (Town/Village)
            if (scenesNeeded > 0 && availableTypes.Contains(SceneType.Town))
            {
                config.SceneCounts[SceneType.Town] = config.SceneCounts.GetValueOrDefault(SceneType.Town, 0) + 1;
                scenesNeeded--;
            }
            else if (scenesNeeded > 0 && availableTypes.Contains(SceneType.Village)) 
            {
                 config.SceneCounts[SceneType.Village] = config.SceneCounts.GetValueOrDefault(SceneType.Village, 0) + 1;
                 scenesNeeded--;
            }

            // 2. Добавить общие объекты (Tavern, Shop, Square)
            SceneType[] commonUtilities = { SceneType.Tavern, SceneType.Shop, SceneType.Square };
            foreach(var utilityType in commonUtilities)
            {
                if (scenesNeeded > 0 && availableTypes.Contains(utilityType))
                {
                    config.SceneCounts[utilityType] = config.SceneCounts.GetValueOrDefault(utilityType, 0) + 1;
                    scenesNeeded--;
                }
            }
            
            // 3. Распределить оставшиеся сцены на основе весов из NPCActivityType.swift
            if (scenesNeeded > 0)
            {
                var locationTypeWeights = CalculateLocationTypeWeightsFromSwiftData();
                
                List<SceneType> weightedVarietyTypes = availableTypes
                    .Except(commonUtilities)
                    .Except(new[] { SceneType.Town, SceneType.Village, SceneType.City })
                    .Where(st => locationTypeWeights.ContainsKey(st) && locationTypeWeights[st] > 0)
                    .ToList();

                if (weightedVarietyTypes.Any())
                {
                    var weightedList = weightedVarietyTypes
                        .Select(st => new { SceneType = st, Weight = locationTypeWeights[st] })
                        .ToList();
                    int totalWeight = weightedList.Sum(x => x.Weight);

                    while (scenesNeeded > 0 && totalWeight > 0 && weightedList.Any()) // Добавил weightedList.Any()
                    {
                        int randomNumber = random.Next(totalWeight);
                        SceneType chosenType = SceneType.Generic; // Fallback, should be replaced
                        
                        int cumulativeWeight = 0;
                        bool chosen = false;
                        foreach (var item in weightedList)
                        {
                            cumulativeWeight += item.Weight;
                            if (randomNumber < cumulativeWeight)
                            {
                                chosenType = item.SceneType;
                                chosen = true;
                                break;
                            }
                        }
                        // Если totalWeight > 0, но все веса элементов = 0 (маловероятно тут, но для защиты)
                        // или если random.Next(totalWeight) вернул значение, приводящее к выходу за пределы
                        if (!chosen && weightedList.Any()) chosenType = weightedList.First().SceneType;


                        if (chosenType != SceneType.Generic) // Убедимся что выбрали что-то конкретное
                        {
                             config.SceneCounts[chosenType] = config.SceneCounts.GetValueOrDefault(chosenType, 0) + 1;
                             scenesNeeded--;
                        }
                        else // Если не удалось выбрать по весам (например, все веса 0), прерываем цикл взвешенного выбора
                        {
                            break; 
                        }

                        // Для простоты, позволяем многократный выбор одного типа по весу.
                        // Если нужно уникальные, можно убирать/уменьшать вес.
                    }
                }
            }
            
            // 4. Если все еще нужны сцены (например, типы с весами закончились или их не было)
            //    используем логику отката: добавляем в Town/Village или первый доступный тип.
            if (scenesNeeded > 0)
            {
                if (config.SceneCounts.ContainsKey(SceneType.Town))
                    config.SceneCounts[SceneType.Town] += scenesNeeded;
                else if (config.SceneCounts.ContainsKey(SceneType.Village))
                    config.SceneCounts[SceneType.Village] += scenesNeeded;
                else if (availableTypes.Any()) 
                {
                    var fallbackType = availableTypes.FirstOrDefault(st => st != SceneType.City && !commonUtilities.Contains(st) && st != SceneType.Town && st != SceneType.Village);
                    if (fallbackType == default(SceneType) && availableTypes.Any()) fallbackType = availableTypes.First(); // самый общий откат
                     
                    if(fallbackType != default(SceneType)) // Убедимся что нашли тип для отката
                         config.SceneCounts[fallbackType] = config.SceneCounts.GetValueOrDefault(fallbackType, 0) + scenesNeeded;
                    else // Крайний случай: если вообще нет доступных типов (не должно произойти)
                         ShowNotification($"Не удалось распределить {scenesNeeded} сцен. Нет доступных типов.");
                }
                scenesNeeded = 0;
            }

            if (!config.SceneCounts.Any())
            {
                ShowNotification("Не удалось определить типы сцен для генерации по населению.");
                return;
            }
            
            var generator = new LocationGenerator();
            List<Scene> generatedScenes = generator.GenerateLocation(config);
            generator.SaveScenesToFile(generatedScenes, Constants.ScenesPath);
            ShowNotification($"Локация для населения {TargetPopulation} ('{config.LocationName}') успешно сгенерирована!\\nСцен создано: {generatedScenes.Count}");
            
            await LoadScenesAsync();
        }

        private Dictionary<string, SceneType[]> GetSwiftToCSharpSceneTypeMapping()
        {
            return new Dictionary<string, SceneType[]>
            {
                { "tavern", new[] { SceneType.Tavern } },
                { "house", new[] { SceneType.Village } },
                { "cottage", new[] { SceneType.Village } },
                { "manor", new[] { SceneType.Castle, SceneType.Town } },
                { "keep", new[] { SceneType.Castle } },
                { "barracks", new[] { SceneType.Castle, SceneType.Town } },
                { "brothel", new[] { SceneType.Shop, SceneType.Tavern } },
                { "shop", new[] { SceneType.Shop } },
                { "temple", new[] { SceneType.Temple } },
                { "cathedral", new[] { SceneType.Temple } },
                { "monastery", new[] { SceneType.Temple } },
                { "square", new[] { SceneType.Square } },
                { "market", new[] { SceneType.Square, SceneType.Town } },
                { "blacksmith", new[] { SceneType.Shop } },
                { "alchemistShop", new[] { SceneType.Shop } },
                { "bookstore", new[] { SceneType.Shop } },
                { "military", new[] { SceneType.Castle, SceneType.Town } }, // As a location/building
                { "watchtower", new[] { SceneType.Castle, SceneType.Ruins } },
                { "dungeon", new[] { SceneType.Dungeon } },
                { "cemetery", new[] { SceneType.Crypt } },
                { "crypt", new[] { SceneType.Crypt } }, // Explicitly from .pray
                { "bathhouse", new[] { SceneType.Shop } },
                { "warehouse", new[] { SceneType.Town, SceneType.Shop } },
                { "docks", new[] { SceneType.Town } }
                // SceneType.Forest, Cave, Ruins, Mine не имеют прямых соответствий в validLocationTypes активностей NPC
            };
        }

        private List<string> GetAllSwiftValidLocationTypeMentions()
        {
            // Данные извлечены из файла NPCActivityType.swift (validLocationTypes)
            return new List<string>
            {
                // .sleep
                "house", "manor", "cottage", "barracks", "keep", "brothel",
                // .eat
                "tavern", "house", "manor", "keep", "barracks",
                // .idle
                "shop", "temple",
                // .socialize
                "tavern", "square", "market", "bathhouse", "manor", "cathedral", "brothel", "house", "shop", "temple",
                // .craft
                "blacksmith", "alchemistShop",
                // .sell
                "market", "shop", "tavern", "square",
                // .guardPost
                "military", "watchtower", "barracks", "manor", "brothel", "dungeon",
                // .patrol (ignoring "quarter", "road")
                "square", "brothel", "cemetery", "dungeon",
                // .research
                "bookstore", "cathedral", "monastery", "blacksmith", "alchemistShop", "temple",
                // .train
                "military", "barracks",
                // .manage
                "manor", "keep", "market",
                // .clean
                "house", "manor", "barracks", "keep", "tavern", "brothel", "cemetery", "shop", "temple",
                // .serve
                "tavern", "manor", "keep",
                // .entertain (ignoring "road")
                "tavern", "brothel", "square",
                // .harvest (ignoring "road")
                "square",
                // .cook
                "house", "manor", "tavern",
                // .transport
                "warehouse", "docks", "market",
                // .tendGraves
                "cemetery",
                // .watchOver
                "dungeon",
                // .thieving (ignoring "road")
                "tavern", "market", "brothel", "house", "square", "blacksmith", "alchemistShop", "manor", "cathedral", "shop", "warehouse",
                // .pray
                "cathedral", "monastery", "crypt", "cemetery", "temple",
                // .study
                "bookstore", "cathedral", "temple",
                // .drink (ignoring "road")
                "tavern", "brothel", "house",
                // .gamble
                "tavern", "brothel",
                // .bathe
                "bathhouse", "house", "tavern", "brothel",
                // .explore (ignoring "road")
                "tavern", "market", "manor", "brothel", "blacksmith", "alchemistShop", "bookstore", "square", "military", "bathhouse", "cemetery", "shop", "temple",
                // .mourn
                "cemetery",
                // .quest
                "tavern", "keep", "manor",
                // .smuggle
                "docks", "warehouse",
                // .spy (ignoring "road")
                "brothel", "tavern",
                // .lookingForProtection
                "tavern", "manor",
                // .jailed
                "dungeon",
                // .fleeing
                "military", "watchtower", "barracks", "manor", "tavern", "cathedral", "monastery",
                // .casualty
                "military", "watchtower", "barracks", "manor"
            };
        }

        private Dictionary<SceneType, int> CalculateLocationTypeWeightsFromSwiftData()
        {
            var weights = new Dictionary<SceneType, int>();
            foreach (SceneType type in Enum.GetValues(typeof(SceneType)))
            {
                weights[type] = 0; // Initialize all weights to 0
            }

            var mapping = GetSwiftToCSharpSceneTypeMapping();
            var allMentions = GetAllSwiftValidLocationTypeMentions();

            foreach (string mention in allMentions)
            {
                if (mapping.TryGetValue(mention, out SceneType[]? csharpTypes))
                {
                    if (csharpTypes != null)
                    {
                        foreach (SceneType csharpType in csharpTypes)
                        {
                            weights[csharpType]++;
                        }
                    }
                }
            }
            return weights;
        }
    }
} 