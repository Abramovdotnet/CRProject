//
//  PlayerWidget.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 23.04.2025.
//

import SwiftUICore

struct PlayerWidget : View {
    let player: Player
 
    private let buttonWidth: CGFloat = 180

    var body: some View {
        ZStack(alignment: .top) {
            // Background
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
                .frame(width: buttonWidth, height: 320)
            
            // Content (Image and Text)
            VStack(alignment: .leading, spacing: 0) {
                // Image container with parallax
                ZStack {
                    Image("player1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: buttonWidth, height: 180)
                        .clipped() // Add clipping after the frame
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                }
                .frame(width: buttonWidth, height: 180)
                .background(Color.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: player.sex == .female ? "figure.stand.dress" : "figure.wave")
                            .font(Theme.bodyFont)
                            .foregroundColor(player.isVampire ? Theme.primaryColor : Theme.textColor)
                        Text(player.name)
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textColor)
                        Spacer()
                        Text("Age \(player.age)")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textColor)
                    }
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top) {
                            Text("Health")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textColor)
                            Spacer()
                            Text(String(format: "%.1f%%", player.bloodMeter.currentBlood))
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.bloodProgressColor)
                        }
                        
                        ProgressBar(value: Double(player.bloodMeter.currentBlood / 100), color: Theme.bloodProgressColor, height: 6)
           
                            .shadow(color: Theme.bloodProgressColor.opacity(0.3), radius: 2)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
            }
            
            VStack(alignment: .trailing) {
                Spacer()
                VStack {
                    HStack {
                        Image(systemName: player.profession.icon)
                            .font(Theme.bodyFont)
                            .foregroundColor(player.profession.color)
                            .lineLimit(1)
                        Text("\(player.profession.rawValue)")
                            .font(Theme.bodyFont)
                            .foregroundColor(player.profession.color)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.bottom, 6)
            .padding(.top, 2)
            .padding(.horizontal, 8)
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.bloodProgressColor.opacity(0.8), lineWidth: 2)
                .background(Color.white.opacity(0.05))
                .blur(radius: 0.5)
        }
        .frame(width: buttonWidth, height: 320)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.9))
                .blur(radius: 2)
                .offset(y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
