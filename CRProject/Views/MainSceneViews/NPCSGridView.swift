import UIKit
import SwiftUI
import CoreMotion
import Combine

class NPCSGridView: UIView {
    var npcs: [NPC] {
        didSet {
            // Set up NPC observation for each NPC
            setupNPCObservation()
            collectionView.reloadData()
        }
    }
    private let npcManager: NPCInteractionManager
    private let gameStateService: GameStateService
    private let onAction: (NPCAction) -> Void
    
    private var lastTapTimes: [Int: Date] = [:]
    // Store cancellables for each NPC
    private var npcCancellables: [Int: Set<AnyCancellable>] = [:]
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 5
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(NPCCell.self, forCellWithReuseIdentifier: "NPCCell")
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .always
        cv.alwaysBounceVertical = true
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()
    
    init(npcs: [NPC],
         npcManager: NPCInteractionManager = .shared,
         gameStateService: GameStateService = DependencyManager.shared.resolve(),
         onAction: @escaping (NPCAction) -> Void) {
        self.npcs = npcs
        self.npcManager = npcManager
        self.gameStateService = gameStateService
        self.onAction = onAction
        super.init(frame: .zero)
        
        setupViews()
        setupObservers()
        setupNPCObservation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        layer.cornerRadius = 12
        layer.borderWidth = 0
        layer.borderColor = UIColor.clear.cgColor
        
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        // Add tap gesture recognizer to detect taps on empty spaces
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        tapGesture.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tapGesture)
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(npcManagerDidUpdate),
            name: .npcManagerDidUpdate,
            object: nil
        )
        
        // Also observe scene character changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSceneCharactersChanged),
            name: Notification.Name("sceneCharactersChanged"),
            object: nil
        )
    }
    
    private func setupNPCObservation() {
        // Clear previous cancellables
        npcCancellables.forEach { $0.value.forEach { $0.cancel() } }
        npcCancellables.removeAll()
        
        // Create new observation for each NPC
        for npc in npcs {
            var cancellables = Set<AnyCancellable>()
            
            // Observe bloodMeter changes
            npc.bloodMeter.$currentBlood
                .dropFirst() // Skip initial value
                .sink { [weak self, weak npc] _ in
                    guard let npc = npc else { return }
                    self?.updateNPCCell(for: npc)
                }
                .store(in: &cancellables)
                
            // Observe current activity changes
            npc.$currentActivity
                .dropFirst() // Skip initial value
                .sink { [weak self, weak npc] _ in
                    guard let npc = npc else { return }
                    self?.updateNPCCell(for: npc)
                }
                .store(in: &cancellables)
                
            // Observe isIntimidated changes
            npc.$isIntimidated
                .dropFirst() // Skip initial value
                .sink { [weak self, weak npc] newValue in
                    guard let npc = npc else { return }
                    self?.updateNPCCell(for: npc)
                }
                .store(in: &cancellables)
                
            // Observe isBeasyByPlayerAction changes
            npc.$isBeasyByPlayerAction
                .dropFirst() // Skip initial value
                .sink { [weak self, weak npc] newValue in
                    guard let npc = npc else { return }
                    self?.updateNPCCell(for: npc)
                }
                .store(in: &cancellables)
            
            // Store the cancellables for this NPC
            npcCancellables[npc.id] = cancellables
        }
        
        // Also observe NPC selection changes from the manager
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNPCSelectionChanged),
            name: Notification.Name("npcSelectionChanged"),
            object: nil
        )
    }
    
    private func updateNPCCell(for npc: NPC) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Get the current sorted list of NPCs
            let sortedNPCs = self.prepareNPCData()
            
            // Find the index of the NPC in the sorted list
            if let index = sortedNPCs.firstIndex(where: { $0.id == npc.id }) {
                
                // Find the cell and update it
                if let cell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? NPCCell {
                    let isSelected = self.npcManager.selectedNPC?.id == npc.id
                    let isDisabled = self.checkIfDisabled(npc: npc)
                    
                    cell.configure(with: npc, isSelected: isSelected, isDisabled: isDisabled)
                }
            }
        }
    }
    
    @objc private func npcManagerDidUpdate() {
        
        // First capture the currently selected NPC ID
        let selectedNPCID = NPCInteractionManager.shared.selectedNPC?.id
        
        // Then reload the collection view
        collectionView.reloadData()
        
        // Wait for layout to complete, then ensure the selected NPC still shows health indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            self.refreshVisibleCells()
            
            // Explicitly update the cell for the selected NPC
            if let selectedNPCID = selectedNPCID,
               let visibleCells = self.collectionView.visibleCells as? [NPCCell],
               let selectedCell = visibleCells.first(where: { ($0.currentNPC?.id ?? -1) == selectedNPCID }) {
                // Force layout immediately
                selectedCell.layoutIfNeeded()
                
                // Directly access the health indicator and make it visible
                if let healthIndicator = selectedCell.layer.sublayers?.first(where: { $0 is CAShapeLayer }) as? CAShapeLayer {
                    healthIndicator.opacity = 1.0
                }
            }
        }
    }
    
    @objc private func handleSceneCharactersChanged(_ notification: Notification) {
        // Make sure to refresh visible cells when scene characters change
        refreshVisibleCells()
    }
    
    private func prepareNPCData() -> [NPC] {
        let sortedNPCs = npcs.sorted { $0.lastPlayerInteractionDate > $1.lastPlayerInteractionDate }
        return Array(sortedNPCs.prefix(100))
    }
    
    private func checkIfDisabled(npc: NPC) -> Bool {
        guard let player = gameStateService.getPlayer() else { return false }
        guard npc.currentActivity != .followingPlayer else { return false }
        guard npc.currentActivity != .allyingPlayer else { return false }
        guard npc.currentActivity != .seductedByPlayer else { return false }
        return player.hiddenAt != .none
    }
    
    private func handleTap(on npc: NPC) {
        let currentTime = Date()
        if let lastTapTime = lastTapTimes[npc.id], currentTime.timeIntervalSince(lastTapTime) < 0.3 {
            onAction(.investigate(npc))
            lastTapTimes[npc.id] = nil
        } else {
            // Update selection immediately before notifying manager
            let oldSelectedNPC = npcManager.selectedNPC
            npcManager.select(with: npc)
            
            // Update cells for both the previously selected NPC and newly selected NPC
            if let oldNPC = oldSelectedNPC {
                updateNPCCell(for: oldNPC)
            }
            updateNPCCell(for: npc)
            
            lastTapTimes[npc.id] = currentTime
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        // Cancel all NPC observation
        npcCancellables.forEach { $0.value.forEach { $0.cancel() } }
    }
    
    // Force refresh all visible cells
    func refreshVisibleCells() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Get visible cells
            let visibleCellIndexPaths = self.collectionView.indexPathsForVisibleItems
            
            let sortedNPCs = self.prepareNPCData()
            
            // Update each visible cell
            for indexPath in visibleCellIndexPaths {
                guard indexPath.item < sortedNPCs.count else { continue }
                
                let npc = sortedNPCs[indexPath.item]
                if let cell = self.collectionView.cellForItem(at: indexPath) as? NPCCell {
                    let isSelected = NPCInteractionManager.shared.selectedNPC?.id == npc.id
                    let isDisabled = self.checkIfDisabled(npc: npc)
                    
                    cell.configure(with: npc, isSelected: isSelected, isDisabled: isDisabled)
                    
                    // Force cell to layout to ensure health indicator is displayed properly
                    cell.layoutIfNeeded()
                    
                    // If this is the selected cell, ensure health indicator is visible
                    if isSelected {
                    }
                }
            }
        }
    }
    
    @objc private func handleNPCSelectionChanged(_ notification: Notification) {
        // When NPC selection changes, refresh cells to ensure health indicator is shown
        DispatchQueue.main.async { [weak self] in
            self?.refreshVisibleCells()
        }
    }
    
    // Handle taps on the empty space of the grid
    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: collectionView)
        
        // Check if the tap was on a cell
        if let indexPath = collectionView.indexPathForItem(at: location) {
            // Tap was on a cell, don't do anything here as it will be handled by didSelectItemAt
            return
        }
        
        // Tap was on empty space, deselect any selected NPC
        if npcManager.selectedNPC != nil {
            // Store reference to previously selected NPC to update its cell
            let previouslySelected = npcManager.selectedNPC
            
            // Clear the selection
            npcManager.selectedNPC = nil
            
            // Update UI for the previously selected NPC's cell
            if let prevNPC = previouslySelected {
                updateNPCCell(for: prevNPC)
            }
            
            // Post notification to update other views
            NotificationCenter.default.post(name: Notification.Name("npcSelectionChanged"), object: nil)
        }
    }
}

