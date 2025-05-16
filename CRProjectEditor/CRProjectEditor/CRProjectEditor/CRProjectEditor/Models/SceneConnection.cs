using System.Text.Json.Serialization;

namespace CRProjectEditor.Models
{
    public class SceneConnection
    {
        [JsonPropertyName("connectedSceneId")]
        public int ConnectedSceneId { get; set; }

        [JsonPropertyName("travelTime")]
        public double TravelTime { get; set; } = 1.0;

        [JsonPropertyName("connectionType")]
        public string ConnectionType { get; set; } = "Standard";
    }
} 