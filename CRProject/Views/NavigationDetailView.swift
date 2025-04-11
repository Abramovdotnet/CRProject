import SwiftUI

struct NavigationDetailView: View {
    @ObservedObject var viewModel: MainSceneViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var offset: CGPoint = .zero
    @State private var scale: CGFloat = 0.8
    
    private let bloodCostPerMove: Int = 5
    private let minBloodThreshold: Int = 10 // 10% threshold
    private let maxOffset: CGFloat = 200
    private let dragSensitivity: CGFloat = 0.45  // Reduced to 45% for more precise control
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Navigation Web
                NavigationWebView(
                    viewModel: viewModel,
                    offset: $offset,
                    scale: $scale,
                    geometry: geometry,
                    onLocationSelected: { location in
                        if canTravelTo(location) {
                            viewModel.navigateToLocation(location)
                        }
                    }
                )
                
                // Header with safe area for dismiss gesture
                VStack {
                    NavigationHeader(dismiss: dismiss)
                        .frame(height: 44)
                        .background(Color.black.opacity(0.7))
                    
                    if viewModel.playerBloodPercentage <= 30 {
                        BloodWarningBanner(currentBlood: Int(viewModel.playerBloodPercentage))
                    }
                    
                    Spacer()
                }
                
                // Controls Overlay
                VStack {
                    Spacer()
                    NavigationControls(scale: $scale, offset: $offset, maxOffset: 200)
                        .padding(.bottom, 8)
                }
            }
        }
        .background(Color.black.opacity(0.001))  // Prevent scroll-through
        .interactiveDismissDisabled(true)  // Disable interactive dismiss
    }
    
    private func canTravelTo(_ location: Scene) -> Bool {
        return viewModel.isLocationAccessible(location)
    }
}

// MARK: - Supporting Views
struct NavigationWebView: View {
    @ObservedObject var viewModel: MainSceneViewModel
    @ObservedObject var vampireNatureRevealService: VampireNatureRevealService = DependencyManager.shared.resolve()
    @Binding var offset: CGPoint
    @Binding var scale: CGFloat
    let geometry: GeometryProxy
    let onLocationSelected: (Scene) -> Void
    
    // Layout constants
    private let maxChildNodes = 10
    private let maxSiblingNodes = 10
    private let margin: CGFloat = 50
    
    // Current position always at center
    private var currentPosition: CGPoint {
        CGPoint(x: geometry.size.width/2, y: (geometry.size.height/2) + 10)
    }
    
