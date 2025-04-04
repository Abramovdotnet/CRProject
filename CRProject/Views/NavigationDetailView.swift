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
                            dismiss()
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

private struct NavigationWebView: View {
    let viewModel: MainSceneViewModel
    @Binding var offset: CGPoint
    @Binding var scale: CGFloat
    let geometry: GeometryProxy
    let onLocationSelected: (Scene) -> Void
    @State private var startOffset: CGPoint = .zero
    
    var body: some View {
        // Fixed drag area that covers the entire view
        Color.white.opacity(0.1)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if value.translation == .zero {
                            startOffset = offset
                        }
                        
                        // Direct 1:1 movement with finger
                        let newX = startOffset.x + value.translation.width
                        let newY = startOffset.y + value.translation.height
                        
                        offset = CGPoint(
                            x: newX.clamped(to: -200...200),
                            y: newY.clamped(to: -200...200)
                        )
                    }
                    .onEnded { value in
                        // Small momentum effect
                        let velocity = CGPoint(
                            x: value.predictedEndLocation.x - value.location.x,
                            y: value.predictedEndLocation.y - value.location.y
                        )
                        
                        withAnimation(.interpolatingSpring(
                            mass: 0.8,
                            stiffness: 350,
                            damping: 25,
                            initialVelocity: 0
                        )) {
                            let finalX = offset.x + velocity.x * 0.05  // Reduced momentum
                            let finalY = offset.y + velocity.y * 0.05
                            
                            offset = CGPoint(
                                x: finalX.clamped(to: -200...200),
                                y: finalY.clamped(to: -200...200)
                            )
                        }
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = value.magnitude.clamped(to: 0.2...0.8)
                    }
                    .onEnded { value in
                        withAnimation(.interpolatingSpring(
                            mass: 0.8,
                            stiffness: 350,
                            damping: 25,
                            initialVelocity: 0
                        )) {
                            scale = value.magnitude.clamped(to: 0.2...0.8)
                        }
                    }
            )
            .overlay {
                // Movable content
                ZStack {
                    // Connection Lines Layer
                    ForEach(viewModel.allConnections) { connection in
                        ConnectionLine(
                            from: connection.from,
                            to: connection.to,
                            awareness: connection.awareness
                        )
                    }
                    
                    // Location Nodes Layer
                    ForEach(viewModel.allLocations) { location in
                        if let position = viewModel.locationPositions?[location.id] {
                            LocationNode(
                                location: location,
                                currentLocation: viewModel.currentScene,
                                bloodCost: 5,
                                playerBlood: Int(viewModel.playerBloodPercentage),
                                onSelected: { onLocationSelected(location) }
                            )
                            .position(position)
                        }
                    }
                }
                .offset(x: offset.x, y: offset.y)
                .scaleEffect(scale)
            }
            .animation(.easeInOut, value: viewModel.currentScene?.id)
            .onAppear {
                viewModel.updateLocationPositions(in: geometry)
            }
            .onChange(of: viewModel.currentScene?.id) { _, _ in
                withAnimation(.easeInOut) {
                    offset = .zero
                    startOffset = .zero
                    viewModel.updateLocationPositions(in: geometry)
                }
            }
    }
}

private struct LocationNode: View {
    let location: Scene
    let currentLocation: Scene?
    let bloodCost: Int
    let playerBlood: Int
    let onSelected: () -> Void
    
    private var isAccessible: Bool {
        guard location.id != currentLocation?.id else { return false }  // Disable current location
        return (playerBlood - bloodCost) >= 10
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
    
    private var relationshipLabel: String? {
        if location.id == currentLocation?.id {
            return "Current"
        } else if location.id == currentLocation?.parentSceneId {
            return "Parent"
        } else if location.parentSceneId == currentLocation?.id {
            return "Child"
        } else if location.parentSceneId == currentLocation?.parentSceneId {
            return "Sibling"
        }
        return nil
    }
    
    var body: some View {
        Button(action: onSelected) {
            VStack(spacing: 4) {
                Image(systemName: relationshipIcon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                Text(location.name)
                    .font(Theme.captionFont)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor)
                if let label = relationshipLabel {
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(textColor.opacity(0.8))
                }
            }
            .frame(width: 100, height: 100)  // Increased size
            .background(
                ZStack {
                    Circle()
                        .fill(backgroundStyle)
                    Circle()
                        .fill(Color.black.opacity(0.3))  // Dark overlay for better contrast
                }
            )
            .clipShape(Circle())
            .overlay(Circle().stroke(borderStyle, lineWidth: 3))  // Increased border width
            .shadow(color: shadowColor, radius: 8, x: 0, y: 2)  // Enhanced shadow
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
    
    private var textColor: Color {
        if location.id == currentLocation?.id {
            return .white
        }
        return isAccessible ? Theme.textColor : Theme.textColor.opacity(0.3)
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
