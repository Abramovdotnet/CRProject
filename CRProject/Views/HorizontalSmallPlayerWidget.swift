import SwiftUICore
import SwiftUI

struct HorizontalSmallPlayerWidget: View {
    let player: Player

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.9),
                            Color(player.profession.color).opacity(0.05)
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
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Image(systemName: player.sex == .female ? "figure.stand.dress" : "figure.wave")
                                .font(Theme.bodyFont)
                                .foregroundColor(player.isVampire ? Theme.primaryColor : Theme.textColor)
                            Text(player.name)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textColor)
                            Image(systemName: player.profession.icon)
                                .font(Theme.bodyFont)
                                .foregroundColor(player.profession.color)
                            Text(player.profession.rawValue)
                                .font(Theme.bodyFont)
                                .foregroundColor(player.profession.color)
                        }
                        .padding(5)
                    }
                    .padding(5)
                }
            }
            .padding(5)
            
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.bloodProgressColor.opacity(0.8), lineWidth: 2)
                .background(Color.white.opacity(0.05))
                .blur(radius: 0.5)
        }
        .frame(height: 25)
        .cornerRadius(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.3))
                .blur(radius: 2)
                .offset(y: 2)
        )
        .shadow(color: Theme.bloodProgressColor.opacity(0.5), radius: 15)
    }
}
