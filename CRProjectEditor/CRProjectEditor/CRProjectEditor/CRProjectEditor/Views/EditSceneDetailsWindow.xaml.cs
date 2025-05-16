using System.Windows;

namespace CRProjectEditor.Views
{
    public partial class EditSceneDetailsWindow : Window
    {
        public string SceneName { get; private set; }
        public string SceneDescription { get; private set; }

        public EditSceneDetailsWindow(string currentName, string currentDescription)
        {
            InitializeComponent();
            Owner = Application.Current.MainWindow;
            SceneNameTextBox.Text = currentName;
            SceneDescriptionTextBox.Text = currentDescription;
            SceneName = currentName;
            SceneDescription = currentDescription;
        }

        private void SaveButton_Click(object sender, RoutedEventArgs e)
        {
            SceneName = SceneNameTextBox.Text;
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