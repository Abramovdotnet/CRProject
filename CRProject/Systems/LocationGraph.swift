import Foundation
// Для CGPoint и CGFloat, если будем использовать их для координат.
// Если Scene.x и Scene.y уже Int, то SwiftUI можно не импортировать для этого файла.
// import SwiftUI 

// Убедимся, что SceneId это Int, как в Scene.swift
typealias SceneId = Int

struct PathNode: Comparable, Hashable {
    let sceneId: SceneId
    let gScore: Double // Стоимость пути от начальной вершины до текущей
    let fScore: Double // gScore + эвристическая оценка расстояния до цели (hScore)

    static func < (lhs: PathNode, rhs: PathNode) -> Bool {
        lhs.fScore < rhs.fScore
    }

    static func == (lhs: PathNode, rhs: PathNode) -> Bool {
        lhs.sceneId == rhs.sceneId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(sceneId)
    }
}

class LocationGraph {

    private var scenes: [SceneId: Scene] = [:]

    init(scenes: [Scene] = []) { // Добавлен параметр по умолчанию
        self.updateScenes(scenes: scenes)
    }
    
    func updateScenes(scenes: [Scene]) {
        self.scenes = Dictionary(uniqueKeysWithValues: scenes.map { ($0.id, $0) })
        // DebugLogService.shared.log("LocationGraph updated with \\(self.scenes.count) scenes.", category: "LocationGraph")
    }
    
    public func getScene(by id: SceneId) -> Scene? {
        return scenes[id]
    }

    // Эвристическая функция (Евклидово расстояние)
    private func heuristic(from sceneAId: SceneId, to sceneBId: SceneId) -> Double {
        guard let sceneA = scenes[sceneAId], let sceneB = scenes[sceneBId] else {
            // DebugLogService.shared.log("Heuristic: Scene not found for ID \(sceneAId) or \(sceneBId).", category: "LocationGraph")
            return Double.infinity 
        }
        let dx = Double(sceneA.x - sceneB.x)
        let dy = Double(sceneA.y - sceneB.y)
        return sqrt(dx*dx + dy*dy)
    }

    func findShortestPath(from startSceneId: SceneId, to goalSceneId: SceneId) -> [SceneId]? {
        guard scenes[startSceneId] != nil else {
            //DebugLogService.shared.log("Error: Start scene ID \\(startSceneId) not found in graph.", category: "LocationGraph")
            return nil 
        }
        guard scenes[goalSceneId] != nil else {
            //DebugLogService.shared.log("Error: Goal scene ID \\(goalSceneId) not found in graph.", category: "LocationGraph")
            return nil
        }

        if startSceneId == goalSceneId {
            return [startSceneId]
        }

        var openSet = Heap<PathNode>() 
        let initialNode = PathNode(sceneId: startSceneId, gScore: 0, fScore: heuristic(from: startSceneId, to: goalSceneId))
        openSet.insert(initialNode)

        var cameFrom: [SceneId: SceneId] = [:] 
        var gScore: [SceneId: Double] = [startSceneId: 0]

        var closedSet: Set<SceneId> = [] 

        while !openSet.isEmpty {
            guard let current = openSet.remove() else { break } 

            if current.sceneId == goalSceneId {
                return reconstructPath(cameFrom: cameFrom, current: goalSceneId)
            }

            if closedSet.contains(current.sceneId) {
                continue
            }
            
            closedSet.insert(current.sceneId)

            guard let currentScene = scenes[current.sceneId] else { continue }

            for connection in currentScene.connections {
                let neighborSceneId = connection.connectedSceneId
                
                if closedSet.contains(neighborSceneId) { 
                    continue
                }

                guard scenes[neighborSceneId] != nil else {
                    // DebugLogService.shared.log("Warning: Neighbor scene ID \\(neighborSceneId) for scene \\(current.sceneId) not found in graph data. Skipping.", category: "LocationGraph")
                    continue 
                }

                let tentativeGScore = current.gScore + connection.travelTime

                if tentativeGScore < (gScore[neighborSceneId] ?? Double.infinity) {
                    cameFrom[neighborSceneId] = current.sceneId
                    gScore[neighborSceneId] = tentativeGScore
                    let newFScore = tentativeGScore + heuristic(from: neighborSceneId, to: goalSceneId)
                    
                    let neighborNode = PathNode(sceneId: neighborSceneId, gScore: tentativeGScore, fScore: newFScore)
                    openSet.insert(neighborNode) 
                }
            }
        }
        //DebugLogService.shared.log("Path not found from \\(startSceneId) to \\(goalSceneId).", category: "LocationGraph")
        return nil 
    }

