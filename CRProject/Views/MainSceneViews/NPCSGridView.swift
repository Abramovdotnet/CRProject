import SwiftUICore
import SwiftUI

struct NPCSGridView: View {
    let npcs: [NPC]
    @StateObject private var npcManager = NPCInteractionManager.shared
    @StateObject private var gameStateService: GameStateService = DependencyManager.shared.resolve()
    var onAction: (NPCAction) -> Void
    
    // Fixed 6-column grid configuration
    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 8), count: 6)
    
    private struct NPCData: Identifiable {
        let npc: NPC
        let isSelected: Bool
        let isDisabled: Bool
        var id: Int { npc.index }
    }
    
    private func prepareNPCData() -> [NPCData] {
        var result: [NPCData] = []
        
        // Sort NPCs by index in descending order
        let sortedNPCs: [NPC] = npcs.sorted { $0.index > $1.index }
        
        // Take first 100 NPCs
        let maxNPCs = min(100, sortedNPCs.count)
        let limitedNPCs: [NPC] = Array(sortedNPCs[0..<maxNPCs])
        
        // Create NPCData for each NPC
        for npc in limitedNPCs {
            let isSelected: Bool = npcManager.selectedNPC?.id == npc.id
            let isDisabled: Bool = {
                guard let player = gameStateService.getPlayer() else { return false }
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
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(prepareNPCData()) { data in
                    NPCGridButton(
                        npc: data.npc,
                        isSelected: data.isSelected,
                        isDisabled: data.isDisabled
                    ) {
                        if data.isSelected {
                            onAction(.startConversation(data.npc))
                        } else {
                            npcManager.select(with: data.npc)
                        }
                    }
                }
            }
            .padding(8)
        }
    }
}

struct NPCGridButton: View {
    let npc: NPC
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    @State private var moonOpacity: Double = 0.6
    @State private var heartOpacity: Double = 0.6
    @State private var activityOpacity: Double = 0.7
    
    var body: some View {
        Button(action: {
            VibrationService.shared.lightTap()
            onTap()
        }) {
            VStack {
                ZStack {
                    // Background with conditional glow for sleeping NPCs
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Theme.accentColor.opacity(0.5) : Color.black.opacity(0.7))
                        .overlay(
                            Group {
                                if npc.currentActivity == .sleep {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue.opacity(0.1), lineWidth: 2)
                                }
                            }
                        )
                        .shadow(color: npc.currentActivity == .sleep ? Color.blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 0)
                        .animation(.easeInOut(duration: 0.3), value: npc.currentActivity == .sleep)
                    // Blood meter for known NPCs
                    if !npc.isUnknown {
                        VStack {
                            Spacer()
                            // Horizontal progress bar container
                            HStack(spacing: 1) {
                                ForEach(0..<5) { index in
                                    let segmentValue = Double(npc.bloodMeter.currentBlood) / 100.0
                                    let segmentThreshold = Double(index + 1) / 5.0
                                    
                                    Rectangle()
                                        .fill(segmentValue >= segmentThreshold ?
                                              Theme.bloodProgressColor : Color.black.opacity(0.3))
                                        .frame(height: 2)
                                }
                            }
                            .frame(width: 30)
                            .padding(.bottom, 3)
                            .animation(.easeInOut(duration: 0.3), value: npc.bloodMeter.currentBlood)
                        }
                    }
                    
                    // Content
                    VStack(spacing: 4) {
                        ZStack(alignment: .topLeading) {
                            Image(systemName: npc.isUnknown ? "questionmark.circle" : "waveform.path.ecg")
                                .font(.system(size: 16))
                                .foregroundColor(iconColor())
                                .animation(.easeInOut(duration: 0.3), value: npc.isUnknown)
                        }
                        .frame(width: 40, height: 20)
                        
                        if !npc.isUnknown {
                            HStack(spacing: 4) {
                                Image(systemName: npc.sex == .female ? "figure.stand.dress" : "figure.wave")
                                    .font(Theme.smallFont)
                                    .foregroundColor(npc.isVampire ? Theme.primaryColor : Theme.textColor)
                                    .lineLimit(1)
                                Image(systemName: npc.profession.icon)
                                    .font(Theme.smallFont)
                                    .foregroundColor(npc.isVampire ? Theme.primaryColor : Theme.textColor)
                                    .lineLimit(1)
                            }
                            .offset(y: -2)
                            .animation(.easeInOut(duration: 0.3), value: npc.isUnknown)
                        }
                    }
                    .frame(width: 50, height: 50)
                  
                    
                    // Status icons container using ZStack for corner alignment
                    ZStack(alignment: .topLeading) {
                        if npc.currentActivity == .sleep && npc.isIntimidated {
                            // Both: Moon top-left, Heart top-right
                            Image(systemName: "moon.zzz.fill")
                                .font(Theme.bodyFont)
                                .foregroundColor(isSelected ? Theme.textColor : .blue)
                                .opacity(moonOpacity)
                                .padding(4)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .animation(.easeInOut(duration: 0.3), value: npc.currentActivity == .sleep)
                            
                            Image(systemName: "heart.fill")
                                .font(Theme.bodyFont)
                                .foregroundColor(isSelected ? Theme.textColor : Theme.bloodProgressColor)
                                .opacity(heartOpacity)
                                .padding(4)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                .animation(.easeInOut(duration: 0.3), value: npc.isIntimidated)
                            
                        } else if npc.currentActivity == .sleep {
                            // Only Sleeping: Moon top-left
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 12))
                                .foregroundColor(isSelected ? Theme.textColor : .blue)
                                .opacity(moonOpacity)
                                .padding(4)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .animation(.easeInOut(duration: 0.3), value: npc.currentActivity == .sleep)
                            
                        } else if npc.isIntimidated {
                            // Only Intimidated: Heart top-left
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundColor(isSelected ? Theme.textColor : Theme.bloodProgressColor)
                                .opacity(heartOpacity)
                                .padding(4)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .animation(.easeInOut(duration: 0.3), value: npc.isIntimidated)
                        }
                    }
                    .frame(width: 50, height: 50)
                }
                
                // Activity display
                Rectangle()
                    .fill(Color.clear)
                    .cornerRadius(4)
                    .frame(width: 70, height: 20)
                    .overlay(
                        HStack {
                            Image(systemName: npc.currentActivity.icon)
                                .foregroundColor(npc.currentActivity.color)
                                .font(Theme.smallFont)
                            Text(npc.currentActivity.description)
                                .foregroundColor(Theme.textColor)
                                .font(Theme.smallFont)
                                .padding(.leading, -5)
                        }
                
                    )
                    .opacity(activityOpacity)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 0.8).repeatForever()) {
                            activityOpacity = 1.0
                        }
                    }
                    .padding(.top, -5)
              
            }
            
            
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(npc.isAlive ? (isDisabled ? 0.5 : 1) : 0.7)
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.3), value: npc.isAlive)
        .animation(.easeInOut(duration: 0.3), value: isDisabled)
        .onAppear {
            if npc.currentActivity == .sleep {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever()) {
                    moonOpacity = 1.0
                }
            }
            if npc.isIntimidated {
                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
                    heartOpacity = 1.0
                }
            }
        }
    }
    
    func iconColor() -> Color {
        if npc.isAlive {
            if isSelected {
                return Theme.textColor
            } else {
                return npc.isUnknown ? .white : npc.isVampire ? Theme.primaryColor : .green
            }
        } else {
            return Theme.primaryColor
        }
    }
}
