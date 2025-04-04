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
                Image("MainSceneBackground")
                    .resizable()
                    .ignoresSafeArea()
                
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
    @Binding var offset: CGPoint
    @Binding var scale: CGFloat
    let geometry: GeometryProxy
    let onLocationSelected: (Scene) -> Void
    
    // Layout constants
    private let maxChildNodes = 10
    private let maxSiblingNodes = 10
    private let maxParentSiblingNodes = 10
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
                    
                    // Connection lines
                    ForEach(connections) { connection in
                        StraightConnectionLine(connection: connection)
                    }
                    
                    // Location nodes
                    ForEach(viewModel.allVisibleScenes) { location in
                        if let position = relativePosition(for: location) {
                            VStack{
                                LocationNode(
                                    location: location,
                                    currentLocation: viewModel.currentScene,
                                    playerBlood: Int(viewModel.playerBloodPercentage),
                                    onSelected: { onLocationSelected(location) }
                                )
                                .position(position)
                                .zIndex(location.id == viewModel.currentScene?.id ? 100 : 1)
                            }
                        }
                    }
                }
                .offset(x: offset.x, y: offset.y)
                .scaleEffect(scale)
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
        
        let hasParent = viewModel.parentScene != nil
        let availableWidth = geometry.size.width - margin * 2
        let leftColumnWidth = hasParent ? availableWidth * 0.6 : availableWidth
        
        // Siblings in inner circle
        if viewModel.siblingScenes.contains(where: { $0.id == location.id }) {
            let siblings = Array(viewModel.siblingScenes.prefix(maxSiblingNodes))
            guard let index = siblings.firstIndex(where: { $0.id == location.id }) else { return nil }
            let angle = 2 * .pi / CGFloat(siblings.count) * CGFloat(index)
            let radius = min(leftColumnWidth, geometry.size.height) * 0.22
            return CGPoint(
                x: currentPosition.x + cos(angle) * radius,
                y: currentPosition.y + sin(angle) * radius
            )
        }
        
        // Children in outer circle
        if viewModel.childScenes.contains(where: { $0.id == location.id }) {
            let children = Array(viewModel.childScenes.prefix(maxChildNodes))
            guard let index = children.firstIndex(where: { $0.id == location.id }) else { return nil }
            let angle = 2 * .pi / CGFloat(children.count) * CGFloat(index)
            let radius = min(leftColumnWidth, geometry.size.height) * 0.42
            return CGPoint(
                x: currentPosition.x + cos(angle) * radius,
                y: currentPosition.y + sin(angle) * radius
            )
        }
        
        // Parent in right column center
        if let parent = viewModel.parentScene, location.id == parent.id {
            let rightCenter = CGPoint(
                x: currentPosition.x + (geometry.size.width * 0.3), // 30% into right column
                y: currentPosition.y
            )
            return rightCenter
        }
        
        // Parent siblings in right column circle
        if let parent = viewModel.parentScene,
           LocationReader.getSiblingLocations(for: parent.id).contains(where: { $0.id == location.id }) {
            let parentSiblings = Array(LocationReader.getSiblingLocations(for: parent.id).prefix(maxParentSiblingNodes))
            guard let index = parentSiblings.firstIndex(where: { $0.id == location.id }) else { return nil }
            let rightCenter = CGPoint(
                x: currentPosition.x + (geometry.size.width * 0.3),
                y: currentPosition.y
            )
            let angle = 2 * .pi / CGFloat(parentSiblings.count) * CGFloat(index)
            let radius = min(geometry.size.width * 0.2, geometry.size.height) * 0.35
            return CGPoint(
                x: rightCenter.x + cos(angle) * radius,
                y: rightCenter.y + sin(angle) * radius
            )
        }
        
        return nil
    }
    
    private var connections: [Connection] {
        var connections = [Connection]()
        guard let current = viewModel.currentScene,
              let currentPos = relativePosition(for: current) else {
            return connections
        }
        
        // Connect to parent (straight horizontal line to right)
        if let parent = viewModel.parentScene,
           let parentPos = relativePosition(for: parent) {
            connections.append(Connection(
                from: currentPos,
                to: parentPos,
                awareness: 1.0,
                isParentConnection: true
            ))
        }
        
        // Connect to children (radial lines)
        for child in viewModel.childScenes.prefix(maxChildNodes) {
            if let childPos = relativePosition(for: child) {
                connections.append(Connection(
                    from: currentPos,
                    to: childPos,
                    awareness: 1.0
                ))
            }
        }
        
        // Connect to children (radial lines)
        for sibling in viewModel.siblingScenes.prefix(maxSiblingNodes) {
            if let siblingPos = relativePosition(for: sibling) {
                connections.append(Connection(
                    from: currentPos,
                    to: siblingPos,
                    awareness: 1.0
                ))
            }
        }
        
        return connections
    }
}

