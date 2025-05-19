using CRProjectEditor.Models; // Required for SceneType
using System;
using System.Windows;
using System.Windows.Input; // For KeyEventArgs and TextCompositionEventArgs
using System.Text.RegularExpressions; // For Regex
using System.Collections.Generic;

namespace CRProjectEditor.Views
{
    public partial class EditSceneDetailsWindow : Window
    {
        public string SceneIdString { get; private set; }
        public string SceneName { get; private set; }
        public string SceneDescription { get; private set; }
        public SceneType SelectedSceneType { get; private set; }
        public bool IsIndoor { get; private set; }
        public int? ParentSceneId { get; private set; }
        public int Population { get; private set; }
        public int Radius { get; private set; }

        private readonly SceneType _initialSceneType; // To keep the original type for name generation if needed
        private readonly Func<SceneType, string, string> _nameGenerator;
        private bool _isIdActuallyEditable; // Internal flag based on how the window was opened

        // Constructor for creating a new scene (ID might be placeholder or determined later)
        public EditSceneDetailsWindow(int currentId, string currentName, string currentDescription, 
                                    SceneType sceneType, Func<SceneType, string, string> nameGenerator, bool isIdEditable = true)
            : this(CreateDefaultScene(currentId, currentName, currentDescription, sceneType), nameGenerator, isIdEditable)
        {
        }

        private static Scene CreateDefaultScene(int currentId, string currentName, string currentDescription, SceneType sceneType)
        {
            Scene scene = new()
            {
                Id = currentId,
                Name = currentName,
                Description = currentDescription,
                SceneType = sceneType,
                IsIndoor = false,
                ParentSceneId = null,
                Population = 0,
                Radius = 10
            };

            var indoorSceneTypes = new List<SceneType>
                {
                    SceneType.Castle, SceneType.Cathedral, SceneType.Cloister, SceneType.Temple,
                    SceneType.Crypt, SceneType.Manor, SceneType.Military, SceneType.Blacksmith,
                    SceneType.AlchemistShop, SceneType.Warehouse, SceneType.Bookstore, SceneType.Shop,
                    SceneType.Mine, SceneType.Tavern, SceneType.Brothel, SceneType.Bathhouse,
                    SceneType.Cave, SceneType.House, SceneType.Dungeon
                };

            if (indoorSceneTypes.Contains(sceneType))
            {
                scene.IsIndoor = true;
            }

            return scene;
        }

        // Constructor for editing an existing scene (receives full scene object)
        public EditSceneDetailsWindow(Scene sceneToEdit, Func<SceneType, string, string> nameGenerator, bool isIdEditable = true)
        {
            InitializeComponent();
            Owner = Application.Current.MainWindow;
            DataContext = this; // For potential future bindings directly to properties

            // --- Заполнение SceneTypeComboBox ---
            SceneTypeComboBox.ItemsSource = Enum.GetValues(typeof(SceneType));
            // --- Конец заполнения ---

            _isIdActuallyEditable = isIdEditable;
            SceneIdTextBox.IsReadOnly = !isIdEditable;
            if (!isIdEditable)
            {
                SceneIdTextBox.ToolTip = "ID нельзя изменить в этом режиме.";
            }

            // Populate fields from sceneToEdit
            SceneIdString = sceneToEdit.Id.ToString();
            SceneIdTextBox.Text = SceneIdString;
            SceneName = sceneToEdit.Name;
            SceneNameTextBox.Text = SceneName;
            SceneDescription = sceneToEdit.Description;
            SceneDescriptionTextBox.Text = SceneDescription;
            
            SelectedSceneType = sceneToEdit.SceneType;
            SceneTypeComboBox.SelectedItem = SelectedSceneType;
            _initialSceneType = sceneToEdit.SceneType; // Store for name generator

            IsIndoor = sceneToEdit.IsIndoor;
            IsIndoorCheckBox.IsChecked = IsIndoor;

            ParentSceneId = sceneToEdit.ParentSceneId;
            ParentSceneIdTextBox.Text = ParentSceneId?.ToString() ?? string.Empty;

            Population = sceneToEdit.Population;
            PopulationTextBox.Text = Population.ToString();

            Radius = sceneToEdit.Radius;
            RadiusTextBox.Text = Radius.ToString();
            
            _nameGenerator = nameGenerator;
        }

        private void GenerateNameButton_Click(object sender, RoutedEventArgs e)
        {
            if (_nameGenerator != null)
            {
                // Use the currently selected SceneType in the ComboBox for name generation
                SceneType typeForNameGen = (SceneType)(SceneTypeComboBox.SelectedItem ?? _initialSceneType);
                string newName = _nameGenerator(typeForNameGen, SceneNameTextBox.Text); 
                SceneNameTextBox.Text = newName; 
            }
        }

        private void SaveButton_Click(object sender, RoutedEventArgs e)
        {
            // Validate and retrieve values
            SceneIdString = SceneIdTextBox.Text; // ID is retrieved but might not have been editable
            SceneName = SceneNameTextBox.Text;
            SceneDescription = SceneDescriptionTextBox.Text;
            SelectedSceneType = (SceneType)(SceneTypeComboBox.SelectedItem ?? _initialSceneType);
            IsIndoor = IsIndoorCheckBox.IsChecked ?? false;
            
            if (int.TryParse(ParentSceneIdTextBox.Text, out int parentId))
            {
                ParentSceneId = parentId;
            }
            else if (string.IsNullOrWhiteSpace(ParentSceneIdTextBox.Text))
            {
                ParentSceneId = null; 
            }
            else
            {
                MessageBox.Show("ParentScene ID должен быть числом или пустым.", "Ошибка Валидации", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            if (int.TryParse(PopulationTextBox.Text, out int populationValue))
            {
                Population = populationValue;
            }
            else
            {
                MessageBox.Show("Население должно быть числом.", "Ошибка Валидации", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            if (int.TryParse(RadiusTextBox.Text, out int radiusValue))
            {
                Radius = radiusValue;
            }
            else
            {
                MessageBox.Show("Радиус должен быть числом.", "Ошибка Валидации", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            DialogResult = true;
            Close();
        }

        private void CancelButton_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
            Close();
        }

        // Helper to allow only numeric input for TextBoxes
        private void NumericTextBox_PreviewTextInput(object sender, TextCompositionEventArgs e)
        {
            Regex regex = new Regex("[^0-9-]+"); // Allows numbers and a leading minus (though ParentId, Pop, Radius are likely non-negative)
            e.Handled = regex.IsMatch(e.Text);
        }
    }
} 