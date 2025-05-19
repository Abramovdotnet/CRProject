using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CRProjectEditor.Models;
using CRProjectEditor.Services; // Added for INotificationService
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
using System.Diagnostics;
using System.Text.RegularExpressions; // For Regex in asset loading
using Microsoft.Win32; // For OpenFileDialog

namespace CRProjectEditor.ViewModels
{
    // Вспомогательный класс для опций фильтра с "Все"
    public class AllFilterPlaceholder
    {
        public string DisplayName { get; set; }
        public AllFilterPlaceholder(string displayName) { DisplayName = displayName; }
        public override string ToString() => DisplayName;
    }

    // Вспомогательный класс для элементов ComboBox фильтров Да/Нет/Все
    public class FilterOption<TValue>
    {
        public string DisplayName { get; set; }
        public TValue Value { get; set; }
        public FilterOption(string displayName, TValue value)
        {
            DisplayName = displayName;
            Value = value;
        }
        public override string ToString() => DisplayName;
    }

    // Вспомогательный класс для парсинга LocationNames.json
    public class LocationNameEntry
    {
        public string Name { get; set; }
        public string SceneType { get; set; }
    }

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
        private readonly INotificationService _notificationService;
        private List<NpcModel> _allNpcs = new List<NpcModel>(); // Список всех NPC
        public string ViewModelDisplayName => "World";

        private ObservableCollection<Scene> _scenes = new ObservableCollection<Scene>();
        public ObservableCollection<Scene> Scenes
        {
            get => _scenes;
            set 
            {
                if (SetProperty(ref _scenes, value))
                {
                    // Если коллекция сцен заменяется, нужно обновить фильтрованные сцены
                    // и переподписаться на CollectionChanged, если это необходимо для динамического обновления фильтров
                    // На данный момент ApplyFilters будет вызван после операций, изменяющих Scenes
                    ApplyFilters(); 
        }
            }
        }

        // --- Начало свойств для фильтрации ---
        [ObservableProperty]
        private string? _searchNameText;

        public ObservableCollection<object> SceneTypesForFilter { get; } = new ObservableCollection<object>();

        [ObservableProperty]
        private object? _selectedSceneTypeForFilter;
        
        public ObservableCollection<FilterOption<bool?>> IndoorOptionsForFilter { get; } = new ObservableCollection<FilterOption<bool?>>();

        [ObservableProperty]
        private FilterOption<bool?>? _selectedIndoorOptionForFilter;

        public ObservableCollection<FilterOption<bool?>> ResidentsOptionsForFilter { get; } = new ObservableCollection<FilterOption<bool?>>();
        
        [ObservableProperty]
        private FilterOption<bool?>? _selectedResidentsOptionForFilter;

        public ObservableCollection<Scene> FilteredScenes { get; } = new ObservableCollection<Scene>();
        // --- Конец свойств для фильтрации ---

        [ObservableProperty]
        private string _newLocationName = "НоваяЛокация";

        public ObservableCollection<SceneTypeCountSetting> SceneTypeConfigs { get; }

        [ObservableProperty]
        private int _targetPopulation = 100; // Default population

        public ICommand GenerateLocationCommand { get; }
        public ICommand GenerateCoordinatesCommand { get; }
        public IAsyncRelayCommand GenerateLocationForPopulationCommand { get; }
        public IAsyncRelayCommand SaveCurrentMapLayoutCommand { get; }

        [ObservableProperty]
        [NotifyCanExecuteChangedFor(nameof(AddConnectionCommand))]
        [NotifyCanExecuteChangedFor(nameof(DeleteAllConnectionsCommand))]
        [NotifyCanExecuteChangedFor(nameof(DeleteSelectedSceneCommand))]
        private Scene? _mapSelectedScene;

        [ObservableProperty]
        [NotifyCanExecuteChangedFor(nameof(AddConnectionCommand))]
        private Scene? _selectedSceneForConnection;

        public ObservableCollection<Scene> AllOtherScenesForConnection { get; } = new ObservableCollection<Scene>();

        public IAsyncRelayCommand AddConnectionCommand { get; }
        public IAsyncRelayCommand DeleteAllConnectionsCommand { get; }
        public IAsyncRelayCommand DeleteSelectedSceneCommand { get; }

        public ICommand EditSceneFromGridCommand { get; }

        public ObservableCollection<SceneType> AvailableSceneTypesForDrag { get; }

        [ObservableProperty]
        private string? _selectedSceneImagePath;

        public ObservableCollection<AssetDisplayInfo> AvailableAssetImages { get; } = new ObservableCollection<AssetDisplayInfo>();

        [ObservableProperty]
        [NotifyPropertyChangedFor(nameof(SelectedAssetPreviewPath))]
        private AssetDisplayInfo? _selectedAsset;

        [ObservableProperty]
        private ObservableCollection<NpcModel> _selectedSceneResidents = new ObservableCollection<NpcModel>();

        // Добавленный частичный метод для реакции на изменение SelectedAsset
        partial void OnSelectedAssetChanged(AssetDisplayInfo? oldValue, AssetDisplayInfo? newValue)
        {
            // Явно уведомляем команду об изменении возможности ее выполнения
            DeleteAssetCommand.NotifyCanExecuteChanged();
            // Также можно обновить другие команды, если они зависят от SelectedAsset
            // Например, если бы у нас была команда "EditSelectedAssetCommand"
            // EditSelectedAssetCommand?.NotifyCanExecuteChanged(); 
        }

        public string? SelectedAssetPreviewPath
        {
            get => SelectedAsset?.ImagePath;
        }

        public IAsyncRelayCommand CreateAssetCommand { get; }
        public IAsyncRelayCommand DeleteAssetCommand { get; }

