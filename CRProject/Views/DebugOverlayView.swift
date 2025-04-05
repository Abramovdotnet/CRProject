import SwiftUI

struct DebugOverlayView: View {
    @ObservedObject var viewModel: MainSceneViewModel
    @State private var selectedCategory: String? = nil
    @State private var logs: [DebugLogMessage] = []
    @State private var timer: Timer?
    @State private var scrollProxy: ScrollViewProxy?
    
    var body: some View {
        GeometryReader { geometry in
            if viewModel.isDebugOverlayVisible {
                VStack(alignment: .leading, spacing: 4) {
                    // Header with title and close button
                    HStack {
                        Text("Debug Overlay")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {
                            viewModel.toggleDebugOverlay()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(DebugLogService.shared.getCategories(), id: \.self) { category in
                                Button(action: {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }) {
                                    Text(category)
                                        .font(.system(size: 8))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(selectedCategory == category ? Color.blue : Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    
                    // Logs
                    ScrollView {
                        ScrollViewReader { proxy in
                            LazyVStack(alignment: .leading, spacing: 1) {
                                ForEach(filteredLogs) { log in
                                    HStack(alignment: .top, spacing: 4) {
                                        Text(log.timestamp)
                                            .font(.system(size: 8))
                                            .foregroundColor(.gray)
                                        
                                        Text(log.category)
                                            .font(.system(size: 8))
                                            .foregroundColor(categoryColor(log.category))
                                            .padding(.horizontal, 3)
                                            .background(categoryColor(log.category).opacity(0.2))
                                            .cornerRadius(2)
                                        
                                        Text(log.message)
                                            .font(.system(size: 8))
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 1)
                                    .id(log.id)
                                }
                            }
                            .onAppear {
                                scrollProxy = proxy
                                scrollToBottom()
                            }
                        }
                    }
                }
                .frame(maxHeight: geometry.size.height / 2)
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }
        }
        .onAppear {
            startLogUpdates()
        }
        .onDisappear {
            stopLogUpdates()
        }
        .onChange(of: logs) { _ in
            scrollToBottom()
        }
    }
    
    private var filteredLogs: [DebugLogMessage] {
        if let category = selectedCategory {
            return logs.filter { $0.category == category }
        }
        return logs
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Error": return .red
        case "Warning": return .orange
        case "Location": return .blue
        case "NPC": return .purple
        case "Dialogue": return .green
        case "Debug": return .gray
        case "Dependency": return .yellow
        case "Scene": return .cyan
        default: return .white
        }
    }
    
    private func scrollToBottom() {
        if let lastLog = filteredLogs.last {
            withAnimation {
                scrollProxy?.scrollTo(lastLog.id, anchor: .bottom)
            }
        }
    }
    
    private func startLogUpdates() {
        updateLogs()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateLogs()
        }
    }
    
    private func stopLogUpdates() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateLogs() {
        logs = DebugLogService.shared.getLogs()
    }
}

// Add this to your main view to use the debug overlay
extension View {
    func withDebugOverlay(viewModel: MainSceneViewModel) -> some View {
        ZStack {
            self
            DebugOverlayView(viewModel: viewModel)
        }
    }
} 