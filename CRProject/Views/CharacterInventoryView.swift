//
//  CharacterInventoryView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 22.04.2025.
//

import SwiftUI

// Remove the duplicate ItemGroup structure and use extension instead
extension ItemGroup {
    var isConsumable: Bool { items[0].isConsumable }
}

struct ItemRowView: View {
    let item: Item
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                HStack {
                    Image(systemName: item.icon())
                        .foregroundColor(item.color())
                        .font(Theme.smallFont)
                    
                    Text(item.name)
                        .font(Theme.smallFont)
                        .foregroundColor(Theme.textColor)
                    
                    Spacer()
                    
                    Text("\(item.cost)")
                        .font(Theme.smallFont)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Theme.awarenessProgressColor.opacity(0.3) : Color.clear)
                )
            }
            .padding(.horizontal, 6)
        }
    }
}

struct CharacterInventoryView: View {
    var character: any Character
    let scene: Scene
    let mainViewModel: MainSceneViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCharacterItems: [Item] = []
    @State private var selectedItemType: ItemType? = nil
    @State private var isScrolling = false
    @State private var refreshID = UUID() // Add a refresh ID to force view updates
    
    @StateObject private var npcManager = NPCInteractionManager.shared
    
    // Grouped items for display
    private var groupedItems: [ItemGroup] {
        let filteredItems = selectedItemType == nil ? character.items : character.items.filter { $0.type == selectedItemType }
        return Dictionary(grouping: filteredItems, by: { $0.id.description })
            .map { ItemGroup(items: $0.value) }
            .sorted { $0.name < $1.name }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: UIImage(named: "location\(scene.id.description)") ?? UIImage(named: "MainSceneBackground")!)
                    .resizable()
                    .ignoresSafeArea()
                
                DustEmitterView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                       .edgesIgnoringSafeArea(.all)
                
                    // Bottom row: Player items, Trade section, NPC items
                HStack(alignment: .top, spacing: 20) {
                    VStack {
                        // Character info
                        if let player = character as? Player {
                            PlayerWidget(player: player)
                        }
                        
                        if let npcCharacter = character as? NPC {
                            // NPC info
                            HorizontalNPCWidget(npc: npcCharacter)
                                .frame(maxWidth: .infinity)
                        }
                        Spacer()
                    }
                    // Player's items
                    VStack(spacing: 2) {
                        // Item type filters
                        HStack(spacing: 10) {
                            Button(action: { selectedItemType = nil }) {
                                Image(systemName: "tag")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(selectedItemType == nil ? .yellow : Theme.textColor)
                            }
                            ForEach(ItemType.allCases, id: \.self) { type in
                                Button(action: { selectedItemType = type }) {
                                    Image(systemName: type.icon)
                                        .font(Theme.bodyFont)
                                        .foregroundColor(selectedItemType == type ? .yellow : Theme.textColor)
                                }
                            }
                        }
                        .frame(height: 30)
                        .padding(.horizontal, 8)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(groupedItems) { group in
                                    HStack {
                                        HStack {
                                            Image(systemName: group.icon)
                                                .foregroundColor(group.color)
                                                .font(Theme.bodyFont)
                                            Text(group.count > 1 ? "\(group.name) (\(group.count))" : group.name)
                                                .font(Theme.bodyFont)
                                                .foregroundColor(Theme.textColor)
                                            Spacer()
                                            Text("\(group.cost)")
                                                .font(Theme.bodyFont)
                                                .foregroundColor(.green)
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 8)
                                    }
                                    .padding(.horizontal, 6)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if !isScrolling {
                                            handleItemTap(group)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .id(refreshID) // Add an ID that changes to force refresh
                        }
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { _ in isScrolling = true }
                                .onEnded { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isScrolling = false
                                    }
                                }
                        )
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity)
                        
                        HStack(alignment: .top) {
                            Image(systemName: "cedisign")
                                .font(Theme.bodyFont)
                                .foregroundColor(.green)
                            Text("\(character.coins.value)")
                                .font(Theme.bodyFont)
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 30)
                .padding(.bottom, 5)
                
                VStack(alignment: .leading) {
                    TopWidgetView(viewModel: mainViewModel)
                        .frame(maxWidth: .infinity)
                        .padding(.top, geometry.safeAreaInsets.top)
                        .foregroundColor(Theme.textColor)
                    
                Spacer()
                }
            }
        }
    }
    
    private func handleItemTap(_ group: ItemGroup) {
        // Get first item in the group
        guard let item = group.items.first else { return }
        
        // Select the item
        selectItem(item.index)
        
        // If item is consumable, call the consume function
        if item.isConsumable {
            consumeItem(item)
        }
    }
    
    private func consumeItem(_ item: Item) {
        guard let player = character as? Player else { return }
        FeedingService.shared.consumeFood(vampire: player, food: item)
        
        // Remove the consumed item from player's inventory
        if let index = player.items.firstIndex(where: { $0.index == item.index }) {
            player.items.remove(at: index)
            
            // Force UI refresh
            refreshID = UUID()
            
            // Update selected items if needed
            if let selectedIndex = selectedCharacterItems.firstIndex(where: { $0.index == item.index }) {
                selectedCharacterItems.remove(at: selectedIndex)
            }
        }
    }
    
    private func selectItem(_ index: Int) {
        if let item = character.items.first(where: { $0.index == index }) {
            if let existingIndex = selectedCharacterItems.firstIndex(where: { $0.index == index }) {
                selectedCharacterItems.remove(at: existingIndex)
            } else {
                selectedCharacterItems.append(item)
            }
            mainViewModel.selectedItemIndex = index
        }
    }
}
