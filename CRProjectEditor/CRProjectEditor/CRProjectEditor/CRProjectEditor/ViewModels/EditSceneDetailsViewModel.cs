using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CRProjectEditor.Models;
using CRProjectEditor.Services; // Assuming INotificationService might be needed
using CRProjectEditor.Tools;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks; // For async operations
using System.Windows; // For MessageBox, DialogResult if not fully moved from view

namespace CRProjectEditor.ViewModels
{
    public partial class EditSceneDetailsViewModel : ObservableObject
    {
        private readonly Scene _originalScene;
        private readonly List<NpcModel> _allNpcsSharedList; // Changed from _allNpcsMasterList, now expects a shared instance
        private readonly Func<SceneType, string, string>? _nameGenerator;
        private readonly INotificationService? _notificationService; // Optional, for user feedback

        // Scene Properties
        [ObservableProperty]
        private int _sceneId;

        [ObservableProperty]
        private string _sceneName;

        [ObservableProperty]
        private string _sceneDescription;

        [ObservableProperty]
        private SceneType _selectedSceneType;

        [ObservableProperty]
        private bool _isIndoor;

        [ObservableProperty]
        private int? _parentSceneId;
        
        [ObservableProperty]
        private string _parentSceneIdText; // For TextBox binding, to handle nulls and validation

        [ObservableProperty]
        private int _population;

        [ObservableProperty]
        private string _populationText; // For TextBox binding and validation

        [ObservableProperty]
        private int _radius;
        
        [ObservableProperty]
        private string _radiusText; // For TextBox binding and validation

        [ObservableProperty]
        private bool _isIdEditable;

        public ObservableCollection<SceneType> SceneTypes { get; } = new ObservableCollection<SceneType>();

        // NPC Management Properties
        [ObservableProperty]
        private ObservableCollection<NpcModel> _availableNpcsView = new ObservableCollection<NpcModel>();

        [ObservableProperty]
        private ObservableCollection<NpcModel> _sceneNpcsView = new ObservableCollection<NpcModel>();

        [ObservableProperty]
        private string _npcFilterText = string.Empty;
        partial void OnNpcFilterTextChanged(string value) => RefreshAvailableNpcsView();

        // New Filter Properties
        public ObservableCollection<string> AvailableSexes { get; } = new ObservableCollection<string>();
        public ObservableCollection<string> AvailableProfessions { get; } = new ObservableCollection<string>();

        private const string AnySex = "Любой";
        private const string AnyProfession = "Любая";

        [ObservableProperty]
        private string _filterSex = AnySex;
        partial void OnFilterSexChanged(string value) => RefreshAvailableNpcsView();

        [ObservableProperty]
        private string _filterProfession = AnyProfession;
        partial void OnFilterProfessionChanged(string value) => RefreshAvailableNpcsView();

        [ObservableProperty]
        private bool? _filterIsVampireNullable = null; // null = Any, true = Yes, false = No
        partial void OnFilterIsVampireNullableChanged(bool? value) => RefreshAvailableNpcsView();

        [ObservableProperty]
        private NpcModel? _selectedAvailableNpc;

        [ObservableProperty]
        private NpcModel? _selectedSceneNpc;
        
        // We might need these for multi-selection in ListViews
        public ObservableCollection<object> SelectedAvailableNpcs { get; } = new ObservableCollection<object>();
        public ObservableCollection<object> SelectedSceneNpcs { get; } = new ObservableCollection<object>();

        // Constructor
        public EditSceneDetailsViewModel(Scene sceneToEdit, List<NpcModel> allNpcsShared, Func<SceneType, string, string>? nameGenerator, bool isIdEditable, INotificationService? notificationService = null)
        {
            _originalScene = sceneToEdit;
            _allNpcsSharedList = allNpcsShared ?? new List<NpcModel>(); // Use provided list or an empty one if null
            _nameGenerator = nameGenerator;
            _isIdEditable = isIdEditable;
            _notificationService = notificationService;

            // Initialize Scene Types for ComboBox
            foreach (SceneType type in Enum.GetValues(typeof(SceneType)))
            {
                SceneTypes.Add(type);
            }

            // Populate Scene Properties from sceneToEdit
            SceneId = sceneToEdit.Id;
            SceneName = sceneToEdit.Name;
            SceneDescription = sceneToEdit.Description;
            SelectedSceneType = sceneToEdit.SceneType;
            IsIndoor = sceneToEdit.IsIndoor;
            ParentSceneId = sceneToEdit.ParentSceneId;
            ParentSceneIdText = sceneToEdit.ParentSceneId?.ToString() ?? string.Empty;
            Population = sceneToEdit.Population;
            PopulationText = sceneToEdit.Population.ToString();
            Radius = sceneToEdit.Radius;
            RadiusText = sceneToEdit.Radius.ToString();

            // No longer loads NPCs itself; uses the provided shared list
            InitializeNpcFilterCollections(); 
            PopulateNpcLists(); 
        }

        private void InitializeNpcFilterCollections()
        {
            AvailableSexes.Clear();
            AvailableSexes.Add(AnySex);
            if (_allNpcsSharedList.Any())
            {
                _allNpcsSharedList.Select(npc => npc.Sex).Where(s => !string.IsNullOrEmpty(s)).Distinct().OrderBy(s => s).ToList().ForEach(s => AvailableSexes.Add(s!));
            }
            FilterSex = AnySex; // Set default

            AvailableProfessions.Clear();
            AvailableProfessions.Add(AnyProfession);
            if (_allNpcsSharedList.Any())
            {
                _allNpcsSharedList.Select(npc => npc.Profession).Where(p => !string.IsNullOrEmpty(p)).Distinct().OrderBy(p => p).ToList().ForEach(p => AvailableProfessions.Add(p!));
            }
            FilterProfession = AnyProfession; // Set default

            FilterIsVampireNullable = null; // Default to Any
        }

