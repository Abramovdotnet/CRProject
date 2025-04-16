import SwiftUICore
import SwiftUI

struct NPCSGridView: View {
    let npcs: [NPC]
    @StateObject private var npcManager = NPCInteractionManager.shared
    @StateObject private var gameStateService: GameStateService = DependencyManager.shared.resolve()
    var onAction: (NPCAction) -> Void
    
    @State private var isDragging = false
    @State private var scrollOffset: CGFloat = 0 // Track scroll position
    
    private struct NPCData: Identifiable {
        let npc: NPC
        let isSelected: Bool
        let isDisabled: Bool
        var id: Int { npc.index }
    }
    
    private func prepareNPCData() -> [NPCData] {
        var result: [NPCData] = []
        
        // Sort NPCs by lastPlayerInteractionDate (descending, handling optionals)
        let sortedNPCs = npcs.sorted { npc1, npc2 in
            return npc1.lastPlayerInteractionDate > npc2.lastPlayerInteractionDate
        }
        
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
    
    // Add edge gradient mask
    private var edgeMask: some View {
        HStack(spacing: 0) {
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 40)
            
            Rectangle()
                .fill(Color.black)
            
            LinearGradient(
                gradient: Gradient(colors: [.black, .clear]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 40)
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                // Background with blur effect on edges
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear.opacity(0.7))
                        .frame(width: 10)
                        .blur(radius: 3)
                    Spacer()
                    Rectangle()
                        .fill(Color.clear.opacity(0.7))
                        .frame(width: 10)
                        .blur(radius: 3)
                }
                .allowsHitTesting(false)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 20) {
                        // Add a scroll position anchor view at the very start
                        Color.clear
                            .frame(width: 1)
                            .id("scrollAnchor")
                        
                        ForEach(prepareNPCData()) { data in
                            NPCGridButton(
                                npc: data.npc,
                                isSelected: data.isSelected,
                                isDisabled: data.isDisabled,
                                onTap: {
                                    npcManager.select(with: data.npc)
                                },
                                onAction: onAction
                            )
                            .scrollTransition(.interactive) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.5)
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.8)
                                    .rotation3DEffect(
                                        .degrees(phase.value * -20),
                                        axis: (x: 0, y: 1, z: 0)
                                    )
                            }
                            .shadow(color: data.isSelected ? Theme.primaryColor.opacity(0.5) : .black.opacity(0.5), radius: data.isSelected ? 15 : 10)
                            .id(data.id)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .frame(height: 280)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear.opacity(0.7))
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 5)
                        .blur(radius: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .mask(edgeMask)
                
                // Scroll when an actual interaction action occurs
                .onChange(of: npcManager.lastInteractionActionTimestamp) { _ in 
                    guard npcManager.lastInteractionActionTimestamp != nil else { return }
                    
                    withAnimation(.easeOut(duration: 0.3)) {
                        // Scroll to the anchor view instead of first NPC
                        proxy.scrollTo("scrollAnchor", anchor: .leading)
                    }
                }
            }
        }
    }
}

struct NPCGridButton: View {
    let npc: NPC
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    let onAction: (NPCAction) -> Void
    
    @State private var moonOpacity: Double = 0.6
    @State private var heartOpacity: Double = 0.6
    @State private var activityOpacity: Double = 0.7
    @State private var isHovered = false
    @State private var tappedScale: CGFloat = 1.0
    @State private var lastTapTime: Date = Date()
    
