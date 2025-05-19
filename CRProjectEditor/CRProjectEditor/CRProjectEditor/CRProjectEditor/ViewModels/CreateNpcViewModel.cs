using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CRProjectEditor.Models;
using CRProjectEditor.Services;
using CRProjectEditor.Tools;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using System.Windows;

namespace CRProjectEditor.ViewModels
{
    public partial class CreateNpcViewModel : ObservableObject
    {
        [ObservableProperty]
        private NpcModel _newNpc = new NpcModel();

        public List<int> ExistingNpcIds { get; set; } = new List<int>();
        private List<NpcModel> _allNpcsForValidation = new List<NpcModel>();
        private readonly INotificationService _notificationService;

        // Sex
        public ObservableCollection<string> AvailableSexes { get; } = new ObservableCollection<string>();
        // Name Generation
        private List<NpcNameModel> _npcNameModels = new List<NpcNameModel>();
        private List<SurnameModel> _surnameModels = new List<SurnameModel>();
        public IRelayCommand GenerateNameCommand { get; }

        // Profession
        public ObservableCollection<string> AvailableProfessions { get; } = new ObservableCollection<string>();
        // Morality
        public ObservableCollection<string> AvailableMoralities { get; } = new ObservableCollection<string>();
        // Motivation
        public ObservableCollection<string> AvailableMotivations { get; } = new ObservableCollection<string>();

        // Scene (HomeLocation)
        public ObservableCollection<Scene> AvailableScenes { get; } = new ObservableCollection<Scene>();
        [ObservableProperty]
        private Scene? _selectedScene;
        partial void OnSelectedSceneChanged(Scene? value)
        {
            NewNpc.HomeLocationId = value?.Id ?? 0;
            SaveNpcCommand.NotifyCanExecuteChanged();
        }

        public IRelayCommand SaveNpcCommand { get; }
        public IRelayCommand CancelCommand { get; }

        public event Action? RequestClose;
        public event Action<NpcModel>? NpcCreated;

        private Random _random = new Random(); // Instance for random selection

        public CreateNpcViewModel(List<NpcModel> allNpcs, INotificationService notificationService)
        {
            _allNpcsForValidation = allNpcs ?? new List<NpcModel>();
            ExistingNpcIds = _allNpcsForValidation.Select(n => n.Id).ToList();
            _notificationService = notificationService;

            NewNpc.Id = ExistingNpcIds.Any() ? ExistingNpcIds.Max() + 1 : 1;
            NewNpc.Age = _random.Next(18, 81); // Random age between 18 and 80 inclusive

            LoadSexes();
            if (AvailableSexes.Any())
            {
                NewNpc.Sex = AvailableSexes[_random.Next(AvailableSexes.Count)];
            }
            // Attempt to generate name immediately after sex is set, 
            // relies on _npcNameModels & _surnameModels being potentially loaded by LoadInitialDataAsync call later
            // or CanGenerateName will prevent execution until data is ready.
            // For more robust immediate generation, LoadNamesAndSurnamesAsync might need to be awaited here.

            LoadProfessions(_allNpcsForValidation);
            if (AvailableProfessions.Any())
            {
                NewNpc.Profession = AvailableProfessions[_random.Next(AvailableProfessions.Count)];
            }
            else
            {
                NewNpc.Profession = null; // Or some default if list is empty
            }
            
            LoadMoralities(_allNpcsForValidation);
            if (AvailableMoralities.Any())
            {
                NewNpc.Morality = AvailableMoralities[_random.Next(AvailableMoralities.Count)];
            }

            LoadMotivations(_allNpcsForValidation);
            if (AvailableMotivations.Any())
            {
                NewNpc.Motivation = AvailableMotivations[_random.Next(AvailableMotivations.Count)];
            }
            
            GenerateNameCommand = new RelayCommand(GenerateName, CanGenerateName);
            SaveNpcCommand = new RelayCommand(SaveNpc, CanSaveNpc);
            CancelCommand = new RelayCommand(Cancel);
            
            NewNpc.PropertyChanged += (s, e) => {
                SaveNpcCommand.NotifyCanExecuteChanged();
                if (e.PropertyName == nameof(NewNpc.Sex))
                {
                    GenerateNameCommand.NotifyCanExecuteChanged();
                    // Optionally, auto-generate name when sex changes *after* initial load
                    // if (CanGenerateName()) { GenerateName(); }
                }
            };

            // Asynchronous loading for names, surnames, scenes
            // and then attempt to generate name if conditions are met.
            _ = InitializeAndGenerateNameAsync(); 
        }
        
