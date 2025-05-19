using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CRProjectEditor.Models;
using CRProjectEditor.Services;
using CRProjectEditor.Tools;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows.Data; // Required for CollectionViewSource if we were to use it
using CRProjectEditor.Views; // Для NpcEditView
using Microsoft.Win32; // Для OpenFileDialog
using System.Text.Json.Serialization;

namespace CRProjectEditor.ViewModels
{
    public enum AssetFilterOption
    {
        Any,
        HasAssets,
        NoAssets
    }

    public partial class NPCsViewModel : ObservableObject
    {
        private readonly INotificationService _notificationService;
        private List<NpcModel> _allNpcs = new List<NpcModel>();
        private static string? _assetImageContentTemplateCache; // Кэш для шаблона JSON

        public string ViewModelDisplayName => "NPCs";

        [ObservableProperty]
        private ObservableCollection<NpcModel> _filteredNpcs = new ObservableCollection<NpcModel>();

        // Filter Properties
        [ObservableProperty]
        private string _filterName = string.Empty;
        partial void OnFilterNameChanged(string value) => ApplyFilters();

        [ObservableProperty]
        private string? _filterSex;
        partial void OnFilterSexChanged(string? value) => ApplyFilters();

        [ObservableProperty]
        private string? _filterProfession;
        partial void OnFilterProfessionChanged(string? value) => ApplyFilters();

        [ObservableProperty]
        private bool? _filterIsVampireNullable;
        partial void OnFilterIsVampireNullableChanged(bool? value) => ApplyFilters();
        
        [ObservableProperty]
        private string? _filterMorality;
        partial void OnFilterMoralityChanged(string? value) => ApplyFilters();

        [ObservableProperty]
        private string? _filterMotivation;
        partial void OnFilterMotivationChanged(string? value) => ApplyFilters();

        [ObservableProperty]
        private AssetFilterOption _filterHasAssets = AssetFilterOption.Any;
        partial void OnFilterHasAssetsChanged(AssetFilterOption value) => ApplyFilters();

        [ObservableProperty]
        private NpcModel? _selectedNpc;
        partial void OnSelectedNpcChanged(NpcModel? value)
        {
            OnPropertyChanged(nameof(SelectedNpcImagePath));
            EditNpcCommand.NotifyCanExecuteChanged();
            AddOrReplaceAssetCommand.NotifyCanExecuteChanged();
            DeleteAssetCommand.NotifyCanExecuteChanged();
        }

        public string? SelectedNpcImagePath => SelectedNpc?.ImagePath;

        // ComboBox ItemsSources
        public ObservableCollection<string> AvailableSexes { get; } = new ObservableCollection<string>();
        public ObservableCollection<string> AvailableProfessions { get; } = new ObservableCollection<string>();
        public ObservableCollection<string> AvailableMoralities { get; } = new ObservableCollection<string>();
        public ObservableCollection<string> AvailableMotivations { get; } = new ObservableCollection<string>();
        
        private const string AnySex = "Любой";
        private const string AnyProfession = "Любая";
        private const string AnyMorality = "Любая";
        private const string AnyMotivation = "Любая";


        public IAsyncRelayCommand LoadNpcsCommand { get; }
        public IRelayCommand ClearFiltersCommand { get; }
        public IRelayCommand FixHomeLocationsCommand { get; }
        public IAsyncRelayCommand EditNpcCommand { get; }
        public IAsyncRelayCommand AddOrReplaceAssetCommand { get; }
        public IAsyncRelayCommand DeleteAssetCommand { get; }

        public NPCsViewModel(INotificationService notificationService)
        {
            _notificationService = notificationService;
            LoadNpcsCommand = new AsyncRelayCommand(LoadNpcsAsync);
            ClearFiltersCommand = new RelayCommand(ClearFilters);
            FixHomeLocationsCommand = new AsyncRelayCommand(FixHomeLocationsAsync);
            EditNpcCommand = new AsyncRelayCommand(OpenEditNpcWindowAsync, CanEditNpc);
            AddOrReplaceAssetCommand = new AsyncRelayCommand(AddOrReplaceAssetAsync, CanManageAsset);
            DeleteAssetCommand = new AsyncRelayCommand(DeleteAssetAsync, CanDeleteAsset);
            _ = LoadNpcsAsync(); 
            _ = LoadAssetTemplateAsync(); // Загружаем шаблон при инициализации
        }

