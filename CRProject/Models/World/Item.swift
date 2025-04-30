//
//  Item.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 22.04.2025.
//

import SwiftUI

class Item : Codable {
    var id: Int = 0
    var type: ItemType = .food
    var name: String = "Food"
    var cost: Int = 0
    var index: Int = 0
    private static var runtimeIndex: Int = 0
    
    private enum CodingKeys: String, CodingKey {
        case id, type, name, cost
    }
    
    static func createUnique(_ item: Item) -> Item {
        Item.runtimeIndex += 1
        
        let instance = Item()
        instance.id = item.id
        instance.type = item.type
        instance.name = item.name
        instance.cost = item.cost
        instance.index = Item.runtimeIndex
        
        return instance
    }
    
    func icon() -> String {
        return type.icon
    }
    
    func color() -> Color {
        return type.color
    }
    
    var isConsumable: Bool {
        switch type {
        case .drink, .food:
            return true
        default:
            return false
        }
    }
}

enum ItemType : String, CaseIterable, Codable {
    case weapon = "weapon"
    case armor = "armor"
    case clothing = "clothing"
    case drink = "drink"
    case food = "food"
    case artefact = "artefact"
    case picture = "picture"
    case kitchenStuff = "kitchen_stuff"
    case jewelery = "jewelery"
    case tools = "tools"
    case alchemy = "alchemy"
    case paper = "paper"
    case resource = "resource"
    
    var icon: String {
        switch self {
        case .weapon:
            return "figure.baseball"
        case .armor:
            return "shield"
        case .clothing:
            return "tshirt"
        case .drink:
            return "wineglass"
        case .food:
            return "fork.knife"
        case .artefact:
            return "sparkles"
        case .picture:
            return "photo"
        case .kitchenStuff:
            return "house.circle.fill"
        case .jewelery:
            return "diamond"
        case .tools:
            return "wrench"
        case .alchemy:
            return "flask"
        case .paper:
            return "books.vertical.fill"
        case .resource:
            return "cube.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .weapon:
            return .red
        case .armor:
            return .blue
        case .clothing:
            return .purple
        case .drink:
            return .orange
        case .food:
            return .green
        case .artefact:
            return .yellow
        case .picture:
            return .pink
        case .kitchenStuff:
            return .brown
        case .jewelery:
            return .teal
        case .tools:
            return .gray
        case .alchemy:
            return .indigo
        case .paper:
            return Theme.textColor
        case .resource:
            return .indigo
        }
    }
}
