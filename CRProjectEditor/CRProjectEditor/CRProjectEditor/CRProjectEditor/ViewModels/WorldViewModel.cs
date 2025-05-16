using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CRProjectEditor.Models;
using CRProjectEditor.Tools;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
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

        public ICommand GenerateLocationCommand { get; }

        public WorldViewModel()
        {
            SceneTypeConfigs = new ObservableCollection<SceneTypeCountSetting>();
            foreach (SceneType type in Enum.GetValues(typeof(SceneType)))
            {
                SceneTypeConfigs.Add(new SceneTypeCountSetting(type));
            }

            GenerateLocationCommand = new AsyncRelayCommand(GenerateLocationAndRefreshAsync);
            _ = LoadScenesAsync(); 
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
                System.Diagnostics.Debug.WriteLine("Не выбрано ни одной сцены для генерации.");
                // Тут можно показать сообщение пользователю
                return;
            }

            var generator = new LocationGenerator();
            List<Scene> generatedScenes = generator.GenerateLocation(config);
            generator.SaveScenesToFile(generatedScenes, Constants.ScenesPath);

            // Обновляем DataGrid
            await LoadScenesAsync();
        }
    }
} 