    private func reconstructPath(cameFrom: [SceneId: SceneId], current: SceneId) -> [SceneId] {
        var totalPath: [SceneId] = [current]
        var currentTrace = current
        var safetyCounter = 0
        let maxPathLength = scenes.count > 0 ? scenes.count * 2 : 200 // Немного запаса, и базовое значение если scenes пусто

        while let previous = cameFrom[currentTrace] {
            if previous == currentTrace {
                //DebugLogService.shared.log("Error: Path reconstruction detected direct self-loop for ID \\(currentTrace). Aborting path.", category: "LocationGraph")
                return [] 
            }
            if totalPath.last == previous {
                 //DebugLogService.shared.log("Error: Path reconstruction detected immediate duplicate previous ID \\(previous). Aborting path to prevent simple cycle.", category: "LocationGraph")
                return []
            }
            totalPath.append(previous)
            currentTrace = previous
            
            safetyCounter += 1
            if safetyCounter > maxPathLength { 
                //DebugLogService.shared.log("Error: Path reconstruction exceeded safety limit (\\(safetyCounter) > \\(maxPathLength) steps). Path: \\(totalPath.reversed())", category: "LocationGraph")
                return [] 
            }
        }
        return totalPath.reversed()
    }
}

struct Heap<T: Comparable & Hashable> {
    private var elements: [T] = []

    var isEmpty: Bool {
        return elements.isEmpty
    }

    var count: Int {
        return elements.count
    }

    func peek() -> T? {
        return elements.first
    }
    
    mutating func insert(_ element: T) {
        elements.append(element)
        siftUp(from: elements.count - 1)
    }

    mutating func remove() -> T? {
        guard !isEmpty else { return nil }
        if elements.count == 1 {
            return elements.removeLast()
        }
        let first = elements[0]
        elements[0] = elements.removeLast()
        siftDown(from: 0)
        return first
    }

    private func parentIndex(ofChildAt index: Int) -> Int { (index - 1) / 2 }
    private func leftChildIndex(ofParentAt index: Int) -> Int { 2 * index + 1 }
    private func rightChildIndex(ofParentAt index: Int) -> Int { 2 * index + 2 }

    private mutating func siftUp(from index: Int) {
        var childIndex = index
        let child = elements[childIndex]
        var pIndex = parentIndex(ofChildAt: childIndex)

        while childIndex > 0 && child < elements[pIndex] {
            elements[childIndex] = elements[pIndex]
            childIndex = pIndex
            pIndex = parentIndex(ofChildAt: childIndex)
        }
        elements[childIndex] = child
    }

    private mutating func siftDown(from index: Int) {
        var parentIndex = index
        while true {
            let leftIdx = leftChildIndex(ofParentAt: parentIndex)
            let rightIdx = rightChildIndex(ofParentAt: parentIndex)
            var candidateIndex = parentIndex

            if leftIdx < count && elements[leftIdx] < elements[candidateIndex] {
                candidateIndex = leftIdx
            }
            if rightIdx < count && elements[rightIdx] < elements[candidateIndex] {
                candidateIndex = rightIdx
            }
            if candidateIndex == parentIndex {
                return
            }
            elements.swapAt(parentIndex, candidateIndex)
            parentIndex = candidateIndex
        }
    }
} 