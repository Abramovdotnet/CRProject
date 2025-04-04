import Foundation
import SwiftUI

struct NavigationLayout {
    let centerPoint: CGPoint
    let radius: CGFloat
    let maxLevels: Int
    
    private let minNodeSpacing: CGFloat = 120  // Minimum space between nodes
    
    init(centerPoint: CGPoint, radius: CGFloat = 80, maxLevels: Int = 3) {
        self.centerPoint = centerPoint
        self.radius = radius
        self.maxLevels = maxLevels
    }
    
    func calculatePositions(
        for scenes: [Scene],
        currentScene: Scene?,
        parentScene: Scene?,
        siblingScenes: [Scene],
        childScenes: [Scene]
    ) -> [UUID: CGPoint] {
        var positions: [UUID: CGPoint] = [:]
        guard let current = currentScene else { return positions }
        
        // Position current scene at center
        positions[current.id] = centerPoint
        
        // Calculate spacings
        let horizontalSpacing = max(radius * 3.5, minNodeSpacing)  // Ensure minimum spacing
        let verticalSpacing = max(radius * 2.5, minNodeSpacing)    // Ensure minimum spacing
        
        // Position parent above current with extra vertical space
        if let parent = parentScene {
            positions[parent.id] = CGPoint(
                x: centerPoint.x,
                y: centerPoint.y - verticalSpacing * 1.6  // Increased from 1.4 for more space
            )
            
            // Add parent's siblings with spacing checks
            let parentSiblings = Array(LocationReader.getSiblingLocations(for: parent.id).prefix(4))
            if !parentSiblings.isEmpty {
                let totalWidth = CGFloat(parentSiblings.count - 1) * horizontalSpacing
                let startX = centerPoint.x - totalWidth / 2
                
                for (index, sibling) in parentSiblings.enumerated() {
                    let baseX = startX + CGFloat(index) * horizontalSpacing
                    let baseY = positions[parent.id]?.y ?? centerPoint.y - verticalSpacing * 1.6
                    
                    // Adjust position if too close to existing nodes
                    var adjustedX = baseX
                    var adjustedY = baseY
                    
                    while isPositionTooClose(CGPoint(x: adjustedX, y: adjustedY), to: positions) {
                        adjustedX += 20  // Small horizontal adjustment
                        adjustedY -= 20  // Small vertical adjustment
                    }
                    
                    positions[sibling.id] = CGPoint(x: adjustedX, y: adjustedY)
                }
            }
        }
        
        // Position siblings with spacing enforcement
        let siblings = Array(siblingScenes.prefix(6))
        let leftSiblings = Array(siblings[..<min(3, siblings.count)])
        let rightSiblings = Array(siblings[min(3, siblings.count)...])
        
        // Position left siblings with spacing checks
        for (index, sibling) in leftSiblings.enumerated() {
            var baseX = centerPoint.x - horizontalSpacing * 1.4
            var baseY = centerPoint.y + (CGFloat(index) - 0.5) * verticalSpacing
            
            while isPositionTooClose(CGPoint(x: baseX, y: baseY), to: positions) {
                baseX -= 20  // Move further left
                baseY += 20  // Adjust vertical position
            }
            
            positions[sibling.id] = CGPoint(x: baseX, y: baseY)
        }
        
        // Position right siblings with spacing checks
        for (index, sibling) in rightSiblings.enumerated() {
            var baseX = centerPoint.x + horizontalSpacing * 1.4
            var baseY = centerPoint.y + (CGFloat(index) - 0.5) * verticalSpacing
            
            while isPositionTooClose(CGPoint(x: baseX, y: baseY), to: positions) {
                baseX += 20  // Move further right
                baseY += 20  // Adjust vertical position
            }
            
            positions[sibling.id] = CGPoint(x: baseX, y: baseY)
        }
        
        // Position children in an arc with spacing checks
        let children = Array(childScenes.prefix(6))
        if !children.isEmpty {
            let totalWidth = CGFloat(children.count - 1) * horizontalSpacing
            let startX = centerPoint.x - totalWidth / 2
            
            for (index, child) in children.enumerated() {
                var baseX = startX + CGFloat(index) * horizontalSpacing
                var baseY = centerPoint.y + verticalSpacing * 1.6  // Increased from 1.4
                
                while isPositionTooClose(CGPoint(x: baseX, y: baseY), to: positions) {
                    baseX += 20  // Small horizontal adjustment
                    baseY += 20  // Move further down
                }
                
                positions[child.id] = CGPoint(x: baseX, y: baseY)
            }
        }
        
        return positions
    }
    
    private func isPositionTooClose(_ position: CGPoint, to existingPositions: [UUID: CGPoint]) -> Bool {
        for existingPosition in existingPositions.values {
            let distance = hypot(position.x - existingPosition.x, position.y - existingPosition.y)
            if distance < minNodeSpacing {
                return true
            }
        }
        return false
    }
    
    private func calculatePoint(angle: CGFloat, level: CGFloat) -> CGPoint {
        let distance = radius * level
        return CGPoint(
            x: centerPoint.x + cos(angle) * distance,
            y: centerPoint.y + sin(angle) * distance
        )
    }
}

extension MainSceneViewModel {
    func calculateLocationPositions(in geometry: GeometryProxy) -> [UUID: CGPoint] {
        let layout = NavigationLayout(
            centerPoint: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.5),
            radius: 80,
            maxLevels: 3
        )
        return layout.calculatePositions(
            for: allLocations,
            currentScene: currentScene,
            parentScene: parentScene,
            siblingScenes: siblingScenes,
            childScenes: childScenes
        )
    }
} 
