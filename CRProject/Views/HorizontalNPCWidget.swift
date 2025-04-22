import SwiftUICore
import SwiftUI

struct HorizontalNPCWidget: View {
    let npc: NPC
    @StateObject private var npcManager = NPCInteractionManager.shared
    
    var body: some View {
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
            
            VStack(alignment: .center) {
                HStack {
                    ZStack {
                        getNPCImage()
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            .padding(5)
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
                                Image(systemName: npc.profession.icon)
                                    .font(Theme.smallFont)
                                    .foregroundColor(npc.profession.color)
                                Text(npc.profession.rawValue)
                                    .font(Theme.smallFont)
                                    .foregroundColor(npc.profession.color)

                                Spacer()
                                Text("Age \(npc.age)")
                                    .font(Theme.smallFont)
                                    .foregroundColor(Theme.textColor)
                            }
                            .padding(.top, 5)
                            .padding(.horizontal, 5)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .top) {
                                    Text("Health")
                                        .font(Theme.smallFont)
                                        .foregroundColor(Theme.textColor)
                                    Spacer()
                                    Text(String(format: "%.1f%%", npc.bloodMeter.currentBlood))
                                        .font(Theme.smallFont)
                                        .foregroundColor(Theme.bloodProgressColor)
                                }
                                
                                ProgressBar(value: Double(npc.bloodMeter.currentBlood / 100), color: Theme.bloodProgressColor, height: 6)
                                    .frame(maxWidth: .infinity)
                                    .shadow(color: Theme.bloodProgressColor.opacity(0.3), radius: 2)
                            }
                            .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("Relationship ")
                                        .font(Theme.smallFont)
                                        .foregroundColor(Theme.textColor)
                                    Spacer()
                                    Text(getRelationshipPercentage())
                                        .font(Theme.smallFont)
                                        .foregroundColor(getRelationshipColor())
                                }
                                
                                GradientProgressBar(value: Float(abs(npc.playerRelationship.value)), barColor: npc.playerRelationship.value >= 0 ? Color.green : Color.red, backgroundColor: Theme.textColor.opacity(0.3))
                                    .frame(height: 5)
                                    .shadow(color: Color.green.opacity(0.3), radius: 2)
                            }
                            .padding(.top, 2)
                        }
                        .padding(.horizontal, 5)
                    }
                }
    
                HStack(spacing: 6) {
                    if !npc.isUnknown {
                        Text(npc.sex.rawValue)
                            .font(Theme.smallFont)
                            .foregroundColor(Theme.textColor)
                        Image(systemName: npc.sex == .female ? "figure.stand.dress" : "figure.wave")
                            .font(Theme.smallFont)
                            .foregroundColor(Color.yellow)
                        Text(npc.age.description)
                            .font(Theme.smallFont)
                            .foregroundColor(Color.yellow)
                        Image(systemName: npc.currentActivity.icon)
                            .foregroundColor(npc.currentActivity.color)
                            .font(Theme.smallFont)
                            .padding(.leading, 3)
                        Text(npc.currentActivity.description)
                            .font(Theme.smallFont)
                            .foregroundColor(npc.currentActivity.color)
                        
                        if npc.isSpecialBehaviorSet {
                            Text(getSpecialBehaviorProgress())
                                .font(Theme.smallFont)
                                .foregroundColor(Theme.bloodProgressColor)
                        }
                    }
                    Image(systemName: npc.morality.icon)
                        .font(Theme.smallFont)
                        .foregroundColor(npc.morality.color)
                    Text(npc.morality.description)
                        .font(Theme.smallFont)
                        .foregroundColor(npc.morality.color)
                    Image(systemName: npc.motivation.icon)
                        .font(Theme.smallFont)
                        .foregroundColor(npc.motivation.color)
                    Text(npc.motivation.description)
                        .font(Theme.smallFont)
                        .foregroundColor(npc.motivation.color)
                }
                .padding(.bottom, 5)
                .padding(.top, 2)
                .padding(.horizontal, 5)
            }
            .padding(5)
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(npc.currentActivity.color.opacity(0.8), lineWidth: 2)
                .background(Color.white.opacity(0.05))
                .blur(radius: 0.5)
                .padding(.horizontal, -2)
        }
        .frame(height: 100)
        .cornerRadius(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .blur(radius: 2)
                .offset(y: 2)
        )
        .shadow(color: npc.currentActivity.color.opacity(0.5), radius: 15)
        .onChange(of: npcManager.npcStateChanged) { _ in
            // Force view update when NPC state changes
        }
    }
    
    private func getNPCImage() -> Image {
        if npc.isUnknown {
            return Image(uiImage: UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")!)
        } else {
            return Image(uiImage: UIImage(named: "npc\(npc.id.description)") ?? UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")!)
        }
    }
    
    private func getSpecialBehaviorProgress() -> String {
        return "\(Float(npc.specialBehaviorTime ?? 0) / 4.0 * 100)%"
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
