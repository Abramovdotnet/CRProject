import SwiftUI

struct MainSceneView: View {
    @ObservedObject var viewModel: MainSceneViewModel
    @StateObject private var npcManager = NPCInteractionManager.shared
    @StateObject private var gameStateService: GameStateService = DependencyManager.shared.resolve()
    @State private var navigationPath = NavigationPath()
    @State private var compassScale: CGFloat = 1.0
    @State private var watchScale: CGFloat = 1.0
    @State private var spentTimeWatchScale: CGFloat = 1.0
    @State private var noneHideoutScale: CGFloat = 1.0
    @State private var shadowHideoutScale: CGFloat = 1.0
    @State private var showHistory = false
    @State private var showSmokeEffect = false
    @State private var activeDialogueViewModel: DialogueViewModel? = nil
    
    // New enum for navigation destinations
    enum NavigationDestination: Hashable {
        case navigation
        case dialogue
        case vampireGaze
        case trade
        case inventory
        case smithing
        case abilities
        case loot
        case questJournal
        case hidingCell
    }
    
    init(viewModel: MainSceneViewModel) {
        self.viewModel = viewModel
        
        // Configure the navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = UIColor.clear
        navBarAppearance.shadowColor = .clear
        
        // Remove the default back button text
        navBarAppearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        
        // Apply to all navigation bars
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
    
    // Reference to grid view for scrolling
    private var gridViewRef: NPCSGridView?
    
    private var isPlayerHidden: Bool {
        guard let player = gameStateService.getPlayer() else { return false }
        return player.hiddenAt != .none
    }
    
    private var isPlayerArrested: Bool {
        guard let player = gameStateService.getPlayer() else { return false }
        return player.isArrested
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
            // Global background to ensure no white edges
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Прозрачная область для обнаружения тапов на фон
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                
                NavigationStack(path: $navigationPath) {
                    ZStack {
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
                                .ignoresSafeArea()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .allowsHitTesting(false)
                        }
                        
                        DustEmitterView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        VStack(spacing: 0) {
                            TopWidgetView(viewModel: viewModel)
                                .frame(height: 35)
                                .frame(maxWidth: .infinity, alignment: .top)
                                .background(Color.clear)
                            
                            // Main content area - now without any padding
                            HStack(spacing: 0) {
                                // Left buttons - aligned to the left edge
                                VStack(alignment: .center, spacing: 4) {
                                    // Advance time
                                    MainSceneActionButton(
                                        icon: "hourglass.bottomhalf.fill",
                                        color: Theme.textColor,
                                        action: {
                                            viewModel.advanceTime()
                                        }
                                    )
                                    // Swtich NPCs/Chat view
                                    MainSceneActionButton(
                                        icon: showHistory ? "person.3.fill" : "widget.large",
                                        color: Theme.textColor,
                                        action: {
                                            showHistory.toggle()
                                        }
                                    )
                                    
                                    if viewModel.currentScene?.sceneType == .blacksmith {
                                        MainSceneActionButton(
                                            icon: "hammer.fill",
                                            color: Theme.textColor,
                                            action: {
                                                navigationPath.append(NavigationDestination.smithing)
                                            }
                                        )
                                    }
                                    
                                    // Quest Journal Button - Moved here
                                    MainSceneActionButton(
                                        icon: "book.closed.fill", // Or another icon like "list.star"
                                        color: Theme.textColor,
                                        action: {
                                            navigationPath.append(NavigationDestination.questJournal)
                                        }
                                    )
                                    
                                    if !isPlayerHidden && !isPlayerArrested {
                                        // Show navigation
                                        MainSceneActionButton(
                                            icon: "map.fill",
                                            color: Theme.bloodProgressColor,
                                            action: {
                                                navigationPath.append(NavigationDestination.navigation)
                                            }
                                        )
                                    }
                                    // Показываем кнопку HidingCell только если можно спрятаться
                                    if gameStateService.checkCouldHide() {
                                        MainSceneActionButton(
                                            icon: "eye.circle.fill",
                                            color: Theme.textColor,
                                            action: {
                                                navigationPath.append(NavigationDestination.hidingCell)
                                            }
                                        )
                                    }
                                    // Hide
                                    if let player = GameStateService.shared.player, player.hiddenAt == .none && AbilitiesSystem.shared.hasInvisibility {
                                        ForEach(viewModel.getAvailableHideouts(), id: \.self) { hideout in
                                            MainSceneActionButton(
                                                icon: "eye.fill",
                                                color: Theme.bloodProgressColor,
                                                action: {
                                                    showSmokeEffect = true
                                                    viewModel.getGameStateService().movePlayerThroughHideouts(to: hideout)
                                                    StatisticsService.shared.increaseDisappearances()
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
                                    
                                    if !isPlayerArrested {
                                        MainSceneActionButton(
                                            icon: "duffle.bag.fill",
                                            color: Theme.bloodProgressColor,
                                            action: {
                                                navigationPath.append(NavigationDestination.inventory)
                                            }
                                        )
                                    }
                                    
                                    MainSceneActionButton(
                                        icon: "moon.stars.circle.fill",
                                        color: Theme.bloodProgressColor,
                                        action: {
                                            navigationPath.append(NavigationDestination.abilities)
                                        }
                                    )
                                    
                                    Spacer()
                                }
                                .frame(width: 60)
                                
                                Spacer(minLength: 10)
                                
                                // Center NPCSGridView
                                VStack {
                                    if showHistory {
                                        ChatHistoryView(eventsBus: DependencyManager.shared.resolve())
                                            .frame(maxWidth: .infinity)
                                    } else {
                                        NPCSGridViewRepresentable(
                                            npcs: viewModel.npcs,
                                            npcManager: .shared,
                                            gameStateService: DependencyManager.shared.resolve(),
                                            onAction: viewModel.handleNPCAction
                                        )
                                    }
       
                                    DesiresView(npc: npcManager.selectedNPC, onAction: viewModel.handleNPCAction, viewModel: viewModel)
                                }
                                .layoutPriority(1)
                                
                                Spacer(minLength: 10)
                                
                                // Information panel
                                VStack(spacing: 8) {
                                    if npcManager.selectedNPC != nil {
                                        //HorizontalNPCWidget(npc: npcManager.selectedNPC!)
                                        NPCWidget(npc: npcManager.selectedNPC!, isSelected: true, isDisabled: false, showCurrentActivity: true, onTap: { Void() }, onAction: { _ in Void ()})
                                    } else {
                                        PlayerWidget(player: GameStateService.shared.player!)
                                    }
                               
                                    // Chat History
                                    /*ChatHistoryView(eventsBus: DependencyManager.shared.resolve())
                                        .frame(maxWidth: .infinity)*/
                                }

                                
                                Spacer(minLength: 10)
                                
                                // Right buttons - aligned to the right edge
                                VStack(alignment: .center, spacing: 4) {
                                    if let selectedNPC = npcManager.selectedNPC {
                                        if selectedNPC.currentActivity != .jailed && !isPlayerArrested && !selectedNPC.isAlive {
                                            MainSceneActionButton(
                                                icon: "bag.fill",
                                                color: Theme.textColor,
                                                action: {
                                                    navigationPath.append(NavigationDestination.loot)
                                                }
                                            )
                                        }
                                        if !selectedNPC.isUnknown && selectedNPC.isAlive {
                                            if selectedNPC.currentActivity != .sleep && selectedNPC.currentActivity != .fleeing && selectedNPC.currentActivity != .bathe {
                                                // Start conversation
                                                MainSceneActionButton(
                                                    icon: "bubble.left.fill",
                                                    color: Theme.textColor,
                                                    action: {
                                                        viewModel.handleNPCAction(.startConversation(selectedNPC))
                                                        
                                                        // Создаем DialogueViewModel и открываем диалог
                                                        if let dialogueVM = viewModel.createDialogueViewModel(for: selectedNPC) {
                                                            activeDialogueViewModel = dialogueVM
                                                            navigationPath.append(NavigationDestination.dialogue)
                                                        }
                                                    }
                                                )
                                                
                                                if selectedNPC.isTradeAvailable() && selectedNPC.currentActivity != .jailed && !isPlayerArrested {
                                                    // Trade
                                                    MainSceneActionButton(
                                                        icon: "cart.fill",
                                                        color: Theme.textColor,
                                                        action: {
                                                            navigationPath.append(NavigationDestination.trade)
                                                        }
                                                    )
                                                }
                                            }
                                            
                                            // Start intimidation
                                            MainSceneActionButton(
                                                icon: "bolt.heart.fill",
                                                color: Theme.bloodProgressColor,
                                                action: {
                                                    viewModel.handleNPCAction(.startIntimidation(selectedNPC))
                                                    // Handle VampireGaze
                                                    if viewModel.isShowingVampireGazeView {
                                                        navigationPath.append(NavigationDestination.vampireGaze)
                                                    }
                                                }
                                            )
                                            
                                            if !selectedNPC.isVampire && selectedNPC.currentActivity != .jailed && !isPlayerArrested {
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
                                    
                                    Spacer()
                                }
                                .frame(width: 60)
                                
                                Spacer(minLength: 10)
                            }
                            .padding(.top)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        
                        // Red Overlay for low blood
                        Rectangle()
                            .fill(.red)
                            .opacity(lowBloodRedOpacity)
                            .allowsHitTesting(false) // Make overlay non-interactive
                    }
                    .background(Color.black)
                    .foregroundColor(Theme.textColor)
                    .animation(.easeInOut(duration: 0.5), value: lowBloodRedOpacity)
                    .navigationBarHidden(true)
                    .withDebugOverlay(viewModel: viewModel)
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        switch destination {
                        case .navigation:
                            WorldMapViewRepresentable(mainViewModel: viewModel)
                                .edgesIgnoringSafeArea(.all)
                                .navigationBarHidden(true)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button(action: {
                                            safePopNavigation()
                                        }) {
                                            Image(systemName: "chevron.backward")
                                                .foregroundColor(Theme.textColor)
                                        }
                                    }
                                }
                        case .dialogue:
                            ZStack {
                                Color.black.edgesIgnoringSafeArea(.all)
                                
                                if let dialogueViewModel = activeDialogueViewModel {
                                    DialogueView(
                                        viewModel: dialogueViewModel, 
                                        mainViewModel: viewModel,
                                        isSkipable: !dialogueViewModel.isSpecificDialogueSet
                                    )
                                        .onDisappear {
                                            activeDialogueViewModel = nil
                                        }
                                } else {
                                    Text("Loading Dialogue...")
                                        .foregroundColor(Theme.textColor)
                                        .onAppear {
                                            // If dialogue not available, go back safely
                                            if !navigationPath.isEmpty {
                                                navigationPath.removeLast()
                                            }
                                        }
                                }
                            }
                            .navigationBarHidden(true)
                            .gesture(
                                DragGesture()
                                    .onEnded { gesture in
                                        // Разрешаем закрытие жестом только для обычных диалогов
                                        if gesture.translation.width > 100 && 
                                            activeDialogueViewModel?.isSpecificDialogueSet == false {
                                            safePopNavigation()
                                            activeDialogueViewModel = nil
                                        }
                                    }
                            )
                            
                        case .vampireGaze:
                            ZStack {
                                Color.black.edgesIgnoringSafeArea(.all)
                                
                                if let npc = npcManager.selectedNPC {
                                    VampireGazeView(npc: npc, isPresented: $viewModel.isShowingVampireGazeView, mainViewModel: viewModel)
                                        .onDisappear {
                                            viewModel.isShowingVampireGazeView = false
                                        }
                                }
                            }
                            .navigationBarHidden(true)
                            .gesture(
                                DragGesture()
                                    .onEnded { gesture in
                                        if gesture.translation.width > 100 {
                                            safePopNavigation()
                                            viewModel.isShowingVampireGazeView = false
                                        }
                                    }
                            )
                            
                        case .trade:
                            ZStack {
                                Color.black.edgesIgnoringSafeArea(.all)
                                
                                if let npc = npcManager.selectedNPC {
                                    TradeView(player: gameStateService.player!, npc: npc, scene: GameStateService.shared.currentScene!, mainViewModel: viewModel)
                                }
                            }
                            .navigationBarHidden(true)
                            .gesture(
                                DragGesture()
                                    .onEnded { gesture in
                                        if gesture.translation.width > 100 {
                                            safePopNavigation()
                                        }
                                    }
                            )
                            
                        case .inventory:
                            ZStack {
                                Color.black.edgesIgnoringSafeArea(.all)
                                
                                CharacterInventoryView(character: gameStateService.player!, scene: GameStateService.shared.currentScene!, mainViewModel: viewModel)
                            }
                            .navigationBarHidden(true)
                            .gesture(
                                DragGesture()
                                    .onEnded { gesture in
                                        if gesture.translation.width > 100 {
                                            safePopNavigation()
                                        }
                                    }
                            )
                            
                        case .smithing:
                            ZStack {
                                Color.black.edgesIgnoringSafeArea(.all)
                                
                                SmithingView(player: gameStateService.player!, mainViewModel: viewModel)
                            }
                            .navigationBarHidden(true)
                            .gesture(
                                DragGesture()
                                    .onEnded { gesture in
                                        if gesture.translation.width > 100 {
                                            safePopNavigation()
                                        }
                                    }
                            )
                            
                        case .abilities:
                            ZStack {
                                Color.black.edgesIgnoringSafeArea(.all)
                                
                                AbilitiesView(scene: GameStateService.shared.currentScene!, mainViewModel: viewModel)
                            }
                            .navigationBarHidden(true)
                            .gesture(
                                DragGesture()
                                    .onEnded { gesture in
                                        if gesture.translation.width > 100 {
                                            safePopNavigation()
                                        }
                                    }
                            )
                            
                        case .loot:
                            ZStack {
                                Color.black.edgesIgnoringSafeArea(.all)
                                
                                if let npc = npcManager.selectedNPC {
                                    LootView(player: gameStateService.player!, npc: npc, scene: GameStateService.shared.currentScene!, mainViewModel: viewModel)
                                }
                            }
                            .navigationBarHidden(true)
                            .gesture(
                                DragGesture()
                                    .onEnded { gesture in
                                        if gesture.translation.width > 100 {
                                            safePopNavigation()
                                        }
                                    }
                            )
                            
                        case .questJournal:
                            ZStack { // Wrap in ZStack for background and gesture
                                Color.black.edgesIgnoringSafeArea(.all)
                                // Передаем viewModel из MainSceneView в QuestJournalView
                                QuestJournalView(mainSceneViewModel: viewModel)
                            }
                            .navigationBarHidden(true)
                            .gesture(
                                DragGesture()
                                    .onEnded { gesture in
                                        if gesture.translation.width > 100 { // Standard swipe distance
                                            safePopNavigation()
                                        }
                                    }
                            )
                        case .hidingCell:
                            ZStack {
                                Color.black.edgesIgnoringSafeArea(.all)
                                HidingCellView(mainSceneViewModel: viewModel)
                            }
                            .navigationBarHidden(true)
                            .gesture(
                                DragGesture()
                                    .onEnded { gesture in
                                        if gesture.translation.width > 100 {
                                            safePopNavigation()
                                        }
                                    }
                            )
                        }
                    }
                }
       
            }
            .onAppear {

                NotificationCenter.default.addObserver(
                    forName: Notification.Name("openDialogueTrigger"),
                    object: nil,
                    queue: .main
                ) { [self] notification in
                    guard let userInfo = notification.userInfo else {
                        DebugLogService.shared.log("Error: Received .openDialogueTrigger notification with nil userInfo.", category: "Error")
                        return
                    }

                    guard let dialogueFilename = userInfo["specificDialogueFilename"] as? String else {
                        DebugLogService.shared.log("Error: .openDialogueTrigger missing 'specificDialogueFilename' in userInfo: \\(userInfo)", category: "Error")
                        return
                    }

                    let forceOpen = userInfo["forceOpen"] as? Bool ?? false
                    let targetNPCId = userInfo["targetNPCId"] as? Int
                    let interactingNPCIdFromQuest = userInfo["interactingNPCId"] as? Int
                    
                    DebugLogService.shared.log("Received .openDialogueTrigger: file='\\(dialogueFilename)', targetNPCId=\\(targetNPCId ?? -1), forceOpen=\\(forceOpen), interactingFromQuest=\\(interactingNPCIdFromQuest ?? -1)", category: "DialogueTrigger")

                    var npcForDialogue: NPC? = nil

                    if forceOpen {
                        if let npcId = targetNPCId {
                            npcForDialogue = NPCReader.getRuntimeNPC(by: npcId)
                            if npcForDialogue == nil {
                                DebugLogService.shared.log("Warning: forceOpen dialogue trigger for targetNPCId \\(npcId) but NPC not found.", category: "DialogueTrigger")
                            }
                        }
                    } else {
                        let currentInteractingNPC = npcManager.selectedNPC

                        if let tid = targetNPCId {
                            if currentInteractingNPC?.id == tid {
                                npcForDialogue = currentInteractingNPC
                            } else {
                                DebugLogService.shared.log("Info: .openDialogueTrigger for targetNPCId \\(tid) but current NPC is \\(currentInteractingNPC?.id ?? -1). Dialogue not opened.", category: "DialogueTrigger")
                                // if let targetNpcName = npcManager.getNPC(by: tid)?.name {
                                //     PopUpState.shared.show(message: "Нужно поговорить с \\(targetNpcName).")
                                // }
                                return 
                            }
                        } else if let qNPCId = interactingNPCIdFromQuest {
                            if currentInteractingNPC?.id == qNPCId {
                                npcForDialogue = currentInteractingNPC
                            } else {
                                 DebugLogService.shared.log("Info: .openDialogueTrigger with interactingNPCIdFromQuest \\(qNPCId) but current NPC is \\(currentInteractingNPC?.id ?? -1). Dialogue not opened.", category: "DialogueTrigger")
                                 return
                            }
                        } else if currentInteractingNPC != nil {
                            npcForDialogue = currentInteractingNPC
                        } else {
                            DebugLogService.shared.log("Warning: .openDialogueTrigger (not forced) but no NPC context available (target, quest, or current). Dialogue not opened.", category: "DialogueTrigger")
                            return
                        }
                    }

                    guard let player = gameStateService.player else {
                        DebugLogService.shared.log("Error: .openDialogueTrigger - player object is nil.", category: "Error")
                        return
                    }

                    let dialogueVM = DialogueViewModel(npc: npcForDialogue!, player: player, specificDialogueFilename: dialogueFilename)
                    activeDialogueViewModel = dialogueVM

                    DispatchQueue.main.async {
                        navigationPath = NavigationPath() 
                        navigationPath.append(NavigationDestination.dialogue)
                    }
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: Notification.Name("openDialogueTrigger"), object: nil)
            }
        }
    }
    
    // Add a safe remove method
    func safePopNavigation() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func setDefaultHideoutButtonScale(hideoutType: HidingCell) {
        shadowHideoutScale = 1.0
    }
    
    func reduceHideoutButtonScale(hideoutType: HidingCell) {
        shadowHideoutScale = 0.9
    }
    
    func getHideoutButtonScale(hideoutType: HidingCell) -> CGFloat {
        return shadowHideoutScale
    }
}

enum NPCAction {
    case startConversation(NPC)
    case startIntimidation(NPC)
    case feed(NPC)
    case drain(NPC)
    case investigate(NPC)
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
