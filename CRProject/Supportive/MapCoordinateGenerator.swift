import UIKit
import Foundation // For Double.pi, cos, sin

class CoordinateGenerator {

    // Helper struct to manage scene state during generation
    private struct PlacementInfo {
        var scene: Scene
        var rect: CGRect
    }

    func generateCoordinates(
        scenes: [Scene],
        markerSizeOnScreen: CGSize,
        mapCoordinateScale: CGFloat,
        baseDistancePerTravelTimeUnit: CGFloat
    ) -> [Scene] {

        guard !scenes.isEmpty else { return [] }

        // --- Initial Calculations ---
        let markerWidthInJsonUnits = markerSizeOnScreen.width / mapCoordinateScale
        let markerHeightInJsonUnits = markerSizeOnScreen.height / mapCoordinateScale

        var workingScenes: [Int: Scene] = [:] // Scenes with updated coordinates
        for scene in scenes {
            // Create copies to modify x, y. Scene is a class, so if we modify input directly and fail, it's problematic.
            // However, the function returns [Scene], implying we manage the output list.
            // For now, let's assume we are modifying the input scenes directly if they are classes and x,y are vars.
            // If Scene is a struct, we'd need to build a new array.
            // Let's clarify Scene definition: If it's a class, direct modification is fine.
            // For this example, I'll create a dictionary of scenes to be returned.
            workingScenes[scene.id] = scene // Assuming original scenes are modified or new ones created if struct
        }
        
        var placedInfos: [Int: PlacementInfo] = [:] // Info for placed scenes
        var processingQueue: [Int] = [] // Queue of scene IDs to process
        var enqueuedOrPlacedIds: Set<Int> = []

        // --- Algorithm Logic ---

        // 1. Place the initial scene (first in the list)
        let initialScene = scenes[0]
        initialScene.x = 0
        initialScene.y = 0
        
        let initialRect = CGRect(
            x: initialScene.x - Int(markerWidthInJsonUnits / 2),
            y: initialScene.y - Int(markerHeightInJsonUnits / 2),
            width: Int(markerWidthInJsonUnits),
            height: Int(markerHeightInJsonUnits)
        )
        placedInfos[initialScene.id] = PlacementInfo(scene: initialScene, rect: initialRect)
        enqueuedOrPlacedIds.insert(initialScene.id)
        
        // Add its neighbors to the processing queue
        for connection in initialScene.connections {
            if !enqueuedOrPlacedIds.contains(connection.connectedSceneId) {
                processingQueue.append(connection.connectedSceneId)
                enqueuedOrPlacedIds.insert(connection.connectedSceneId)
            }
        }
        
        // 2. Process the queue
        var head = 0
        while head < processingQueue.count {
            let currentSceneIdToPlace = processingQueue[head]
            head += 1
            
            guard let currentSceneObject = workingScenes[currentSceneIdToPlace] else {
                print("Error: Scene object not found for ID: \(currentSceneIdToPlace)")
                continue
            }

            // Find an anchor (a placed neighbor)
            var anchorInfo: PlacementInfo? = nil
            var connectionToAnchor: SceneConnection? = nil

            for conn in currentSceneObject.connections {
                if let placedAnchorInfo = placedInfos[conn.connectedSceneId] {
                    anchorInfo = placedAnchorInfo
                    connectionToAnchor = conn
                    break
                }
            }

            guard let AInfo = anchorInfo, let conn = connectionToAnchor else {
                // This scene has no placed neighbors yet, or it's disconnected.
                // For now, skip or place far away. Could re-queue for later if complex.
                print("Warning: No placed anchor found for scene \(currentSceneObject.name) (ID: \(currentSceneIdToPlace)). Skipping or placing at default.")
                // Simple fallback: place it relative to origin to avoid crash, though this is not ideal.
                // A better strategy for disconnected components is needed for a robust solution.
                if placedInfos[currentSceneIdToPlace] == nil { // Avoid re-placing if already skipped & 'placed'
                    placeSceneWithoutAnchor(currentSceneObject, markerWidthInJsonUnits, markerHeightInJsonUnits, &placedInfos, &enqueuedOrPlacedIds, Point(x:1000, y:1000 * placedInfos.count )) // crude offset for disconnected
                }
                continue
            }
            
            let targetJsonDistance = conn.travelTime * baseDistancePerTravelTimeUnit
            
            var placedSuccessfully = false
            let angles = stride(from: 0, to: 2 * Double.pi, by: Double.pi / 12).map { $0 } // 24 angles
            var currentSearchDistance = targetJsonDistance
            let maxSearchAttempts = 5 // Try up to 5 distance increments
            let distanceIncrement = markerWidthInJsonUnits * 0.5 // Increment distance if collisions

            for attempt in 0..<maxSearchAttempts {
                if placedSuccessfully { break }
                
                for angle in angles {
                    let candidateX = AInfo.scene.x + Int(round(currentSearchDistance * cos(angle)))
                    let candidateY = AInfo.scene.y + Int(round(currentSearchDistance * sin(angle)))
                    
                    let candidateRect = CGRect(
                        x: candidateX - Int(markerWidthInJsonUnits / 2),
                        y: candidateY - Int(markerHeightInJsonUnits / 2),
                        width: Int(markerWidthInJsonUnits),
                        height: Int(markerHeightInJsonUnits)
                    )
                    
                    var collision = false
                    for (_, existingInfo) in placedInfos {
                        if candidateRect.intersects(existingInfo.rect) {
                            collision = true
                            break
                        }
                    }
                    
                    if !collision {
                        currentSceneObject.x = candidateX
                        currentSceneObject.y = candidateY
                        placedInfos[currentSceneObject.id] = PlacementInfo(scene: currentSceneObject, rect: candidateRect)
                        // enqueuedOrPlacedIds is already updated when scene was added to queue
                        
                        // Add its unplaced neighbors to the queue
                        for neighborConnection in currentSceneObject.connections {
                            if !enqueuedOrPlacedIds.contains(neighborConnection.connectedSceneId) {
                                processingQueue.append(neighborConnection.connectedSceneId)
                                enqueuedOrPlacedIds.insert(neighborConnection.connectedSceneId)
                            }
                        }
                        placedSuccessfully = true
                        break // Found a spot for this angle/distance iteration
                    }
                }
                if !placedSuccessfully {
                    currentSearchDistance += distanceIncrement // Increase search radius if no spot found
                }
            }

            if !placedSuccessfully {
                print("Warning: Could not place scene \(currentSceneObject.name) (ID: \(currentSceneIdToPlace)) without collision after \(maxSearchAttempts) attempts. Placing at last attempted or default.")
                // Fallback: place at last tried position or a default one to avoid losing it
                // This could be the last 'candidateX, candidateY' or a more robust fallback
                // For now, let it remain unplaced or place with a crude offset if not already 'placed' by skip
                 if placedInfos[currentSceneIdToPlace] == nil {
                     placeSceneWithoutAnchor(currentSceneObject, markerWidthInJsonUnits, markerHeightInJsonUnits, &placedInfos, &enqueuedOrPlacedIds, Point(x:1000, y:1000 * placedInfos.count + 500 ))
                 }
            }
        }
        
        // Prepare the final list of scenes from our working copy
        // The `workingScenes` dictionary values contain the scenes with modified x, y
        return scenes.map { workingScenes[$0.id]! }
    }

    // Helper for disconnected/problematic scenes (very basic)
    private func placeSceneWithoutAnchor(_ scene: Scene, _ width: CGFloat, _ height: CGFloat, _ placedInfos: inout [Int: PlacementInfo], _ enqueuedOrPlacedIds: inout Set<Int>, _ fallbackPoint: Point) {
        scene.x = fallbackPoint.x
        scene.y = fallbackPoint.y
        let rect = CGRect(x: scene.x - Int(width / 2), y: scene.y - Int(height / 2), width: Int(width), height: Int(height))
        placedInfos[scene.id] = PlacementInfo(scene: scene, rect: rect)
        // enqueuedOrPlacedIds.insert(scene.id) // Should already be in by the time it's processed
         // Add its unplaced neighbors to the queue (if this function were to be more robust)
        // For now, this is just a sink for problematic scenes.
    }
}

struct Point { var x: Int; var y: Int }

// Assuming Scene has x, y as Int vars and connections as [SceneConnection]
// struct SceneConnection { let connectedSceneId: Int; let travelTime: Double }
// class Scene { var id: Int; var name: String; var x: Int = 0; var y: Int = 0; var connections: [SceneConnection] ... } 