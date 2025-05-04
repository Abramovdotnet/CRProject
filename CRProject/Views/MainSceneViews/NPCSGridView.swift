import SwiftUICore
import SwiftUI
import CoreMotion

struct NPCSGridView: View {
    let npcs: [NPC]
    @StateObject private var npcManager = NPCInteractionManager.shared
    @StateObject private var gameStateService: GameStateService = DependencyManager.shared.resolve()
    var onAction: (NPCAction) -> Void
    
    @State private var isDragging = false
    @State private var scrollOffset: CGFloat = 0 // Track scroll position
    @State private var contentOpacity = 0.0
    
    private struct NPCData: Identifiable {
        let npc: NPC
        let isSelected: Bool
        let isDisabled: Bool
        var id: Int { npc.index }
    }
    
    private func prepareNPCData() -> [NPCData] {
        var result: [NPCData] = []
        
        // Sort NPCs by lastPlayerInteractionDate (descending, handling optionals)
        let sortedNPCs = npcs
        
        // Take first 100 NPCs
        let maxNPCs = min(100, sortedNPCs.count)
        let limitedNPCs = Array(sortedNPCs[0..<maxNPCs])
        
        // Create NPCData for each NPC
        for npc in limitedNPCs {
            let isSelected: Bool = npcManager.selectedNPC?.id == npc.id
            let isDisabled: Bool = {
                guard let player = gameStateService.getPlayer() else { return false }
                guard npc.currentActivity != .followingPlayer else { return false }
                guard npc.currentActivity != .allyingPlayer else { return false }
                guard npc.currentActivity != .seductedByPlayer else { return false }
                return player.hiddenAt != .none
            }()
            
            let data = NPCData(
                npc: npc,
                isSelected: isSelected,
                isDisabled: isDisabled
            )
            result.append(data)
        }
        
        return result
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // NPC Grid with more columns - optimized for left side
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 105, maximum: 115), spacing: 8),
                        GridItem(.adaptive(minimum: 105, maximum: 115), spacing: 8)
                    ], spacing: 8) {
                        ForEach(prepareNPCData()) { data in
                            NPCCircleCard(
                                npc: data.npc,
                                isSelected: data.isSelected,
                                isDisabled: data.isDisabled,
                                onTap: {
                                    npcManager.select(with: data.npc)
                                },
                                onDoubleTap: {
                                    npcManager.select(with: data.npc)
                                    onAction(.investigate(data.npc))
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                }
                .opacity(contentOpacity)
            }
            .onAppear {
                withAnimation(.easeIn(duration: 0.3)) {
                    contentOpacity = 1
                }
            }
            .background(Color.black.opacity(0.5))
            .cornerRadius(12)
        }
    }
}

struct NPCCircleCard: View {
    let npc: NPC
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
    @State private var tapCount = 0
    @State private var lastTapTime: Date = Date()
    @State private var glowOpacity: Double = 0
    
