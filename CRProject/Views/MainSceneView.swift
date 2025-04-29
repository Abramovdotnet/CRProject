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
    @State private var showingTrade = false
    @State private var showingInventory = false
    @State private var showingSmithing = false
    @State private var showingAbilities = false
    
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
                                        color: Theme.textColor,
                                        action: {
                                            viewModel.advanceTime()
                                        }
                                    )
                                    
                                    if viewModel.currentScene?.sceneType == .blacksmith {
                                        MainSceneActionButton(
                                            icon: "hammer.fill",
                                            color: Theme.textColor,
                                            action: {
                                                showingSmithing = true
                                            }
                                        )
                                    }
                                    
                                    if !isPlayerHidden {
                                        // Show navigation
                                        MainSceneActionButton(
                                            icon: "map.fill",
                                            color: Theme.bloodProgressColor,
                                            action: {
                                                showingNavigation = true
                                            }
                                        )
                                    }
                                    
                                    // Hide
                                    if let player = viewModel.getPlayer(), player.hiddenAt == .none && AbilitiesSystem.shared.hasInvisibility {
                                        ForEach(viewModel.getAvailableHideouts(), id: \.self) { hideout in
                                            MainSceneActionButton(
                                                icon: "eye.fill",
                                                color: Theme.bloodProgressColor,
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
                                        if AbilitiesSystem.shared.hasInvisibility {
                                            MainSceneActionButton(
                                                icon: "eye.slash",
                                                color: .red,
                                                action: {
                                                    viewModel.getGameStateService().movePlayerThroughHideouts(to: .none)
                                                }
                                            )
                                            .disabled(viewModel.currentScene?.isIndoor == false && !gameStateService.isNightTime)
                                            
                                            if AbilitiesSystem.shared.hasWhisper {
                                                MainSceneActionButton(
                                                    icon: Ability.whisper.icon,
                                                    color: Ability.whisper.color,
                                                    action: {
                                                        viewModel.getGameStateService().whisperToRandomNpc()
                                                    }
                                                )
                                                .disabled(viewModel.currentScene?.isIndoor == false && !gameStateService.isNightTime)
                                            }
                                        }
                                    }
                                    
                                    MainSceneActionButton(
                                        icon: "duffle.bag.fill",
                                        color: Theme.bloodProgressColor,
                                        action: {
                                            showingInventory = true
                                        }
                                    )
                                    
                                    MainSceneActionButton(
                                        icon: "moon.stars.circle.fill",
                                        color: Theme.bloodProgressColor,
                                        action: {
                                            showingAbilities = true
                                        }
                                    )
                                    
                                    Spacer()
                                }
                                .frame(width: 15)
                                Spacer()
                                NPCSGridView(
                                    npcs: viewModel.npcs,
                                    onAction: viewModel.handleNPCAction
                                )
                                Spacer()
                                HStack(spacing: 10) {
                                    VStack {
                                        DesiresView(npc: npcManager.selectedNPC, onAction: viewModel.handleNPCAction)
                                            .id(npcManager.selectedNPC?.id ?? 0)
                                        
                                        if npcManager.selectedNPC != nil {
                                            HorizontalNPCWidget(npc: npcManager.selectedNPC!)
                                        }
                                   
                                        // Chat History
                                        ChatHistoryView(eventsBus: DependencyManager.shared.resolve())
                                            .frame(maxWidth: .infinity)
                                    }
                                    .frame(maxWidth: .infinity)
                
                                    // Actions
                                    VStack(alignment: .leading, spacing: 4) {
                                        if let selectedNPC = npcManager.selectedNPC {
                                            if !selectedNPC.isUnknown && selectedNPC.isAlive {
                                                if selectedNPC.currentActivity != .sleep && selectedNPC.currentActivity != .fleeing && selectedNPC.currentActivity != .bathe {
                                                    // Start conversation
                                                    MainSceneActionButton(
                                                        icon: "bubble.left.fill",
                                                        color: Theme.textColor,
                                                        action: {
                                                            viewModel.handleNPCAction(.startConversation(selectedNPC))
                                                        }
                                                    )
                                                    
                                                    // Trade
                                                    MainSceneActionButton(
                                                        icon: "cart.fill",
                                                        color: Theme.textColor,
                                                        action: {
                                                            showingTrade = true
                                                        }
                                                    )
                                                }
                                                
                                                // Start intimidation
                                                MainSceneActionButton(
                                                    icon: "bolt.heart.fill",
                                                    color: Theme.bloodProgressColor,
                                                    action: {
                                                        viewModel.handleNPCAction(.startIntimidation(selectedNPC))
                                                    }
                                                )
                                                
                                                if !selectedNPC.isVampire {
                                                    // Feed
                                                    MainSceneActionButton(
                                                        icon: "drop.halffull",
                                                        color: Theme.bloodProgressColor,
                                                        action: {
                                                            viewModel.handleNPCAction(.feed(selectedNPC))
                                                        }
                                                    )
                                                    
                                                    // Empty blood
                                                    MainSceneActionButton(
                                                        icon: "drop.fill",
                                                        color: Theme.bloodProgressColor,
                                                        action: {
                                                            viewModel.handleNPCAction(.drain(selectedNPC))
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
                                .frame(width: 460)
                            }
                            .frame(maxHeight: .infinity)
                        }
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
                        offset: .constant(.zero),
                        scale: .constant(1.0),
                        geometry: geometry,
                        onLocationSelected: { location in
                            if viewModel.isLocationAccessible(location) {
                                viewModel.navigateToLocation(location)
                            }
                        }
                    )
                    .background(Color.black.edgesIgnoringSafeArea(.all))
                    .overlay(PopUpOverlayView().environmentObject(PopUpState.shared))
                }
            }
            .sheet(isPresented: $npcManager.isShowingDialogue, onDismiss: { viewModel.activeDialogueViewModel = nil }) {
                if let dialogueViewModel = viewModel.activeDialogueViewModel {
                    DialogueView(viewModel: dialogueViewModel, mainViewModel: viewModel)
                        .overlay(PopUpOverlayView().environmentObject(PopUpState.shared))
                } else {
                    Text("Loading Dialogue...")
                        .overlay(PopUpOverlayView().environmentObject(PopUpState.shared))
                }
            }
            .sheet(isPresented: $viewModel.isShowingVampireGazeView) {
                if let npc = npcManager.selectedNPC {
                    VampireGazeView(npc: npc, isPresented: $viewModel.isShowingVampireGazeView, mainViewModel: viewModel)
                        .overlay(PopUpOverlayView().environmentObject(PopUpState.shared))
                }
            }
            .sheet(isPresented: $showingTrade) {
                if let npc = npcManager.selectedNPC {
                    TradeView(player: gameStateService.player!, npc: npc, scene: GameStateService.shared.currentScene!, mainViewModel: viewModel)
                        .overlay(PopUpOverlayView().environmentObject(PopUpState.shared))
                }
            }
            .sheet(isPresented: $showingInventory) {
                CharacterInventoryView(character: gameStateService.player!, scene: GameStateService.shared.currentScene!, mainViewModel: viewModel)
                    .overlay(PopUpOverlayView().environmentObject(PopUpState.shared))
            }
            .sheet(isPresented: $showingSmithing) {
                SmithingView(player: gameStateService.player!, mainViewModel: viewModel)
                    .overlay(PopUpOverlayView().environmentObject(PopUpState.shared))
            }
            .sheet(isPresented: $showingAbilities) {
                AbilitiesView(scene: GameStateService.shared.currentScene!, mainViewModel: viewModel)
                    .overlay(PopUpOverlayView().environmentObject(PopUpState.shared))
            }
            .overlay(PopUpOverlayView().environmentObject(PopUpState.shared))
            .withDebugOverlay(viewModel: viewModel)
        }
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
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .foregroundColor(color)
                        }
                        .frame(width: 30, height: 30)
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
