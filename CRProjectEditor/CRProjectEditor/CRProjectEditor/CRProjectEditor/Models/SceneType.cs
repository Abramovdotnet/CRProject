namespace CRProjectEditor.Models
{
    // Simplified SceneType enum for JSON deserialization and logic
    public enum SceneType
    {
        // В соответствии с SceneType.swift

        // General
        Town,
        Castle,

        // Districts
        District,

        // Religious Buildings
        Cathedral,
        Cloister,
        Cemetery,
        Temple,
        Crypt,

        // Administrative Buildings
        Manor,
        Military,

        // Commercial Buildings
        Blacksmith,
        AlchemistShop,
        Warehouse,
        Bookstore,
        Shop,       // Общий магазин, если специфичные не подходят
        Mine,

        // Entertainment Buildings
        Tavern,
        Brothel,
        Bathhouse,

        // Public Spaces
        Square,
        Docks,
        Road, // Хотя Road может быть больше связью, чем полноценной сценой для генератора

        // Natural/Wilderness
        Forest,
        Cave,
        Ruins,
        
        // Misc
        House,    // Для жилых зон
        Dungeon
    }
} 