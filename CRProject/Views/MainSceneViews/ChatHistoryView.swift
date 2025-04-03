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
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let timestampHour: Int
    let timestampDay: Int
    let timestampHourString: String
    let message: String  // Non-optional
    let type: MessageType
    
    // Add this initializer to handle optional strings
    init(timestampHour: Int,
         timestampDay: Int,
         timestampHourString: String,
         message: String?,  // Optional input
         type: MessageType) {
        self.timestampHour = timestampHour
        self.timestampDay = timestampDay
        self.timestampHourString = timestampHourString
        self.message = message ?? ""  // Convert to non-optional
        self.type = type
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
        }
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Text(message.timestampHourString)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray)
            
            Text(message.message)
                .font(.caption)
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
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textColor)
            }
            .padding(.top, 8)
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.secondaryColor.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                .opacity(0.9)
        )
    }
}
