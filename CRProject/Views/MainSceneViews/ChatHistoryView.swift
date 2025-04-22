import Combine
import SwiftUI
import SwiftUICore
import Foundation

enum MessageType: String, CaseIterable {
    case common
    case warning
    case system
    case dialogue
    case event
    case danger
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let timestampHour: Int
    let timestampDay: Int
    let timestampHourString: String
    let message: String
    let type: MessageType
    let location: String?
    let player: Player?
    let primaryNPC: NPC?
    let secondaryNPC: NPC?
    let interactionType: NPCInteraction?
    let hasSuccess: Bool
    let isSuccess: Bool?
    let isDiscussion: Bool
    let messageLocation: String?
    let rumorInteractionType: NPCInteraction?
    let rumorPrimaryNPC: NPC?
    let rumorSecondaryNPC: NPC?
    
    init(
        timestampHour: Int,
        timestampDay: Int,
        timestampHourString: String,
        message: String?,
        type: MessageType,
        location: String? = nil,
        player: Player? = nil,
        primaryNPC: NPC? = nil,
        secondaryNPC: NPC? = nil,
        interactionType: NPCInteraction? = nil,
        hasSuccess: Bool = false,
        isSuccess: Bool? = nil,
        isDiscussion: Bool = false,
        messageLocation: String? = nil,
        rumorInteractionType: NPCInteraction? = nil,
        rumorPrimaryNPC: NPC? = nil,
        rumorSecondaryNPC: NPC? = nil
    ) {
        self.timestampHour = timestampHour
        self.timestampDay = timestampDay
        self.timestampHourString = timestampHourString
        self.message = message ?? ""
        self.type = type
        self.location = location
        self.player = player
        self.primaryNPC = primaryNPC
        self.secondaryNPC = secondaryNPC
        self.interactionType = interactionType
        self.hasSuccess = hasSuccess
        self.isSuccess = isSuccess
        self.isDiscussion = isDiscussion
        self.messageLocation = messageLocation
        self.rumorInteractionType = rumorInteractionType
        self.rumorPrimaryNPC = rumorPrimaryNPC
        self.rumorSecondaryNPC = rumorSecondaryNPC
    }
}

struct NPCIconView: View {
    let npc: NPC
    
    var body: some View {
        HStack(spacing: 4) {
            Text(npc.name)
                .font(Theme.smallFont)
                .foregroundColor(Theme.textColor)
        }
    }
}

struct InteractionIconView: View {
    let type: NPCInteraction
    let hasSuccess: Bool
    let isSuccess: Bool?
    