        private void InitializeFilterCollections()
        {
            AvailableSexes.Clear();
            AvailableSexes.Add(AnySex);
            // Assuming NpcModel.Sex is a string like "male", "female"
            _allNpcs.Select(npc => npc.Sex).Distinct().OrderBy(s => s).ToList().ForEach(s => AvailableSexes.Add(s));
            FilterSex = AnySex;

            AvailableProfessions.Clear();
            AvailableProfessions.Add(AnyProfession);
            _allNpcs.Select(npc => npc.Profession).Distinct().OrderBy(p => p).ToList().ForEach(p => AvailableProfessions.Add(p));
            FilterProfession = AnyProfession;

            AvailableMoralities.Clear();
            AvailableMoralities.Add(AnyMorality);
            _allNpcs.Select(npc => npc.Morality).Distinct().OrderBy(m => m).ToList().ForEach(m => AvailableMoralities.Add(m));
            FilterMorality = AnyMorality;
            
            AvailableMotivations.Clear();
            AvailableMotivations.Add(AnyMotivation);
            _allNpcs.Select(npc => npc.Motivation).Distinct().OrderBy(m => m).ToList().ForEach(m => AvailableMotivations.Add(m));
            FilterMotivation = AnyMotivation;
        }

        private void ClearFilters()
        {
            FilterName = string.Empty;
            FilterSex = AnySex;
            FilterProfession = AnyProfession;
            FilterIsVampireNullable = null;
            FilterMorality = AnyMorality;
            FilterMotivation = AnyMotivation;
            FilterHasAssets = AssetFilterOption.Any;
        }

        private async Task FixHomeLocationsAsync()
        {
            var invalidHomeLocationNpcs = FilteredNpcs.Where(n => n.IsHomeLocationRelevant == false);

            foreach (var npc in invalidHomeLocationNpcs)
            {
                npc.HomeLocationId = 0;
            }

            await SaveAllNpcsToJsonAsync();
            await LoadNpcsAsync();

            _notificationService.UpdateStatus($"Исправлено {invalidHomeLocationNpcs.Count()} NPC.");
            _notificationService.ShowToast($"Исправлено {invalidHomeLocationNpcs.Count()} NPC.", ToastType.Success);
        }

        private async Task LoadNpcsAsync()
        {
            _notificationService.UpdateStatus("Загрузка NPC...");
            _allNpcs.Clear();
            // FilteredNpcs.Clear(); // Cleared in ApplyFilters

            try
            {
                if (!File.Exists(Constants.NPCSPath))
                {
                    Debug.WriteLine($"[NPCsViewModel] Файл NPC не найден: {Constants.NPCSPath}");
                    _notificationService.ShowToast("Файл данных NPC не найден.", ToastType.Error);
                    _notificationService.UpdateStatus("Файл NPC не найден.");
                    return;
                }

                string jsonString = await File.ReadAllTextAsync(Constants.NPCSPath);
                if (string.IsNullOrWhiteSpace(jsonString))
                {
                    Debug.WriteLine("[NPCsViewModel] Файл NPC пуст.");
                    _notificationService.ShowToast("Файл данных NPC пуст.", ToastType.Warning);
                    _notificationService.UpdateStatus("Файл NPC пуст.");
                    return;
                }

                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true,
                    AllowTrailingCommas = true
                };

                var loadedNpcs = JsonSerializer.Deserialize<List<NpcModel>>(jsonString, options);

                if (loadedNpcs != null)
                {
                    _allNpcs.AddRange(loadedNpcs);
                    InitializeFilterCollections(); // Populate filter dropdowns
                    ApplyFilters(); // Apply initial (empty) filters
                    _notificationService.UpdateStatus($"Загружено {_allNpcs.Count} NPC. Отображается {FilteredNpcs.Count}.");
                    _notificationService.ShowToast($"Загружено {_allNpcs.Count} NPC.", ToastType.Success);
                }
                else
                {
                    _notificationService.ShowToast("Не удалось десериализовать данные NPC.", ToastType.Error);
                    _notificationService.UpdateStatus("Ошибка загрузки NPC.");
                }

                await ValidateNpcHomeLocationsAsync();
            }
            catch (JsonException jsonEx)
            {
                Debug.WriteLine($"[NPCsViewModel] Ошибка JSON при загрузке NPC: {jsonEx.Message} (Path: {jsonEx.Path}, Line: {jsonEx.LineNumber}, Pos: {jsonEx.BytePositionInLine})");
                _notificationService.ShowToast($"Ошибка формата данных NPC (JSON): {jsonEx.Message}", ToastType.Error);
                _notificationService.UpdateStatus("Ошибка формата данных NPC.");
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[NPCsViewModel] Общая ошибка при загрузке NPC: {ex.Message}");
                _notificationService.ShowToast($"Ошибка при загрузке данных NPC: {ex.Message}", ToastType.Error);
                _notificationService.UpdateStatus("Ошибка загрузки NPC.");
            }
        }

