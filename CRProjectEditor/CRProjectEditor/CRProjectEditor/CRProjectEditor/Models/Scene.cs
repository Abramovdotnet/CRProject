using System.Collections.Generic;
using System.Numerics;
using System.Text.Json.Serialization;

namespace CRProjectEditor.Models
{
    public class Scene
    {
        [JsonPropertyName("id")]
        public int Id { get; set; }

        [JsonPropertyName("name")]
        public string Name { get; set; } = string.Empty;

        [JsonPropertyName("description")]
        public string Description { get; set; } = string.Empty;

        [JsonPropertyName("sceneType")]
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public SceneType SceneType { get; set; }

        [JsonPropertyName("isIndoor")]
        public bool IsIndoor { get; set; }

        [JsonPropertyName("parentSceneId")]
        public int? ParentSceneId { get; set; }

        [JsonPropertyName("childSceneIds")]
        public List<int> ChildSceneIds { get; set; } = new List<int>();

        [JsonPropertyName("hubSceneIds")]
        public List<int> HubSceneIds { get; set; } = new List<int>();
        
        [JsonPropertyName("x")]
        public int X { get; set; }

        [JsonPropertyName("y")]
        public int Y { get; set; }

        [JsonPropertyName("connections")]
        public List<SceneConnection> Connections { get; set; } = new List<SceneConnection>();

        [JsonPropertyName("population")]
        public int Population { get; set; }

        [JsonPropertyName("radius")]
        public int Radius { get; set; } // Changed to int for consistency, can be float if needed

        [JsonPropertyName("residentCount")]
        [JsonIgnore] // Calculated, not directly from JSON
        public int ResidentCount { get; set; }

        // Properties for the coordinate generation algorithm
        [JsonIgnore]
        public Vector2 Point { get; set; } // Using Vector2 for calculations
        [JsonIgnore]
        public bool IsPlaced { get; set; }
    }
} 