import Combine
import SwiftUI
import SwiftUICore
import Foundation

struct ChatHistoryView: View {
    @ObservedObject var eventsBus: GameEventsBusService
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
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
