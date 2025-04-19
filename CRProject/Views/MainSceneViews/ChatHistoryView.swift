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
    let message: String  // Non-optional
    let icon: String?
    let iconColor: Color?
    let type: MessageType
    
    // Add this initializer to handle optional strings
    init(timestampHour: Int,
         timestampDay: Int,
         timestampHourString: String,
         message: String?,
         icon: String? = nil,// Optional input
         iconColor: Color? = nil,
         type: MessageType) {
        self.timestampHour = timestampHour
        self.timestampDay = timestampDay
        self.timestampHourString = timestampHourString
        self.message = message ?? ""  // Convert to non-optional
        self.type = type
        self.icon = icon
        self.iconColor = iconColor
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    @State private var isAppearing = false
    
    private var typeColor: Color {
        switch message.type {
        case .common: return Theme.textColor
        case .warning: return .yellow
        case .system: return .blue
        case .dialogue: return .green
        case .event: return .orange
        case .danger: return .red
        }
    }
    
    var body: some View {
        HStack(alignment: .top) {
            if message.icon != nil {
                Image(systemName: message.icon!)
                    .foregroundColor(message.iconColor ?? typeColor)
                    .font(Theme.smallFont)
            }
            Text(message.timestampHourString)
                .font(Theme.smallFont)
            
            Text(message.message)
                .font(Theme.smallFont)
                .foregroundColor(typeColor.opacity(0.9))
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
        VStack {
            // Header with clear button
            HStack {
                Text("History")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textColor)
            }
            .padding(.horizontal, 8)
            
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(eventsBus.messages) { message in
                            ChatMessageView(message: message)
                                .padding(.horizontal, 8)
                                .id(message.id)
                                .transition(
                                    .asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity
                                    )
                                )
                        }
                    }
                    .padding(.vertical, 4)
                    .animation(.spring(), value: eventsBus.messages.count)
                }
                .onChange(of: eventsBus.messages.count) { _ in
                    if let last = eventsBus.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 4)
        .padding(.top, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.82))
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                .opacity(0.9)
        )
    }
}