        public WorldViewModel(INotificationService notificationService)
        {
            _notificationService = notificationService;

            // --- Инициализация фильтров ---
            InitializeFilterOptions();
            // Устанавливаем значения по умолчанию для фильтров (например, "Все")
            _selectedSceneTypeForFilter = SceneTypesForFilter.FirstOrDefault();
            _selectedIndoorOptionForFilter = IndoorOptionsForFilter.FirstOrDefault();
            _selectedResidentsOptionForFilter = ResidentsOptionsForFilter.FirstOrDefault();
            // --- Конец инициализации фильтров ---

            AvailableSceneTypesForDrag = new ObservableCollection<SceneType>();
            foreach (SceneType type in Enum.GetValues(typeof(SceneType)))
            {
                // Optionally, filter out types like Town/District if they shouldn't be drag-creatable
                // if (type != SceneType.Town && type != SceneType.District) 
                // {
                AvailableSceneTypesForDrag.Add(type);
                // }
            }

            SceneTypeConfigs = new ObservableCollection<SceneTypeCountSetting>();
            foreach (SceneType type in Enum.GetValues(typeof(SceneType)))
            {
                SceneTypeConfigs.Add(new SceneTypeCountSetting(type));
            }

            GenerateLocationCommand = new AsyncRelayCommand(GenerateLocationAndRefreshAsync);
            GenerateCoordinatesCommand = new AsyncRelayCommand(GenerateCoordinatesAndRefreshAsync);
            GenerateLocationForPopulationCommand = new AsyncRelayCommand(GenerateLocationForPopulationAndRefreshAsync);
            SaveCurrentMapLayoutCommand = new AsyncRelayCommand(SaveCurrentMapLayoutAsync);
            
            AddConnectionCommand = new AsyncRelayCommand(AddConnectionAsync, CanAddConnection);
            DeleteAllConnectionsCommand = new AsyncRelayCommand(DeleteAllConnectionsAsync, CanDeleteConnections);
            DeleteSelectedSceneCommand = new AsyncRelayCommand(DeleteSelectedSceneAsync, CanDeleteSelectedScene);
            
            CreateAssetCommand = new AsyncRelayCommand(CreateAssetAsync);
            DeleteAssetCommand = new AsyncRelayCommand(DeleteAssetAsync, CanDeleteAsset);

            EditSceneFromGridCommand = new RelayCommand<Scene>(ExecuteEditSceneFromGrid);

            _ = LoadScenesAsync(); 
            _ = LoadAssetImagesAsync(); // Load assets
            _ = LoadNpcsDataAsync(); // Загружаем данные NPC

            this.PropertyChanged += (s, e) => {
                if (e.PropertyName == nameof(MapSelectedScene))
                {
                    UpdateAllOtherScenesForConnection();
                    UpdateSelectedSceneImagePath();
                    UpdateSelectedSceneResidents(); // Обновляем список резидентов
                }
                // --- Добавляем обработчики для изменения свойств фильтров ---
                else if (e.PropertyName == nameof(SearchNameText) ||
                         e.PropertyName == nameof(SelectedSceneTypeForFilter) ||
                         e.PropertyName == nameof(SelectedIndoorOptionForFilter) ||
                         e.PropertyName == nameof(SelectedResidentsOptionForFilter))
                {
                    ApplyFilters();
                }
                // --- Конец обработчиков ---
            };
        }

        private void InitializeFilterOptions()
        {
            // Типы сцен
            SceneTypesForFilter.Add(new AllFilterPlaceholder("Все типы"));
            foreach (SceneType type in Enum.GetValues(typeof(SceneType)))
            {
                SceneTypesForFilter.Add(type);
            }

            // IsIndoor
            IndoorOptionsForFilter.Add(new FilterOption<bool?>("Indoor: Все", null));
            IndoorOptionsForFilter.Add(new FilterOption<bool?>("Indoor: Да", true));
            IndoorOptionsForFilter.Add(new FilterOption<bool?>("Indoor: Нет", false));

            // HasResidents
            ResidentsOptionsForFilter.Add(new FilterOption<bool?>("Резиденты: Все", null));
            ResidentsOptionsForFilter.Add(new FilterOption<bool?>("Резиденты: Есть", true));
            ResidentsOptionsForFilter.Add(new FilterOption<bool?>("Резиденты: Нет", false));
        }

        private void ApplyFilters()
        {
            if (Scenes == null)
            {
                FilteredScenes.Clear();
                return;
            }

            IEnumerable<Scene> currentFiltered = Scenes;

            // 1. Фильтр по имени
            if (!string.IsNullOrWhiteSpace(SearchNameText))
            {
                currentFiltered = currentFiltered.Where(s => s.Name.Contains(SearchNameText, StringComparison.OrdinalIgnoreCase));
            }

            // 2. Фильтр по типу сцены
            if (SelectedSceneTypeForFilter is SceneType selectedType) // Проверяем, что это именно SceneType, а не AllFilterPlaceholder
            {
                currentFiltered = currentFiltered.Where(s => s.SceneType == selectedType);
            }

            // 3. Фильтр IsIndoor
            if (SelectedIndoorOptionForFilter != null && SelectedIndoorOptionForFilter.Value.HasValue)
            {
                currentFiltered = currentFiltered.Where(s => s.IsIndoor == SelectedIndoorOptionForFilter.Value.Value);
            }

            // 4. Фильтр по наличию резидентов
            if (SelectedResidentsOptionForFilter != null && SelectedResidentsOptionForFilter.Value.HasValue)
            {
                if (SelectedResidentsOptionForFilter.Value.Value) // true означает "Есть резиденты"
                {
                    currentFiltered = currentFiltered.Where(s => s.ResidentCount > 0);
                }
                else // false означает "Нет резидентов"
                {
                    currentFiltered = currentFiltered.Where(s => s.ResidentCount == 0);
                }
            }
            
            // Обновляем коллекцию FilteredScenes
            // Чтобы избежать мерцания DataGrid, можно сначала очистить и потом добавить,
            // или использовать более сложный механизм синхронизации, если необходимо.
            // Для простоты пока так:
            var newFilteredList = currentFiltered.ToList();
            FilteredScenes.Clear();
            foreach (var scene in newFilteredList)
            {
                FilteredScenes.Add(scene);
            }
            Debug.WriteLine($"[ApplyFilters] Applied. Filtered count: {FilteredScenes.Count}");
        }

        partial void OnMapSelectedSceneChanged(Scene? oldValue, Scene? newValue)
        {
            UpdateAllOtherScenesForConnection();
            UpdateSelectedSceneImagePath(); 
            UpdateSelectedSceneResidents(); // Обновляем список резидентов при прямом изменении свойства
        }

        private void UpdateSelectedSceneImagePath()
        {
            if (MapSelectedScene == null)
            {
                SelectedSceneImagePath = null;
                return;
            }

            // Ensure Constants.SceneAssetsFolderPath is correctly referenced
            // and that System.IO.File.Exists is available.
            string path = $"{Constants.SceneAssetsFolderPath}\\\\location{MapSelectedScene.Id}.imageset\\\\location{MapSelectedScene.Id}.png";
            if (File.Exists(path))
            {
                SelectedSceneImagePath = path;
            }
            else
            {
                SelectedSceneImagePath = null;
                Debug.WriteLine($"[WorldViewModel] Image not found for scene {MapSelectedScene.Id} at path: {path}");
            }
        }

        private void UpdateAllOtherScenesForConnection()
        {
            AllOtherScenesForConnection.Clear();
            if (MapSelectedScene != null && Scenes != null)
            {
                foreach (var scene in Scenes)
                {
                    if (scene.Id != MapSelectedScene.Id)
                    {
                        AllOtherScenesForConnection.Add(scene);
                    }
                }
            }
            SelectedSceneForConnection = null; // Reset selection when the list changes
        }

        private bool CanAddConnection()
        {
            return MapSelectedScene != null && SelectedSceneForConnection != null;
        }

