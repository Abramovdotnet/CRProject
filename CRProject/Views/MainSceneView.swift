import SwiftUI

struct MainSceneView: View {
    @ObservedObject var viewModel: MainSceneViewModel
    @StateObject private var npcManager = NPCInteractionManager.shared
    @StateObject private var gameStateService: GameStateService = DependencyManager.shared.resolve()
    @State private var showingNavigation = false
    @State private var compassScale: CGFloat = 1.0
    @State private var watchScale: CGFloat = 1.0
    @State private var spentTimeWatchScale: CGFloat = 1.0
    @State private var noneHideoutScale: CGFloat = 1.0
    @State private var shadowHideoutScale: CGFloat = 1.0
    @State private var showSmokeEffect = false
    @State private var showingVampireGaze = false
    
    init(viewModel: MainSceneViewModel) {
        self.viewModel = viewModel
    }
    
    // Reference to grid view for scrolling
    private var gridViewRef: NPCSGridView?
    
    private var isPlayerHidden: Bool {
        guard let player = gameStateService.getPlayer() else { return false }
        return player.hiddenAt != .none
    }
    
    // Computed property for red overlay opacity based on blood
    private var lowBloodRedOpacity: Double {
        let blood = viewModel.playerBloodPercentage
        if blood > 30 {
            return 0.0 // No effect above 30%
        } else if blood <= 10 {
            return 0.25 // Max effect capped at 60% opacity to avoid pure red
        } else {
            // Linear interpolation between 30% (opacity 0) and 10% (opacity 0.6)
            // Formula: maxOpacity * (startBlood - currentBlood) / (startBlood - endBlood)
            return 0.25 * (30.0 - Double(blood)) / 20.0
        }
    }
    
    var body: some View {
        if viewModel.isGameEnd {
            EndGameView()
        } else {
            GeometryReader { geometry in
                ZStack { // Apply colorMultiply to this ZStack
                    Image(uiImage: UIImage(named: "location\(viewModel.currentScene!.id.description)") ?? UIImage(named: "MainSceneBackground")!)
                        .resizable()
                        .ignoresSafeArea()
                        .saturation(isPlayerHidden ? 0 : 1)
                        .animation(.easeInOut(duration: 0.3), value: isPlayerHidden)
                        .overlay(
                            Group {
                                if isPlayerHidden {
                                    Rectangle()
                                        .fill(
                                            RadialGradient(
                                                gradient: Gradient(colors: [
                                                    Color.black.opacity(0.0),
                                                    Color.black.opacity(0.9)
                                                ]),
                                                center: .center,
                                                startRadius: 0,
                                                endRadius: UIScreen.main.bounds.width * 0.5
                                            )
                                        )
                                        .ignoresSafeArea()
                                        .animation(.easeInOut(duration: 0.3), value: isPlayerHidden)
                                }
                            }
                        )
                        .onAppear {
                            let imageName = UIImage(named: viewModel.currentScene!.sceneType.rawValue) != nil ? 
                            viewModel.currentScene!.sceneType.rawValue : "MainSceneBackground"
                            DebugLogService.shared.log("Loading background: \(imageName)", category: "Scene")
                        }
                    
                    if showSmokeEffect {
                        SmokeEffect(duration: 1.0)
                            .allowsHitTesting(false)
                    }
                    
                    DustEmitterView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                           .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 0) {
                        TopWidgetView(viewModel: viewModel)
                            .frame(maxWidth: .infinity)
                            .background(Color.clear)
                        
                        GeometryReader { geometry in
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    // Advance time
                                    MainSceneActionButton(
                                        icon: "hourglass.bottomhalf.fill",
                                        color: .blue,
                                        action: {
                                            viewModel.advanceTime()
                                        }
                                    )
                                    
                                    if !isPlayerHidden {
                                        // Show navigation
                                        MainSceneActionButton(
                                            icon: "map.fill",
                                            color: .green,
                                            action: {
                                                showingNavigation = true
                                            }
                                        )
                                    }
                                    
                                    // Hide
                                    if viewModel.getPlayer().hiddenAt == .none {
                                        ForEach(viewModel.getAvailableHideouts(), id: \.self) { hideout in
                                            MainSceneActionButton(
                                                icon: "eye.fill",
                                                color: .purple,
                                                action: {
                                                    showSmokeEffect = true
                                                    viewModel.getGameStateService().movePlayerThroughHideouts(to: hideout)
                                                    
                                                    // Reset smoke effect after animation
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                        showSmokeEffect = false
                                                    }
                                                }
                                            )
                                        }
                                    } else {
                                        MainSceneActionButton(
                                            icon: "eye.slash",
                                            color: .red,
                                            action: {
                                                viewModel.getGameStateService().movePlayerThroughHideouts(to: .none)
                                            }
                                        )
                                        .disabled(viewModel.currentScene?.isIndoor == false && !gameStateService.isNightTime)
                                    }
                                    Spacer()
                                }
                                .frame(width: 50)
                                Spacer()
                                NPCSGridView(
                                    npcs: viewModel.npcs,
                                    onAction: handleNPCAction
                                )
                                Spacer()
                                HStack(spacing: 10) {
                                    VStack {
                                        NPCInfoView(npc: npcManager.selectedNPC, onAction: handleNPCAction)
                                            .id(npcManager.selectedNPC?.id ?? 0)
                                        
                                        if npcManager.selectedNPC != nil {
                                            HorizontalNPCGridButton(npc: npcManager.selectedNPC!)
                                        }
                                   
                                        // Chat History
                                        ChatHistoryView(eventsBus: DependencyManager.shared.resolve())
                                            .frame(maxWidth: .infinity)
                                    }
                                    .frame(maxWidth: .infinity)
                
                                    // Actions
                                    VStack(alignment: .leading, spacing: 4) {
                                        if let selectedNPC = npcManager.selectedNPC {
                                            if selectedNPC.isAlive {
                                                // Start conversation
                                                MainSceneActionButton(
                                                    icon: "bubble.left.fill",
                                                    color: .white,
                                                    action: {
                                                        handleNPCAction(.startConversation(selectedNPC))
                                                    }
                                                )
                                            }
                                            
                                            if !selectedNPC.isUnknown {
                                                // Start intimidation
                                                MainSceneActionButton(
                                                    icon: "bolt.heart.fill",
                                                    color: .purple,
                                                    action: {
                                                        handleNPCAction(.startIntimidation(selectedNPC))
                                                    }
                                                )
                                                
                                                if !selectedNPC.isVampire {
                                                    // Feed
                                                    MainSceneActionButton(
                                                        icon: "drop.halffull",
                                                        color: Theme.bloodProgressColor,
                                                        action: {
                                                            handleNPCAction(.feed(selectedNPC))
                                                        }
                                                    )
                                                    
                                                    // Empty blood
                                                    MainSceneActionButton(
                                                        icon: "drop.fill",
                                                        color: Theme.bloodProgressColor,
                                                        action: {
                                                            handleNPCAction(.drain(selectedNPC))
                                                        }
                                                    )
                                                }
                                            }
                                        }
                                    }
                                    .frame(width: 60)
                                    .frame(maxHeight: .infinity, alignment: .top)
                                    .padding(.trailing, 10)
                                }
                                .frame(width: 420)
                            }
                            .padding(.horizontal, -10)
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                
                // Red Overlay for low blood
                Rectangle()
                    .fill(.red)
                    .opacity(lowBloodRedOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false) // Make overlay non-interactive
            }
            .foregroundColor(Theme.textColor)
            .animation(.easeInOut(duration: 0.5), value: lowBloodRedOpacity) // Keep animation on ZStack
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
                if let npc = npcManager.selectedNPC,
                   let player = viewModel.gameStateService.getPlayer() {
                    DialogueView(viewModel: DialogueViewModel(npc: npc, player: player), mainViewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingVampireGaze) {
                if let npc = npcManager.selectedNPC {
                    VampireGazeView(npc: npc, isPresented: $showingVampireGaze, mainViewModel: viewModel)
                }
            }
            .withDebugOverlay(viewModel: viewModel)
        }
    }
    
