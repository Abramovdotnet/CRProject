using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CRProjectEditor.Models;
using CRProjectEditor.Services;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;

namespace CRProjectEditor.ViewModels
{
    public partial class NpcEditViewModel : ObservableObject
    {
        [ObservableProperty]
        private NpcModel _editingNpc;

        public ObservableCollection<string> AvailableSexes { get; } = new ObservableCollection<string>();
        public ObservableCollection<string> AvailableProfessions { get; } = new ObservableCollection<string>();
        public ObservableCollection<string> AvailableMoralities { get; } = new ObservableCollection<string>();
        public ObservableCollection<string> AvailableMotivations { get; } = new ObservableCollection<string>();

        private readonly List<NpcModel> _otherNpcs;
        private readonly INotificationService _notificationService;

        public IRelayCommand SaveCommand { get; }
        public IRelayCommand CancelCommand { get; }

        public event Action<bool>? RequestClose;

        public NpcEditViewModel(
            NpcModel npcToEdit,
            List<NpcModel> otherNpcs,
            INotificationService notificationService)
        {
            _editingNpc = npcToEdit;
            _otherNpcs = otherNpcs;
            _notificationService = notificationService;

            var allNpcsForDropdowns = new List<NpcModel>(_otherNpcs);
            allNpcsForDropdowns.Add(_editingNpc);

            PopulateDropdown(AvailableSexes, allNpcsForDropdowns.Select(n => n.Sex).Distinct());
            PopulateDropdown(AvailableProfessions, allNpcsForDropdowns.Select(n => n.Profession).Distinct());
            PopulateDropdown(AvailableMoralities, allNpcsForDropdowns.Select(n => n.Morality).Distinct());
            PopulateDropdown(AvailableMotivations, allNpcsForDropdowns.Select(n => n.Motivation).Distinct());
            
            EnsureValueInCollection(AvailableSexes, EditingNpc.Sex);
            EnsureValueInCollection(AvailableProfessions, EditingNpc.Profession);
            EnsureValueInCollection(AvailableMoralities, EditingNpc.Morality);
            EnsureValueInCollection(AvailableMotivations, EditingNpc.Motivation);


            SaveCommand = new RelayCommand(OnSave, CanSave);
            CancelCommand = new RelayCommand(OnCancel);
            EditingNpc.PropertyChanged += (s, e) => SaveCommand.NotifyCanExecuteChanged();
        }
        
        private void PopulateDropdown(ObservableCollection<string> collection, IEnumerable<string?> values)
        {
            collection.Clear();
            foreach (var value in values.Where(v => !string.IsNullOrEmpty(v)).OrderBy(v => v))
            {
                collection.Add(value!);
            }
        }

        private void EnsureValueInCollection(ObservableCollection<string> collection, string? value)
        {
            if (!string.IsNullOrEmpty(value) && !collection.Contains(value))
            {
                collection.Add(value);
                var sorted = collection.OrderBy(x => x).ToList();
                collection.Clear();
                foreach(var item in sorted) collection.Add(item);
            }
        }

        private bool CanSave()
        {
            bool isNameValid = !string.IsNullOrWhiteSpace(EditingNpc.Name);
            bool isIdValid = EditingNpc.Id > 0;
            
            return isNameValid && isIdValid;
        }

        private void OnSave()
        {
            if (!CanSave())
            {
                _notificationService.ShowToast("Не все обязательные поля заполнены или данные некорректны.", ToastType.Warning);
                return;
            }
            RequestClose?.Invoke(true);
        }

        private void OnCancel()
        {
            RequestClose?.Invoke(false);
        }
    }
} 