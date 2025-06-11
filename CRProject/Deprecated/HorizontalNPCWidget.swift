import SwiftUICore
import SwiftUI

struct HorizontalNPCWidget: View {
    let npc: NPC
    var showCurrentActivity: Bool = true
    @StateObject private var npcManager = NPCInteractionManager.shared
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.7)
            
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
                                    .font(Theme.bodyFont)
                                    .foregroundColor(npc.isVampire ? Theme.primaryColor : Theme.textColor)
                                Text(npc.name)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textColor)
                                Image(systemName: npc.profession.icon)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(npc.profession.color)
                                Text(npc.profession.rawValue)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(npc.profession.color)

                                Spacer()
                                Text("Age \(npc.age)")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textColor)
                            }
                            .padding(.top, 5)
                            .padding(.horizontal, 5)
                            
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
                                    .frame(maxWidth: .infinity)
                                    .shadow(color: Theme.bloodProgressColor.opacity(0.3), radius: 2)
                            }
                            .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 2) {
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
                            .padding(.top, 2)
                        }
                        .padding(.horizontal, 5)
                    }
                }
    
                HStack(spacing: 6) {
                    if !npc.isUnknown {
                        if showCurrentActivity {
                            Image(systemName: npc.currentActivity.icon)
                                .foregroundColor(npc.currentActivity.color)
                                .font(Theme.bodyFont)
                                .padding(.leading, 3)
                            Text(npc.currentActivity.description)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textColor)
                        }
                        
                        if npc.isSpecialBehaviorSet {
                            Text(getSpecialBehaviorProgress())
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.bloodProgressColor)
                        }
                    }
                    Image(systemName: npc.morality.icon)
                        .font(Theme.bodyFont)
                        .foregroundColor(npc.morality.color)
                    Text(npc.morality.description)
                        .font(Theme.bodyFont)
                        .foregroundColor(npc.morality.color)
                    Image(systemName: npc.motivation.icon)
                        .font(Theme.bodyFont)
                        .foregroundColor(npc.motivation.color)
                    Text(npc.motivation.description)
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textColor)
                }
                .padding(.bottom, 5)
                .padding(.top, 2)
                .padding(.horizontal, 5)
            }
            .padding(5)
            
            if !showCurrentActivity {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.awarenessProgressColor, lineWidth: 1)
                    .blur(radius: 0.5)
            }
        }
        .frame(height: 120)
        .cornerRadius(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .blur(radius: 2)
                .offset(y: 2)
        )
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
        return "\(Float(npc.specialBehaviorTime) / 4.0 * 100)%"
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
