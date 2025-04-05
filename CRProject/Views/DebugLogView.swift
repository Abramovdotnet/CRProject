import SwiftUI

struct DebugLogView: View {
    @State private var logs: [DebugLogMessage] = []
    @State private var selectedCategory: String? = nil
    @State private var timer: Timer?
    @State private var scrollProxy: ScrollViewProxy?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 4) {
                // Header with title and categories
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Debug")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    
                    categoriesView
                }
                
                // Logs
                logsView
            }
            .frame(maxHeight: geometry.size.height / 3)
            .background(Color.black.opacity(0.7))
            .cornerRadius(8)
            .padding(.horizontal, 8)
            .padding(.top, 4)
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
    
    private var categoriesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(DebugLogService.shared.getCategories(), id: \.self) { category in
                    Button(action: { toggleCategory(category) }) {
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
            .padding(.bottom, 2)
        }
    }
    
    private var logsView: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(filteredLogs) { log in
                        logEntryView(log)
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
    
    private func logEntryView(_ log: DebugLogMessage) -> some View {
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
    }
    
    private func toggleCategory(_ category: String) {
        selectedCategory = selectedCategory == category ? nil : category
    }
    
    private func scrollToBottom() {
        if let lastLog = filteredLogs.last {
            withAnimation {
                scrollProxy?.scrollTo(lastLog.id, anchor: .bottom)
            }
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