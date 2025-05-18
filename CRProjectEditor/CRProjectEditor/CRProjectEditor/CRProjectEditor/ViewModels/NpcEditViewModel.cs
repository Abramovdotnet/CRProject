using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CRProjectEditor.Models;
using System.Collections.ObjectModel;
using System.Linq;

namespace CRProjectEditor.ViewModels
{
    public partial class NpcEditViewModel : ObservableObject
    {
        [ObservableProperty]
        private NpcModel _editingNpc; // This will be a copy of the original NPC

        // Collections for ComboBoxes, to be populated from the parent ViewModel or service
        public ObservableCollection<string> AvailableSexes { get; }
        public ObservableCollection<string> AvailableProfessions { get; }
        public ObservableCollection<string> AvailableMoralities { get; }
        public ObservableCollection<string> AvailableMotivations { get; }

        // Store the original lists without the "Any" option for editing purposes
        private readonly ObservableCollection<string> _originalSexes;
        private readonly ObservableCollection<string> _originalProfessions;
        private readonly ObservableCollection<string> _originalMoralities;
        private readonly ObservableCollection<string> _originalMotivations;

        public IRelayCommand SaveCommand { get; }
        public IRelayCommand CancelCommand { get; }

        // Delegate to be set by the View to close the dialog
        public System.Action<bool?>? CloseAction { get; set; }

        public NpcEditViewModel(NpcModel npcToEdit, 
                                ObservableCollection<string> availableSexes,
                                ObservableCollection<string> availableProfessions,
                                ObservableCollection<string> availableMoralities,
                                ObservableCollection<string> availableMotivations)
        {
            // Create a deep copy for editing to avoid modifying the original object directly
            // For NpcModel, if it's all value types or strings, a shallow copy might be enough
            // but a proper deep copy mechanism is safer if NpcModel has complex reference type properties.
            // Assuming NpcModel properties are simple enough or ObservableObject handles changes.
            // Let's create a new instance and copy properties.
            EditingNpc = new NpcModel
            {
                Id = npcToEdit.Id, // ID is not editable but needed for reference
                Name = npcToEdit.Name,
                Sex = npcToEdit.Sex,
                Age = npcToEdit.Age,
                Profession = npcToEdit.Profession,
                HomeLocationId = npcToEdit.HomeLocationId,
                IsVampire = npcToEdit.IsVampire,
                Morality = npcToEdit.Morality,
                Motivation = npcToEdit.Motivation,
                Background = npcToEdit.Background
                // ImagePath and HasAssets are derived, no need to copy for editing logic itself
            };

            // Filter out the "Any" option for editor ComboBoxes if present
            _originalSexes = new ObservableCollection<string>(availableSexes.Where(s => s != "Любой"));
            _originalProfessions = new ObservableCollection<string>(availableProfessions.Where(p => p != "Любая"));
            _originalMoralities = new ObservableCollection<string>(availableMoralities.Where(m => m != "Любая"));
            _originalMotivations = new ObservableCollection<string>(availableMotivations.Where(m => m != "Любая"));

            AvailableSexes = _originalSexes;
            AvailableProfessions = _originalProfessions;
            AvailableMoralities = _originalMoralities;
            AvailableMotivations = _originalMotivations;
            
            // Ensure the current NPC's sex/profession etc. is selected if it exists in the filtered list
            if (!string.IsNullOrEmpty(EditingNpc.Sex) && !AvailableSexes.Contains(EditingNpc.Sex))
            {
                // This case should ideally not happen if data is consistent. 
                // Or, the lists should always contain all possible values from the data.
                // For now, if it's not in the list, it won't be selected.
            }


            SaveCommand = new RelayCommand(OnSave);
            CancelCommand = new RelayCommand(OnCancel);
        }

        private void OnSave()
        {
            // Here, you could add validation logic if needed.
            // If validation passes:
            CloseAction?.Invoke(true);
        }

        private void OnCancel()
        {
            CloseAction?.Invoke(false);
        }
    }
} 