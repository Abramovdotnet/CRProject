using CRProjectEditor.Models; // Required for SceneType
using CRProjectEditor.ViewModels; // Added for ViewModel
using CRProjectEditor.Services;   // Added for INotificationService
using System;
using System.Windows;
using System.Windows.Input; // For KeyEventArgs and TextCompositionEventArgs
using System.Text.RegularExpressions; // For Regex
using System.Collections.Generic;

namespace CRProjectEditor.Views
{
    public partial class EditSceneDetailsWindow : Window
    {
        private readonly EditSceneDetailsViewModel _viewModel;

        // Constructor for creating/editing a scene using a Scene object
        public EditSceneDetailsWindow(Scene scene, List<NpcModel> allNpcs, Func<SceneType, string, string> nameGenerator, 
                                    bool isIdEditable = true, INotificationService? notificationService = null)
        {
            InitializeComponent();
            _viewModel = new EditSceneDetailsViewModel(scene, allNpcs, nameGenerator, isIdEditable, notificationService);
            DataContext = _viewModel;
            _viewModel.RequestClose += (result) => 
            {
                try { DialogResult = result; } catch { /* Can throw if already closed */ }
                // No need to call Close() explicitly if DialogResult is set before window is shown, 
                // or if it's set while window is active.
            };
        }

        // Constructor for creating a new scene with individual parameters
        // This constructor might be less used now that WorldViewModel prepares a tempSceneForDialog
        // but kept for compatibility or direct instantiation if needed.
        public EditSceneDetailsWindow(int currentId, string currentName, string currentDescription, 
                                    SceneType sceneType, List<NpcModel> allNpcs, Func<SceneType, string, string> nameGenerator, 
                                    bool isIdEditable = true, INotificationService? notificationService = null)
            : this(CreateDefaultScene(currentId, currentName, currentDescription, sceneType), allNpcs, nameGenerator, isIdEditable, notificationService)
        {
            // The base constructor is called, which initializes _viewModel and DataContext.
            // Any specific logic for this overload can go here.
        }

        // Helper to create a default Scene object, can be static or moved to ViewModel if preferred
        public static Scene CreateDefaultScene(int id, string name, string description, SceneType type)
        {
            return new Scene
            {
                Id = id,
                Name = name,
                Description = description,
                SceneType = type,
                IsIndoor = false, // Default value
                ParentSceneId = null, // Default value
                Population = 0, // Default value
                Radius = 10, // Default value
                X = 0, Y = 0, // Default coordinates
                Connections = new List<SceneConnection>(),
                HubSceneIds = new List<int>()
                // ResidentCount is calculated, not stored directly usually.
                // ImagePath is usually derived or set elsewhere.
            };
        }

        private void SceneName_PreviewTextInput(object sender, TextCompositionEventArgs e)
        {
            // Allow letters, numbers, spaces, and some punctuation. Disallow file path specific chars.
            Regex regex = new Regex(@"[^a-zA-Z0-9_.,;:()'""\s-]");
            e.Handled = regex.IsMatch(e.Text);
        }

        private void Numeric_PreviewTextInput(object sender, TextCompositionEventArgs e)
        {
            Regex regex = new Regex("[^0-9]"); // Allow only numbers
            e.Handled = regex.IsMatch(e.Text);
        }

        private void NullableNumeric_PreviewTextInput(object sender, TextCompositionEventArgs e)
        {
            // For ParentSceneId which can be empty or numeric
            if (string.IsNullOrEmpty(e.Text)) // Allow empty input (e.g., from pasting an empty string or deleting)
            {
                e.Handled = false;
                return;
            }
            Regex regex = new Regex("[^0-9]"); // Allow only numbers if not empty
            e.Handled = regex.IsMatch(e.Text);
        }
    }
} 