    var body: some View {
        Color.clear
            .overlay(
                ZStack {
                    Image("MainSceneBackground")
                        .resizable()
                        .ignoresSafeArea()
                    
                    // Map content in a ZStack with content scaled and offset
                    ZStack {
                        // Connection lines
                        ForEach(connections) { connection in
                            StraightConnectionLine(connection: connection)
                        }
                        
                        // Location nodes
                        ForEach(viewModel.allVisibleScenes) { location in
                            let nodeData = LocationNodeData(
                                location: location,
                                currentLocation: viewModel.currentScene,
                                playerBlood: Int(viewModel.playerBloodPercentage),
                                awarenessLevel: Int(vampireNatureRevealService.getAwareness(for: location.id)),
                                onSelected: { onLocationSelected(location) }
                            )
                            if let position = relativePosition(for: location) {
                                VStack{
                                    LocationNode(data: nodeData)
                                    .position(position)
                                    .zIndex(location.id == viewModel.currentScene?.id ? 100 : 1)
                                }
                            }
                        }
                    }
                    .offset(x: offset.x, y: offset.y)
                    .scaleEffect(scale)
                    
                    // Top widget overlay that stays fixed at the top
                    VStack {
                        TopWidgetView(viewModel: viewModel)
                            .frame(maxWidth: .infinity)
                            .padding(.top, geometry.safeAreaInsets.top)
                            .foregroundColor(Theme.textColor)
                        
                        HStack {
                            Image(systemName: viewModel.parentScene?.sceneType.iconName ?? "")
                                .font(Theme.titleFont) // Slightly smaller for better fit
                                .foregroundColor(Theme.textColor)
                            Text(viewModel.parentScene?.name ?? "")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textColor)
                            Spacer()
                    
                        }
                        Spacer()
                    }
                }
            )
            .onChange(of: viewModel.currentScene?.id) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    offset = .zero // Reset offset on location change
                }
            }
    }
    
    // Calculate position relative to current node's center
    private func relativePosition(for location: Scene) -> CGPoint? {
        guard let current = viewModel.currentScene else { return nil }
        
        if location.id == current.id {
            return currentPosition
        }
        
        let allSiblings = viewModel.siblingScenes + (current.hubSceneIds.compactMap { id in
            try? LocationReader.getLocation(by: id)
        })

        if allSiblings.contains(where: { $0.id == location.id }) {
            let innerCircleSiblings = Array(allSiblings.prefix(8)) // First 8 in inner circle
            let outerCircleSiblings = Array(allSiblings.dropFirst(8)) // Rest in outer circle
            
            // Check if location is in inner circle
            if let index = innerCircleSiblings.firstIndex(where: { $0.id == location.id }) {
                let angle = 2 * .pi / CGFloat(innerCircleSiblings.count) * CGFloat(index)
                let radius = geometry.size.height * 0.3
                return CGPoint(
                    x: currentPosition.x + cos(angle) * radius * 1.2,
                    y: currentPosition.y + sin(angle) * radius * 1.3
                )
            }
            // Check if location is in outer circle
            else if let index = outerCircleSiblings.firstIndex(where: { $0.id == location.id }) {
                let angle = 2 * .pi / CGFloat(outerCircleSiblings.count) * CGFloat(index)
                let radius = geometry.size.height * 0.42
                return CGPoint(
                    x: currentPosition.x + cos(angle) * radius * 2,
                    y: currentPosition.y + sin(angle) * radius * 0.95
                )
            }
        }
        
        return nil
    }
    
    private var connections: [Connection] {
        var connections = [Connection]()
        guard let current = viewModel.currentScene,
              let currentPos = relativePosition(for: current) else {
            return connections
        }
        
        // Connect to children (radial lines)
        for child in viewModel.childScenes.prefix(maxChildNodes) {
            if let childPos = relativePosition(for: child) {
                connections.append(Connection(
                    from: currentPos,
                    to: childPos,
                    awareness: 1.0,
                    isChildConnection: true
                ))
            }
        }
        
        // Connect to siblings and hub locations (radial lines)
        let allSiblings = viewModel.siblingScenes + (current.hubSceneIds.compactMap { id in
            try? LocationReader.getLocation(by: id)
        })
        for sibling in allSiblings.prefix(maxSiblingNodes) {
            if let siblingPos = relativePosition(for: sibling) {
                connections.append(Connection(
                    from: currentPos,
                    to: siblingPos,
                    awareness: 1.0,
                    isSiblingConnection: true
                ))
            }
        }
        
        return connections
    }
}

struct LocationNodeData {
    let location: Scene
    let currentLocation: Scene?
    let playerBlood: Int
    let awarenessLevel: Int
    
    let onSelected: () -> Void
}
struct LocationNode: View {
    let data: LocationNodeData
    
    private var isAccessible: Bool {
        guard data.location.id != data.currentLocation?.id else { return false }  // Disable current location
        return (data.playerBlood - 5) >= 10
    }
    
    private var relationshipIcon: String {
        if data.location.id == data.currentLocation?.parentSceneId {
            return "arrow.up.circle.fill"  // Parent
        } else if data.location.parentSceneId == data.currentLocation?.id {
            return "arrow.down.circle.fill"  // Child
        } else if data.location.parentSceneId == data.currentLocation?.parentSceneId {
            return "arrow.left.and.right.circle.fill"  // Sibling
        }
        return data.location.isIndoor ? "house.circle.fill" : "tree.circle.fill"
    }
    
