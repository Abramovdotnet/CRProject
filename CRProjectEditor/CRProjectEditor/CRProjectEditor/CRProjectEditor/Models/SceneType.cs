namespace CRProjectEditor.Models
{
    // Simplified SceneType enum for JSON deserialization and logic
    public enum SceneType
    {
        // Add all your SceneType cases here as strings if needed for parsing,
        // or ensure they match the JSON string values.
        // For the generator, we mainly care about its existence for deserialization.
        Generic, // Placeholder if specific types aren't crucial for coordinate generation
        Town, City, Village, Dungeon, Forest, Cave, Ruins, Crypt, Mine, Castle, Shop, Temple, // From SceneType.swift
        // Added from Duskvale.json inspection:
        Square, Tavern, Blacksmith, House, Road
    }
} 