        private async Task InitializeAndGenerateNameAsync() // Renamed and modified
        {
            await LoadNamesAndSurnamesAsync();
            await LoadScenesAsync();
            // Now that names/surnames are loaded, try generating a name if sex is set
            if (CanGenerateName())
            {
                GenerateName();
            }
            GenerateNameCommand.NotifyCanExecuteChanged();
        }

        private void LoadSexes()
        {
            AvailableSexes.Clear();
            AvailableSexes.Add("Male");
            AvailableSexes.Add("Female");
        }

        private async Task LoadNamesAndSurnamesAsync()
        {
            try
            {
                if (File.Exists(Constants.NpcNamesPath))
                {
                    string namesJson = await File.ReadAllTextAsync(Constants.NpcNamesPath);
                    _npcNameModels = JsonSerializer.Deserialize<List<NpcNameModel>>(namesJson, new JsonSerializerOptions { PropertyNameCaseInsensitive = true }) ?? new List<NpcNameModel>();
                }
                else
                {
                    _notificationService.ShowToast("Names file not found.", ToastType.Error);
                }

                if (File.Exists(Constants.NpcSurnamesPath))
                {
                    string surnamesJson = await File.ReadAllTextAsync(Constants.NpcSurnamesPath);
                    _surnameModels = JsonSerializer.Deserialize<List<SurnameModel>>(surnamesJson, new JsonSerializerOptions { PropertyNameCaseInsensitive = true }) ?? new List<SurnameModel>();
                }
                else
                {
                    _notificationService.ShowToast("Surnames file not found.", ToastType.Error);
                }
            }
            catch (Exception ex)
            {
                _notificationService.ShowToast($"Error loading names/surnames: {ex.Message}", ToastType.Error);
            }
        }
        
        private bool CanGenerateName()
        {
            // Ensure names and surnames are loaded, and sex is selected
            return !string.IsNullOrEmpty(NewNpc.Sex) && _npcNameModels.Any() && _surnameModels.Any();
        }

        private void GenerateName()
        {
            if (!CanGenerateName()) // Extra check
            {
                _notificationService.ShowToast("Cannot generate name. Ensure sex is selected and name data is loaded.", ToastType.Warning);
                return;
            }

            var relevantNames = _npcNameModels.Where(n => string.Equals(n.Sex, NewNpc.Sex, StringComparison.OrdinalIgnoreCase)).ToList();
            if (!relevantNames.Any())
            {
                _notificationService.ShowToast($"No names found for sex: {NewNpc.Sex}", ToastType.Warning);
                return;
            }
            if (!_surnameModels.Any())
            {
                _notificationService.ShowToast("No surnames found.", ToastType.Warning);
                return;
            }

            Random random = new Random();
            string generatedName;
            int attempts = 0;
            const int maxAttempts = 200; // Increased attempts

            do
            {
                string randomFirstName = relevantNames[random.Next(relevantNames.Count)].Name;
                string randomSurname = _surnameModels[random.Next(_surnameModels.Count)].Surname;
                generatedName = $"{randomFirstName} {randomSurname}";
                attempts++;
            }
            while (_allNpcsForValidation.Any(npc => string.Equals(npc.Name, generatedName, StringComparison.OrdinalIgnoreCase)) && attempts < maxAttempts);

            if (attempts >= maxAttempts && _allNpcsForValidation.Any(npc => string.Equals(npc.Name, generatedName, StringComparison.OrdinalIgnoreCase)))
            {
                _notificationService.ShowToast("Could not generate a unique name after several attempts. You may need to manually edit.", ToastType.Warning);
            }
            NewNpc.Name = generatedName; // Set the name regardless of uniqueness after max attempts
            
        }

        private void LoadProfessions(List<NpcModel> allNpcs)
        {
            AvailableProfessions.Clear();
            var professions = allNpcs.Select(npc => npc.Profession)
                                     .Where(p => !string.IsNullOrWhiteSpace(p))
                                     .Distinct()
                                     .OrderBy(p => p);
            foreach (var prof in professions)
            {
                AvailableProfessions.Add(prof!);
            }
        }
        
