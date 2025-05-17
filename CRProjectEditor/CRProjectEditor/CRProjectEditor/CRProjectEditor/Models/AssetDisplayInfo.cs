namespace CRProjectEditor.Models
{
    public class AssetDisplayInfo
    {
        public int AssetId { get; set; }
        public string ImagePath { get; set; } // Path to an image representation, if any
        // Add any other relevant asset properties here

        public AssetDisplayInfo(int assetId, string imagePath)
        {
            AssetId = assetId;
            ImagePath = imagePath;
        }
    }
} 