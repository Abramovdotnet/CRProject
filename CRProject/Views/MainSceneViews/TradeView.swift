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
    
    // Temporary inventories
    @State private var tempPlayerItems: [Item] = []
    @State private var tempNPCItems: [Item] = []
    @State private var dealTotal: Int = 0
    
    // Sorting state
    @State private var playerSortType: ItemType? = nil
    @State private var npcSortType: ItemType? = nil
    
    // Store original inventories for deal calculation
    @State private var originalPlayerItems: [Item] = []
    @State private var originalNPCItems: [Item] = []
    
    @State private var isPlayerDragging = false
    @State private var isNPCDragging = false
    @State private var playerDragStart: CGPoint? = nil
    @State private var npcDragStart: CGPoint? = nil
    
    private var groupedPlayerItems: [ItemGroup] {
        let items = playerSortType == nil ? tempPlayerItems : tempPlayerItems.filter { $0.type == playerSortType }
        return Dictionary(grouping: items, by: { $0.id.description })
            .map { ItemGroup(items: $0.value) }
            .sorted { $0.name < $1.name }
    }
    
    private var groupedNPCItems: [ItemGroup] {
        let items = npcSortType == nil ? tempNPCItems : tempNPCItems.filter { $0.type == npcSortType }
        return Dictionary(grouping: items, by: { $0.id.description })
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
                    HStack(spacing: 20) {
                        // Player inventory
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
                            
                            VStack(spacing: 2) {
                                HStack(spacing: 10) {
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
                                                if !isPlayerDragging {
                                                    moveItemFromPlayerToNPC(group)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                .simultaneousGesture(
                                    DragGesture()
                                        .onChanged { _ in isPlayerDragging = true }
                                        .onEnded { _ in
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                isPlayerDragging = false
                                            }
                                        }
                                )
                            }
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity)
                        }
                        // NPC inventory
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
                            VStack(spacing: 2) {
                                HStack(spacing: 10) {
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
                                                if !isNPCDragging {
                                                    moveItemFromNPCToPlayer(group)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                .simultaneousGesture(
                                    DragGesture()
                                        .onChanged { _ in isNPCDragging = true }
                                        .onEnded { _ in
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                isNPCDragging = false
                                            }
                                        }
                                )
                            }
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    HStack {
                        Spacer()
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
                        .disabled(!couldMakeADeal())
                        Spacer()
                    }
                    .frame(width: 200)
                }
                .padding(.horizontal, 25)
                .padding(.top, 25)
                .padding(.bottom, 5)
                .onAppear {
                    tempPlayerItems = player.items
                    tempNPCItems = npc.items
                    originalPlayerItems = player.items
                    originalNPCItems = npc.items
                    updateDealTotal()
                }
                VStack(alignment: .leading) {
                    TopWidgetView(viewModel: mainViewModel)
                        .frame(height: 35)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .padding(.top, geometry.safeAreaInsets.top)
                        .foregroundColor(Theme.textColor)
                        .allowsHitTesting(false)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func moveItemFromPlayerToNPC(_ group: ItemGroup) {
        guard let firstItem = group.items.first else { return }
        if let index = tempPlayerItems.firstIndex(where: { $0.index == firstItem.index }) {
            let item = tempPlayerItems.remove(at: index)
            tempNPCItems.append(item)
            updateDealTotal()
        }
    }
    
    private func moveItemFromNPCToPlayer(_ group: ItemGroup) {
        guard let firstItem = group.items.first else { return }
        if let index = tempNPCItems.firstIndex(where: { $0.index == firstItem.index }) {
            let item = tempNPCItems.remove(at: index)
            tempPlayerItems.append(item)
            updateDealTotal()
        }
    }
    
    private func updateDealTotal() {
        // Items moved from player to NPC
        let playerToNPC = originalPlayerItems.filter { original in !tempPlayerItems.contains(where: { $0.index == original.index }) }
        let npcToPlayer = originalNPCItems.filter { original in !tempNPCItems.contains(where: { $0.index == original.index }) }
        let playerValue = playerToNPC.reduce(0) { $0 + $1.cost }
        let npcValue = npcToPlayer.reduce(0) { $0 + $1.cost }
        dealTotal = playerValue - npcValue
    }
    
    private func couldMakeADeal() -> Bool {
        if dealTotal > 0 {
            return npc.coins.value >= dealTotal
        } else {
            return player.coins.value >= abs(dealTotal)
        }
    }
    
    private func makeADeal() {
        player.items = tempPlayerItems
        npc.items = tempNPCItems
        // Update coins
        if dealTotal > 0 {
            npc.coins.value -= dealTotal
            player.coins.value += dealTotal
        } else {
            player.coins.value -= abs(dealTotal)
            npc.coins.value += abs(dealTotal)
        }
        npc.playerRelationship.increase(amount: 1)
        
        if abs(dealTotal) >= 500 && abs(dealTotal) < 1000 {
            StatisticsService.shared.increase500CoinsDeals()
        } else if abs(dealTotal) >= 1000 {
            StatisticsService.shared.increase1000CoinsDeals()
        }
        
        npc.isBeasyByPlayerAction = true
        
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