extension NPCSGridView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = prepareNPCData().count
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NPCCell", for: indexPath) as! NPCCell
        let sortedNPCs = prepareNPCData()
        
        guard indexPath.item < sortedNPCs.count else {
            return cell
        }
        
        let npc = sortedNPCs[indexPath.item]
        let isSelected = NPCInteractionManager.shared.selectedNPC?.id == npc.id
        let isDisabled = checkIfDisabled(npc: npc)
        
        cell.configure(with: npc, isSelected: isSelected, isDisabled: isDisabled)
        
        // Ensure health indicator is properly visible for selected cells immediately
        if isSelected {
            cell.healthIndicator.opacity = 1.0
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Calculate appropriate cell size based on collection view width
        let width = collectionView.bounds.width
        
        // Determine number of items per row based on width
        // For phones and small screens: typically 3 items per row
        // For larger screens/iPads: 4-5 items per row
        let itemsPerRow: CGFloat
        
        if width < 350 {
            itemsPerRow = 2 // Very small screens
        } else if width < 500 {
            itemsPerRow = 3 // Standard iPhone portrait
        } else if width < 800 {
            itemsPerRow = 4 // Larger screens
        } else {
            itemsPerRow = 5 // iPads and landscape
        }
        
        // Account for section insets and minimum spacing
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let insets = layout.sectionInset
        let spacing = layout.minimumInteritemSpacing
        
        // Calculate available width
        let availableWidth = width - insets.left - insets.right - spacing * (itemsPerRow - 1)
        
        // Calculate item width
        let itemWidth = floor(availableWidth / itemsPerRow)
        
        // Use a fixed aspect ratio close to 1:1.1 for the cell (slightly taller than wide)
        return CGSize(width: itemWidth, height: itemWidth * 1.1)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sortedNPCs = prepareNPCData()
        
        guard indexPath.item < sortedNPCs.count else {
            return
        }
        
        let npc = sortedNPCs[indexPath.item]
        handleTap(on: npc)
    }
}



extension Notification.Name {
    static let npcManagerDidUpdate = Notification.Name("npcManagerDidUpdate")
}


struct NPCSGridViewRepresentable: UIViewRepresentable {
    let npcs: [NPC]
    let npcManager: NPCInteractionManager
    let gameStateService: GameStateService
    let onAction: (NPCAction) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: NPCSGridViewRepresentable
        var gridView: NPCSGridView?
        
        init(_ parent: NPCSGridViewRepresentable) {
            self.parent = parent
        }
        
        func refreshVisibleCells() {
            gridView?.refreshVisibleCells()
        }
    }
    
    func makeUIView(context: Context) -> NPCSGridView {
        let gridView = NPCSGridView(
            npcs: npcs,
            npcManager: npcManager,
            gameStateService: gameStateService,
            onAction: onAction
        )
        context.coordinator.gridView = gridView
        return gridView
    }
    
    func updateUIView(_ uiView: NPCSGridView, context: Context) {
        uiView.npcs = npcs
        context.coordinator.gridView = uiView
        // The collectionView will be reloaded automatically by the didSet property observer
    }
}
