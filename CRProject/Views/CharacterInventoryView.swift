//
//  TradeView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 22.04.2025.
//

import SwiftUI

struct CharacterInventoryView: View {
    var character: any Character
    let scene: Scene
    let mainViewModel: MainSceneViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCharacterItems: [Item] = []
    
    @StateObject private var npcManager = NPCInteractionManager.shared
    
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
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(character.items, id: \.id) { item in
                                    ItemRowView(
                                        item: item,
                                        isSelected: selectedCharacterItems.contains { $0.index == item.index },
                                        onTap: {
                                            if let index = selectedCharacterItems.firstIndex(where: { $0.index == item.index }) {
                                                selectedCharacterItems.remove(at: index)
                                            } else {
                                                selectedCharacterItems.append(item)
                                            }
                                            mainViewModel.selectedItemIndex = item.index
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
                            Text("\(character.coins.value)")
                                .font(Theme.smallFont)
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