    private func handleNPCAction(_ action: NPCAction) {
        switch action {
        case .startConversation(let npc):
            // Don't call playerInteracted here - it will be called after dialogue completion
            npcManager.startConversation(with: npc)
        case .startIntimidation(let npc):
            // Don't call playerInteracted here - it will be called after gaze completion
            showVampireGaze(npc: npc)
        case .feed(let npc):
            viewModel.feedOnCharacter(npc)
            npcManager.playerInteracted(with: npc)
        case .drain(let npc):
            viewModel.emptyBloodFromCharacter(npc)
            npcManager.playerInteracted(with: npc)
        case .investigate(let npc):
            viewModel.investigateNPC(npc)
            npcManager.select(with: npc)
        }
    }
    
    private func showVampireGaze(npc: NPC) {
        npcManager.selectedNPC = npc
        showingVampireGaze = true
    }
    
    func setDefaultHideoutButtonScale(hideoutType: HidingCell) {
        switch hideoutType {
        case .shadow:
            shadowHideoutScale = 1
            break
        default:
            noneHideoutScale = 1
        }
    }
    
    func reduceHideoutButtonScale(hideoutType: HidingCell) {
        switch hideoutType {
        case .shadow:
            shadowHideoutScale = 0.9
            break
        default:
            noneHideoutScale = 0.9
        }
    }
    
    func getHideoutButtonScale(hideoutType: HidingCell) -> CGFloat {
        switch hideoutType {
        case .shadow:
            return shadowHideoutScale
        case .none:
            return noneHideoutScale
        }
    }
}

enum NPCAction {
    case startConversation(NPC)
    case startIntimidation(NPC)
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


struct MainSceneActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack {
            ZStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        scale = 0.9
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring()) {
                            scale = 1.0
                            action()
                            VibrationService.shared.lightTap()
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(color)
                                .blur(radius: 15)
                                .opacity(0.9)
                            
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            color.opacity(0.3),
                                            Color.black.opacity(0.8)
                                        ]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 25
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .foregroundColor(color)
                        }
                        .frame(width: 45, height: 45)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .scaleEffect(scale)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Circle())
                .shadow(color: .black, radius: 3, x: 0, y: 2)
            }
            .shadow(color: .black, radius: 3, x: 0, y: 2)
        }
    }
}