    var body: some View {
        Button(action: {
            // Handle tap with double-tap detection
            let now = Date()
            if now.timeIntervalSince(lastTapTime) < 0.3 {
                // Double tap detected
                tapCount += 1
                if tapCount == 2 {
                    onDoubleTap()
                    tapCount = 0
                }
            } else {
                // Single tap
                tapCount = 1
                onTap()
            }
            lastTapTime = now
        }) {
            ZStack(alignment: .bottom) {
                // Main content container
                VStack(spacing: 0) {
                    // Avatar container with fixed height
                    ZStack {
                        // Fixed height container
                        Color.clear
                            .frame(width: 85, height: 85)
                        
                        // Selection glow - animated, only for selected NPCs
                        if isSelected {
                            Circle()
                                .fill(Color.red.opacity(0.2))
                                .blur(radius: 8)
                                .frame(width: 80, height: 80)
                                .opacity(glowOpacity)
                        }
                        
                        // Health indicator - only for selected NPCs
                        if !npc.isUnknown && isSelected {
                            Circle()
                                .trim(from: 0, to: CGFloat(npc.bloodMeter.currentBlood / 100))
                                .stroke(
                                    Theme.bloodProgressColor,
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .frame(width: 73, height: 73)
                        }
                        
                        // Circular frame - no stroke for unselected
                        Circle()
                            .fill(Color.black.opacity(isSelected ? 0.4 : 0.3))
                            .frame(width: 70, height: 70)
                            .overlay(
                                isSelected ?
                                Circle()
                                    .stroke(Color.red.opacity(0.6), lineWidth: 1.5)
                                : nil
                            )
                        
                        // NPC avatar
                        getNPCImage()
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 65, height: 65)
                            .clipShape(Circle())
                        
                        // Profession icon at top left
                        if !npc.isUnknown {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                                    .frame(width: 25, height: 25)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                
                                Image(systemName: npc.profession.icon)
                                    .foregroundColor(npc.profession.color)
                                    .font(.system(size: 14))
                                    .shadow(color: .black, radius: 1, x: 0, y: 0)
                            }
                            .offset(x: -24, y: -24)
                        }
                        
                        // Activity icon at bottom right
                        if !npc.isUnknown {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                                    .frame(width: 25, height: 25)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                
                                Image(systemName: npc.currentActivity.icon)
                                    .foregroundColor(npc.currentActivity.color)
                                    .font(.system(size: 14))
                                    .shadow(color: .black, radius: 1, x: 0, y: 0)
                            }
                            .offset(x: 24, y: 24)
                        }
                        
                        // Desired victim indicator with sphere icon
                        if !npc.isUnknown && GameStateService.shared.getPlayer()!.desiredVictim.isDesiredVictim(npc: npc) {
                            ZStack {
                                // Frame (bottom layer)
                                Image("iconFrame")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 27 * 1.1, height: 27 * 1.1)
                                
                                // Background circle (middle layer)
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                                    .frame(width: 27 * 0.85, height: 27 * 0.85)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                
                                // Sphere icon
                                Image("sphere1")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 27 * 0.8, height: 27 * 0.8)
                                    .shadow(color: .black, radius: 1, x: 0, y: 0)
                            }
                            .shadow(color: isSelected ? Theme.bloodProgressColor : Color.black, radius: 3, x: 0, y: 2)
                            .overlay(
                                Circle()
                                    .fill(isSelected ? Color.red.opacity(0.3) : Color.clear)
                                    .frame(width: 27 * 1.4, height: 27 * 1.4)
                                    .blur(radius: 4)
                                    .opacity(isSelected ? 0.7 : 0)
                            )
                            .offset(x: 24, y: -24)
                        }
                        
                        // Health percentage indicator
                        if !npc.isUnknown {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 25, height: 25)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                
                                Text("\(Int(npc.bloodMeter.currentBlood))%")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(.white)
                                    .shadow(color: .black, radius: 1)
                            }
                            .offset(x: -24, y: 24)
                        }
                    }
                    
                    Spacer()
                        .frame(height: 25) // Space for the name label below
                }
                
                // Name label overlay at bottom
                ZStack {
                    // Name background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.7))
                        .frame(height: 25)
                    
                    // Name text
                    if !npc.isUnknown {
                        Text(npc.name)
                            .font(Theme.bodyFont)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("Unknown")
                            .font(Theme.bodyFont)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 0)
            }
            .frame(width: 105, height: 115)
            .padding(.vertical, 5)
            .padding(.horizontal, 5)
            .shadow(color: isSelected ? Color.red.opacity(0.3) : Color.black.opacity(0.2), radius: 3)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(npc.isAlive ? (isDisabled ? 0.5 : 1) : 0.4)
        .disabled(isDisabled)
        .onChange(of: isSelected) { newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                glowOpacity = newValue ? 1.0 : 0.0
            }
        }
        .onAppear {
            // Initialize glow based on selection state
            glowOpacity = isSelected ? 1.0 : 0.0
        }
    }
    
    private func getNPCImage() -> Image {
        if npc.isUnknown {
            return Image(uiImage: UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")!)
        } else {
            return Image(uiImage: UIImage(named: "npc\(npc.id.description)") ?? UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")!)
        }
    }
}