        private async Task AddConnectionAsync()
        {
            if (MapSelectedScene == null || SelectedSceneForConnection == null)
            {
                _notificationService.ShowToast("Основная сцена или сцена для подключения не выбраны.", ToastType.Warning);
                return;
            }

            // Проверка на существующее подключение к этой же сцене
            if (MapSelectedScene.Connections.Any(c => c.ConnectedSceneId == SelectedSceneForConnection.Id))
            {
                _notificationService.ShowToast($"Сцена '{MapSelectedScene.Name}' уже подключена к '{SelectedSceneForConnection.Name}'.", ToastType.Info);
                return;
            }
            
            // Проверка на подключение к самому себе
            if (MapSelectedScene.Id == SelectedSceneForConnection.Id)
            {
                 _notificationService.ShowToast("Нельзя подключить сцену к самой себе.", ToastType.Warning);
                 return;
            }

            MapSelectedScene.Connections.Add(new SceneConnection { ConnectedSceneId = SelectedSceneForConnection.Id, ConnectionType = "Standard" });
            
            // Опционально: добавить симметричное подключение, если это предполагается логикой
            // var targetScene = Scenes.FirstOrDefault(s => s.Id == SelectedSceneForConnection.Id);
            // if (targetScene != null && !targetScene.Connections.Any(c => c.ConnectedSceneId == MapSelectedScene.Id))
            // {
            // targetScene.Connections.Add(new SceneConnection { ConnectedSceneId = MapSelectedScene.Id, ConnectionType = "Standard" });
            // }

            await SaveCurrentMapLayoutSilentlyAsync(); // Сохраняем изменения и оно покажет свое уведомление
            await LoadScenesAsync();      // Перезагружаем для обновления карты (и DataGrid)
                                          // MapSelectedScene может стать null после LoadScenesAsync, если объект пересоздается
                                          // По идее, ObservableCollection должен обновить существующие экземпляры, если Id совпадают.
                                          // Но если LoadScenesAsync полностью заменяет Scenes новыми объектами, нужно будет восстановить MapSelectedScene.
        }

        private bool CanDeleteConnections()
        {
            return MapSelectedScene != null && MapSelectedScene.Connections.Any();
        }

        private async Task DeleteAllConnectionsAsync()
        {
            if (MapSelectedScene == null)
            {
                _notificationService.ShowToast("Сцена не выбрана.", ToastType.Info);
                return;
            }

            if (!MapSelectedScene.Connections.Any())
            {
                _notificationService.ShowToast($"У сцены '{MapSelectedScene.Name}' нет подключений для удаления.", ToastType.Info);
                return;
            }
            
            // Опционально: удалить симметричные подключения
            // foreach(var connectionToRemove in MapSelectedScene.Connections.ToList()) // ToList для безопасного изменения коллекции
            // {
            // var otherScene = Scenes.FirstOrDefault(s => s.Id == connectionToRemove.ConnectedSceneId);
            // if (otherScene != null)
            // {
            // otherScene.Connections.RemoveAll(c => c.ConnectedSceneId == MapSelectedScene.Id);
            // }
            // }

            int numRemoved = MapSelectedScene.Connections.Count;
            MapSelectedScene.Connections.Clear();
            
            // DEBUG: Check if the scene in the main Scenes collection was affected
            if (MapSelectedScene != null) // Ensure MapSelectedScene is not null before accessing Id
            {
                var sceneInCollection = Scenes.FirstOrDefault(s => s.Id == MapSelectedScene.Id);
                if (sceneInCollection != null)
                {
                    Debug.WriteLine($"[DEBUG] Scene {sceneInCollection.Name} (ID: {sceneInCollection.Id}) in Scenes collection has {sceneInCollection.Connections.Count} connections after Clear() and before Save. Expected: 0.");
                }
                else
                {
                    Debug.WriteLine($"[DEBUG] Scene {MapSelectedScene.Name} (ID: {MapSelectedScene.Id}) NOT FOUND in Scenes collection after Clear(). This is unexpected.");
                }
            }

            await SaveCurrentMapLayoutSilentlyAsync(); // Сохраняем изменения и оно покажет свое уведомление
            await LoadScenesAsync(); 
        }

        private bool CanDeleteSelectedScene()
        {
            return MapSelectedScene != null;
        }

        private async Task DeleteSelectedSceneAsync()
        {
            if (MapSelectedScene == null)
            {
                _notificationService.ShowToast("Сцена для удаления не выбрана.", ToastType.Warning);
                return;
            }

            // Запрос подтверждения от пользователя (опционально, но рекомендуется)
            // Для простоты пока пропустим, но в реальном приложении стоит добавить MessageBox с вопросом.

            int sceneIdToRemove = MapSelectedScene.Id;
            string sceneNameRemoved = MapSelectedScene.Name;

            // 1. Удаляем саму сцену из основного списка
            var sceneToRemove = Scenes.FirstOrDefault(s => s.Id == sceneIdToRemove);
            if (sceneToRemove != null)
            {
                Scenes.Remove(sceneToRemove);
            }
            else
            {
                _notificationService.ShowToast($"Не удалось найти сцену {sceneNameRemoved} (ID: {sceneIdToRemove}) для удаления в коллекции.", ToastType.Error);
                return; // Если не нашли, дальше нет смысла идти
            }

            // 2. Проходимся по всем ОСТАВШИМСЯ сценам и удаляем подключения к удаленной сцене
            foreach (var scene in Scenes)
            {
                scene.Connections.RemoveAll(conn => conn.ConnectedSceneId == sceneIdToRemove);
            }
            
            // 3. Сбрасываем выбор, так как выбранная сцена удалена
            MapSelectedScene = null;
            // SelectedSceneForConnection и AllOtherScenesForConnection обновятся автоматически через PropertyChanged на MapSelectedScene

            // 4. Сохраняем изменения и перезагружаем
            await SaveCurrentMapLayoutSilentlyAsync(); 
            await LoadScenesAsync();
        }

