//
//  ItemReader.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 22.04.2025.
//

import Foundation

class ItemReader {
    static let shared = ItemReader()
    private var items: [Item] = []
    
    private init() {
        loadItems()
    }
    
    private func loadItems() {
        guard let url = Bundle.main.url(forResource: "Items", withExtension: "json") else {
            print("Failed to find Items.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(ItemContainer.self, from: data)
            items = container.items
            
            var index = 0
            
            for item in items {
                item.index = index
                index += 1
            }
        } catch {
            print("Error loading items: \(error)")
        }
    }
    
    func getItems() -> [Item] {
        return items
    }
    
    func getItem(by id: Int) -> Item? {
        return items.first { $0.id == id }
    }
    
    func getItemByIndex(by index: Int) -> Item? {
        return items.first { $0.index == index }
    }
}

private struct ItemContainer: Codable {
    let items: [Item]
} 
