using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using MauiApp1.Tools;
using System.Numerics;
using System.Diagnostics;
using System.Threading.Tasks; // Added for Task

namespace MauiApp1.ViewModels // Changed namespace to ViewModels
{
    public partial class WorldViewModel : ObservableObject
    {
        private string _duskvaleJsonPath = "/Users/abramovanatoliy/Documents/CRProject/CRProject/Data/Duskvale/Duskvale.json"; 
        private Vector2 _markerSize = new Vector2(120, 50); 
        private float _coordinateScale = 80.0f;
        private float _baseDistanceUnit = 2.0f;

        [ObservableProperty]
        private string? _statusMessage;

        public WorldViewModel()
        {
        }

        [RelayCommand]
        private async Task GenerateMapCoordinates()
        {
            StatusMessage = "Processing... please wait.";
            try
            {
                await Task.Run(() => 
                {
                    MapJsonGenerator.ProcessMapFile(_duskvaleJsonPath, _markerSize, _coordinateScale, _baseDistanceUnit);
                });
                StatusMessage = $"Map coordinates generated successfully for {_duskvaleJsonPath}!";
                Debug.WriteLine("Map generation process completed.");
            }
            catch (System.Exception ex) // Explicit System.Exception
            {
                StatusMessage = $"Error generating map: {ex.Message}";
                Debug.WriteLine($"Error during map generation: {ex.Message}");
            }
        }
    }
} 