import SwiftUI

// MARK: - Navigation Layout Engine
struct NavigationWebLayout {
    let geometry: GeometryProxy
    let hasParent: Bool
    
    // Layout constants
    private let margin: CGFloat = 40
    private let maxChildNodes = 10
    private let maxSiblingNodes = 10
    private let maxParentSiblingNodes = 10
    
    // Computed properties
    private var availableWidth: CGFloat {
        geometry.size.width - margin * 2
    }
    
    private var availableHeight: CGFloat {
        geometry.size.height - margin * 2
    }
    
    private var leftColumnWidth: CGFloat {
        hasParent ? availableWidth * 0.6 : availableWidth
    }
    
    private var rightColumnWidth: CGFloat {
        hasParent ? availableWidth * 0.4 : 0
    }
    
    private var leftCenter: CGPoint {
        CGPoint(
            x: margin + leftColumnWidth / 2,
            y: geometry.size.height / 2
        )
    }
    
    private var rightCenter: CGPoint {
        CGPoint(
            x: margin + leftColumnWidth + rightColumnWidth / 2,
            y: geometry.size.height / 2
        )
    }
    
    func calculatePositions(
        current: Scene,
        parent: Scene?,
        siblings: [Scene],
        children: [Scene],
        parentSiblings: [Scene]
    ) -> [UUID: CGPoint] {
        var positions = [UUID: CGPoint]()
        
        // Position current node
        positions[current.id] = leftCenter
        
        // Position siblings in inner circle
        positionNodesInCircle(
            nodes: Array(siblings.prefix(maxSiblingNodes)),
            around: leftCenter,
            radius: min(leftColumnWidth, availableHeight) * 0.3,
            positions: &positions
        )
        
        // Position children in outer circle
        positionNodesInCircle(
            nodes: Array(children.prefix(maxChildNodes)),
            around: leftCenter,
            radius: min(leftColumnWidth, availableHeight) * 0.45,
            positions: &positions
        )
        
        // Position parent and its siblings if exists
        if let parent = parent {
            positions[parent.id] = rightCenter
            
            positionNodesInCircle(
                nodes: Array(parentSiblings.prefix(maxParentSiblingNodes)),
                around: rightCenter,
                radius: min(rightColumnWidth, availableHeight) * 0.35,
                positions: &positions
            )
        }
        
        return positions
    }
    
    private func positionNodesInCircle(
        nodes: [Scene],
        around center: CGPoint,
        radius: CGFloat,
        positions: inout [UUID: CGPoint]
    ) {
        guard !nodes.isEmpty else { return }
        
        let angleStep = 2 * .pi / CGFloat(nodes.count)
        let startAngle = -CGFloat.pi / 2 // Start from top (12 o'clock)
        
        for (index, node) in nodes.enumerated() {
            let angle = startAngle + angleStep * CGFloat(index)
            positions[node.id] = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
        }
    }
}

// MARK: - Connection Lines
struct ConnectionLinesView: View {
    let connections: [Connection]
    
    var body: some View {
        ForEach(connections) { connection in
            Path { path in
                path.move(to: connection.from)
                path.addLine(to: connection.to)
            }
            .stroke(
                Theme.primaryColor.opacity(Double(connection.awareness)),
                style: StrokeStyle(
                    lineWidth: 2,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            
            // Draw arrowhead
            ArrowheadShape(from: connection.from, to: connection.to)
                .fill(Theme.primaryColor.opacity(Double(connection.awareness)))
        }
    }
}

struct ArrowheadShape: Shape {
    let from: CGPoint
    let to: CGPoint
    
    func path(in rect: CGRect) -> Path {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLength: CGFloat = 10
        let arrowAngle = CGFloat.pi / 6 // 30 degrees
        
        let point1 = CGPoint(
            x: to.x - arrowLength * cos(angle + arrowAngle),
            y: to.y - arrowLength * sin(angle + arrowAngle)
        )
        
        let point2 = CGPoint(
            x: to.x - arrowLength * cos(angle - arrowAngle),
            y: to.y - arrowLength * sin(angle - arrowAngle)
        )
        
        return Path { path in
            path.move(to: to)
            path.addLine(to: point1)
            path.move(to: to)
            path.addLine(to: point2)
        }
    }
}


struct StraightConnectionLine: View {
    let connection: Connection
    
    var body: some View {
        Path { path in
            path.move(to: connection.from)
            path.addLine(to: connection.to)
            
            // Only add arrowhead for parent connection
            if connection.isParentConnection {
                let angle = atan2(connection.to.y - connection.from.y, 
                                 connection.to.x - connection.from.x)
                let arrowLength: CGFloat = 10
                let arrowAngle = CGFloat.pi / 6
                
                let point1 = CGPoint(
                    x: connection.to.x - arrowLength * cos(angle + arrowAngle),
                    y: connection.to.y - arrowLength * sin(angle + arrowAngle)
                )
                
                let point2 = CGPoint(
                    x: connection.to.x - arrowLength * cos(angle - arrowAngle),
                    y: connection.to.y - arrowLength * sin(angle - arrowAngle)
                )
                
                path.move(to: connection.to)
                path.addLine(to: point1)
                path.move(to: connection.to)
                path.addLine(to: point2)
            }
        }
        .stroke(
            Theme.primaryColor.opacity(Double(connection.awareness)),
            style: StrokeStyle(
                lineWidth: connection.isParentConnection ? 3 : 2,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }
}

// Updated Connection model
struct Connection: Identifiable {
    let id = UUID()
    let from: CGPoint
    let to: CGPoint
    let awareness: Float
    var isParentConnection: Bool = false
}
