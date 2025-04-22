import SwiftUICore
import SwiftUI

struct HorizontalPlayerWidget: View {
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
                    ZStack {
                        Image("player1")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            .padding(5)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Image(systemName: player.sex == .female ? "figure.stand.dress" : "figure.wave")
                                .font(Theme.smallFont)
                                .foregroundColor(player.isVampire ? Theme.primaryColor : Theme.textColor)
                            Text(player.name)
                                .font(Theme.smallFont)
                                .foregroundColor(Theme.textColor)
                            Image(systemName: player.profession.icon)
                                .font(Theme.smallFont)
                                .foregroundColor(player.profession.color)
                            Text(player.profession.rawValue)
                                .font(Theme.smallFont)
                                .foregroundColor(player.profession.color)

                            Spacer()
                            Text("Age \(player.age)")
                                .font(Theme.smallFont)
                                .foregroundColor(Theme.textColor)
                        }
                        .padding(5)
                    }
                    .padding(5)
                }
    
                HStack(spacing: 6) {
                    Text(player.sex.rawValue)
                        .font(Theme.smallFont)
                        .foregroundColor(Theme.textColor)
                    Image(systemName: player.sex == .female ? "figure.stand.dress" : "figure.wave")
                        .font(Theme.smallFont)
                        .foregroundColor(Color.yellow)
                    Text(player.age.description)
                        .font(Theme.smallFont)
                        .foregroundColor(Color.yellow)
                }
                .padding(5)
            }
            .padding(5)
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.bloodProgressColor.opacity(0.8), lineWidth: 2)
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
        .shadow(color: Theme.bloodProgressColor.opacity(0.5), radius: 15)
    }
}
