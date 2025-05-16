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

            const double AverageResidentsPerHouse = 3.0; 
            const double InfrastructureToHousingRatio = 0.6; 

            int requiredHousingScenes = (int)Math.Ceiling(TargetPopulation / AverageResidentsPerHouse);
            if (requiredHousingScenes == 0 && TargetPopulation > 0) requiredHousingScenes = 1;
            
            int infrastructureScenes = (int)Math.Ceiling(requiredHousingScenes * InfrastructureToHousingRatio);
            int initialScenesNeeded = requiredHousingScenes + infrastructureScenes;
            if (initialScenesNeeded == 0 && TargetPopulation > 0) initialScenesNeeded = 1;
            
            int scenesNeeded = initialScenesNeeded;

            var config = new LocationGenerationConfig
            {
                LocationName = $"{NewLocationName}_Pop{TargetPopulation}",
                SceneCounts = new Dictionary<SceneType, int>()
            };
            
            List<SceneType> allSceneTypes = Enum.GetValues(typeof(SceneType)).Cast<SceneType>().ToList();
            Random random = new Random();

            var excludedUrbanTypes = new List<SceneType> { SceneType.Town, SceneType.District, SceneType.Road };
            var nonCityTypes = new List<SceneType> { SceneType.Mine, SceneType.Forest, SceneType.Cave, SceneType.Ruins };


            // 1. Гарантированное количество жилых сцен (House)
            if (allSceneTypes.Contains(SceneType.House) && scenesNeeded > 0 && requiredHousingScenes > 0)
            {
                int housesToAdd = Math.Min(requiredHousingScenes, scenesNeeded);
                config.SceneCounts[SceneType.House] = housesToAdd;
                scenesNeeded -= housesToAdd;
            }
            else if (requiredHousingScenes > 0)
            {
                ShowNotification("Тип сцены 'House' не найден, невозможно сгенерировать жилье!");
            }

            // 2. Инфраструктура по вехам населения (Milestone Infrastructure)
            var milestoneInfrastructure = new List<Tuple<SceneType, int, int>> // Тип, Порог населения для *каждой* единицы, Макс. кол-во (0 если нет явного максимума сверх расчета)
            {
                Tuple.Create(SceneType.Blacksmith, 100, 0),
                Tuple.Create(SceneType.AlchemistShop, 100, 0),
                Tuple.Create(SceneType.Tavern, 100, 0),
                Tuple.Create(SceneType.Brothel, 200, TargetPopulation > 1000 ? 3 : (TargetPopulation > 500 ? 2 : 1) ), // Максимум борделей
                Tuple.Create(SceneType.Cathedral, 500, 1) // Максимум 1 собор
            };

            foreach (var rule in milestoneInfrastructure)
            {
                if (!allSceneTypes.Contains(rule.Item1) || scenesNeeded == 0 || excludedUrbanTypes.Contains(rule.Item1) || nonCityTypes.Contains(rule.Item1)) continue;

                int desiredCount = (int)Math.Ceiling((double)TargetPopulation / rule.Item2);
                if (rule.Item3 > 0) // Если есть максимум
                {
                    desiredCount = Math.Min(desiredCount, rule.Item3);
                }
                
                int currentCount = config.SceneCounts.GetValueOrDefault(rule.Item1, 0);
                int countToAdd = Math.Max(0, desiredCount - currentCount); // Добавляем только то, чего не хватает
                countToAdd = Math.Min(countToAdd, scenesNeeded);

                if (countToAdd > 0)
                {
                    config.SceneCounts[rule.Item1] = currentCount + countToAdd;
                    scenesNeeded -= countToAdd;
                }
            }
            
            // 3. Масштабируемые ключевые службы (бывший typesToScale, District и Tavern удалены)
            var typesToScale = new List<Tuple<SceneType, double, int, bool>> 
            { 
                Tuple.Create(SceneType.Shop,     0.25, 20, true),
                Tuple.Create(SceneType.Square,   0.15, 5, true) // Уменьшил макс. кол-во площадей
            };

            foreach (var scaleRule in typesToScale)
            {
                if (!allSceneTypes.Contains(scaleRule.Item1) || scenesNeeded == 0 || excludedUrbanTypes.Contains(scaleRule.Item1) || nonCityTypes.Contains(scaleRule.Item1)) continue;

                int baseCountForCalc = infrastructureScenes; 
                int desiredCount = (int)Math.Ceiling(baseCountForCalc * scaleRule.Item2);
                if (scaleRule.Item4) desiredCount = Math.Max(1, desiredCount); 
                
                desiredCount = Math.Min(desiredCount, scaleRule.Item3); 

                int currentCount = config.SceneCounts.GetValueOrDefault(scaleRule.Item1, 0);
                int countToAdd = Math.Max(0, desiredCount - currentCount);
                countToAdd = Math.Min(countToAdd, scenesNeeded);   

                if (countToAdd > 0)
                {
                    config.SceneCounts[scaleRule.Item1] = currentCount + countToAdd;
                    scenesNeeded -= countToAdd;
                }
            }
            
            // 4. Ключевые "уникальные" строения (Cathedral удален, Town/District исключены)
            var uniqueTypeRules = new List<Tuple<SceneType, int, int>>
            {
                Tuple.Create(SceneType.Castle, 600, TargetPopulation > 1200 ? 2 : 1),
                Tuple.Create(SceneType.Temple, 400, TargetPopulation > 800 ? 2 : (initialScenesNeeded > 10 ? 1 : 0)),
                Tuple.Create(SceneType.Manor,  300, TargetPopulation > 700 ? 3 : (initialScenesNeeded > 5 ? 1 : 0)),
                Tuple.Create(SceneType.Military, 500, TargetPopulation > 1000 ? 2 : (initialScenesNeeded > 8 ? 1 : 0)),
                Tuple.Create(SceneType.Cloister, 500, 1)  
            };

            foreach(var rule in uniqueTypeRules)
            {
                if (!allSceneTypes.Contains(rule.Item1) || scenesNeeded == 0 || excludedUrbanTypes.Contains(rule.Item1) || nonCityTypes.Contains(rule.Item1)) continue;

                int numToAdd = 0;
                int currentTypeCount = config.SceneCounts.GetValueOrDefault(rule.Item1, 0);
                
                if (TargetPopulation >= rule.Item2 && currentTypeCount < rule.Item3)
                {
                    numToAdd = Math.Min(rule.Item3 - currentTypeCount, scenesNeeded);
                }
                else if (currentTypeCount == 0 && initialScenesNeeded > (rule.Item1 == SceneType.Castle ? 15 : 10) && currentTypeCount < rule.Item3 )
                {
                     numToAdd = Math.Min(1, scenesNeeded); // Добавить 1, если еще нет, но город большой
                }
                
                // Эта строка может быть избыточной или неверной, если numToAdd уже рассчитан до rule.Item3
                // numToAdd = Math.Min(numToAdd, rule.Item3 - currentTypeCount); 
                numToAdd = Math.Max(0, numToAdd); // Убедимся, что не отрицательное
                numToAdd = Math.Min(numToAdd, scenesNeeded);


                if (numToAdd > 0)
                {
                    config.SceneCounts[rule.Item1] = currentTypeCount + numToAdd;
                    scenesNeeded -= numToAdd;
                }
            }

            // 5. Обеспечение разнообразия для крупных городов (например, население >= 500)
            if (TargetPopulation >= 300 && scenesNeeded > 0) // Порог можно настроить
            {
                var desirableUrbanSceneTypes = new List<SceneType>
                {
                    // Основные городские службы, которые должны быть почти всегда
                    SceneType.Shop, SceneType.Square, SceneType.Tavern, SceneType.Blacksmith, SceneType.AlchemistShop,
                    // Важные, но менее частые
                    SceneType.Temple, SceneType.Manor, SceneType.Military, 
                    // Редкие или специфичные
                    SceneType.Castle, SceneType.Cathedral, SceneType.Cloister, SceneType.Brothel, 
                    // Вспомогательные
                    SceneType.Cemetery, SceneType.Warehouse, SceneType.Bookstore, SceneType.Bathhouse, SceneType.Docks, SceneType.Crypt
                }.Distinct().ToList(); // Убираем дубликаты, если они случайно появятся

                foreach (var desirableType in desirableUrbanSceneTypes)
                {
                    if (scenesNeeded == 0) break;
                    if (excludedUrbanTypes.Contains(desirableType) || nonCityTypes.Contains(desirableType) || desirableType == SceneType.House) continue;

                    if (!config.SceneCounts.ContainsKey(desirableType) || config.SceneCounts[desirableType] == 0)
                    {
                        if (CheckIfTypeCanBeAdded(desirableType, config.SceneCounts, uniqueTypeRules, typesToScale, milestoneInfrastructure))
                        {
                            config.SceneCounts[desirableType] = config.SceneCounts.GetValueOrDefault(desirableType, 0) + 1;
                            scenesNeeded--;
                        }
                    }
                }
            }

            // 6. Взвешенное распределение оставшихся сцен
            if (scenesNeeded > 0)
            {
                var locationTypeWeights = CalculateLocationTypeWeightsFromSwiftData();
                List<SceneType> varietyPool = allSceneTypes
                    .Where(st => !excludedUrbanTypes.Contains(st) && !nonCityTypes.Contains(st) && st != SceneType.House)
                    .ToList();

                // Убираем типы, которые уже достигли своих максимумов
                varietyPool.RemoveAll(st => !CheckIfTypeCanBeAdded(st, config.SceneCounts, uniqueTypeRules, typesToScale, milestoneInfrastructure));
                
                var weightedList = varietyPool
                    .Select(st => new { SceneType = st, Weight = locationTypeWeights.GetValueOrDefault(st, 0) })
                    .Where(x => x.Weight > 0) 
                    .OrderByDescending(x => x.Weight) 
                    .ToList();
                
                int totalWeight = weightedList.Sum(x => x.Weight);

                while (scenesNeeded > 0 && totalWeight > 0 && weightedList.Any())
                {
                    int randomNumber = random.Next(totalWeight);
                    SceneType chosenType = SceneType.Shop; // Default, будет перезаписан
                    int cumulativeWeight = 0;
                    bool found = false;
                    foreach (var item in weightedList)
                    {
                        cumulativeWeight += item.Weight;
                        if (randomNumber < cumulativeWeight)
                        {
                            chosenType = item.SceneType;
                            found = true;
                            break;
                        }
                    }
                    if (!found && weightedList.Any()) chosenType = weightedList.First().SceneType;
                    else if (!found) { break; } 

                    if (CheckIfTypeCanBeAdded(chosenType, config.SceneCounts, uniqueTypeRules, typesToScale, milestoneInfrastructure))
                    {
                        config.SceneCounts[chosenType] = config.SceneCounts.GetValueOrDefault(chosenType, 0) + 1;
                        scenesNeeded--;
                        // Если тип после добавления достиг лимита, его нужно убрать из weightedList для след. итераций
                        if (!CheckIfTypeCanBeAdded(chosenType, config.SceneCounts, uniqueTypeRules, typesToScale, milestoneInfrastructure))
                        {
                             weightedList.RemoveAll(item => item.SceneType == chosenType);
                             totalWeight = weightedList.Sum(x => x.Weight); // Пересчитать
                        }
                    }
                    else
                    {
                        // Если тип достиг максимума, убираем его из дальнейшего рассмотрения
                        weightedList.RemoveAll(item => item.SceneType == chosenType);
                        totalWeight = weightedList.Sum(x => x.Weight); 
                        if (!weightedList.Any() || totalWeight == 0) break; 
                    }
                }
            }
            
            // 7. Заполнение (Fallback)
            if (scenesNeeded > 0)
            {
                var fallbackCandidates = allSceneTypes
                    .Where(st => !excludedUrbanTypes.Contains(st) && !nonCityTypes.Contains(st) && st != SceneType.House)
                    .OrderBy(st => config.SceneCounts.GetValueOrDefault(st, 0)) // Предпочитаем те, которых меньше
                    .ToList();

                while (scenesNeeded > 0 && fallbackCandidates.Any())
                {
                    bool addedInLoop = false;
                    foreach (var fallbackType in fallbackCandidates)
                    {
                        if (scenesNeeded == 0) break;
                        if (CheckIfTypeCanBeAdded(fallbackType, config.SceneCounts, uniqueTypeRules, typesToScale, milestoneInfrastructure))
                        {
                            config.SceneCounts[fallbackType] = config.SceneCounts.GetValueOrDefault(fallbackType, 0) + 1;
                            scenesNeeded--;
                            addedInLoop = true;
                        }
                    }
                    if (!addedInLoop) break; // Если за целый проход по кандидатам ничего не добавили (все уперлись в лимиты)
                }
            }

            if (!config.SceneCounts.Any())
            {
                ShowNotification("Не удалось определить типы сцен для генерации по населению.");
                return;
            }
            
            var generator = new LocationGenerator();
            List<Scene> generatedScenes = generator.GenerateLocation(config);
            generatedScenes = generatedScenes.OrderBy(s => s.SceneType.ToString()).ThenBy(s => s.Name).ToList();
            generator.SaveScenesToFile(generatedScenes, Constants.ScenesPath);
            ShowNotification($"Локация для населения {TargetPopulation} ('{config.LocationName}') успешно сгенерирована! Сцен создано: {generatedScenes.Count}");
            
            await LoadScenesAsync();
        }

        private bool CheckIfTypeCanBeAdded(SceneType type, IReadOnlyDictionary<SceneType, int> currentCounts,
                                   List<Tuple<SceneType, int, int>> uniqueRules,
                                   List<Tuple<SceneType, double, int, bool>> scaleRules,
                                   List<Tuple<SceneType, int, int>> milestoneRules)
        {
            int currentCount = currentCounts.GetValueOrDefault(type, 0);

            var uniqueRule = uniqueRules.FirstOrDefault(r => r.Item1 == type);
            if (uniqueRule != null && currentCount >= uniqueRule.Item3) return false;

            var scaleRule = scaleRules.FirstOrDefault(r => r.Item1 == type);
            if (scaleRule != null && currentCount >= scaleRule.Item3) return false;
    
            var milestoneRule = milestoneRules.FirstOrDefault(r => r.Item1 == type);
            // Для milestoneRule.Item3 == 0 означает "нет явного максимума сверх расчета по количеству на порог населения"
            // Поэтому проверяем >= milestoneRule.Item3 только если milestoneRule.Item3 > 0
            if (milestoneRule != null && milestoneRule.Item3 > 0 && currentCount >= milestoneRule.Item3) return false; 

            return true;
        }

        private int GetTypeLimit(SceneType type,
                                 List<Tuple<SceneType, int, int>> uniqueRules,
                                 List<Tuple<SceneType, double, int, bool>> scaleRules,
                                 List<Tuple<SceneType, int, int>> milestoneRules)
        {
            int limit = int.MaxValue; 

            var uniqueRule = uniqueRules.FirstOrDefault(r => r.Item1 == type);
            if (uniqueRule != null) limit = Math.Min(limit, uniqueRule.Item3);

            var scaleRule = scaleRules.FirstOrDefault(r => r.Item1 == type);
            if (scaleRule != null) limit = Math.Min(limit, scaleRule.Item3);

            var milestoneRule = milestoneRules.FirstOrDefault(r => r.Item1 == type);
            if (milestoneRule != null && milestoneRule.Item3 > 0) limit = Math.Min(limit, milestoneRule.Item3);

            return limit == int.MaxValue ? 0 : limit; // 0 означает "нет специфического лимита из этих правил"
        }

        private Dictionary<string, SceneType[]> GetSwiftToCSharpSceneTypeMapping()
        {
            return new Dictionary<string, SceneType[]>
            {
                // Town исключен из всех сопоставлений
                { "castle", new[] { SceneType.Castle } },
                { "cathedral", new[] { SceneType.Cathedral } },
                { "cloister", new[] { SceneType.Cloister } }, 
                { "cemetery", new[] { SceneType.Cemetery } },
                { "temple", new[] { SceneType.Temple } },
                { "crypt", new[] { SceneType.Crypt } },
                { "manor", new[] { SceneType.Manor, SceneType.Castle } }, // Town убран
                { "military", new[] { SceneType.Military, SceneType.Castle } }, // Town убран
                { "blacksmith", new[] { SceneType.Blacksmith } },
                { "alchemistShop", new[] { SceneType.AlchemistShop } },
                { "warehouse", new[] { SceneType.Warehouse, SceneType.Shop } }, // Town убран, Shop как альтернатива для склада в "городе"
                { "bookstore", new[] { SceneType.Bookstore } },
                { "shop", new[] { SceneType.Shop } }, 
                { "mine", new[] { SceneType.Mine } },
                { "tavern", new[] { SceneType.Tavern } },
                { "brothel", new[] { SceneType.Brothel } },
                { "bathhouse", new[] { SceneType.Bathhouse } },
                { "square", new[] { SceneType.Square } },
                { "docks", new[] { SceneType.Docks } }, // Town убран
                { "road", new[] { SceneType.Road } }, 
                { "forest", new[] { SceneType.Forest } },
                { "cave", new[] { SceneType.Cave } },
                { "ruins", new[] { SceneType.Ruins } },
                { "house", new[] { SceneType.House } }, 
                { "dungeon", new[] { SceneType.Dungeon } },
                { "cottage", new[] { SceneType.House } }, 
                { "barracks", new[] { SceneType.Military, SceneType.Castle } }, // Town убран
                { "keep", new[] { SceneType.Castle, SceneType.Manor } }, // Town убран
                { "market", new[] { SceneType.Square, SceneType.Shop } }, // Town убран
                { "watchtower", new[] { SceneType.Military, SceneType.Castle, SceneType.Ruins } } 
                // Запись "town" -> SceneType.Town удалена
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
            // Инициализируем веса для всех актуальных C# SceneType
            foreach (SceneType type in Enum.GetValues(typeof(SceneType)))
            {
                weights[type] = 0; 
            }

            var mapping = GetSwiftToCSharpSceneTypeMapping();
            var allMentions = GetAllSwiftValidLocationTypeMentions(); // Этот метод не менялся

            foreach (string mention in allMentions)
            {
                if (mapping.TryGetValue(mention, out SceneType[]? csharpTypes))
                {
                    if (csharpTypes != null)
                    {
                        foreach (SceneType csharpType in csharpTypes)
                        {
                            // Убедимся, что такой тип есть в нашем enum (должен быть после инициализации)
                            if (weights.ContainsKey(csharpType))
                            { 
                                weights[csharpType]++;
                            }
                        }
                    }
                }
            }
            return weights;
        }
    }
} 