    var body: some View {
        VStack{
            Button(action: data.onSelected) {
                ZStack {
                    Image("iconFrame")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70 * 1.05, height: 70 * 1.05)
                    Circle()
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 70 * 0.9, height: 70 * 0.9)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    Image("roundStoneTexture")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70 * 0.8, height: 70 * 0.8)
                    
                    VStack{
                        HStack{
                            Image(systemName: data.location.sceneType.iconName)
                                .font(Theme.smallFont) // Slightly smaller for better fit
                                .foregroundColor(iconColor)
                            Text(data.location.sceneType.displayName)
                                .font(Theme.smallFont)
                                .foregroundColor(Theme.textColor)
                                .padding(.leading, -5)
                        }
                        .padding(.top, needToShowNavigateIcon() ? -7 : 0)
                        Text(data.location.name)
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textColor)
                        
                        HStack {
                            ZStack{
                                Rectangle()
                                    .foregroundColor(.black.opacity(0.8))
                                    .frame(width: 50, height: 8)
                                    .cornerRadius(4)
                            
                                HStack(spacing:1) {
                                    ForEach(0..<5) { index in
                                        let segmentValue = Double(data.awarenessLevel) / 100.0
                                        let segmentThreshold = Double(index + 1) / 10.0
                                        
                                        Rectangle()
                                            .fill(segmentValue >= segmentThreshold ?
                                                  Theme.awarenessProgressColor : Theme.textColor.opacity(0.5))
                                            .frame(height: 5)
                                    }
                                }.padding(.horizontal, 2)
                            }
    
                        }
                        .frame(width: 50)
                        .padding(.top, -5)
                        
                        Text("Awareness")
                            .font(Theme.smallFont)
                            .foregroundColor(Theme.textColor)
                            .padding(.top, -8)
                            .padding(.bottom, 3)
 
                        if needToShowNavigateIcon() {
                            HStack {
                                Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
                                     .foregroundColor(Theme.accentColor)
                                     .font(Theme.smallFont)
                                Text(navigationLabel())
                                   .font(Theme.smallFont)
                                   .foregroundColor(Theme.textColor)
                                   .padding(.leading, -5)
                            }
              
                        }
                    }
                    .padding(.top, needToShowNavigateIcon() ? 35 : 10)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Circle())
                .shadow(color: .black, radius: 3, x: 0, y: 2)
            }
        }
        .disabled(!isAccessible)
        .opacity(data.location.id == data.currentLocation?.id ? 1.0 : isAccessible ? 1.0 : 0.4)  // More contrast for inaccessible nodes
    }
    
    func needToShowNavigateIcon() -> Bool {
        return data.location.hubSceneIds.count > 0 && data.location.id != data.currentLocation?.id
    }
    
    func navigationLabel() -> String {
        if data.location.parentSceneId == 0 {
            return "Visit"
        } else if data.location.sceneType != .road {
            return "To \(data.location.parentSceneName)"
        } else {
            return data.currentLocation?.parentSceneId == data.location.parentSceneId ? "Back" : "To houses"
        }
    }
    
    func relationshipLabel() -> String {
        if data.location.id == data.currentLocation?.id {
            return "Current"
        } else if data.location.id == data.currentLocation?.parentSceneId {
            return "Parent"
        } else if data.location.parentSceneId == data.currentLocation?.id {
            return "Child"
        } else if data.location.parentSceneId == data.currentLocation?.parentSceneId {
            return "Sibling"
        }
        return ""
    }
    
    private var backgroundStyle: Color {
        if data.location.id == data.currentLocation?.id {
            return Theme.primaryColor
        }
        if data.location.id == data.currentLocation?.parentSceneId {
            return Theme.secondaryColor  // Full opacity for parent
        }
        if data.location.parentSceneId == data.currentLocation?.id {
            return Theme.secondaryColor.opacity(0.8)  // Slightly more opaque for children
        }
        return isAccessible ? Theme.secondaryColor.opacity(0.7) : Theme.secondaryColor.opacity(0.4)
    }
    
    private var borderStyle: Color {
        if relationshipLabel() == "Parent" {
            return .blue
        } else if relationshipLabel() == "Sibling" {
            return .purple
        } else if relationshipLabel() == "Child" {
            return .green
        }
        return isAccessible ? Theme.primaryColor : Theme.primaryColor.opacity(0.3)
    }
    
    private var iconColor: Color {
        if relationshipLabel() == "Parent" {
            return Color.blue
        } else if relationshipLabel() == "Sibling" {
            return Color.purple
        } else if relationshipLabel() == "Child" {
            return Color.green
        }
        return Color.red
    }
    
    private var shadowColor: Color {
        if relationshipLabel() == "Parent" {
            return Color.blue.opacity(0.5)
        } else if relationshipLabel() == "Sibling" {
            return Color.purple.opacity(0.5)
        } else if relationshipLabel() == "Child" {
            return Color.green.opacity(0.5)
        }
        return Color.red.opacity(0.5)
    }
}

private struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    let awareness: Float
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(style: StrokeStyle(
            lineWidth: 3,  // Increased line width
            lineCap: .round,
            lineJoin: .round,
            dash: [8, 4]  // Adjusted dash pattern
        ))
        .shadow(color: Theme.primaryColor.opacity(0.3), radius: 4)  // Added subtle glow
        .foregroundColor(Theme.primaryColor.opacity(Double(awareness)))
    }
}

private struct NavigationHeader: View {
    let dismiss: DismissAction
    
    var body: some View {
        HStack {
            Text("Navigation Map")
                .font(.title)
                .foregroundColor(.white)
                .padding(.leading)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .padding(.trailing)
        }
    }
}

private struct BloodWarningBanner: View {
    let currentBlood: Int
    
    var body: some View {
                HStack {
            Image(systemName: "drop.fill")
                .foregroundColor(.red)
            Text("Low Blood Warning: \(currentBlood)%")
                .font(Theme.bodyFont)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.black.opacity(0.7))
    }
}

private struct NavigationControls: View {
    @Binding var scale: CGFloat
    @Binding var offset: CGPoint
    let maxOffset: CGFloat
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { scale = max(0.5, scale - 0.1) }) {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
            }
            
            Button(action: {
                withAnimation(.spring()) {
                    scale = 0.8  // Reset to default scale
                    offset = .zero
                }
            }) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title3)
            }
            
            Button(action: { scale = min(1.2, scale + 0.1) }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(16)
    }
}

// MARK: - Helper Extensions

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

extension MainSceneViewModel {
    var allLocations: [Scene] {
        var locations: [Scene] = []
        guard let current = currentScene else { return locations }
        
        // Add current scene
        locations.append(current)
        
        // Add immediate siblings and hub locations (limit to 6)
        let allSiblings = siblingScenes + (current.hubSceneIds.compactMap { id in
            try? LocationReader.getLocation(by: id)
        })
        locations.append(contentsOf: Array(allSiblings.prefix(6)))
        
        // Add immediate children (limit to 6)
        locations.append(contentsOf: Array(childScenes.prefix(6)))
        
        return locations.uniqued()
    }
    
    var allConnections: [Connection] {
        var connections = [Connection]()
        guard let positions = locationPositions,
              let current = currentScene,
              let currentPos = positions[current.id] else { return connections }
        
        // Add connections to siblings and hub locations
        let allSiblings = siblingScenes + (current.hubSceneIds.compactMap { id in
            try? LocationReader.getLocation(by: id)
        })
        let siblings = Array(allSiblings.prefix(6))
        let leftSiblings = Array(siblings[..<min(3, siblings.count)])
        let rightSiblings = Array(siblings[min(3, siblings.count)...])
        
        // Connect left siblings
        for sibling in leftSiblings {
            if let siblingPos = positions[sibling.id] {
                connections.append(Connection(
                    from: currentPos,
                    to: siblingPos,
                    awareness: 0.8
                ))
            }
        }
        
        // Connect right siblings
        for sibling in rightSiblings {
            if let siblingPos = positions[sibling.id] {
                connections.append(Connection(
                    from: currentPos,
                    to: siblingPos,
                    awareness: 0.8
                ))
            }
        }
        
        // Add connections to children
        let children = Array(childScenes.prefix(6))
        for child in children {
            if let childPos = positions[child.id] {
                connections.append(Connection(
                    from: currentPos,
                    to: childPos,
                    awareness: 0.9
                ))
            }
        }
        
        return connections
    }
    
    func navigateToLocation(_ location: Scene) {
        if location.id == parentScene?.id {
            navigateToParent()
        } else if childScenes.contains(where: { $0.id == location.id }) {
            navigateToChild(location)
        } else if siblingScenes.contains(where: { $0.id == location.id }) {
            navigateToSibling(location)
        } else if let current = currentScene, current.hubSceneIds.contains(location.id) {
            navigateToSibling(location)
        }
        objectWillChange.send()
    }
}

// Helper extension to remove duplicates from array
extension Array where Element: Identifiable {
    func uniqued() -> [Element] {
        var seen = Set<Element.ID>()
        return filter { seen.insert($0.id).inserted }
    }
}

#Preview {
    NavigationDetailView(viewModel: MainSceneViewModel())
}