    var body: some View {
        Button(action: {
            let now = Date()
            let timeSinceLastTap = now.timeIntervalSince(lastTapTime)
            
            if timeSinceLastTap < 0.3 { // Double tap threshold
                // Double tap - investigate
                withAnimation(.easeInOut(duration: 0.1)) {
                    tappedScale = 0.95
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        tappedScale = 1.0
                    }
                }
                VibrationService.shared.regularTap()
                onAction(.investigate(npc))
            } else {
                // Single tap - select
                withAnimation(.easeInOut(duration: 0.1)) {
                    tappedScale = 0.98
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        tappedScale = 1.0
                    }
                }
                VibrationService.shared.lightTap()
                onTap()
            }
            lastTapTime = now
        }) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.9),
                                Color(npc.profession.color).opacity(0.05)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05),
                                        Color.clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                
                Color.black.opacity(0.9)
                
                VStack(alignment: .leading) {
                    ZStack {
                        getNPCImage()
                            .resizable()
                            .frame(width: 160, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    
                    if !npc.isUnknown {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Image(systemName: npc.sex == .female ? "figure.stand.dress" : "figure.wave")
                                    .font(Theme.smallFont)
                                    .foregroundColor(npc.isVampire ? Theme.primaryColor : Theme.textColor)
                                Text(npc.name)
                                    .font(Theme.smallFont)
                                    .foregroundColor(Theme.textColor)
                            }
                            .padding(.top, 4)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Resistance")
                                        .font(Theme.smallFont)
                                        .foregroundColor(Theme.textColor)
                                    
                                    Text(String(format: "%.1f%%", VampireGaze.shared.calculateNPCResistance(npc: npc)))
                                        .font(Theme.smallFont)
                                        .foregroundColor(Theme.bloodProgressColor)
                                }
                                
                                GradientProgressBar(value: VampireGaze.shared.calculateNPCResistance(npc: npc))
                                    .frame(width: 140, height: 5)
                                    .shadow(color: Theme.bloodProgressColor.opacity(0.3), radius: 2)
                            }
                            .padding(.top, 4)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .top) {
                                    Text("Health")
                                        .font(Theme.smallFont)
                                        .foregroundColor(Theme.textColor)
                                    
                                    Text(String(format: "%.1f%%", npc.bloodMeter.currentBlood))
                                        .font(Theme.smallFont)
                                        .foregroundColor(Theme.bloodProgressColor)
                                }
                                
                                ProgressBar(value: Double(npc.bloodMeter.currentBlood / 100), color: Theme.bloodProgressColor, height: 6)
                                    .frame(width: 140)
                                    .shadow(color: Theme.bloodProgressColor.opacity(0.3), radius: 2)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                    }
                }
                
                if !npc.isUnknown {
                    VStack(alignment: .leading) {
                        if npc.isSpecialBehaviorSet {
                            HStack {
                                Spacer()
                                ZStack {
                                    VStack(spacing: 4) {
                                        ProgressBar(value: Double(Double(npc.specialBehaviorTime) / 4.0), color: npc.currentActivity.color, height: 6)
                                            .shadow(color: npc.currentActivity.color.opacity(0.3), radius: 2)
                                        
                                        HStack(alignment: .center) {
                                            Spacer()
                                            Text(npc.currentActivity.description)
                                                .font(Theme.smallFont)
                                                .foregroundColor(Theme.textColor)
                                            
                                            Text(String(format: "%.1f%%", Double(npc.specialBehaviorTime) / 4.0 * 100))
                                                .font(Theme.smallFont)
                                                .foregroundColor(Theme.bloodProgressColor)
                                            Spacer()
                                        }
                                        .padding(.bottom, 4)
                                    }
                                }
                                .frame(width: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.9))
                                        .shadow(color: .black.opacity(0.3), radius: 4)
                                )
                                Spacer()
                            }
                        }
                        Spacer()
                        HStack {
                            Image(systemName: npc.profession.icon)
                                .font(Theme.smallFont)
                                .foregroundColor(npc.isVampire ? Theme.primaryColor : Theme.textColor)
                                .lineLimit(1)
                            Text("\(npc.profession.rawValue)")
                                .font(Theme.smallFont)
                                .foregroundColor(npc.profession.color)
                                .lineLimit(1)
                            Spacer()
                            
                            Image(systemName: npc.isAlive ? npc.currentActivity.icon : "xmark.circle.fill")
                                .foregroundColor(npc.isAlive ? npc.currentActivity.color : Theme.bloodProgressColor)
                                .font(Theme.smallFont)
                            Text(npc.isAlive ? npc.currentActivity.description : "Dead")
                                .foregroundColor(npc.isAlive ? Theme.textColor : Theme.bloodProgressColor)
                                .font(Theme.smallFont)
                                .padding(.leading, -5)
                        }
                    }
                    .padding(.bottom, 6)
                    .padding(.top, 2)
                    .padding(.horizontal, 8)
                }
                
                if npc.isUnknown {
                    Image(systemName: "questionmark.circle")
                        .font(Theme.superTitleFont)
                        .foregroundColor(Theme.textColor)
                        .animation(.easeInOut(duration: 0.3), value: npc.isUnknown)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.primaryColor.opacity(0.8), lineWidth: 2)
                        .background(Color.white.opacity(0.05))
                        .blur(radius: 0.5)
                }
            }
            .cornerRadius(12)
            .frame(width: 160, height: 260)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .blur(radius: 2)
                    .offset(y: 2)
            )
            .scaleEffect(isHovered ? 1.02 : tappedScale)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(npc.isAlive ? (isDisabled ? 0.5 : 1) : 0.7)
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
                if tappedScale != 1.0 { tappedScale = 1.0 }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isSelected)
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
    
    private func getNPCImage() -> Image {
        if npc.isUnknown {
            return Image(uiImage: UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")!)
        } else {
            return Image(uiImage: UIImage(named: "npc\(npc.id.description)") ?? UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")!)
        }
    }
}

struct NPCGridButtonOld: View {
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
                            Image(systemName: npc.isAlive ? npc.currentActivity.icon : "xmark.circle.fill")
                                .foregroundColor(npc.isAlive ? npc.currentActivity.color : Theme.bloodProgressColor)
                                .font(Theme.smallFont)
                            Text(npc.isAlive ? npc.currentActivity.description : "Dead")
                                .foregroundColor(npc.isAlive ? Theme.textColor : Theme.bloodProgressColor)
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
