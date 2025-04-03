import SwiftUI

import SwiftUI

struct MainSceneView: View {
    @ObservedObject var viewModel: MainSceneViewModel
    @StateObject private var npcManager = NPCInteractionManager.shared
    @State private var showingNavigation = false
    @State private var compassScale: CGFloat = 1.0
    
    var body: some View {
        if viewModel.isGameEnd {
            EndGameView()
        } else {
            ZStack {
                Image("MainSceneBackground")
                    .resizable()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    TopWidgetView(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                        .background(Color.clear)
                    
                    HStack(alignment: .top, spacing: 20) {
                        CircularNPCView(
                            npcs: viewModel.npcs,
                            onAction: handleNPCAction
                        )
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Button(action: {
                                // Animation sequence
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    compassScale = 0.9
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.spring()) {
                                        compassScale = 1.0
                                        showingNavigation = true
                                    }
                                }
                            }) {
                                VStack {
                                    Image("compassAlt")
                                        .resizable()
                                        .frame(width: 100, height: 100) // Fixed size
                                        .scaleEffect(compassScale)
                                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                                    
                                    Text(viewModel.currentScene?.name ?? "Unknown")
                                        .font(Theme.bodyFont)
                                        .padding(.top, 4)
                                    
                                    LocationInfoView(scene: viewModel.currentScene, viewModel: viewModel)
                                        .frame(width: 100)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding()
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .foregroundColor(Theme.textColor)
            .sheet(isPresented: $showingNavigation) {
                NavigationDetailView(viewModel: viewModel)
            }
            .sheet(isPresented: $npcManager.isShowingDialogue) {
                if let npc = npcManager.currentNPC,
                   let player = viewModel.gameStateService.getPlayer() {
                    DialogueView(viewModel: DialogueViewModel(npc: npc, player: player))
                }
            }
        }
    }
    
    private func handleNPCAction(_ action: NPCAction) {
        switch action {
        case .startConversation(let npc):
            npcManager.startConversation(with: npc)
        case .feed(let npc):
            viewModel.feedOnCharacter(npc)
        case .drain(let npc):
            viewModel.emptyBloodFromCharacter(npc)
        case .investigate(let npc):
            viewModel.investigateNPC(npc)
        }
    }
}

enum NPCAction {
    case startConversation(NPC)
    case feed(NPC)
    case drain(NPC)
    case investigate(NPC)
}

// MARK: - Bottom Widget
private struct BottomWidgetView: View {
    @ObservedObject var viewModel: MainSceneViewModel
    
    var body: some View {
        HStack {
            Text("Debug:")
                .font(Theme.bodyFont)
            
            Spacer()
            
            Text("Blood: \(Int(viewModel.playerBloodPercentage))%")
                .font(Theme.bodyFont)
            
        }
        .padding(.top, 5)
        .padding(.bottom, 5)
    }
}

#Preview {
    MainSceneView(viewModel: MainSceneViewModel())
} 
