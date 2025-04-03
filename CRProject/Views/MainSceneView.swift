import SwiftUI

struct MainSceneView: View {
    @ObservedObject var viewModel: MainSceneViewModel
    @StateObject private var npcManager = NPCInteractionManager.shared
    @State private var showingNavigation = false
    
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
                            Button(action: { showingNavigation = true }) {
                                HStack {
                                    Image(systemName: "moon.stars.fill")
                                        .foregroundColor(Theme.accentColor)
                                    Text(viewModel.currentScene?.name ?? "Unknown")
                                        .font(Theme.bodyFont)
                                    Spacer()
                                    Text("\(viewModel.childScenes.count + viewModel.siblingScenes.count + (viewModel.parentScene != nil ? 1 : 0)) locations")
                                        .font(Theme.captionFont)
                                        .foregroundColor(Theme.textColor.opacity(0.7))
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Theme.textColor.opacity(0.5))
                                }
                                .padding()
                                .background(Theme.secondaryColor)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            LocationInfoView(scene: viewModel.currentScene, viewModel: viewModel)
                        }
                        .padding()
                    }
                    .frame(maxHeight: .infinity)
                    
                    BottomWidgetView(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                        .background(Color.clear)
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
