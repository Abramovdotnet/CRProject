//
//  NPCWidget.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 24.04.2025.
//


import SwiftUICore
import SwiftUI
import CoreMotion // Import CoreMotion

struct NPCWidget: View {
    let npc: NPC
    let isSelected: Bool
    let isDisabled: Bool
    var showCurrentActivity: Bool = true
    var showResistance: Bool = false
    let onTap: () -> Void
    let onAction: (NPCAction) -> Void
    
    @State private var moonOpacity: Double = 0.6
    @State private var heartOpacity: Double = 0.6
    @State private var activityOpacity: Double = 0.7
    @State private var tappedScale: CGFloat = 1.0
    @State private var lastTapTime: Date = Date()
    
    private let buttonWidth: CGFloat = 180

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
                onTap() // Call onTap first to center the view
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
                // Background
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
                    .frame(width: buttonWidth, height: 320)
                
                // Content (Image and Text)
                VStack(alignment: .leading, spacing: 0) {
                    // Image container with parallax
                    ZStack {
                        getNPCImage()
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: buttonWidth, height: 180)
                            .clipped() // Add clipping after the frame
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        if !npc.isUnknown && GameStateService.shared.getPlayer()!.desiredVictim.isDesiredVictim(npc: npc) {
                            ZStack {
                                // 1. Frame (bottom layer)
                                Image("iconFrame")
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
                                
                                Image("sphere1")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40 * 0.8, height: 40 * 0.8)
                            }
                            .shadow(color: Theme.bloodProgressColor, radius: 3, x: 0, y: 2)
                            .overlay(
                                Circle()
                                    .fill(Color.red.opacity(0.3))
                                    .frame(width: 40 * 1.4, height: 40 * 1.4)
                                    .blur(radius: 4)
                                    .opacity(0.7 + sin(Date().timeIntervalSince1970 * 2) * 0.3)
                                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: UUID())
                            )
                        }
                    }
                    .frame(width: buttonWidth, height: 180)
                    .background(Color.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Text details (rest of the card)
                    if !npc.isUnknown {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Image(systemName: npc.sex == .female ? "figure.stand.dress" : "figure.wave")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(npc.isVampire ? Theme.primaryColor : Theme.textColor)
                                Text(npc.name)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textColor)
                                Spacer()
                                Text("Age \(npc.age)")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textColor)
                            }
                            .padding(.top, 4)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                if showResistance {
                                    HStack {
                                        Text("Resistance ")
                                            .font(Theme.bodyFont)
                                            .foregroundColor(Theme.textColor)
                                        Spacer()
                                        Text(String(format: "%.1f%%", VampireGaze.shared.calculateNPCResistance(npc: npc)))
                                            .font(Theme.bodyFont)
                                            .foregroundColor(getRelationshipColor())
                                    }
                                    
                                    GradientProgressBar(value: Float(VampireGaze.shared.calculateNPCResistance(npc: npc)), barColor: Theme.bloodProgressColor.opacity(0.7), backgroundColor: Theme.textColor.opacity(0.3))
                                        .frame(height: 5)
                                        .shadow(color: Color.green.opacity(0.3), radius: 2)
                                } else {
                                    HStack {
                                        Text("Relationship ")
                                            .font(Theme.bodyFont)
                                            .foregroundColor(Theme.textColor)
                                        Spacer()
                                        Text(getRelationshipPercentage())
                                            .font(Theme.bodyFont)
                                            .foregroundColor(getRelationshipColor())
                                    }
                                    
                                    GradientProgressBar(value: Float(abs(npc.playerRelationship.value)), barColor: npc.playerRelationship.value >= 0 ? Color.green : Color.red, backgroundColor: Theme.textColor.opacity(0.3))
                                        .frame(height: 5)
                                        .shadow(color: Color.green.opacity(0.3), radius: 2)
                                }
                            }
                            .padding(.top, 8)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .top) {
                                    Text("Health")
                                        .font(Theme.bodyFont)
                                        .foregroundColor(Theme.textColor)
                                    Spacer()
                                    Text(String(format: "%.1f%%", npc.bloodMeter.currentBlood))
                                        .font(Theme.bodyFont)
                                        .foregroundColor(Theme.bloodProgressColor)
                                }
                                
                                ProgressBar(value: Double(npc.bloodMeter.currentBlood / 100), color: Theme.bloodProgressColor, height: 6)
                   
                                    .shadow(color: Theme.bloodProgressColor.opacity(0.3), radius: 2)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                    }
                }
                
                if !npc.isUnknown && npc.isAlive {
                    VStack(alignment: .leading) {
                        Spacer()
                        VStack {
                            HStack {
                                Image(systemName: npc.profession.icon)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(npc.profession.color)
                                    .lineLimit(1)
                                Text("\(npc.profession.rawValue)")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(npc.profession.color)
                                    .lineLimit(1)
                                    .padding(.leading, -5)
                            }
             
                            if showCurrentActivity {
                                HStack {
                                    Image(systemName: npc.isAlive ? npc.currentActivity.icon : "xmark.circle.fill")
                                        .foregroundColor(npc.isAlive ? npc.currentActivity.color : Theme.bloodProgressColor)
                                        .font(Theme.bodyFont)
                                    Text(npc.isAlive ? npc.currentActivity.description : "Dead")
                                        .foregroundColor(npc.isAlive ? Theme.textColor : Theme.bloodProgressColor)
                                        .font(Theme.bodyFont)
                                        .padding(.leading, -5)
                                }
                                .padding(.top, 2)
                            }
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
                        .stroke(Color.black.opacity(1.0), lineWidth: 0.5)
                        .background(Color.white.opacity(0.05))
                        .blur(radius: 2.5)
                }
                
                if !showCurrentActivity {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 0.5)
                        .background(Color.white.opacity(0.05))
                        .blur(radius: 2.5)
                }
            }
            .frame(width: buttonWidth, height: 320)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.9))
                    .blur(radius: 2)
                    .offset(y: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(tappedScale)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(npc.isAlive ? (isDisabled ? 0.5 : 1) : 0.7)
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.3), value: isSelected)
        .frame(width: buttonWidth, height: 320)
        .shadow(color: .black, radius: 10, x: 1, y: 1)
    }
    
    private func getNPCImage() -> Image {
        if npc.isUnknown {
            return Image(uiImage: UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")!)
        } else {
            return Image(uiImage: UIImage(named: "npc\(npc.id.description)") ?? UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")!)
        }
    }
    
    private func getRelationshipPercentage() -> String {
        if npc.playerRelationship.value < 0 {
            return "-\(abs(npc.playerRelationship.value))%"
        } else {
            return "\(npc.playerRelationship.value)%"
        }
    }
    
    private func getRelationshipColor() -> Color {
        if npc.playerRelationship.value < 0 {
            return Theme.bloodProgressColor
        } else {
            return .green
        }
    }
}
