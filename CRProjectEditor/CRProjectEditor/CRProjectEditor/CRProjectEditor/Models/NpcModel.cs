using System.Text.Json.Serialization;
using CommunityToolkit.Mvvm.ComponentModel;
using CRProjectEditor.Tools; 
using System.IO;            

namespace CRProjectEditor.Models
{
    public partial class NpcModel : ObservableObject
    {
        [JsonPropertyName("id")]
        public int Id { get; set; }

        [JsonPropertyName("name")]
        public string? Name { get; set; }

        [JsonPropertyName("sex")]
        public string? Sex { get; set; }

        [JsonPropertyName("age")]
        public int Age { get; set; }

        [JsonPropertyName("profession")]
        public string? Profession { get; set; }

        [JsonPropertyName("homeLocationId")]
        public int HomeLocationId { get; set; }

        [JsonPropertyName("isVampire")]
        public bool IsVampire { get; set; }

        [JsonPropertyName("morality")]
        public string? Morality { get; set; }

        [JsonPropertyName("motivation")]
        public string? Motivation { get; set; }

        [JsonPropertyName("background")]
        public string Background { get; set; } = string.Empty;

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

        public void RefreshAssetProperties()
        {
            OnPropertyChanged(nameof(ImagePath));
            OnPropertyChanged(nameof(HasAssets));
        }
    }
} 