        private async Task LoadScenesAsync()
        {
            _notificationService.UpdateStatus("Загрузка сцен...");
            try
            {
                if (!File.Exists(Constants.ScenesPath))
                {
                    System.Diagnostics.Debug.WriteLine($"Файл сцен не найден: {Constants.ScenesPath}");
                    App.Current.Dispatcher.Invoke(() => Scenes.Clear());
                    _notificationService.ShowToast("Файл сцен не найден. Создайте новую локацию.", ToastType.Warning);
                    _notificationService.UpdateStatus("Файл сцен не найден.");
                    return;
                }

                string jsonString = await File.ReadAllTextAsync(Constants.ScenesPath);
                if (string.IsNullOrWhiteSpace(jsonString))
                {
                    System.Diagnostics.Debug.WriteLine("Файл сцен пуст.");
                    App.Current.Dispatcher.Invoke(() => Scenes.Clear());
                    _notificationService.ShowToast("Файл сцен пуст.", ToastType.Warning);
                    _notificationService.UpdateStatus("Файл сцен пуст.");
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
                    // ApplyFilters(); // Вызываем ApplyFilters после загрузки и присвоения Scenes
                });
                _notificationService.UpdateStatus($"Загружено {Scenes.Count} сцен.");
                _notificationService.ShowToast($"Загружено {Scenes.Count} сцен.", ToastType.Success);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Ошибка загрузки сцен: {ex.Message}");
                _notificationService.ShowToast($"Ошибка загрузки сцен: {ex.Message}", ToastType.Error);
                _notificationService.UpdateStatus("Ошибка загрузки сцен.");
                App.Current.Dispatcher.Invoke(() => Scenes.Clear());
            }
            // ApplyFilters(); // Также вызывается в сеттере Scenes
        }

        private async Task GenerateLocationAndRefreshAsync()
        {
            _notificationService.UpdateStatus("Генерация локации...");
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
                _notificationService.ShowToast("Не выбрано ни одной сцены для генерации. Укажите количество для хотя бы одного типа сцен.", ToastType.Warning);
                return;
            }

            var generator = new LocationGenerator();
            List<Scene> generatedScenes = generator.GenerateLocation(config);
            generator.SaveScenesToFile(generatedScenes, Constants.ScenesPath);
            _notificationService.ShowToast($"Локация '{NewLocationName}' успешно сгенерирована и сохранена!\nСцен создано: {generatedScenes.Count}", ToastType.Success);
            
            await LoadScenesAsync();
        }

        private async Task GenerateCoordinatesAndRefreshAsync()
        {
            _notificationService.UpdateStatus("Генерация координат...");
            try
            {
                float baseDistanceUnit = 0.5f; // JSON units per travel time unit. Corrected based on history.
                System.Numerics.Vector2 markerSize = new System.Numerics.Vector2(5, 5); // Screen pixels for marker, used for spacing logic if ProcessMapFile needs it
                float coordinateScale = 1.0f; // If 1.0, then screen pixels = JSON units for marker dimensions

                MapJsonGenerator.ProcessMapFile(Constants.ScenesPath, markerSize, coordinateScale, baseDistanceUnit);
                _notificationService.ShowToast("Координаты для текущих сцен сгенерированы.", ToastType.Success);
                _notificationService.UpdateStatus("Координаты сгенерированы.");
            }
            catch (Exception ex)
            {
                _notificationService.ShowToast($"Ошибка генерации координат: {ex.Message}", ToastType.Error);
                _notificationService.UpdateStatus("Ошибка генерации координат.");
            }
            await LoadScenesAsync();
        }

        private async Task GenerateLocationForPopulationAndRefreshAsync()
        {
            _notificationService.UpdateStatus("Генерация локации по населению...");
            if (TargetPopulation <= 0)
            {
                _notificationService.ShowToast("Целевое население должно быть больше нуля.", ToastType.Warning);
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
                _notificationService.ShowToast("Тип сцены 'House' не найден, невозможно сгенерировать жилье!", ToastType.Warning);
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
                _notificationService.ShowToast("Не удалось определить типы сцен для генерации по населению.", ToastType.Error);
                return;
            }
            
            var generator = new LocationGenerator();
            List<Scene> generatedScenes = generator.GenerateLocation(config);
            generatedScenes = generatedScenes.OrderBy(s => s.SceneType.ToString()).ThenBy(s => s.Name).ToList();
            generator.SaveScenesToFile(generatedScenes, Constants.ScenesPath);
            _notificationService.ShowToast($"Локация для населения {TargetPopulation} ('{config.LocationName}') успешно сгенерирована! Сцен создано: {generatedScenes.Count}", ToastType.Success);
            
            await LoadScenesAsync();
        }

        private async Task SaveCurrentMapLayoutAsync()
        {
            _notificationService.UpdateStatus("Сохранение разметки карты...");
            if (Scenes == null || !Scenes.Any())
            {
                _notificationService.ShowToast("Нет сцен для сохранения.", ToastType.Warning);
                return;
            }

            try
            {
                var options = new JsonSerializerOptions
                {
                    WriteIndented = true,
                    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
                    Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) }
                };
                // Ensure Scenes is your ObservableCollection<Scene>
                string jsonString = JsonSerializer.Serialize(Scenes.ToList(), options); 
                await File.WriteAllTextAsync(Constants.ScenesPath, jsonString);
                _notificationService.ShowToast("Расположение сцен успешно сохранено.", ToastType.Success);
            }
            catch (Exception ex)
            {
                _notificationService.ShowToast($"Ошибка при сохранении расположения сцен: {ex.Message}", ToastType.Error);
                Debug.WriteLine($"Ошибка сохранения JSON: {ex.Message}");
            }
        }

        private async Task SaveCurrentMapLayoutSilentlyAsync()
        {
            if (Scenes == null || !Scenes.Any())
            {
                // Нечего сохранять, тихо выходим
                return;
            }

            try
            {
                var options = new JsonSerializerOptions
                {
                    WriteIndented = true,
                    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
                    Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) }
                };
                string jsonString = JsonSerializer.Serialize(Scenes.ToList(), options); 
                await File.WriteAllTextAsync(Constants.ScenesPath, jsonString);
                // Уведомление удалено
                Debug.WriteLine($"Расположение {Scenes.Count} сцен успешно сохранено (без уведомления) в {Constants.ScenesPath}");
            }
            catch (Exception ex)
            {
                // Можно логировать ошибку, но уведомление пользователю не показываем
                Debug.WriteLine($"Ошибка при сохранении расположения сцен (без уведомления): {ex.Message}");
            }
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

        public async Task AddConnectionFromMapAsync(Scene sourceScene, Scene targetScene)
        {
            if (sourceScene == null || targetScene == null)
            {
                // ShowNotification("Исходная или целевая сцена не определены."); // Тихо выходим
                return;
            }

            if (sourceScene.Id == targetScene.Id)
            {
                // ShowNotification("Нельзя подключить сцену к самой себе."); // Тихо выходим
                return;
            }

            var actualSourceScene = Scenes.FirstOrDefault(s => s.Id == sourceScene.Id);
            var actualTargetScene = Scenes.FirstOrDefault(s => s.Id == targetScene.Id);

            if (actualSourceScene == null || actualTargetScene == null)
            {
                // ShowNotification("Одна из сцен не найдена в текущем списке. Попробуйте обновить карту."); // Тихо выходим
                return;
            }

            bool connectionMade = false;

            // Добавляем A -> B
            if (!actualSourceScene.Connections.Any(c => c.ConnectedSceneId == actualTargetScene.Id))
            {
                actualSourceScene.Connections.Add(new SceneConnection 
                { 
                    ConnectedSceneId = actualTargetScene.Id, 
                    ConnectionType = "ManualCanvas"
                });
                connectionMade = true;
            }
            else
            {
                // ShowNotification($"Сцена '{actualSourceScene.Name}' уже подключена к '{actualTargetScene.Name}'."); // Уже есть, тихо выходим
            }

            // Добавляем B -> A (симметрично)
            if (!actualTargetScene.Connections.Any(c => c.ConnectedSceneId == actualSourceScene.Id))
            {
                actualTargetScene.Connections.Add(new SceneConnection
                {
                    ConnectedSceneId = actualSourceScene.Id,
                    ConnectionType = "ManualCanvas"
                });
                connectionMade = true; // Даже если первая связь уже была, вторая может быть новой
            }
            else
            {
                // ShowNotification($"Сцена '{actualTargetScene.Name}' уже подключена к '{actualSourceScene.Name}' (симметрично)."); // Уже есть, тихо выходим
            }

            if (connectionMade)
            {
                // ShowNotification($"Подключение от '{actualSourceScene.Name}' к '{actualTargetScene.Name}' добавлено/обновлено."); // Убрали
                await SaveCurrentMapLayoutSilentlyAsync(); // Используем тихий метод сохранения
                await LoadScenesAsync();      
            }
        }

        // Method to generate a unique location name (UPDATED for new JSON structure)
        public string GenerateUniqueLocationName(SceneType sceneType, string currentNameIfNoneFound)
        {
            try
            {
                if (!File.Exists(Constants.LocationNamesPath))
                {
                    _notificationService.ShowToast($"Файл имен локаций не найден: {Constants.LocationNamesPath}", ToastType.Warning);
                    return currentNameIfNoneFound;
                }

                string jsonString = File.ReadAllText(Constants.LocationNamesPath);
                if (string.IsNullOrWhiteSpace(jsonString))
                {
                    _notificationService.ShowToast("Файл имен локаций пуст.", ToastType.Warning);
                    return currentNameIfNoneFound;
                }

                var locationNameEntries = JsonSerializer.Deserialize<List<LocationNameEntry>>(jsonString, 
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                if (locationNameEntries == null || !locationNameEntries.Any())
                {
                    _notificationService.ShowToast("В файле имен локаций не найдено записей.", ToastType.Info);
                    return currentNameIfNoneFound;
                }

                // Фильтруем имена для нужного типа сцены, сравнивая без учета регистра
                // так как в JSON у вас "cave", а enum.ToString() даст "Cave"
                string sceneTypeString = sceneType.ToString();
                var namesForType = locationNameEntries
                    .Where(entry => string.Equals(entry.SceneType, sceneTypeString, StringComparison.OrdinalIgnoreCase))
                    .Select(entry => entry.Name)
                    .ToList();

                if (!namesForType.Any())
                {
                    _notificationService.ShowToast($"Для типа '{sceneTypeString}' не найдено имен в файле.", ToastType.Info);
                    return currentNameIfNoneFound;
                }

                var existingNames = new HashSet<string>(Scenes.Select(s => s.Name), StringComparer.OrdinalIgnoreCase);
                
                var random = new Random();
                var shuffledNames = namesForType.OrderBy(x => random.Next()).ToList();

                foreach (var name in shuffledNames)
                {
                    if (!existingNames.Contains(name))
                    {
                        return name;
                    }
                }
                
                _notificationService.ShowToast($"Не удалось найти уникальное имя для типа '{sceneTypeString}'. Все варианты заняты.", ToastType.Warning);
                return currentNameIfNoneFound;
            }
            catch (JsonException jsonEx)
            {
                _notificationService.ShowToast($"Ошибка чтения JSON файла имен: {jsonEx.Message}", ToastType.Error);
                Debug.WriteLine($"[GenerateUniqueLocationName] JSON Error: {jsonEx} (Path: {jsonEx.Path}, Line: {jsonEx.LineNumber}, Pos: {jsonEx.BytePositionInLine})");
                return currentNameIfNoneFound;
            }
            catch (Exception ex)
            {
                _notificationService.ShowToast($"Ошибка при генерации имени: {ex.Message}", ToastType.Error);
                Debug.WriteLine($"[GenerateUniqueLocationName] General Error: {ex}");
                return currentNameIfNoneFound;
            }
        }

        public async Task AddNewSceneFromMapAsync(SceneType sceneType, double x, double y)
        {
            string defaultName = $"New {sceneType.ToString()}";
            string defaultDescription = "A newly created scene.";
            int placeholderIdForNewScene = 0; 

            // Call the name generator for an initial suggestion, or use default if it fails
            defaultName = GenerateUniqueLocationName(sceneType, defaultName);

            var editWindow = new EditSceneDetailsWindow(placeholderIdForNewScene, defaultName, defaultDescription, 
                                                    sceneType, GenerateUniqueLocationName) // Pass the method
            {
                Title = "Создать Новую Сцену", 
                Owner = Application.Current.MainWindow
            };

            if (editWindow.ShowDialog() == true)
            {
                string sceneName = editWindow.SceneName;
                string sceneDescription = editWindow.SceneDescription;

                int newId = 0;
                if (Scenes.Any())
                {
                    newId = Scenes.Max(s => s.Id) + 1;
                }

                var newScene = new Scene
                {
                    Id = newId,
                    Name = sceneName, 
                    SceneType = sceneType,
                    Description = sceneDescription, 
                    X = (int)Math.Round(x),
                    Y = (int)Math.Round(y),
                    Connections = new List<SceneConnection>(),
                    IsIndoor = false, 
                    ParentSceneId = 0, 
                    HubSceneIds = new List<int>(), 
                    Population = 0, 
                    Radius = 10 
                };

                Scenes.Add(newScene);
                await SaveCurrentMapLayoutSilentlyAsync(); 
                await LoadScenesAsync(); 
            }
            else
            {
                Debug.WriteLine("Создание новой сцены отменено пользователем.");
            }
        }

        public async Task HandleSceneEditRequestAsync(Scene sceneToEdit)
        {
            if (sceneToEdit == null) return;

            var sceneInCollection = Scenes.FirstOrDefault(s => s.Id == sceneToEdit.Id);
            if (sceneInCollection == null)
            {
                _notificationService.ShowToast("Выбранная сцена не найдена в текущем списке.", ToastType.Error);
                return;
            }

            var editWindow = new EditSceneDetailsWindow(sceneInCollection.Id, sceneInCollection.Name, sceneInCollection.Description, 
                                                    sceneInCollection.SceneType, GenerateUniqueLocationName) // Pass SceneType and method
            {
                Owner = Application.Current.MainWindow
            };

            if (editWindow.ShowDialog() == true)
            {
                string newIdString = editWindow.SceneIdString;
                string newName = editWindow.SceneName;
                string newDescription = editWindow.SceneDescription;
                bool changed = false;
                int originalId = sceneInCollection.Id;
                int newNumericId = originalId;

                if (newIdString != originalId.ToString())
                {
                    if (!int.TryParse(newIdString, out newNumericId))
                    {
                        _notificationService.ShowToast("Ошибка: ID должен быть числом.", ToastType.Warning);
                        return; 
                    }

                    if (newNumericId != originalId && Scenes.Any(s => s.Id == newNumericId && s.Id != originalId))
                    {
                        _notificationService.ShowToast($"Ошибка: ID '{newNumericId}' уже используется другой сценой.", ToastType.Warning);
                        return; 
                    }
                    else if (newNumericId != originalId) // Only if truly different and unique
                    {
                        sceneInCollection.Id = newNumericId;
                        changed = true;
                        Debug.WriteLine($"Scene ID changed from {originalId} to {newNumericId}");
                        foreach (var s in Scenes)
                        {
                            if (s.Connections != null)
                            {
                                foreach (var conn in s.Connections)
                                {
                                    if (conn.ConnectedSceneId == originalId)
                                    {
                                        conn.ConnectedSceneId = newNumericId;
                                    }
                                }
                            }
                        }
                    }
                }

                if (sceneInCollection.Name != newName)
                {
                    sceneInCollection.Name = newName;
                    changed = true;
                }
                if (sceneInCollection.Description != newDescription)
                {
                    sceneInCollection.Description = newDescription;
                    changed = true;
                }

                if (changed)
                {
                    await SaveCurrentMapLayoutAsync(); 
                    await LoadScenesAsync(); 
                    _notificationService.ShowToast("Детали сцены обновлены.", ToastType.Success);
                }
            }
        }

        private async Task LoadAssetImagesAsync()
        {
            _notificationService.UpdateStatus("Загрузка изображений ассетов...");
            await Task.Run(() => // Perform disk operations on a background thread
            {
                var tempAssetList = new List<AssetDisplayInfo>();
                try
                {
                    if (Directory.Exists(Constants.SceneAssetsFolderPath))
                    {
                        var imageSetDirectories = Directory.GetDirectories(Constants.SceneAssetsFolderPath, "location*.imageset");
                        Regex idRegex = new Regex(@"location(\d+)\.imageset");

                        foreach (var dir in imageSetDirectories)
                        {
                            Match match = idRegex.Match(System.IO.Path.GetFileName(dir)); // Use System.IO.Path.GetFileName
                            if (match.Success && int.TryParse(match.Groups[1].Value, out int assetId))
                            {
                                string pngFileName = $"location{assetId}.png";
                                string imagePath = System.IO.Path.Combine(dir, pngFileName);

                                if (File.Exists(imagePath))
                                {
                                    tempAssetList.Add(new AssetDisplayInfo(assetId, imagePath));
                                }
                                else
                                {
                                    Debug.WriteLine($"[LoadAssetImagesAsync] PNG file not found: {imagePath}");
                                }
                            }
                            else
                            {
                                Debug.WriteLine($"[LoadAssetImagesAsync] Could not parse asset ID from directory: {dir}");
                            }
                        }
                    }
                    else
                    {
                        Debug.WriteLine($"[LoadAssetImagesAsync] SceneAssetsFolderPath does not exist: {Constants.SceneAssetsFolderPath}");
                    }
                }
                catch (Exception ex)
                {
                    Debug.WriteLine($"[LoadAssetImagesAsync] Error loading asset images: {ex.Message}");
                    // Optionally show a notification to the user if appropriate
                }
                
                // Update the ObservableCollection on the UI thread
                Application.Current.Dispatcher.Invoke(() =>
                {
                    AvailableAssetImages.Clear();
                    foreach (var asset in tempAssetList.OrderBy(a => a.AssetId))
                    {
                        AvailableAssetImages.Add(asset);
                    }
                    Debug.WriteLine($"[LoadAssetImagesAsync] Loaded {AvailableAssetImages.Count} asset images.");
                });
            });
        }

        // Method to handle asset assignment/ID change via drag-drop
        public async Task ChangeSceneIdFromAssetAsync(Scene targetScene, AssetDisplayInfo assetInfo)
        {
            if (targetScene == null || assetInfo == null)
            {
                _notificationService.ShowToast("Ошибка: Целевая сцена или информация об ассете не определены.", ToastType.Error);
                return;
            }

            int newSceneId = assetInfo.AssetId;
            var sceneInCollectionToChange = Scenes.FirstOrDefault(s => s.Id == targetScene.Id);

            if (sceneInCollectionToChange == null)
            {
                _notificationService.ShowToast($"Ошибка: Сцена с ID {targetScene.Id} не найдена в текущей коллекции.", ToastType.Error);
                return;
            }

            // Проверка, не занят ли новый ID другой сценой (исключая текущую изменяемую сцену)
            var existingSceneWithNewId = Scenes.FirstOrDefault(s => s.Id == newSceneId && s.Id != sceneInCollectionToChange.Id);
            if (existingSceneWithNewId != null)
            {
                _notificationService.ShowDialog(
                    "Конфликт ID",
                    $"ID ассета ({newSceneId}) уже используется сценой '{existingSceneWithNewId.Name}' (ID: {existingSceneWithNewId.Id}).\n\nИзменение ID отменено. \nЕсли вы хотите использовать этот ID, сначала измените ID существующей сцены ('{existingSceneWithNewId.Name}') вручную.",
                    DialogType.Error
                );
                return;
            }

            int oldSceneId = sceneInCollectionToChange.Id;
            string oldSceneName = sceneInCollectionToChange.Name; // Store for notification

            if (oldSceneId == newSceneId)
            {
                _notificationService.ShowToast($"Сцена '{oldSceneName}' уже имеет ID {newSceneId}. Изменений не требуется.", ToastType.Info);
                // Optionally, still update BackgroundImagePath if that's a separate concern
                // sceneInCollectionToChange.BackgroundImagePath = assetInfo.ImagePath;
                // await SaveCurrentMapLayoutSilentlyAsync();
                return;
            }
            
            // Подтверждение от пользователя (если это не просто смена картинки, а именно ID)
            _notificationService.ShowDialog(
                "Подтверждение смены ID",
                $"Вы уверены, что хотите изменить ID сцены '{oldSceneName}' (было {oldSceneId}) на ID ассета {newSceneId}?\nЭто действие обновит все связанные подключения.",
                DialogType.Confirmation,
                onOk: async () => 
                {
                    _notificationService.UpdateStatus($"Изменение ID сцены '{oldSceneName}' на {newSceneId}...");
                    sceneInCollectionToChange.Id = newSceneId;

                    // Обновить ID во всех связях
                    foreach (var scene in Scenes)
                    {
                        foreach (var connection in scene.Connections)
                        {
                            if (connection.ConnectedSceneId == oldSceneId)
                            {
                                connection.ConnectedSceneId = newSceneId;
                            }
                        }
                        // Обновление устаревших HubSceneIds и ConnectedSceneIds УДАЛЕНО
                        // так как эти поля либо отсутствуют, либо их обновление здесь нецелесообразно
                    }

                    // Обновить SelectedSceneImagePath, если измененная сцена была выбрана
                    if (MapSelectedScene?.Id == oldSceneId) // Сначала проверяем по старому ID
                    {
                         // MapSelectedScene теперь указывает на измененный объект, его ID уже новый.
                         // Так что, если он был выбран, его ID уже newSceneId
                         UpdateSelectedSceneImagePath(); // Обновит картинку в UI, если MapSelectedScene был измененной сценой
                    }
                    
                    await SaveCurrentMapLayoutSilentlyAsync();
                    _notificationService.ShowToast($"ID сцены '{oldSceneName}' изменен на {newSceneId}. Связи обновлены.", ToastType.Success);
                    _notificationService.UpdateStatus("ID сцены изменен, карта обновляется...");
                    await LoadScenesAsync(); // Перезагрузить, чтобы все UI компоненты (карта, грид) обновились
                },
                onCancel: () =>
                {
                    _notificationService.ShowToast("Изменение ID сцены отменено.", ToastType.Info);
                }
            );
        }

        // Added method and CanExecute for DeleteAssetCommand
        private bool CanDeleteAsset()
        {
            return SelectedAsset != null;
        }

        private async Task DeleteAssetAsync()
        {
            if (SelectedAsset == null) return;

            string assetNameToDelete = $"Asset ID {SelectedAsset.AssetId}"; // Используем ID для идентификации

            // Запрос подтверждения
            bool confirmed = await _notificationService.ShowConfirmationDialogAsync(
                "Подтверждение удаления",
                $"Вы уверены, что хотите удалить ассет {assetNameToDelete}?\nПуть: {SelectedAsset.ImagePath}\nЭто действие необратимо."
            );

            if (confirmed)
            {
                _notificationService.UpdateStatus($"Удаление ассета {assetNameToDelete}...");
                try
                {
                    string assetFolderName = $"location{SelectedAsset.AssetId}.imageset";
                    string assetFolderPath = Path.Combine(Constants.SceneAssetsFolderPath, assetFolderName);

                    if (Directory.Exists(assetFolderPath))
                    {
                        Directory.Delete(assetFolderPath, true); // true для рекурсивного удаления
                        Debug.WriteLine($"[DeleteAssetAsync] Удалена папка: {assetFolderPath}");

                        // Очистить выбор, если удален выбранный элемент
                        AssetDisplayInfo? deletedAsset = SelectedAsset; // Сохраняем ссылку
                        SelectedAsset = null; // Сбрасываем выбор

                        await LoadAssetImagesAsync(); // Обновить список

                        _notificationService.ShowToast($"Ассет {assetNameToDelete} успешно удален.", ToastType.Success);
                        _notificationService.UpdateStatus("Ассет удален.");
                    }
                    else
                    {                       
                        _notificationService.ShowToast($"Ошибка: Папка ассета {assetFolderName} не найдена для удаления.", ToastType.Warning);
                        Debug.WriteLine($"[DeleteAssetAsync] Папка не найдена для удаления: {assetFolderPath}");
                        // Все равно перезагрузить список, на случай если он рассинхронизирован
                        await LoadAssetImagesAsync();
                    }
                }
                catch (Exception ex)
                {
                    _notificationService.ShowToast($"Ошибка при удалении ассета {assetNameToDelete}: {ex.Message}", ToastType.Error);
                    _notificationService.UpdateStatus("Ошибка удаления ассета.");
                    Debug.WriteLine($"[DeleteAssetAsync] Исключение: {ex}");
                }
            }
            else
            {
                _notificationService.UpdateStatus("Удаление ассета отменено.");
            }
        }

        // Added method for CreateAssetCommand
        private async Task CreateAssetAsync()
        {
            var openFileDialog = new OpenFileDialog
            {
                Filter = "PNG Files (*.png)|*.png",
                Title = "Выберите PNG файл для нового ассета"
            };

            if (openFileDialog.ShowDialog() == true)
            {
                string selectedFilePath = openFileDialog.FileName;
                _notificationService.UpdateStatus("Создание нового ассета...");

                try
                {
                    // 1. Определить новый ID для ассета, учитывая ID сцен и других ассетов
                    int maxSceneId = 0;
                    if (Scenes.Any())
                    {
                        maxSceneId = Scenes.Max(s => s.Id);
                    }

                    int maxAssetId = 0;
                    if (AvailableAssetImages.Any())
                    {
                        maxAssetId = AvailableAssetImages.Max(a => a.AssetId);
                    }

                    int newAssetId = Math.Max(maxSceneId, maxAssetId) + 1;
                    
                    // Дополнительная проверка, чтобы убедиться, что ID не занят (на случай если есть "дыры" в нумерации)
                    // и не конфликтует с существующими сценами или ассетами.
                    while (Scenes.Any(s => s.Id == newAssetId) || AvailableAssetImages.Any(a => a.AssetId == newAssetId))
                    {
                        newAssetId++;
                    }
                     Debug.WriteLine($"[CreateAssetAsync] Определен новый Asset ID: {newAssetId} (с учетом сцен и ассетов)");

                    // 2. Создать папку location{ID}.imageset
                    string assetFolderName = $"location{newAssetId}.imageset";
                    string assetFolderPath = Path.Combine(Constants.SceneAssetsFolderPath, assetFolderName);

                    if (Directory.Exists(assetFolderPath))
                    {
                        _notificationService.ShowToast($"Ошибка: Папка для ассета {assetFolderName} уже существует.", ToastType.Error);
                        Debug.WriteLine($"[CreateAssetAsync] Папка {assetFolderPath} уже существует.");
                        return;
                    }
                    Directory.CreateDirectory(assetFolderPath);
                    Debug.WriteLine($"[CreateAssetAsync] Создана папка: {assetFolderPath}");

                    // 3. Скопировать выбранный файл и переименовать
                    string targetImageName = $"location{newAssetId}.png";
                    string targetImagePath = Path.Combine(assetFolderPath, targetImageName);
                    File.Copy(selectedFilePath, targetImagePath);
                    Debug.WriteLine($"[CreateAssetAsync] Файл скопирован в: {targetImagePath}");

                    // 4. Создать Contents.json из шаблона
                    // Путь к шаблону определен ранее как: C:\\Repos\\CRProject\\CRProjectEditor\\CRProjectEditor\\CRProjectEditor\\CRProjectEditor\\Content\\AssetImageContent.json
                    // Используем относительный путь для надежности, если он находится в структуре проекта.
                    // Если он действительно вне проекта, то абсолютный путь, но это менее гибко.
                    // Предположим, что файл Content\AssetImageContent.json находится относительно исполняемого файла или проекта.
                    // Для большей надежности, его можно сделать ресурсом или копировать при сборке.
                    // Пока использую жестко заданный путь, как он был указан вами, но с осторожностью.
                    string templatePath = Path.Combine("Content", "AssetImageSetTemplate.json"); // Assumes Content folder is accessible from working directory or output
                    string contentsJsonPath = Path.Combine(assetFolderPath, "Contents.json");

                    if (!File.Exists(templatePath))
                    {
                         _notificationService.ShowToast($"Критическая ошибка: Файл шаблона AssetImageContent.json не найден по пути {templatePath}", ToastType.Error);
                         Debug.WriteLine($"[CreateAssetAsync] Шаблон не найден: {templatePath}");
                         // Попытка очистки, если папка уже создана, а шаблон нет
                         if(Directory.Exists(assetFolderPath)) Directory.Delete(assetFolderPath, true);
                         return;
                    }
                    
                    string templateContent = await File.ReadAllTextAsync(templatePath);
                    // Заменяем "{id}" в "filename": "location{id}.png"
                    string newContentJson = templateContent.Replace("location{id}.png", targetImageName); 
                    
                    await File.WriteAllTextAsync(contentsJsonPath, newContentJson);
                    Debug.WriteLine($"[CreateAssetAsync] Создан Contents.json: {contentsJsonPath}");

                    // 5. Обновить коллекцию ассетов
                    await LoadAssetImagesAsync();
                    _notificationService.ShowToast($"Ассет ID {newAssetId} успешно создан.", ToastType.Success);
                    _notificationService.UpdateStatus("Новый ассет создан.");
                }
                catch (Exception ex)
                {
                    _notificationService.ShowToast($"Ошибка при создании ассета: {ex.Message}", ToastType.Error);
                    _notificationService.UpdateStatus("Ошибка создания ассета.");
                    Debug.WriteLine($"[CreateAssetAsync] Исключение: {ex}");
                }
            }
        }

        private async Task LoadNpcsDataAsync()
        {
            if (!File.Exists(Constants.NPCSPath))
            {
                Debug.WriteLine($"[WorldViewModel] Файл NPC не найден: {Constants.NPCSPath}");
                // _notificationService?.ShowToast("Файл данных NPC не найден.", ToastType.Error); // Раскомментировать, если нужно уведомление
                return;
            }
            try
            {
                string jsonString = await File.ReadAllTextAsync(Constants.NPCSPath);
                if (string.IsNullOrWhiteSpace(jsonString))
                {
                    Debug.WriteLine("[WorldViewModel] Файл NPC пуст.");
                    return;
                }
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true, AllowTrailingCommas = true };
                var loadedNpcs = JsonSerializer.Deserialize<List<NpcModel>>(jsonString, options);
                if (loadedNpcs != null)
                {
                    _allNpcs = loadedNpcs;
                    Debug.WriteLine($"[WorldViewModel] Загружено {_allNpcs.Count} NPC.");
                    // После загрузки NPC, можно обновить ResidentCount для всех сцен
                    UpdateAllSceneResidentCounts();
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[WorldViewModel] Ошибка при загрузке NPC: {ex.Message}");
            }
        }

        private void UpdateAllSceneResidentCounts()
        {
            if (!_allNpcs.Any() || !Scenes.Any()) return;

            foreach (var scene in Scenes)
            {
                scene.ResidentCount = _allNpcs.Count(npc => npc.HomeLocationId == scene.Id);
            }
            // После обновления ResidentCount, нужно заново применить фильтры,
            // особенно если есть фильтр по наличию резидентов.
            ApplyFilters(); 
        }

        private void UpdateSelectedSceneResidents()
        {
            SelectedSceneResidents.Clear();
            if (MapSelectedScene != null && _allNpcs.Any())
            {
                var residents = _allNpcs.Where(npc => npc.HomeLocationId == MapSelectedScene.Id);
                foreach (var resident in residents)
                {
                    SelectedSceneResidents.Add(resident);
                }
            }
            Debug.WriteLine($"[WorldViewModel] Резиденты для сцены {MapSelectedScene?.Id}: {SelectedSceneResidents.Count}");
        }

        private void ExecuteEditSceneFromGrid(Scene? sceneToEdit)
        {
            if (sceneToEdit == null) return;

            // Находим актуальный объект сцены в основной коллекции, чтобы изменения отразились
            var actualSceneInCollection = Scenes.FirstOrDefault(s => s.Id == sceneToEdit.Id);
            if (actualSceneInCollection == null)
            {
                _notificationService.ShowToast("Сцена для редактирования не найдена в основной коллекции.", ToastType.Error);
                return;
            }

            var editWindow = new EditSceneDetailsWindow(actualSceneInCollection, GenerateUniqueLocationName, false); // isIdEditable = false
            editWindow.Owner = Application.Current.MainWindow;

            if (editWindow.ShowDialog() == true)
            {
                bool changed = false;
                // ID не меняем, так как isIdEditable было false

                if (actualSceneInCollection.Name != editWindow.SceneName)
                {
                    actualSceneInCollection.Name = editWindow.SceneName;
                    changed = true;
                }
                if (actualSceneInCollection.Description != editWindow.SceneDescription)
                {
                    actualSceneInCollection.Description = editWindow.SceneDescription;
                    changed = true;
                }
                if (actualSceneInCollection.SceneType != editWindow.SelectedSceneType)
                {
                    actualSceneInCollection.SceneType = editWindow.SelectedSceneType;
                    changed = true;
                }
                if (actualSceneInCollection.IsIndoor != editWindow.IsIndoor)
                {
                    actualSceneInCollection.IsIndoor = editWindow.IsIndoor;
                    changed = true;
                }
                if (actualSceneInCollection.ParentSceneId != editWindow.ParentSceneId)
                {
                    actualSceneInCollection.ParentSceneId = editWindow.ParentSceneId;
                    changed = true;
                }
                if (actualSceneInCollection.Population != editWindow.Population)
                { 
                    actualSceneInCollection.Population = editWindow.Population;
                    changed = true;
                }
                if (actualSceneInCollection.Radius != editWindow.Radius)
                {
                    actualSceneInCollection.Radius = editWindow.Radius;
                    changed = true;
                }

                if (changed)
                {
                    // Принудительное обновление объекта в коллекции, если это необходимо для UI (хотя ObservableCollection должна справляться)
                    // int index = Scenes.IndexOf(actualSceneInCollection);
                    // if (index != -1) Scenes[index] = actualSceneInCollection; 
                    
                    // Сохраняем изменения и обновляем фильтры
                    _ = SaveCurrentMapLayoutAsync(); // Не ждем завершения, но запускаем
                    ApplyFilters(); // Обновить DataGrid, если что-то поменялось, что влияет на фильтр
                    _notificationService.ShowToast("Детали сцены обновлены.", ToastType.Success);
                }
            }
        }
    }
} 