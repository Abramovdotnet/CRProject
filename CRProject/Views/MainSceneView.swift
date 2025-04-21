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
                                // Left section: NPCSGridView
                                NPCSGridView(
                                    npcs: viewModel.npcs,
                                    onAction: handleNPCAction
                                )
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
                                .frame(width: geometry.size.width * 0.4)
                            
                                VStack(alignment: .leading, spacing: 6) {
                                    // Advance time
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
                                                HStack(spacing: 12) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(Color.blue)
                                                            .blur(radius: 15)
                                                            .opacity(0.9)
                                                        
                                                        Circle()
                                                            .fill(
                                                                RadialGradient(
                                                                    gradient: Gradient(colors: [
                                                                        Color.blue.opacity(0.3),
                                                                        Color.black.opacity(0.8)
                                                                    ]),
                                                                    center: .center,
                                                                    startRadius: 0,
                                                                    endRadius: 25
                                                                )
                                                            )
                                                            .frame(width: 36, height: 36)
                                                        
                                                        Image(systemName: "hourglass.bottomhalf.fill")
                                                            .font(.system(size: 16))
                                                            .foregroundColor(Color.blue)
                                                    }
                                                    .frame(width: 26, height: 25)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .scaleEffect(watchScale)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .contentShape(Circle())
                                            .shadow(color: .black, radius: 3, x: 0, y: 2)
                                        }
                                        .shadow(color: .black, radius: 3, x: 0, y: 2)
                                    }
                                    
                                    if !isPlayerHidden {
                                        // Show navigation
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
                                                    HStack(spacing: 12) {
                                                        ZStack {
                                                            Circle()
                                                                .fill(Color.green)
                                                                .blur(radius: 15)
                                                                .opacity(0.9)
                                                            
                                                            Circle()
                                                                .fill(
                                                                    RadialGradient(
                                                                        gradient: Gradient(colors: [
                                                                            Color.green.opacity(0.3),
                                                                            Color.black.opacity(0.8)
                                                                        ]),
                                                                        center: .center,
                                                                        startRadius: 0,
                                                                        endRadius: 25
                                                                    )
                                                                )
                                                                .frame(width: 36, height: 36)
                                                            
                                                            Image(systemName: "map.fill")
                                                                .font(.system(size: 16))
                                                                .foregroundColor(Color.green)
                                                        }
                                                        .frame(width: 26, height: 25)
                                                    }
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 10)
                                                    .scaleEffect(compassScale)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .contentShape(Circle())
                                                .shadow(color: .black, radius: 3, x: 0, y: 2)
                                            }
                                            .shadow(color: .black, radius: 3, x: 0, y: 2)
                                        }
                                    }
                                    // Hide
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
                                                                    HStack(spacing: 12) {
                                                                        ZStack {
                                                                            Circle()
                                                                                .fill(Color.purple)
                                                                                .blur(radius: 15)
                                                                                .opacity(0.9)
                                                                            
                                                                            Circle()
                                                                                .fill(
                                                                                    RadialGradient(
                                                                                        gradient: Gradient(colors: [
                                                                                            Color.purple.opacity(0.3),
                                                                                            Color.black.opacity(0.8)
                                                                                        ]),
                                                                                        center: .center,
                                                                                        startRadius: 0,
                                                                                        endRadius: 25
                                                                                    )
                                                                                )
                                                                                .frame(width: 36, height: 36)
                                                                            
                                                                            Image(systemName: "eye.fill")
                                                                                .font(.system(size: 16))
                                                                                .foregroundColor(Color.purple)
                                                                        }
                                                                        .frame(width: 26, height: 25)
                                                                    }
                                                                    .frame(maxWidth: .infinity)
                                                                    .padding(.horizontal, 12)
                                                                    .padding(.vertical, 10)
                                                                    .scaleEffect(getHideoutButtonScale(hideoutType: hideout))
                                                                }
                                                                .buttonStyle(PlainButtonStyle())
                                                                .contentShape(Circle())
                                                                .shadow(color: .black, radius: 3, x: 0, y: 2)
                                                            }
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
                                                            HStack(spacing: 12) {
                                                                ZStack {
                                                                    Circle()
                                                                        .fill(Color.red)
                                                                        .blur(radius: 15)
                                                                        .opacity(0.9)
                                                                    
                                                                    Circle()
                                                                        .fill(
                                                                            RadialGradient(
                                                                                gradient: Gradient(colors: [
                                                                                    Color.red.opacity(0.3),
                                                                                    Color.black.opacity(0.8)
                                                                                ]),
                                                                                center: .center,
                                                                                startRadius: 0,
                                                                                endRadius: 25
                                                                            )
                                                                        )
                                                                        .frame(width: 36, height: 36)
                                                                    
                                                                    Image(systemName: "eye.slash")
                                                                        .font(.system(size: 16))
                                                                        .foregroundColor(Color.red)
                                                                }
                                                                .frame(width: 26, height: 25)
                                                            }
                                                            .frame(maxWidth: .infinity)
                                                            .padding(.horizontal, 12)
                                                            .padding(.vertical, 10)
                                                            .scaleEffect(noneHideoutScale)
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                        .contentShape(Circle())
                                                        .shadow(color: .black, radius: 3, x: 0, y: 2)
                                                    }
                                                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                                                }
                                        .disabled(viewModel.currentScene?.isIndoor == false && !gameStateService.isNightTime)
                                    }
                                    
                                    if let selectedNPC = npcManager.selectedNPC {
                                        if selectedNPC.isAlive {
                                            // Start conversation
                                            VStack {
                                                ZStack {
                                                    Button(action: {
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                            withAnimation(.spring()) {
                                                                handleNPCAction(.startConversation(selectedNPC))
                                                                VibrationService.shared.lightTap()
                                                            }
                                                        }
                                                    }) {
                                                        HStack(spacing: 12) {
                                                            ZStack {
                                                                Circle()
                                                                    .fill(Color.white)
                                                                    .blur(radius: 15)
                                                                    .opacity(0.9)
                                                                
                                                                Circle()
                                                                    .fill(
                                                                        RadialGradient(
                                                                            gradient: Gradient(colors: [
                                                                                Color.white.opacity(0.3),
                                                                                Color.black.opacity(0.8)
                                                                            ]),
                                                                            center: .center,
                                                                            startRadius: 0,
                                                                            endRadius: 25
                                                                        )
                                                                    )
                                                                    .frame(width: 36, height: 36)
                                                                
                                                                Image(systemName: "bubble.left.fill")
                                                                    .font(.system(size: 16))
                                                                    .foregroundColor(Color.white)
                                                            }
                                                            .frame(width: 26, height: 25)
                                                        }
                                                        .frame(maxWidth: .infinity)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 10)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                    .contentShape(Circle())
                                                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                                                }
                                                .shadow(color: .black, radius: 3, x: 0, y: 2)
                                            }
                                        }
                                        if !selectedNPC.isUnknown {
                                            // Start intimidation
                                            VStack {
                                                ZStack {
                                                    Button(action: {
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                            withAnimation(.spring()) {
                                                                handleNPCAction(.startIntimidation(selectedNPC))
                                                                VibrationService.shared.lightTap()
                                                            }
                                                        }
                                                    }) {
                                                        HStack(spacing: 12) {
                                                            ZStack {
                                                                Circle()
                                                                    .fill(Color.cyan)
                                                                    .blur(radius: 15)
                                                                    .opacity(0.9)
                                                                
                                                                Circle()
                                                                    .fill(
                                                                        RadialGradient(
                                                                            gradient: Gradient(colors: [
                                                                                Color.cyan.opacity(0.3),
                                                                                Color.black.opacity(0.8)
                                                                            ]),
                                                                            center: .center,
                                                                            startRadius: 0,
                                                                            endRadius: 25
                                                                        )
                                                                    )
                                                                    .frame(width: 36, height: 36)
                                                                
                                                                Image(systemName: "moon.stars")
                                                                    .font(.system(size: 16))
                                                                    .foregroundColor(Color.cyan)
                                                            }
                                                            .frame(width: 26, height: 25)
                                                        }
                                                        .frame(maxWidth: .infinity)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 10)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                    .contentShape(Circle())
                                                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                                                }
                                                .shadow(color: .black, radius: 3, x: 0, y: 2)
                                            }
                                        }
                                        
                                        if !selectedNPC.isVampire {
                                            if !selectedNPC.isUnknown {
                                                // Feed
                                                VStack {
                                                    ZStack {
                                                        Button(action: {
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                                withAnimation(.spring()) {
                                                                    handleNPCAction(.feed(selectedNPC))
                                                                    VibrationService.shared.regularTap()
                                                                }
                                                            }
                                                        }) {
                                                            HStack(spacing: 12) {
                                                                ZStack {
                                                                    Circle()
                                                                        .fill(Theme.bloodProgressColor)
                                                                        .blur(radius: 15)
                                                                        .opacity(0.9)
                                                                    
                                                                    Circle()
                                                                        .fill(
                                                                            RadialGradient(
                                                                                gradient: Gradient(colors: [
                                                                                    Theme.bloodProgressColor.opacity(0.3),
                                                                                    Color.black.opacity(0.8)
                                                                                ]),
                                                                                center: .center,
                                                                                startRadius: 0,
                                                                                endRadius: 25
                                                                            )
                                                                        )
                                                                        .frame(width: 36, height: 36)
                                                                    
                                                                    Image(systemName: "drop.halffull")
                                                                        .font(.system(size: 16))
                                                                        .foregroundColor(Theme.bloodProgressColor)
                                                                }
                                                                .frame(width: 26, height: 25)
                                                            }
                                                            .frame(maxWidth: .infinity)
                                                            .padding(.horizontal, 12)
                                                            .padding(.vertical, 10)
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                        .contentShape(Circle())
                                                        .shadow(color: .black, radius: 3, x: 0, y: 2)
                                                    }
                                                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                                                }
                                            }
                                            // Empty blood
                                            VStack {
                                                ZStack {
                                                    Button(action: {
                                                        withAnimation(.easeInOut(duration: 0.1)) {
                                                            // Add scale animation
                                                        }
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                            withAnimation(.spring()) {
                                                                handleNPCAction(.drain(selectedNPC))
                                                                VibrationService.shared.successVibration()
                                                            }
                                                        }
                                                    }) {
                                                        HStack(spacing: 12) {
                                                            ZStack {
                                                                Circle()
                                                                    .fill(Theme.bloodProgressColor)
                                                                    .blur(radius: 15)
                                                                    .opacity(0.9)
                                                                
                                                                Circle()
                                                                    .fill(
                                                                        RadialGradient(
                                                                            gradient: Gradient(colors: [
                                                                                Theme.bloodProgressColor.opacity(0.3),
                                                                                Color.black.opacity(0.8)
                                                                            ]),
                                                                            center: .center,
                                                                            startRadius: 0,
                                                                            endRadius: 25
                                                                        )
                                                                    )
                                                                    .frame(width: 36, height: 36)
                                                                
                                                                Image(systemName: "drop.fill")
                                                                    .font(.system(size: 16))
                                                                    .foregroundColor(Theme.bloodProgressColor)
                                                            }
                                                            .frame(width: 26, height: 25)
                                                        }
                                                        .frame(maxWidth: .infinity)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 10)
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
                                .frame(width: 25)
                                .frame(maxHeight: .infinity, alignment: .top)
                                
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