struct LocationNode: View {
    let location: Scene
    let currentLocation: Scene?
    let playerBlood: Int

    let onSelected: () -> Void
    
    private var isAccessible: Bool {
        guard location.id != currentLocation?.id else { return false }  // Disable current location
        return (playerBlood - 5) >= 10
    }
    
    private var relationshipIcon: String {
        if location.id == currentLocation?.parentSceneId {
            return "arrow.up.circle.fill"  // Parent
        } else if location.parentSceneId == currentLocation?.id {
            return "arrow.down.circle.fill"  // Child
        } else if location.parentSceneId == currentLocation?.parentSceneId {
            return "arrow.left.and.right.circle.fill"  // Sibling
        }
        return location.isIndoor ? "house.circle.fill" : "tree.circle.fill"
    }
    
    private var relationshipLabel: String {
        if location.id == currentLocation?.id {
            return "Current"
        } else if location.id == currentLocation?.parentSceneId {
            return "Parent"
        } else if location.parentSceneId == currentLocation?.id {
            return "Child"
        } else if location.parentSceneId == currentLocation?.parentSceneId {
            return "Sibling"
        }
        return ""
    }
    
    var body: some View {
        VStack{
            Button(action: onSelected) {
                VStack(spacing: 2) {
                    Image(systemName: location.sceneType.iconName)
                        .font(.system(size: 18)) // Slightly smaller for better fit
                        .foregroundColor(Theme.textColor)
                }
                .frame(width: 40, height: 40) // Slightly larger for better readability
                .background(backgroundStyle)
                .clipShape(Circle())
                .overlay(Circle().stroke(borderStyle, lineWidth: 2))
                .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
            }
            Text(location.name)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textColor)
        }
        .disabled(!isAccessible)
        .opacity(location.id == currentLocation?.id ? 1.0 : isAccessible ? 1.0 : 0.4)  // More contrast for inaccessible nodes
    }
    
    private var backgroundStyle: Color {
        if location.id == currentLocation?.id {
            return Theme.primaryColor
        }
        if location.id == currentLocation?.parentSceneId {
            return Theme.secondaryColor  // Full opacity for parent
        }
        if location.parentSceneId == currentLocation?.id {
            return Theme.secondaryColor.opacity(0.8)  // Slightly more opaque for children
        }
        return isAccessible ? Theme.secondaryColor.opacity(0.7) : Theme.secondaryColor.opacity(0.4)
    }
    
    private var borderStyle: Color {
        if location.id == currentLocation?.id {
            return .white
        }
        return isAccessible ? Theme.primaryColor : Theme.primaryColor.opacity(0.3)
    }
    
    private var iconColor: Color {
        if location.id == currentLocation?.id {
            return .white
        }
        return isAccessible ? Theme.primaryColor : Theme.primaryColor.opacity(0.3)
    }
    
    private var shadowColor: Color {
        if location.id == currentLocation?.id {
            return Theme.primaryColor.opacity(0.5)
        }
        return Color.black.opacity(0.2)
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
        
        // Add parent
        if let parent = parentScene {
            locations.append(parent)
            
            // Add parent's siblings (limit to 4)
            let parentSiblings = LocationReader.getSiblingLocations(for: parent.id)
            locations.append(contentsOf: Array(parentSiblings.prefix(4)))
        }
        
        // Add immediate siblings (limit to 6)
        locations.append(contentsOf: Array(siblingScenes.prefix(6)))
        
        // Add immediate children (limit to 6)
        locations.append(contentsOf: Array(childScenes.prefix(6)))
        
        return locations.uniqued()
    }
    
    var allConnections: [Connection] {
        var connections: [Connection] = []
        guard let positions = locationPositions,
              let current = currentScene,
              let currentPos = positions[current.id] else { return connections }
        
        // Add connections to parent
        if let parent = parentScene,
           let parentPos = positions[parent.id] {
            connections.append(Connection(
                from: currentPos,
                to: parentPos,
                awareness: 1.0
            ))
            
            // Add connections between parent and its siblings
            let parentSiblings = LocationReader.getSiblingLocations(for: parent.id).prefix(4)  // Increased from 2 to 4
            for sibling in parentSiblings {
                if let siblingPos = positions[sibling.id] {
                    connections.append(Connection(
                        from: parentPos,
                        to: siblingPos,
                        awareness: 0.7
                    ))
                }
            }
        }
        
        // Add connections to siblings
        let siblings = Array(siblingScenes.prefix(6))  // Increased from 3 to 6
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
        let children = Array(childScenes.prefix(6))  // Increased from 3 to 6
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
