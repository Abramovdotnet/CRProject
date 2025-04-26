//
//  ChatMessageView.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 26.04.2025.
//


import Combine
import SwiftUI
import SwiftUICore
import Foundation

struct ChatMessageView: View {
    let message: ChatMessage
    @State private var isHovered = false
    @State private var isAppearing = false
    
    private var typeColor: Color {
        switch message.type {
        case .common: return .white.opacity(0.9)
        case .warning: return .yellow.opacity(0.9)
        case .system: return .blue.opacity(0.9)
        case .dialogue: return .green.opacity(0.9)
        case .event: return Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.9)
        case .danger: return .red.opacity(0.9)
        }
    }
    
    private func buildMessageText() -> Text {
        let timestampText = Text("\(message.timestampHourString) ")
            .font(Theme.bodyFont)
            .foregroundColor(Theme.textColor)

        if !message.message.isEmpty {
            return timestampText + Text(message.message)
                .font(Theme.bodyFont)
                .foregroundColor(typeColor)
        } else if message.isDiscussion, let interactionType = message.rumorInteractionType {
            let baseText = timestampText + Text("\(message.primaryNPC?.name ?? "") discussed with \(message.secondaryNPC?.name ?? "") how \(message.rumorPrimaryNPC?.name ?? "") ")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textColor)

            let interactionIconText = Text(Image(systemName: interactionType.icon))
                .font(Theme.bodyFont)
                .foregroundColor(interactionType.color)

            let interactionDescText = Text(" [\(interactionType.description.capitalized)] ")
                .font(Theme.bodyFont)
                .foregroundColor(Color.yellow.opacity(0.9))

            let secondaryRumorText = Text("\(message.rumorSecondaryNPC?.name ?? "") at ")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textColor)

            let locationText = Text("\(message.messageLocation ?? "")")
                .font(Theme.bodyFont)
                .foregroundColor(Color.yellow.opacity(0.9))

            return baseText + interactionIconText + interactionDescText + secondaryRumorText + locationText
        } else if let interactionType = message.interactionType {
            var combinedText = timestampText + Text("\(message.primaryNPC?.name ?? "") ")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textColor)

            if message.hasSuccess {
                combinedText = combinedText + Text("[\(message.isSuccess == true ? "Successfully" : "Unsuccessfully")] ")
                    .font(Theme.bodyFont)
                    .foregroundColor(message.isSuccess == true ? Color.green : Color.red)
            }

            if interactionType.hasCoinsExchange {
                combinedText = combinedText + Text(Image(systemName: "cedisign"))
                    .font(Theme.bodyFont)
                    .foregroundColor(Color.green) + Text(" ")
            }

            combinedText = combinedText + Text(Image(systemName: interactionType.icon))
                .font(Theme.bodyFont)
                .foregroundColor(interactionType.color)

            combinedText = combinedText + Text(" [\(interactionType.description.capitalized)] ")
                .font(Theme.bodyFont)
                .foregroundColor(Color.yellow.opacity(0.9))

            if let secondaryNPC = message.secondaryNPC {
                combinedText = combinedText + Text(secondaryNPC.name)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textColor)
            }
            return combinedText
        } else {
            return timestampText
        }
    }
    
    private func buildPlayerMessageText() -> Text {
        let timestampText = Text("\(message.timestampHourString) ")
            .font(Theme.bodyFont)
            .foregroundColor(Theme.textColor)

        if !message.message.isEmpty {
            return timestampText + Text(message.message)
                .font(Theme.bodyFont)
                .foregroundColor(typeColor)
        } else if message.isDiscussion, let interactionType = message.rumorInteractionType {
            let baseText = timestampText + Text("\(message.player?.name ?? "") discussed with \(message.secondaryNPC?.name ?? "") how \(message.rumorPrimaryNPC?.name ?? "") ")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textColor)

            let interactionIconText = Text(Image(systemName: interactionType.icon))
                .font(Theme.bodyFont)
                .foregroundColor(interactionType.color)

            let interactionDescText = Text(" [\(interactionType.description.capitalized)] ")
                .font(Theme.bodyFont)
                .foregroundColor(Color.yellow.opacity(0.9))

            let secondaryRumorText = Text("\(message.rumorSecondaryNPC?.name ?? "") at ")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textColor)

            let locationText = Text("\(message.messageLocation ?? "")")
                .font(Theme.bodyFont)
                .foregroundColor(Color.yellow.opacity(0.9))

            return baseText + interactionIconText + interactionDescText + secondaryRumorText + locationText
        } else if let interactionType = message.interactionType {
            var combinedText = timestampText + Text("\(message.player?.name ?? "") ")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textColor)

            if message.hasSuccess {
                combinedText = combinedText + Text("[\(message.isSuccess == true ? "Successfully" : "Unsuccessfully")] ")
                    .font(Theme.bodyFont)
                    .foregroundColor(message.isSuccess == true ? Color.green : Color.red)
            }

            if interactionType.hasCoinsExchange {
                combinedText = combinedText + Text(Image(systemName: "cedisign"))
                    .font(Theme.bodyFont)
                    .foregroundColor(Color.green) + Text(" ")
            }

            combinedText = combinedText + Text(Image(systemName: interactionType.icon))
                .font(Theme.bodyFont)
                .foregroundColor(interactionType.color)

            combinedText = combinedText + Text(" [\(interactionType.description.capitalized)] ")
                .font(Theme.bodyFont)
                .foregroundColor(Color.yellow.opacity(0.9))

            if let secondaryNPC = message.secondaryNPC {
                combinedText = combinedText + Text(secondaryNPC.name)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textColor)
            }
            return combinedText
        } else {
            return timestampText
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if message.player != nil {
                buildPlayerMessageText()
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                buildMessageText()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .opacity(isAppearing ? 1 : 0)
        .offset(y: isAppearing ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isAppearing = true
            }
        }
    }
}