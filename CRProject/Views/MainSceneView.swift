import SwiftUI

struct MainSceneView: View {
    @ObservedObject var viewModel: MainSceneViewModel
    @StateObject private var npcManager = NPCInteractionManager.shared
    @State private var showingNavigation = false
    @State private var compassScale: CGFloat = 1.0
    @State private var watchScale: CGFloat = 1.0
    
    var body: some View {
        if viewModel.isGameEnd {
            EndGameView()
        } else {
            ZStack {
                Image(uiImage: UIImage(named: viewModel.currentScene!.sceneType.rawValue) ?? UIImage(named: "MainSceneBackground")!)
                    .resizable()
                    .ignoresSafeArea()
                    .onAppear {
                        let imageName = UIImage(named: viewModel.currentScene!.sceneType.rawValue) != nil ? 
                        viewModel.currentScene!.sceneType.rawValue : "MainSceneBackground"
                        DebugLogService.shared.log("Loading background: \(imageName)", category: "Scene")
                    }
                
                VStack(spacing: 0) {
                    TopWidgetView(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                        .background(Color.clear)
                    
                    GeometryReader { geometry in
                        HStack(spacing: 20) {
                            VStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: viewModel.currentScene?.sceneType.iconName ?? "")
                                            .font(Theme.smallFont) // Slightly smaller for better fit
                                            .foregroundColor(Theme.textColor)
                                        Text(viewModel.currentScene?.name ?? "Unknown")
                                            .font(Theme.captionFont)
                                        Spacer()
                                        
                                        LocationInfoView(scene: viewModel.currentScene, viewModel: viewModel)
                                    }
                                    HStack {
                                        if let sceneType = viewModel.currentScene?.sceneType.rawValue {
                                            Text("Type: \(sceneType.capitalized)")
                                                .foregroundColor(Theme.textColor)
                                                .font(Theme.smallFont)
                                        }
                                        if let isIndoor = viewModel.currentScene?.isIndoor {
                                            Text("Is indoor: \(isIndoor ? "Yes" : "No")")
                                                .font(Theme.smallFont)
                                                .foregroundColor(Theme.textColor)
                                        }
                                        Text("Characters: \(viewModel.npcs.count)")
                                            .foregroundColor(Theme.textColor)
                                            .font(Theme.smallFont)
                                    }
                                }.padding(.top, 10)
                                
                                NPCSGridView(
                                    npcs: viewModel.npcs,
                                    onAction: handleNPCAction
                                )
                                .frame(width: geometry.size.width * 0.5)
                            }
                            
                            // Right section: Location Info and Chat (60%)
                            VStack(spacing: 20) {
                                // Location Info
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(alignment: .top, spacing: 10) {
                                        
                                        VStack {
                                            ZStack {
                                                Text("Spent time")
                                                    .font(Theme.captionFont)
                                                    .foregroundColor(Theme.textColor)
                                                Button(action: {
                                                    withAnimation(.easeInOut(duration: 0.1)) {
                                                        watchScale = 0.9
                                                    }
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                        withAnimation(.spring()) {
                                                            watchScale = 1.0
                                                            viewModel.advanceTime()
                                                        }
                                                    }
                                                }) {
                                                    ZStack {
                                                        // 1. Frame (bottom layer)
                                                        Image("iconFrame")
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .frame(width: 60 * 1.1, height: 60 * 1.1)
                                                        
                                                        // 2. Background circle (middle layer)
                                                        Circle()
                                                            .fill(Color.black.opacity(0.7))
                                                            .frame(width: 60 * 0.85, height: 60 * 0.85)
                                                            .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                                                            .overlay(
                                                                Circle()
                                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                            )
                                                    
                                                        Image("clockWatch")
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .frame(width: 50 * 0.8, height: 50 * 0.8)
                                                    }
                                                    .scaleEffect(watchScale)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .contentShape(Circle())
                                                .shadow(color: .black, radius: 3, x: 0, y: 2)
                                            }
                                            .shadow(color: .black, radius: 3, x: 0, y: 2)
                                        }
                                        
                                        VStack {
                                            ZStack {
                                                Text("Spent time")
                                                    .font(Theme.captionFont)
                                                    .foregroundColor(Theme.textColor)
                                                Button(action: {
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
                                                    ZStack {
                                                        // 1. Frame (bottom layer)
                                                        Image("iconFrame")
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .frame(width: 60 * 1.1, height: 60 * 1.1)
                                                        
                                                        // 2. Background circle (middle layer)
                                                        Circle()
                                                            .fill(Color.black.opacity(0.7))
                                                            .frame(width: 60 * 0.85, height: 60 * 0.85)
                                                            .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                                                            .overlay(
                                                                Circle()
                                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                            )
                                                        
                                                        // 3. Compass icon (top layer)
                                                        Image("compassAlt")
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .frame(width: 50 * 0.8, height: 50 * 0.8)
                                                    }
                                                    .scaleEffect(compassScale)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .contentShape(Circle())
                                                .shadow(color: .black, radius: 3, x: 0, y: 2)
                                            }
                                            .shadow(color: .black, radius: 3, x: 0, y: 2)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                
                                VStack {
                                    // Chat History
                                    ChatHistoryView(eventsBus: DependencyManager.shared.resolve())
                                        .frame(maxWidth: .infinity)
                                        .frame(maxHeight: .infinity)
                                    
                                    if npcManager.currentNPC != nil {
                                        SelectedNPCView(npc: npcManager.currentNPC!, onAction: handleNPCAction)
                                            .id(npcManager.currentNPC!.id)
                                    }
                                }
                                .padding(.bottom, 15)
                                
                            }
                            .frame(width: geometry.size.width * 0.5)
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .padding(.horizontal)
                }
            }
            .foregroundColor(Theme.textColor)
            .sheet(isPresented: $showingNavigation) {
                GeometryReader { geometry in
                    NavigationWebView(
                        viewModel: viewModel,
                        offset: .constant(.zero), // Managed externally if needed
                        scale: .constant(1.0),    // Managed externally if needed
                        geometry: geometry,
                        onLocationSelected: { location in
                            if viewModel.isLocationAccessible(location) {
                                viewModel.navigateToLocation(location)
                            }
                        }
                    )
                    .background(Color.black.edgesIgnoringSafeArea(.all))
                }
            }
            .sheet(isPresented: $npcManager.isShowingDialogue) {
                if let npc = npcManager.currentNPC,
                   let player = viewModel.gameStateService.getPlayer() {
                    DialogueView(viewModel: DialogueViewModel(npc: npc, player: player))
                }
            }
            .withDebugOverlay(viewModel: viewModel)
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