        private void LoadMoralities(List<NpcModel> allNpcs)
        {
            AvailableMoralities.Clear();
            var moralities = allNpcs.Select(npc => npc.Morality)
                                     .Where(m => !string.IsNullOrWhiteSpace(m))
                                     .Distinct()
                                     .OrderBy(m => m);
            foreach (var mor in moralities)
            {
                AvailableMoralities.Add(mor!);
            }
        }

        private void LoadMotivations(List<NpcModel> allNpcs)
        {
            AvailableMotivations.Clear();
            var motivations = allNpcs.Select(npc => npc.Motivation)
                                     .Where(m => !string.IsNullOrWhiteSpace(m))
                                     .Distinct()
                                     .OrderBy(m => m);
            foreach (var mot in motivations)
            {
                AvailableMotivations.Add(mot!);
            }
        }

        private async Task LoadScenesAsync()
        {
            AvailableScenes.Clear();
            try
            {
                if (File.Exists(Constants.ScenesPath))
                {
                    string jsonString = await File.ReadAllTextAsync(Constants.ScenesPath);
                    var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true, Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) } };
                    var loadedScenes = JsonSerializer.Deserialize<ObservableCollection<Scene>>(jsonString, options);
                    if (loadedScenes != null)
                    {
                        foreach (var scene in loadedScenes)
                        {
                            scene.ResidentCount = _allNpcsForValidation.Count(npc => npc.HomeLocationId == scene.Id);
                        }
                        foreach (var scene in loadedScenes.OrderBy(s => s.Name))
                        {
                            AvailableScenes.Add(scene);
                        }
                         // Set default selected scene if any, could be the first one or a "None" option if added
                        // SelectedScene = AvailableScenes.FirstOrDefault(); 
                    }
                }
                else
                {
                     _notificationService.ShowToast("Scenes file not found.", ToastType.Error);
                }
            }
            catch (Exception ex)
            {
                _notificationService.ShowToast($"Error loading scenes: {ex.Message}", ToastType.Error);
            }
        }

        private bool CanSaveNpc()
        {
            if (ExistingNpcIds.Contains(NewNpc.Id) && !_allNpcsForValidation.Any(n => n.Id == NewNpc.Id)) // ID exists and it's not the current NPC (for edit mode, not applicable here but good for general validation)
            {
                 // This case should ideally be prevented by defaulting to a new ID.
                return false;
            }
            // Check if name is unique among *other* NPCs.
            if (_allNpcsForValidation.Any(n => string.Equals(n.Name, NewNpc.Name, StringComparison.OrdinalIgnoreCase)))
            {
                // Allow saving if the name is the same as an existing NPC *only if their IDs are different AND we decide to allow non-unique names*
                // For creation, name must be unique if ID is new. The current check is okay for new NPCs if ID is guaranteed new.
                // Let's refine to ensure new NPC name does not clash.
                if (ExistingNpcIds.Contains(NewNpc.Id)) { /* This means we are trying to use an existing ID, bad */ return false;}
            }

            bool isIdValid = NewNpc.Id > 0 && !ExistingNpcIds.Contains(NewNpc.Id);
            bool isNameValid = !string.IsNullOrWhiteSpace(NewNpc.Name) && 
                               !_allNpcsForValidation.Any(n => string.Equals(n.Name, NewNpc.Name, StringComparison.OrdinalIgnoreCase));
            bool isSexValid = !string.IsNullOrWhiteSpace(NewNpc.Sex);
            bool isProfessionValid = !string.IsNullOrWhiteSpace(NewNpc.Profession);
            bool isMoralityValid = !string.IsNullOrWhiteSpace(NewNpc.Morality);
            bool isMotivationValid = !string.IsNullOrWhiteSpace(NewNpc.Motivation);

            return isIdValid && isNameValid && isSexValid && isProfessionValid && isMoralityValid && isMotivationValid;
        }

        private void SaveNpc()
        {
            if (!CanSaveNpc())
            {
                 _notificationService.ShowToast("Validation failed. Check ID uniqueness, Name uniqueness, and ensure all dropdowns are selected.", ToastType.Warning);
                return;
            }
            NpcCreated?.Invoke(NewNpc);
            RequestClose?.Invoke();
        }

        private void Cancel()
        {
            RequestClose?.Invoke();
        }
    }
} 