        private async Task ValidateNpcHomeLocationsAsync()
        {
            _notificationService.UpdateStatus("Загрузка сцен...");
            try
            {
                if (!File.Exists(Constants.ScenesPath))
                {
                    System.Diagnostics.Debug.WriteLine($"Файл сцен не найден: {Constants.ScenesPath}");
                    _notificationService.ShowToast("Файл сцен не найден. Создайте новую локацию.", ToastType.Warning);
                    _notificationService.UpdateStatus("Файл сцен не найден.");
                    return;
                }

                string jsonString = await File.ReadAllTextAsync(Constants.ScenesPath);
                if (string.IsNullOrWhiteSpace(jsonString))
                {
                    System.Diagnostics.Debug.WriteLine("Файл сцен пуст.");
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

                ValidateNpcHomeLocations(loadedScenes);

            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Ошибка загрузки сцен: {ex.Message}");
                _notificationService.ShowToast($"Ошибка загрузки сцен: {ex.Message}", ToastType.Error);
                _notificationService.UpdateStatus("Ошибка загрузки сцен.");
            }
            // ApplyFilters(); // Также вызывается в сеттере Scenes
        }

        private void ValidateNpcHomeLocations(IEnumerable<Scene> scenes)
        {
            var npcsWithInvalidHomeLocation =
                from npc in _allNpcs
                join scene in scenes on npc.HomeLocationId equals scene.Id into sceneGroup
                from scene in sceneGroup.DefaultIfEmpty()  // left join
                where scene == null && npc.HomeLocationId != 0  // NPC с несуществующим HomeLocationId
                select npc;

            foreach (var npc in npcsWithInvalidHomeLocation)
            {
                npc.IsHomeLocationRelevant = false;
            }
        }

        private void ApplyFilters()
        {
            FilteredNpcs.Clear();
            IEnumerable<NpcModel> view = _allNpcs;

            if (!string.IsNullOrWhiteSpace(FilterName))
            {
                view = view.Where(npc => npc.Name.Contains(FilterName, StringComparison.OrdinalIgnoreCase));
            }

            if (FilterSex != null && FilterSex != AnySex)
            {
                view = view.Where(npc => string.Equals(npc.Sex, FilterSex, StringComparison.OrdinalIgnoreCase));
            }

            if (FilterProfession != null && FilterProfession != AnyProfession)
            {
                view = view.Where(npc => string.Equals(npc.Profession, FilterProfession, StringComparison.OrdinalIgnoreCase));
            }
            
            if (FilterIsVampireNullable.HasValue) // True means filter for vampires, False for non-vampires. Null means don't filter.
            {
                view = view.Where(npc => npc.IsVampire == FilterIsVampireNullable.Value);
            }

            if (FilterMorality != null && FilterMorality != AnyMorality)
            {
                 view = view.Where(npc => string.Equals(npc.Morality, FilterMorality, StringComparison.OrdinalIgnoreCase));
            }

            if (FilterMotivation != null && FilterMotivation != AnyMotivation)
            {
                 view = view.Where(npc => string.Equals(npc.Motivation, FilterMotivation, StringComparison.OrdinalIgnoreCase));
            }

            if (FilterHasAssets == AssetFilterOption.HasAssets)
            {
                view = view.Where(npc => npc.HasAssets);
            }
            else if (FilterHasAssets == AssetFilterOption.NoAssets)
            {
                view = view.Where(npc => !npc.HasAssets);
            }

            foreach (var npc in view.OrderBy(n => n.Name))
            {
                FilteredNpcs.Add(npc);
            }
            
            // Update status if needed, but can be verbose
            // _notificationService.UpdateStatus($"Отображается {FilteredNpcs.Count} из {_allNpcs.Count} NPC.");
        }

        private bool CanEditNpc()
        {
            return SelectedNpc != null;
        }

        private async Task OpenEditNpcWindowAsync()
        {
            if (SelectedNpc == null) return;

            var npcToEditCopy = SelectedNpc; // NpcEditViewModel создаст свою копию

            var editViewModel = new NpcEditViewModel(
                npcToEditCopy, 
                this.AvailableSexes, 
                this.AvailableProfessions, 
                this.AvailableMoralities, 
                this.AvailableMotivations
            );
            
            var editView = new NpcEditView
            {
                DataContext = editViewModel,
                Owner = System.Windows.Application.Current.MainWindow // Устанавливаем владельца для модального окна
            };

            // Настройка CloseAction для ViewModel
            editViewModel.CloseAction = (dialogResult) =>
            {
                editView.DialogResult = dialogResult;
                editView.Close();
            };

            bool? result = editView.ShowDialog();

            if (result == true)
            {
                // Пользователь сохранил изменения. Обновляем оригинальный NPC.
                var originalNpc = _allNpcs.FirstOrDefault(n => n.Id == editViewModel.EditingNpc.Id);
                if (originalNpc != null)
                {
                    originalNpc.Name = editViewModel.EditingNpc.Name;
                    originalNpc.Sex = editViewModel.EditingNpc.Sex;
                    originalNpc.Age = editViewModel.EditingNpc.Age;
                    originalNpc.Profession = editViewModel.EditingNpc.Profession;
                    originalNpc.HomeLocationId = editViewModel.EditingNpc.HomeLocationId;
                    originalNpc.IsVampire = editViewModel.EditingNpc.IsVampire;
                    originalNpc.Morality = editViewModel.EditingNpc.Morality;
                    originalNpc.Motivation = editViewModel.EditingNpc.Motivation;
                    originalNpc.Background = editViewModel.EditingNpc.Background;
                    // Важно: ImagePath и HasAssets пересчитаются автоматически в NpcModel
                    // Также нужно обновить свойства, если NpcModel не уведомляет об изменениях сам (но он ObservableObject)
                    // Для обновления DataGrid, если он не среагировал, можно попробовать обновить элемент в FilteredNpcs
                    // или просто вызвать ApplyFilters()
                }

                await SaveAllNpcsToJsonAsync();
                ApplyFilters(); // Переприменяем фильтры, чтобы обновить отображаемый список
                _notificationService.ShowToast("NPC успешно обновлен.", ToastType.Success);
            }
        }

        private async Task SaveAllNpcsToJsonAsync()
        {
            _notificationService.UpdateStatus("Сохранение NPC...");
            try
            {
                var options = new JsonSerializerOptions
                {
                    WriteIndented = true,
                    PropertyNameCaseInsensitive = true,
                    AllowTrailingCommas = true, // Хотя это больше для чтения, но пусть будет
                    Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping // Для корректного сохранения кириллицы
                };
                string jsonString = JsonSerializer.Serialize(_allNpcs, options);
                await File.WriteAllTextAsync(Constants.NPCSPath, jsonString);
                _notificationService.UpdateStatus("Список NPC сохранен.");
                 _notificationService.ShowToast("Данные NPC сохранены в файл.", ToastType.Success);
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[NPCsViewModel] Ошибка при сохранении NPC в JSON: {ex.Message}");
                _notificationService.ShowToast($"Ошибка при сохранении NPC: {ex.Message}", ToastType.Error);
                _notificationService.UpdateStatus("Ошибка сохранения NPC.");
            }
        }

        private bool CanManageAsset()
        {
            return SelectedNpc != null;
        }

        private bool CanDeleteAsset()
        {
            return SelectedNpc != null && SelectedNpc.HasAssets;
        }

        private static async Task LoadAssetTemplateAsync()
        {
            if (_assetImageContentTemplateCache == null)
            {
                try
                {
                    // Путь к файлу шаблона (убедитесь, что он правильный и файл включен в проект/выходную директорию)
                    string templateFilePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Content", "AssetImageContent.json");
                    if (File.Exists(templateFilePath))
                    {
                        _assetImageContentTemplateCache = await File.ReadAllTextAsync(templateFilePath);
                    }
                    else
                    {
                        Debug.WriteLine($"[NPCsViewModel] Файл шаблона ассета не найден: {templateFilePath}");
                        // Можно показать уведомление пользователю или использовать строку по умолчанию
                        _assetImageContentTemplateCache = "{\"images\":[{\"filename\":\"{filename}\",\"idiom\":\"universal\",\"scale\":\"1x\"},{\"idiom\":\"universal\",\"scale\":\"2x\"},{\"idiom\":\"universal\",\"scale\":\"3x\"}],\"info\":{\"author\":\"xcode\",\"version\":1}}";
                    }
                }
                catch (Exception ex)
                {
                    Debug.WriteLine($"[NPCsViewModel] Ошибка загрузки шаблона ассета: {ex.Message}");
                    // Запасной вариант, если чтение файла не удалось
                     _assetImageContentTemplateCache = "{\"images\":[{\"filename\":\"{filename}\",\"idiom\":\"universal\",\"scale\":\"1x\"},{\"idiom\":\"universal\",\"scale\":\"2x\"},{\"idiom\":\"universal\",\"scale\":\"3x\"}],\"info\":{\"author\":\"xcode\",\"version\":1}}";
                }
            }
        }

        private async Task AddOrReplaceAssetAsync()
        {
            if (SelectedNpc == null) return;

            var openFileDialog = new OpenFileDialog
            {
                Filter = "PNG Images (*.png)|*.png",
                Title = "Выберите PNG для ассета NPC"
            };

            if (openFileDialog.ShowDialog() == true)
            {
                string selectedFilePath = openFileDialog.FileName;
                _notificationService.UpdateStatus("Обработка ассета...");
                try
                {
                    string npcId = SelectedNpc.Id.ToString();
                    string imageSetFolderName = $"npc{npcId}.imageset";
                    string expectedImageFileName = $"npc{npcId}.png";

                    string npcAssetSetPath = Path.Combine(Constants.NPCSAssetsFolderPath, imageSetFolderName);
                    Directory.CreateDirectory(npcAssetSetPath); // Создаст, если не существует

                    string destinationImagePath = Path.Combine(npcAssetSetPath, expectedImageFileName);
                    File.Copy(selectedFilePath, destinationImagePath, true); // true для перезаписи

                    // Создание/обновление Contents.json
                    if (_assetImageContentTemplateCache == null)
                    {
                        await LoadAssetTemplateAsync(); // Убедимся, что шаблон загружен
                        if (_assetImageContentTemplateCache == null) { 
                             _notificationService.ShowToast("Ошибка: Шаблон для Contents.json не загружен.", ToastType.Error);
                             return;
                        }
                    }
                    
                    string rawContentsJsonString = _assetImageContentTemplateCache.Replace("{filename}", expectedImageFileName);
                    
                    // Парсинг и повторная сериализация для форматирования
                    string formattedContentsJson;
                    try
                    {
                        using (JsonDocument jsonDoc = JsonDocument.Parse(rawContentsJsonString))
                        {
                            var options = new JsonSerializerOptions
                            {
                                WriteIndented = true,
                                // Encoder можно добавить, если в шаблоне есть не-ASCII символы, которые нужно сохранить как есть
                                // Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping 
                            };
                            formattedContentsJson = JsonSerializer.Serialize(jsonDoc.RootElement, options);
                        }
                    }
                    catch (JsonException ex)
                    {
                        Debug.WriteLine($"[NPCsViewModel] Ошибка парсинга JSON для форматирования Contents.json: {ex.Message}. Используется исходная строка.");
                        formattedContentsJson = rawContentsJsonString; // В случае ошибки парсинга, записываем как есть
                    }

                    string contentsJsonPath = Path.Combine(npcAssetSetPath, "Contents.json");
                    await File.WriteAllTextAsync(contentsJsonPath, formattedContentsJson);
                    
                    SelectedNpc.RefreshAssetProperties();
                    OnPropertyChanged(nameof(SelectedNpcImagePath)); // Обновляем путь к картинке в UI
                    DeleteAssetCommand.NotifyCanExecuteChanged(); // Может повлиять на доступность кнопки удаления
                    AddOrReplaceAssetCommand.NotifyCanExecuteChanged(); // Может повлиять на текст кнопки (если будем менять)

                    _notificationService.ShowToast("Ассет NPC успешно добавлен/заменен.", ToastType.Success);
                    _notificationService.UpdateStatus("Ассет NPC обновлен.");
                }
                catch (Exception ex)
                {
                    Debug.WriteLine($"[NPCsViewModel] Ошибка при добавлении/замене ассета: {ex.Message}");
                    _notificationService.ShowToast($"Ошибка при обработке ассета: {ex.Message}", ToastType.Error);
                    _notificationService.UpdateStatus("Ошибка обработки ассета.");
                }
            }
        }

        private async Task DeleteAssetAsync()
        {
            if (SelectedNpc == null || !SelectedNpc.HasAssets) return;
            
            // Попросим подтверждение у пользователя
            // Для этого лучше использовать специализированный сервис диалогов, но пока используем простой MessageBox
            var messageBoxResult = System.Windows.MessageBox.Show($"Вы уверены, что хотите удалить ассет для NPC {SelectedNpc.Name} (ID: {SelectedNpc.Id})? Это действие необратимо.",
                                                              "Подтверждение удаления ассета", 
                                                              System.Windows.MessageBoxButton.YesNo, 
                                                              System.Windows.MessageBoxImage.Warning);
            if (messageBoxResult == System.Windows.MessageBoxResult.No)
            {
                return;
            }

            _notificationService.UpdateStatus("Удаление ассета...");
            try
            {
                string npcId = SelectedNpc.Id.ToString();
                string imageSetFolderName = $"npc{npcId}.imageset";
                string npcAssetSetPath = Path.Combine(Constants.NPCSAssetsFolderPath, imageSetFolderName);

                if (Directory.Exists(npcAssetSetPath))
                {
                    Directory.Delete(npcAssetSetPath, true); // true для рекурсивного удаления
                }
                
                SelectedNpc.RefreshAssetProperties();
                OnPropertyChanged(nameof(SelectedNpcImagePath)); // Обновляем UI
                DeleteAssetCommand.NotifyCanExecuteChanged();
                AddOrReplaceAssetCommand.NotifyCanExecuteChanged();

                _notificationService.ShowToast("Ассет NPC успешно удален.", ToastType.Success);
                _notificationService.UpdateStatus("Ассет NPC удален.");
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[NPCsViewModel] Ошибка при удалении ассета: {ex.Message}");
                _notificationService.ShowToast($"Ошибка при удалении ассета: {ex.Message}", ToastType.Error);
                _notificationService.UpdateStatus("Ошибка удаления ассета.");
            }
        }
    }
} 