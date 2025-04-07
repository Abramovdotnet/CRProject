import SwiftUICore
import SwiftUI

struct NPCSGridView: View {
    let npcs: [NPC]
    @StateObject private var npcManager = NPCInteractionManager.shared
    var onAction: (NPCAction) -> Void
    
    // Fixed 6-column grid configuration
    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 24), count: 6)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(npcs.prefix(20)) { npc in
                    NPCGridButton(
                        npc: npc,
                        isSelected: npcManager.currentNPC?.id == npc.id
                    ) {
                        if npcManager.currentNPC?.id == npc.id {
                            onAction(.startConversation(npc))
                        } else {
                            npcManager.select(with: npc)
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
    let onTap: () -> Void
    
    @State private var moonOpacity: Double = 0.6
    @State private var heartOpacity: Double = 0.6
    
    var body: some View {
        Button(action: {
            VibrationService.shared.lightTap()
            onTap()
        }) {
            ZStack {
                // Background with conditional glow for sleeping NPCs
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Theme.accentColor.opacity(0.5) : Color.black.opacity(0.5))
                    .overlay(
                        Group {
                            if npc.isSleeping {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.1), lineWidth: 2)
                            }
                        }
                    )
                    .shadow(color: npc.isSleeping ? Color.blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 0)
                
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
                    }
                }
                
                // Content
                VStack(spacing: 4) {
                    ZStack(alignment: .topLeading) {
                        Image(systemName: npc.isUnknown ? "questionmark.circle" : "waveform.path.ecg")
                            .font(.system(size: 16))
                            .foregroundColor(iconColor())
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
                    }
                }
                .frame(width: 50, height: 50)
                .padding(0)
                
                // Status icons container using ZStack for corner alignment
                ZStack(alignment: .topLeading) { // Default alignment to topLeading
                    if npc.isSleeping && npc.isIntimidated {
                        // Both: Moon top-left, Heart top-right
                        Image(systemName: "moon.zzz.fill")
                            .font(Theme.bodyFont)
                            .foregroundColor(isSelected ? Theme.textColor : .blue)
                            .opacity(moonOpacity)
                            .padding(4) // Padding from the edge
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        
                        Image(systemName: "heart.fill")
                            .font(Theme.bodyFont)
                            .foregroundColor(isSelected ? Theme.textColor : Theme.bloodProgressColor)
                            .opacity(heartOpacity)
                            .padding(4) // Padding from the edge
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        
                    } else if npc.isSleeping {
                        // Only Sleeping: Moon top-left
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 12))
                            .foregroundColor(isSelected ? Theme.textColor : .blue)
                            .opacity(moonOpacity)
                            .padding(4)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        
                    } else if npc.isIntimidated {
                        // Only Intimidated: Heart top-left
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(isSelected ? Theme.textColor : Theme.bloodProgressColor)
                            .opacity(heartOpacity)
                            .padding(4)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
                // Make the ZStack cover the whole button area for alignment
                .frame(width: 50, height: 50) 
            }
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(npc.isAlive ? 1 : 0.7)
        .onAppear {
            if npc.isSleeping {
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
