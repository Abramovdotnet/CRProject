import Foundation
import CoreGraphics

struct Connection: Identifiable {
    let id: UUID
    let from: CGPoint
    let to: CGPoint
    let awareness: Float
    
    init(from: CGPoint, to: CGPoint, awareness: Float) {
        self.id = UUID()
        self.from = from
        self.to = to
        self.awareness = awareness
    }
} 