//
//  TradeView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 22.04.2025.
//

import SwiftUI

// Add this structure after the imports and before TradeView
struct ItemGroup: Identifiable {
    var items: [Item]
    var id: String { items[0].id.description }
    
    var name: String { items[0].name }
    var count: Int { items.count }
    var cost: Int { items[0].cost }
    var icon: String { items[0].icon() }
    var color: Color { items[0].color() }
}

struct TradeView: View {
    @ObservedObject var player: Player
    @ObservedObject var npc: NPC
    let scene: Scene
    let mainViewModel: MainSceneViewModel
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var npcManager = NPCInteractionManager.shared
    
    @State private var selectedPlayerItems: [Item] = []
    @State private var selectedNPCItems: [Item] = []
    @State private var dealTotal: Int = 0
    
    // Sorting state
    @State private var playerSortType: ItemType? = nil
    @State private var npcSortType: ItemType? = nil
    
    private var groupedPlayerItems: [ItemGroup] {
        let items = playerSortType == nil ? player.items : player.items.filter { $0.type == playerSortType }
        return Dictionary(grouping: items, by: { $0.id.description })
            .map { ItemGroup(items: $0.value) }
            .sorted { $0.name < $1.name }
    }
    
    private var groupedNPCItems: [ItemGroup] {
        let items = npcSortType == nil ? npc.items : npc.items.filter { $0.type == npcSortType }
        return Dictionary(grouping: items, by: { $0.id.description })
            .map { ItemGroup(items: $0.value) }
            .sorted { $0.name < $1.name }
    }
    
    private var selectedPlayerGroups: [ItemGroup] {
        Dictionary(grouping: selectedPlayerItems, by: { $0.id.description })
            .map { ItemGroup(items: $0.value) }
            .sorted { $0.name < $1.name }
    }
    
