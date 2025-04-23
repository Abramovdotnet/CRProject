//
//  TradeView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 22.04.2025.
//

import SwiftUI

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
                    // Top row: Player info, Deal total, NPC info
                    HStack(spacing: 5) {
                        // Player info
                        HorizontalPlayerWidget(player: player)
                            .frame(maxWidth: .infinity)
                        
                        // Deal total in the middle
                        VStack(spacing: 4) {
                            Text("Deal Total")
                                .font(Theme.smallFont)
                                .foregroundColor(Theme.textColor)
                            
                            Text("\(Int(dealTotal))")
                                .font(Theme.smallFont)
                                .foregroundColor(dealTotal >= 0 ? .green : .red)
                            Image(systemName: "cedisign")
                                .font(Theme.smallFont)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .frame(maxWidth: 100)
                        
                        // NPC info
                        HorizontalNPCWidget(npc: npc)
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Bottom row: Player items, Trade section, NPC items
                    HStack(spacing: 20) {
                        // Player's items
                        VStack(spacing: 2) {
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(player.items, id: \.index) { item in
                                        ItemRowView(
                                            item: item,
                                            isSelected: selectedPlayerItems.contains { $0.index == item.index },
                                            onTap: {
                                                if let index = selectedPlayerItems.firstIndex(where: { $0.index == item.index }) {
                                                    selectedPlayerItems.remove(at: index)
                                                } else {
                                                    selectedPlayerItems.append(item)
                                                }
                                                updateDealTotal()
                                            }
                                        )
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity)
                            
                            HStack(alignment: .top) {
                                Image(systemName: "cedisign")
                                    .font(Theme.smallFont)
                                    .foregroundColor(.green)
                                Text("\(player.coins.value)")
                                    .font(Theme.smallFont)
                                    .foregroundColor(.green)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 30)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                        }
                        
                        // Middle section with selected items and deal button
                        VStack(spacing: 2) {
                            ScrollView {
                                VStack(spacing: 8) {
                                    if !selectedPlayerItems.isEmpty {
                                        Text("Offering:")
                                            .font(Theme.smallFont)
                                            .foregroundColor(Theme.textColor)
                                        
                                        ForEach(selectedPlayerItems, id: \.index) { item in
                                            ItemRowView(
                                                item: item,
                                                isSelected: true,
                                                onTap: {
                                                    if let index = selectedPlayerItems.firstIndex(where: { $0.index == item.index }) {
                                                        selectedPlayerItems.remove(at: index)
                                                        updateDealTotal()
                                                    }
                                                }
                                            )
                                        }
                                    }
                                    
                                    if !selectedNPCItems.isEmpty {
                                        Text("Requesting:")
                                            .font(Theme.smallFont)
                                            .foregroundColor(Theme.textColor)
                                        
                                        ForEach(selectedNPCItems, id: \.id) { item in
                                            ItemRowView(
                                                item: item,
                                                isSelected: true,
                                                onTap: {
                                                    if let index = selectedNPCItems.firstIndex(where: { $0.index == item.index }) {
                                                        selectedNPCItems.remove(at: index)
                                                        updateDealTotal()
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .padding(.vertical, 4)
                            .frame(maxHeight: .infinity)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                            
                            // Deal button
                            Button(action: {
                                makeADeal()
                                dismiss()
                            }) {
                                Text("Make Deal")
                                    .font(Theme.smallFont)
                                    .foregroundColor(Theme.textColor)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.black.opacity(0.8))
                                    .cornerRadius(12)
                            }
                            .opacity(couldMakeADeal() ? 1.0 : 0.3)
                            .disabled(selectedPlayerItems.isEmpty && selectedNPCItems.isEmpty || !couldMakeADeal())
                        }
                        .frame(maxWidth: .infinity)
                        
                        // NPC's items
                        VStack(spacing: 2) {
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(npc.items, id: \.index) { item in
                                        ItemRowView(
                                            item: item,
                                            isSelected: selectedNPCItems.contains { $0.index == item.index },
                                            onTap: {
                                                if let index = selectedNPCItems.firstIndex(where: { $0.index == item.index }) {
                                                    selectedNPCItems.remove(at: index)
                                                } else {
                                                    selectedNPCItems.append(item)
                                                }
                                                updateDealTotal()
                                            }
                                        )
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity)
                            
                            HStack(alignment: .top) {
                                Spacer()
                                Image(systemName: "cedisign")
                                    .font(Theme.smallFont)
                                    .foregroundColor(.green)
                                Text("\(npc.coins.value)")
                                    .font(Theme.smallFont)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 30)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                        }
                    }
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
    
    private func updateDealTotal() {
        let playerItemsTotal = selectedPlayerItems.reduce(0) { $0 + $1.cost }
        let npcItemsTotal = selectedNPCItems.reduce(0) { $0 + $1.cost }
        dealTotal = playerItemsTotal - npcItemsTotal
    }
    
    private func couldMakeADeal() -> Bool {
        if selectedPlayerItems.isEmpty && selectedNPCItems.isEmpty {
            return false
        }
        
        let playerItemsTotal = selectedPlayerItems.reduce(0) { $0 + $1.cost }
        let npcItemsTotal = selectedNPCItems.reduce(0) { $0 + $1.cost }
        
        if dealTotal < 0 {
            return player.coins.value >= dealTotal
        }

        else if dealTotal > 0 {
            return npc.coins.value >= abs(dealTotal)
        }
    
        return true
    }
    
    func makeADeal() {
        for item in selectedPlayerItems {
            CoinsManagementService.shared.moveCoins(from: npc, to: player, amount: item.cost)
            ItemsManagementService.shared.moveItem(item: item, from: player, to: npc)
        }
        
        for item in selectedNPCItems {
            CoinsManagementService.shared.moveCoins(from: player, to: npc, amount: item.cost)
            ItemsManagementService.shared.moveItem(item: item, from: npc, to: player)
        }
        
        selectedPlayerItems.removeAll()
        selectedNPCItems.removeAll()
        
        npc.playerRelationship.increase(amount: 2)
        
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
                    
                    Text("\(Int(item.cost))")
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
