using System.Text.Json.Serialization;
using CommunityToolkit.Mvvm.ComponentModel;
using CRProjectEditor.Tools; 
using System.IO;            

namespace CRProjectEditor.Models
{
    public partial class NpcModel : ObservableObject
    {
        [ObservableProperty]
        [JsonPropertyName("id")]
        private int _id;

        [ObservableProperty]
        [JsonPropertyName("name")]
        private string? _name;

        [ObservableProperty]
        [JsonPropertyName("sex")]
        private string? _sex;

        [ObservableProperty]
        [JsonPropertyName("age")]
        private int _age;

        [ObservableProperty]
        [JsonPropertyName("profession")]
        private string? _profession;

        [ObservableProperty]
        [JsonPropertyName("isVampire")]
        private bool _isVampire;

        [ObservableProperty]
        [JsonPropertyName("morality")]
        private string? _morality;

        [ObservableProperty]
        [JsonPropertyName("motivation")]
        private string? _motivation;

        [JsonIgnore] // Prevent serialization of this UI-specific property
        public string? ImagePath
        {
            get
            {
                string imageFileName = $"npc{Id}.png";
                string imageSetFolder = $"npc{Id}.imageset";
                string constructedPath = Path.Combine(Constants.NPCSAssetsFolderPath, imageSetFolder, imageFileName);

                if (File.Exists(constructedPath))
                {
                    return constructedPath;
                }
                else
                {
                    // Optionally, log that the image was not found
                    System.Diagnostics.Debug.WriteLine($"[NpcModel] Image not found for NPC {Id} at path: {constructedPath}");
                    return null; // Or return a path to a default placeholder image
                }
            }
        }

        [JsonIgnore]
        public bool HasAssets => !string.IsNullOrEmpty(ImagePath);

        [ObservableProperty]
        [JsonPropertyName("homeLocationId")]
        private int _homeLocationId;

        [ObservableProperty]
        [JsonIgnore]
        private bool _isHomeLocationRelevant = true;


        [ObservableProperty]
        [JsonPropertyName("background")]
        private string _background = string.Empty;

        public void RefreshAssetProperties()
        {
            OnPropertyChanged(nameof(ImagePath));
            OnPropertyChanged(nameof(HasAssets));
        }
    }
} 