    private var selectedNPCGroups: [ItemGroup] {
        Dictionary(grouping: selectedNPCItems, by: { $0.id.description })
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
                
                VStack(spacing: 20) {
                    // Bottom row: Player items, Trade section, NPC items
                    HStack(spacing: 20) {
                        VStack {
                            HStack(alignment: .top) {
                                Image(systemName: "cedisign")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(.green)
                                Text("\(player.coins.value)")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(.green)
                                Spacer()
                                Image(systemName: player.sex == .female ? "figure.stand.dress" : "figure.wave")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(player.isVampire ? Theme.primaryColor : Theme.textColor)
                                Text(player.name)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textColor)
                                Image(systemName: player.profession.icon)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(player.profession.color)
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 30)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                            // Player's items
                            VStack(spacing: 2) {
                                // Sorting buttons for player
                                HStack(spacing: 3) {
                                    Button(action: { playerSortType = nil }) {
                                        Image(systemName: "tag")
                                            .font(Theme.bodyFont)
                                            .foregroundColor(playerSortType == nil ? .yellow : Theme.textColor)
                                    }
                                    ForEach(ItemType.allCases, id: \.self) { type in
                                        Button(action: { playerSortType = type }) {
                                            Image(systemName: type.icon)
                                                .font(Theme.bodyFont)
                                                .foregroundColor(playerSortType == type ? .yellow : Theme.textColor)
                                        }
                                    }
                                }
                                .frame(height: 30)
                                .padding(.horizontal, 8)
                               
                                ScrollView {
                                    VStack(spacing: 8) {
                                        ForEach(groupedPlayerItems) { group in
                                            Button(action: {
                                                handlePlayerItemSelection(group)
                                            }) {
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
                                            }
                                            .padding(.horizontal, 6)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Middle section with selected items and deal button
                        VStack(spacing: 2) {
                            ScrollView {
                                VStack(spacing: 8) {
                                    if !selectedPlayerItems.isEmpty {
                                        Text("Offering:")
                                            .font(Theme.bodyFont)
                                            .foregroundColor(Theme.textColor)
                                        
                                        ForEach(selectedPlayerGroups) { group in
                                            Button(action: {
                                                handleSelectedPlayerItemSelection(group)
                                            }) {
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
                                            }
                                        }
                                    }
                                    
                                    if !selectedNPCItems.isEmpty {
                                        Text("Requesting:")
                                            .font(Theme.bodyFont)
                                            .foregroundColor(Theme.textColor)
                                        
                                        ForEach(selectedNPCGroups) { group in
                                            Button(action: {
                                                handleSelectedNPCItemSelection(group)
                                            }) {
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
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .padding(.vertical, 2)
                            .frame(maxHeight: .infinity)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                        }
                        .frame(maxWidth: 170)
                        
                        VStack {
                            HStack(alignment: .top) {
                                Image(systemName: npc.sex == .female ? "figure.stand.dress" : "figure.wave")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textColor)
                                Text(npc.name)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textColor)
                                Image(systemName: npc.profession.icon)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(player.profession.color)
                                Spacer()
                                Image(systemName: "cedisign")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(.green)
                                Text("\(npc.coins.value)")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 30)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                            // NPC's items
                            VStack(spacing: 2) {
                                // Sorting buttons for NPC
                                HStack(spacing: 3) {
                                    Button(action: { npcSortType = nil }) {
                                        Image(systemName: "tag")
                                            .font(Theme.bodyFont)
                                            .foregroundColor(npcSortType == nil ? .yellow : Theme.textColor)
                                    }
                                    ForEach(ItemType.allCases, id: \.self) { type in
                                        Button(action: { npcSortType = type }) {
                                            Image(systemName: type.icon)
                                                .font(Theme.bodyFont)
                                                .foregroundColor(npcSortType == type ? .yellow : Theme.textColor)
                                        }
                                    }
                                }
                                .frame(height: 30)
                                .padding(.horizontal, 8)
                                
                                ScrollView {
                                    VStack(spacing: 8) {
                                        ForEach(groupedNPCItems) { group in
                                            Button(action: {
                                                handleNPCItemSelection(group)
                                            }) {
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
                                            }
                                            .padding(.horizontal, 6)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    
                    HStack {
                        Spacer()
                        // Deal button
                        Button(action: {
                            makeADeal()
                            dismiss()
                        }) {
                            HStack {
                                Text("Make Deal")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textColor)
                                Text("\(Int(dealTotal))")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(dealTotal >= 0 ? .green : .red)
                                Image(systemName: "cedisign")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                        }
                        .opacity(couldMakeADeal() ? 1.0 : 0.3)
                        .disabled(selectedPlayerItems.isEmpty && selectedNPCItems.isEmpty || !couldMakeADeal())
                        Spacer()
                    }
                    .frame(width: 200)
                }
                .padding(.horizontal, 25)
                .padding(.top, 25)
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
    
    private func handlePlayerItemSelection(_ group: ItemGroup) {
        guard let firstItem = group.items.first else { return }
        
        // When clicking in player's inventory, always move to selected items
        if let itemToMove = player.items.first(where: { $0.id == firstItem.id }) {
            if let index = player.items.firstIndex(where: { $0.index == itemToMove.index }) {
                let item = player.items.remove(at: index)
                selectedPlayerItems.append(item)
                updateDealTotal()
            }
        }
    }
    
    private func handleSelectedPlayerItemSelection(_ group: ItemGroup) {
        guard let firstItem = group.items.first else { return }
        
        // When clicking in selected items, always move back to player's inventory
        if let itemToMove = selectedPlayerItems.first(where: { $0.id == firstItem.id }) {
            if let index = selectedPlayerItems.firstIndex(where: { $0.index == itemToMove.index }) {
                let item = selectedPlayerItems.remove(at: index)
                player.items.append(item)
                updateDealTotal()
            }
        }
    }
    
    private func handleNPCItemSelection(_ group: ItemGroup) {
        guard let firstItem = group.items.first else { return }
        
        // When clicking in NPC's inventory, always move to selected items
        if let itemToMove = npc.items.first(where: { $0.id == firstItem.id }) {
            if let index = npc.items.firstIndex(where: { $0.index == itemToMove.index }) {
                let item = npc.items.remove(at: index)
                selectedNPCItems.append(item)
                updateDealTotal()
            }
        }
    }
    
    private func handleSelectedNPCItemSelection(_ group: ItemGroup) {
        guard let firstItem = group.items.first else { return }
        
        // When clicking in selected items, always move back to NPC's inventory
        if let itemToMove = selectedNPCItems.first(where: { $0.id == firstItem.id }) {
            if let index = selectedNPCItems.firstIndex(where: { $0.index == itemToMove.index }) {
                let item = selectedNPCItems.remove(at: index)
                npc.items.append(item)
                updateDealTotal()
            }
        }
    }
    
    private func updateDealTotal() {
        let playerItemsTotal = selectedPlayerItems.reduce(0) { $0 + $1.cost }
        let npcItemsTotal = selectedNPCItems.reduce(0) { $0 + $1.cost }
        dealTotal = npcItemsTotal - playerItemsTotal
    }
    
    private func couldMakeADeal() -> Bool {
        if dealTotal > 0 {
            return player.coins.value >= dealTotal
        } else {
            return npc.coins.value >= abs(dealTotal)
        }
    }
    
    private func makeADeal() {
        // Add selected NPC items to player
        player.items.append(contentsOf: selectedNPCItems)
        
        // Add selected player items to NPC
        npc.items.append(contentsOf: selectedPlayerItems)
        
        // Update coins
        if dealTotal > 0 {
            player.coins.value -= dealTotal
            npc.coins.value += dealTotal
        } else {
            npc.coins.value -= abs(dealTotal)
            player.coins.value += abs(dealTotal)
        }
        
        // Clear selections
        selectedPlayerItems.removeAll()
        selectedNPCItems.removeAll()
        dealTotal = 0
        
        npc.playerRelationship.increase(amount: 2)
        StatisticsService.shared.increaseBartersCompleted()
        
        npcManager.playerInteracted(with: npc)
        
        GameEventsBusService.shared.addMessageWithIcon(
            type: .common,
            location: GameStateService.shared.currentScene?.name ?? "Unknown",
            player: player,
            secondaryNPC: npc,
            interactionType: NPCInteraction.trade,
            hasSuccess: false,
            isSuccess: nil
        )
        
        GameTimeService.shared.advanceTime()
    }
} 
