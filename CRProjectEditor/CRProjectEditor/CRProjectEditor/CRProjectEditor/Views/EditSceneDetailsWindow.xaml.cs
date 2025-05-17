using CRProjectEditor.Models; // Required for SceneType
using System;
using System.Windows;

namespace CRProjectEditor.Views
{
    public partial class EditSceneDetailsWindow : Window
    {
        public string SceneIdString { get; private set; }
        public string SceneName { get; private set; }
        public string SceneDescription { get; private set; }

        private readonly SceneType _sceneType;
        private readonly Func<SceneType, string, string> _nameGenerator;

        public EditSceneDetailsWindow(int currentId, string currentName, string currentDescription, 
                                    SceneType sceneType, Func<SceneType, string, string> nameGenerator)
        {
            InitializeComponent();
            Owner = Application.Current.MainWindow;
            
            SceneIdTextBox.Text = currentId.ToString();
            SceneNameTextBox.Text = currentName;
            SceneDescriptionTextBox.Text = currentDescription;
            
            SceneIdString = currentId.ToString(); 
            SceneName = currentName;
            SceneDescription = currentDescription;

            _sceneType = sceneType;
            _nameGenerator = nameGenerator;
        }

        private void GenerateNameButton_Click(object sender, RoutedEventArgs e)
        {
            if (_nameGenerator != null)
            {
                string newName = _nameGenerator(_sceneType, SceneNameTextBox.Text); // Pass current name as fallback
                SceneNameTextBox.Text = newName; 
                // The SceneName property will be updated when Save is clicked.
            }
        }

        private void SaveButton_Click(object sender, RoutedEventArgs e)
        {
            SceneIdString = SceneIdTextBox.Text;
            SceneName = SceneNameTextBox.Text; // This will now pick up the potentially generated name
            SceneDescription = SceneDescriptionTextBox.Text;
            DialogResult = true;
            Close();
        }

        private void CancelButton_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
            Close();
        }
    }
} 