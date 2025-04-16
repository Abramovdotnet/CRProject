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
    @State private var basementHideoutScale: CGFloat = 1.0
    @State private var roofHideoutScale: CGFloat = 1.0
    @State private var atticHideoutScale: CGFloat = 1.0
    @State private var graveHideoutScale: CGFloat = 1.0
    @State private var sewerHideoutScale: CGFloat = 1.0
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
                    Image(uiImage: UIImage(named: viewModel.currentScene!.sceneType.rawValue) ?? UIImage(named: "MainSceneBackground")!)
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
                            HStack(spacing: 20) {
                                VStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Image(systemName: viewModel.currentScene?.sceneType.iconName ?? "")
                                                .font(Theme.titleFont) // Slightly smaller for better fit
                                                .foregroundColor(Theme.textColor)
                                            Text(viewModel.currentScene?.name ?? "Unknown")
                                                .font(Theme.captionFont)
                                            Spacer()
                                            
                                            LocationInfoView(scene: viewModel.currentScene, viewModel: viewModel)
                                        }
                                        if viewModel.getPlayer().hiddenAt != .none {
                                            HStack {
                                                Image(systemName: viewModel.getPlayer().hiddenAt.iconName)
                                                    .foregroundColor(Theme.textColor)
                                                    .font(Theme.captionFont)
                                                Text(viewModel.getPlayer().hiddenAt.description)
                                                    .foregroundColor(Theme.textColor)
                                                    .font(Theme.captionFont)
                                            }
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
                                                    Button(action: {
                                                        withAnimation(.easeInOut(duration: 0.1)) {
                                                            watchScale = 0.9
                                                        }
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                            withAnimation(.spring()) {
                                                                watchScale = 1.0
                                                                viewModel.advanceTime()
                                                                VibrationService.shared.lightTap()
                                                            }
                                                        }
                                                    }) {
                                                        ZStack {
                                                            // 1. Frame (bottom layer)
                                                            Image("iconFrame")
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fit)
                                                                .frame(width: 50 * 1.1, height: 50 * 1.1)
                                                            
                                                            // 2. Background circle (middle layer)
                                                            Circle()
                                                                .fill(Color.black.opacity(0.7))
                                                                .frame(width: 50 * 0.85, height: 50 * 0.85)
                                                                .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                                                                .overlay(
                                                                    Circle()
                                                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                                )
                                                            
                                                            Image("clockWatch")
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fit)
                                                                .frame(width: 50 * 0.8, height: 50 * 0.8)
                                                            
                                                            Image(systemName: "hourglass.bottomhalf.fill")
                                                                .font(Theme.bodyFont)
                                                                .foregroundColor(Theme.textColor)
                                                                .padding(.top, 1)
                                                                .shadow(color: .black, radius: 3, x: 0, y: 2)
                                                        }
                                                        .scaleEffect(watchScale)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                    .contentShape(Circle())
                                                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                                                }
                                                .shadow(color: .black, radius: 3, x: 0, y: 2)
                                            }
                                            
                                            if !isPlayerHidden {
                                                VStack {
                                                    ZStack {
                                                        Button(action: {
                                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                                compassScale = 0.9
                                                            }
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                                withAnimation(.spring()) {
                                                                    compassScale = 1.0
                                                                    showingNavigation = true
                                                                    VibrationService.shared.lightTap()
                                                                }
                                                            }
                                                        }) {
                                                            ZStack {
                                                                // 1. Frame (bottom layer)
                                                                Image("iconFrame")
                                                                    .resizable()
                                                                    .aspectRatio(contentMode: .fit)
                                                                    .frame(width: 50 * 1.1, height: 50 * 1.1)
                                                                
                                                                // 2. Background circle (middle layer)
                                                                Circle()
                                                                    .fill(Color.black.opacity(0.7))
                                                                    .frame(width: 50 * 0.85, height: 50 * 0.85)
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
                                                                
                                                                Image(systemName: "map.fill")
                                                                    .font(Theme.bodyFont)
                                                                    .foregroundColor(Theme.textColor)
                                                                    .padding(.top, 1)
                                                                    .shadow(color: .black, radius: 3, x: 0, y: 2)
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
                                    }
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    
                                    // Actions
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack(alignment: .top, spacing: 8) {
                                            if viewModel.getPlayer().hiddenAt == .none {
                                                ForEach(viewModel.getAvailableHideouts(), id: \.self) { hideout in
                                                    VStack {
                                                        ZStack {
                                                            Button(action: {
                                                                withAnimation(.easeInOut(duration: 0.1)) {
                                                                    reduceHideoutButtonScale(hideoutType: hideout)
                                                                }
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                                    withAnimation(.spring()) {
                                                                        setDefaultHideoutButtonScale(hideoutType: hideout)
                                                                        showSmokeEffect = true
                                                                        viewModel.getGameStateService().movePlayerThroughHideouts(to: hideout)
                                                                        VibrationService.shared.lightTap()
                                                                        
                                                                        // Reset smoke effect after animation
                                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                                            showSmokeEffect = false
                                                                        }
                                                                    }
                                                                }
                                                            }) {
                                                                ZStack {
                                                                    // 1. Frame (bottom layer)
                                                                    Image("iconFrameAlt")
                                                                        .resizable()
                                                                        .aspectRatio(contentMode: .fit)
                                                                        .frame(width: 40 * 1.1, height: 40 * 1.1)
                                                                    
                                                                    // 2. Background circle (middle layer)
                                                                    Circle()
                                                                        .fill(Color.black.opacity(0.7))
                                                                        .frame(width: 40 * 0.85, height: 40 * 0.85)
                                                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                                                                        .overlay(
                                                                            Circle()
                                                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                                        )
                                                                    
                                                                        Image(hideout.rawValue)
                                                                            .resizable()
                                                                            .aspectRatio(contentMode: .fit)
                                                                            .frame(width: 40 * 0.8, height: 40 * 0.8)
                                                                        
                                                                        Text(hideout.description)
                                                                            .font(Theme.smallFont)
                                                                            .foregroundColor(Theme.textColor)
                                                                            .padding(.top, 1)
                                                                            .shadow(color: .black, radius: 3, x: 0, y: 2)
                                                                }
                                                                .scaleEffect(getHideoutButtonScale(hideoutType: hideout))
                                                            }
                                                            .buttonStyle(PlainButtonStyle())
                                                            .contentShape(Circle())
                                                            .shadow(color: .black, radius: 3, x: 0, y: 2)
                                                        }
                                                        .shadow(color: .black, radius: 3, x: 0, y: 2)
                                                    }
                                                }
                                            } else {
                                                VStack {
                                                    ZStack {
                                                        Button(action: {
                                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                                noneHideoutScale = 0.9
                                                            }
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                                withAnimation(.spring()) {
                                                                    noneHideoutScale = 1.0
                                                                    viewModel.getGameStateService().movePlayerThroughHideouts(to: .none)
                                                                    VibrationService.shared.lightTap()
                                                                }
                                                            }
                                                        }) {
                                                            ZStack {
                                                                // 1. Frame (bottom layer)
                                                                Image("iconFrameAlt")
                                                                    .resizable()
                                                                    .aspectRatio(contentMode: .fit)
                                                                    .frame(width: 40 * 1.1, height: 40 * 1.1)
                                                                
                                                                // 2. Background circle (middle layer)
                                                                Circle()
                                                                    .fill(Color.black.opacity(0.7))
                                                                    .frame(width: 40 * 0.85, height: 40 * 0.85)
                                                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                                                                    .overlay(
                                                                        Circle()
                                                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                                    )
                                                                
                                                                    Image(viewModel.currentScene?.sceneType.rawValue ?? "default")
                                                                        .resizable()
                                                                        .aspectRatio(contentMode: .fit)
                                                                        .frame(width: 40 * 0.8, height: 40 * 0.8)
                                                                    
                                                                    Text("Exit")
                                                                        .font(Theme.smallFont)
                                                                        .foregroundColor(Theme.textColor)
                                                                        .padding(.top, 1)
                                                                        .shadow(color: .black, radius: 3, x: 0, y: 2)
                                                            }
                                                            .scaleEffect(noneHideoutScale)
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                        .contentShape(Circle())
                                                        .shadow(color: .black, radius: 3, x: 0, y: 2)
                                                    }
                                                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                                                }
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.trailing, 5)
                                    .padding(.top, -10)
                                    .padding(.bottom, -10)
                                    
                                    VStack {
                                        // Chat History
                                        ChatHistoryView(eventsBus: DependencyManager.shared.resolve())
                                            .frame(maxWidth: .infinity)
                                            .frame(maxHeight: .infinity)
                                        
                                        if npcManager.selectedNPC != nil {
                                            SelectedNPCView(npc: npcManager.selectedNPC!, onAction: handleNPCAction)
                                                .id(npcManager.selectedNPC!.id)
                                        }
                                    }
                                    .padding(.bottom, 15)
                                    
                                }
                                .frame(width: geometry.size.width * 0.5)
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .padding(.horizontal)
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
            npcManager.playerInteracted(with: npc)
        }
    }
    
    private func showVampireGaze(npc: NPC) {
        npcManager.selectedNPC = npc
        showingVampireGaze = true
    }
    
    func setDefaultHideoutButtonScale(hideoutType: HidingCell) {
        switch hideoutType {
        case .basement:
            basementHideoutScale = 1
            break
        case .grave:
            graveHideoutScale = 1
            break
        case .roof:
            roofHideoutScale = 1
            break
        case .attic:
            atticHideoutScale = 1
            break
        case .sewers:
            sewerHideoutScale = 1
            break
        default:
            noneHideoutScale = 1
        }
    }
    
    func reduceHideoutButtonScale(hideoutType: HidingCell) {
        switch hideoutType {
        case .basement:
            basementHideoutScale = 0.9
            break
        case .grave:
            graveHideoutScale = 0.9
            break
        case .roof:
            roofHideoutScale = 0.9
            break
        case .attic:
            atticHideoutScale = 0.9
            break
        case .sewers:
            sewerHideoutScale = 0.9
            break
        default:
            noneHideoutScale = 0.9
        }
    }
    
    func getHideoutButtonScale(hideoutType: HidingCell) -> CGFloat {
        switch hideoutType {
        case .basement:
            return basementHideoutScale
        case .grave:
            return graveHideoutScale
        case .roof:
            return roofHideoutScale
        case .attic:
            return atticHideoutScale
        case .none:
            return noneHideoutScale
        case .sewers:
            return sewerHideoutScale
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