    var body: some View {
        HStack(spacing: 4) {
            if hasSuccess {
                Text("[\(isSuccess == true ? "Successfuly" : "Unsuccessfuly")] ")
                    .font(Theme.smallFont)
                    .foregroundColor(isSuccess == true ? Color.green : Color.red)
                +
                Text(Image(systemName: type.icon))
                    .font(Theme.smallFont)
                    .foregroundColor(type.color)
                +
                Text(" [\(type.description.capitalized)]")
                    .font(Theme.smallFont)
                    .foregroundColor(type.color)
            } else {
                Text(Image(systemName: type.icon))
                    .font(Theme.smallFont)
                    .foregroundColor(type.color)
                +
                Text(" [\(type.description.capitalized)]")
                    .font(Theme.smallFont)
                    .foregroundColor(type.color)
            }
        }
        .font(Theme.smallFont)
    }
}

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
            .font(Theme.smallFont)
            .foregroundColor(Theme.textColor)

        if !message.message.isEmpty {
            return timestampText + Text(message.message)
                .font(Theme.smallFont)
                .foregroundColor(typeColor)
        } else if message.isDiscussion, let interactionType = message.rumorInteractionType {
            let baseText = timestampText + Text("\(message.primaryNPC?.name ?? "") discussed with \(message.secondaryNPC?.name ?? "") how \(message.rumorPrimaryNPC?.name ?? "") ")
                .font(Theme.smallFont)
                .foregroundColor(Theme.textColor)

            let interactionIconText = Text(Image(systemName: interactionType.icon))
                .font(Theme.smallFont)
                .foregroundColor(interactionType.color)

            let interactionDescText = Text(" [\(interactionType.description.capitalized)] ")
                .font(Theme.smallFont)
                .foregroundColor(interactionType.color)

            let secondaryRumorText = Text("\(message.rumorSecondaryNPC?.name ?? "") at ")
                .font(Theme.smallFont)
                .foregroundColor(Theme.textColor)

            let locationText = Text("\(message.messageLocation ?? "")")
                .font(Theme.smallFont)
                .foregroundColor(.yellow)

            return baseText + interactionIconText + interactionDescText + secondaryRumorText + locationText
        } else if let interactionType = message.interactionType {
            var combinedText = timestampText + Text("\(message.primaryNPC?.name ?? "") ")
                .font(Theme.smallFont)
                .foregroundColor(Theme.textColor)

            if message.hasSuccess {
                combinedText = combinedText + Text("[\(message.isSuccess == true ? "Successfully" : "Unsuccessfully")] ")
                    .font(Theme.smallFont)
                    .foregroundColor(message.isSuccess == true ? Color.green : Color.red)
            }

            if interactionType.hasCoinsExchange {
                combinedText = combinedText + Text(Image(systemName: "cedisign"))
                    .font(Theme.smallFont)
                    .foregroundColor(Color.green) + Text(" ")
            }

            combinedText = combinedText + Text(Image(systemName: interactionType.icon))
                .font(Theme.smallFont)
                .foregroundColor(interactionType.color)

            combinedText = combinedText + Text(" [\(interactionType.description.capitalized)] ")
                .font(Theme.smallFont)
                .foregroundColor(interactionType.color)

            if let secondaryNPC = message.secondaryNPC {
                combinedText = combinedText + Text(secondaryNPC.name)
                    .font(Theme.smallFont)
                    .foregroundColor(Theme.textColor)
            }
            return combinedText
        } else {
            return timestampText
        }
    }
    
    private func buildPlayerMessageText() -> Text {
        let timestampText = Text("\(message.timestampHourString) ")
            .font(Theme.smallFont)
            .foregroundColor(Theme.textColor)

        if !message.message.isEmpty {
            return timestampText + Text(message.message)
                .font(Theme.smallFont)
                .foregroundColor(typeColor)
        } else if message.isDiscussion, let interactionType = message.rumorInteractionType {
            let baseText = timestampText + Text("\(message.player?.name ?? "") discussed with \(message.secondaryNPC?.name ?? "") how \(message.rumorPrimaryNPC?.name ?? "") ")
                .font(Theme.smallFont)
                .foregroundColor(Theme.textColor)

            let interactionIconText = Text(Image(systemName: interactionType.icon))
                .font(Theme.smallFont)
                .foregroundColor(interactionType.color)

            let interactionDescText = Text(" [\(interactionType.description.capitalized)] ")
                .font(Theme.smallFont)
                .foregroundColor(interactionType.color)

            let secondaryRumorText = Text("\(message.rumorSecondaryNPC?.name ?? "") at ")
                .font(Theme.smallFont)
                .foregroundColor(Theme.textColor)

            let locationText = Text("\(message.messageLocation ?? "")")
                .font(Theme.smallFont)
                .foregroundColor(.yellow)

            return baseText + interactionIconText + interactionDescText + secondaryRumorText + locationText
        } else if let interactionType = message.interactionType {
            var combinedText = timestampText + Text("\(message.player?.name ?? "") ")
                .font(Theme.smallFont)
                .foregroundColor(Theme.textColor)

            if message.hasSuccess {
                combinedText = combinedText + Text("[\(message.isSuccess == true ? "Successfully" : "Unsuccessfully")] ")
                    .font(Theme.smallFont)
                    .foregroundColor(message.isSuccess == true ? Color.green : Color.red)
            }

            if interactionType.hasCoinsExchange {
                combinedText = combinedText + Text(Image(systemName: "cedisign"))
                    .font(Theme.smallFont)
                    .foregroundColor(Color.green) + Text(" ")
            }

            combinedText = combinedText + Text(Image(systemName: interactionType.icon))
                .font(Theme.smallFont)
                .foregroundColor(interactionType.color)

            combinedText = combinedText + Text(" [\(interactionType.description.capitalized)] ")
                .font(Theme.smallFont)
                .foregroundColor(interactionType.color)

            if let secondaryNPC = message.secondaryNPC {
                combinedText = combinedText + Text(secondaryNPC.name)
                    .font(Theme.smallFont)
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
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(isHovered ? 0.4 : 0.2))
        )
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

struct ChatHistoryView: View {
    @ObservedObject var eventsBus: GameEventsBusService
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(eventsBus.messages) { message in
                            ChatMessageView(message: message)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                ))
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                }
                .onChange(of: eventsBus.messages.count) { _ in
                    if let last = eventsBus.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            .clipShape(Rectangle()) // Fix for scrolling issue
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.75))
        )
    }
}
