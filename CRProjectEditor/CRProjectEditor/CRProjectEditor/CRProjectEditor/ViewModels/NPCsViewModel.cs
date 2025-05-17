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

namespace CRProjectEditor.ViewModels
{
    public partial class NPCsViewModel : ObservableObject
    {
        private readonly INotificationService _notificationService;
        private List<NpcModel> _allNpcs = new List<NpcModel>();

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
        private NpcModel? _selectedNpc;
        partial void OnSelectedNpcChanged(NpcModel? value)
        {
            OnPropertyChanged(nameof(SelectedNpcImagePath));
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

        public NPCsViewModel(INotificationService notificationService)
        {
            _notificationService = notificationService;
            LoadNpcsCommand = new AsyncRelayCommand(LoadNpcsAsync);
            ClearFiltersCommand = new RelayCommand(ClearFilters);
            _ = LoadNpcsAsync(); 
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
            FilterIsVampireNullable = null; // null for three-state CheckBox means "indeterminate" or "any"
            FilterMorality = AnyMorality;
            FilterMotivation = AnyMotivation;
            // ApplyFilters(); // This will be called by the property setters
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

            foreach (var npc in view.OrderBy(n => n.Name))
            {
                FilteredNpcs.Add(npc);
            }
            
            // Update status if needed, but can be verbose
            // _notificationService.UpdateStatus($"Отображается {FilteredNpcs.Count} из {_allNpcs.Count} NPC.");
        }
    }
} 