        private void PopulateNpcLists()
        {
            SceneNpcsView.Clear();
            var currentSceneId = this.SceneId; // Use the ID of the scene being edited

            foreach (var npc in _allNpcsSharedList)
            {
                if (npc.HomeLocationId == currentSceneId)
                {
                    SceneNpcsView.Add(npc);
                }
            }
            RefreshAvailableNpcsView(); // This will populate AvailableNpcsView
        }

        private void RefreshAvailableNpcsView()
        {
            AvailableNpcsView.Clear();
            var sceneNpcIds = new HashSet<int>(SceneNpcsView.Select(npc => npc.Id));
            
            IEnumerable<NpcModel> filtered = _allNpcsSharedList.Where(npc => !sceneNpcIds.Contains(npc.Id) && npc.HomeLocationId == 0);

            if (!string.IsNullOrWhiteSpace(NpcFilterText))
            {
                filtered = filtered.Where(npc => npc.Name != null && npc.Name.Contains(NpcFilterText, StringComparison.OrdinalIgnoreCase));
            }

            if (FilterSex != AnySex && !string.IsNullOrEmpty(FilterSex))
            {
                filtered = filtered.Where(npc => string.Equals(npc.Sex, FilterSex, StringComparison.OrdinalIgnoreCase));
            }

            if (FilterProfession != AnyProfession && !string.IsNullOrEmpty(FilterProfession))
            {
                filtered = filtered.Where(npc => string.Equals(npc.Profession, FilterProfession, StringComparison.OrdinalIgnoreCase));
            }

            if (FilterIsVampireNullable.HasValue)
            {
                filtered = filtered.Where(npc => npc.IsVampire == FilterIsVampireNullable.Value);
            }

            foreach (var npc in filtered.OrderBy(n => n.Name))
            {
                AvailableNpcsView.Add(npc);
            }
        }

        [RelayCommand]
        private void AddNpcToScene()
        {
            var npcsToAdd = SelectedAvailableNpcs.Cast<NpcModel>().ToList(); 
            if (!npcsToAdd.Any() && SelectedAvailableNpc != null) 
            {
                npcsToAdd.Add(SelectedAvailableNpc);
            }

            if (npcsToAdd.Any())
            {
                foreach (var npc in npcsToAdd)
                {
                    npc.HomeLocationId = this.SceneId; // This now modifies the shared list instance
                }
                PopulateNpcLists(); 
                SelectedAvailableNpcs.Clear(); 
                SelectedAvailableNpc = null;
            }
        }

        [RelayCommand]
        private void RemoveNpcFromScene()
        {
            var npcsToRemove = SelectedSceneNpcs.Cast<NpcModel>().ToList();  
            if (!npcsToRemove.Any() && SelectedSceneNpc != null) 
            {
                 npcsToRemove.Add(SelectedSceneNpc);
            }
            
            if (npcsToRemove.Any())
            {
                foreach (var npc in npcsToRemove)
                {
                    npc.HomeLocationId = 0; // This now modifies the shared list instance
                }
                PopulateNpcLists();
                SelectedSceneNpcs.Clear(); 
                SelectedSceneNpc = null;
            }
        }
        
        [RelayCommand]
        private void GenerateSceneName()
        {
            if (_nameGenerator != null)
            {
                SceneName = _nameGenerator(SelectedSceneType, SceneName);
            }
        }

        public bool? DialogResult { get; private set; }

        [RelayCommand]
        private void Save()
        {
            // Validate text inputs for numbers
            if (!int.TryParse(PopulationText, out int populationValue))
            {
                MessageBox.Show("Население должно быть числом.", "Ошибка Валидации", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }
            Population = populationValue;

            if (!int.TryParse(RadiusText, out int radiusValue))
            {
                MessageBox.Show("Радиус должен быть числом.", "Ошибка Валидации", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }
            Radius = radiusValue;

            if (string.IsNullOrWhiteSpace(ParentSceneIdText))
            {
                ParentSceneId = null;
            }
            else if (!int.TryParse(ParentSceneIdText, out int parentIdValue))
            {
                MessageBox.Show("ParentScene ID должен быть числом или пустым.", "Ошибка Валидации", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }
            else
            {
                ParentSceneId = parentIdValue;
            }
            
            _originalScene.Name = SceneName;
            _originalScene.Description = SceneDescription;
            _originalScene.SceneType = SelectedSceneType;
            _originalScene.IsIndoor = IsIndoor;
            _originalScene.ParentSceneId = ParentSceneId;
            _originalScene.Population = Population;
            _originalScene.Radius = Radius;
            if (IsIdEditable)
            {
                _originalScene.Id = SceneId; 
            }
            // NPC HomeLocationId changes are already made to the _allNpcsSharedList instance.
            // WorldViewModel is responsible for saving this list.
            DialogResult = true;
            RequestClose?.Invoke(DialogResult); 
        }

        [RelayCommand]
        private void Cancel()
        {
            // NOTE: If NPCs were modified in the shared list and user cancels,
            // those changes are currently NOT reverted. This might be desired or not.
            // To revert, a deep copy of NPC states related to this scene would be needed at init.
            DialogResult = false;
            RequestClose?.Invoke(DialogResult); 
        }

        public Action<bool?>? RequestClose; // Changed to Action<bool?>

        // This is called by Save/Cancel now, View should observe DialogResult.
        // public void CloseWindow(bool dialogValue)
        // {
        //     DialogResult = dialogValue;
        //     RequestClose?.Invoke();
        // }
    }
} 