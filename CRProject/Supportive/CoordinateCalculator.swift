import Foundation
import UIKit // Для CGPoint и CGFloat, если понадобится для расчетов

struct CalculatedScene {
    let scene: Scene
    let point: CGPoint
    // Можно добавить линии к другим CalculatedScene для отрисовки связей
    // var connections: [CalculatedSceneConnection] = []
}

// struct CalculatedSceneConnection {
//     let toSceneId: Int
//     let type: ConnectionType // .sibling, .hub, .parentChild
// }
// 
// enum ConnectionType {
//     case sibling
//     case hub
//     case parentChild
// }

class CoordinateCalculator {

    private let defaultDistance: CGFloat = 15.0 // Агрессивно уменьшаем (было 40.0)
    private let hubDistanceFactor: CGFloat = 1.5 // Множитель для расстояния до хабов (может быть дальше)
    private let rootSpacing: CGFloat = 100.0  // Агрессивно уменьшаем (было 200.0)

    func calculateCoordinatesForAllScenes() -> [CalculatedScene] {
        let allScenes = LocationReader.getLocations()
        var calculatedScenes: [CalculatedScene] = []
        var scenePoints: [Int: CGPoint] = [:] // Для хранения уже рассчитанных координат [sceneId: CGPoint]
        var processedSceneIds: Set<Int> = []

        let rootScenes = allScenes.filter { $0.parentSceneId == 0 || $0.parentSceneId == nil }
        
        // --- НОВОЕ: Расположение корневых сцен по кругу --- (Начало)
        if !rootScenes.isEmpty {
            let centerPoint = CGPoint.zero
            let rootCircleRadius = rootSpacing // Используем rootSpacing как радиус
            // Если корневая сцена одна, просто помещаем ее в центр
            if rootScenes.count == 1 {
                if let firstRoot = rootScenes.first, !processedSceneIds.contains(firstRoot.id) {
                    scenePoints[firstRoot.id] = centerPoint
                    calculatedScenes.append(CalculatedScene(scene: firstRoot, point: centerPoint))
                    processedSceneIds.insert(firstRoot.id)
                    processChildren(of: firstRoot, at: centerPoint, grandParentPoint: centerPoint, isParentRootNode: true, allScenes: allScenes, scenePoints: &scenePoints, calculatedScenes: &calculatedScenes, processedSceneIds: &processedSceneIds)
                }
            } else {
                let rootAngleStep = (2 * CGFloat.pi) / CGFloat(rootScenes.count)
                for (index, rootScene) in rootScenes.enumerated() {
                    if processedSceneIds.contains(rootScene.id) { continue }
                    
                    let angle = rootAngleStep * CGFloat(index)
                    let rootX = centerPoint.x + rootCircleRadius * cos(angle)
                    let rootY = centerPoint.y + rootCircleRadius * sin(angle)
                    let rootPoint = CGPoint(x: rootX, y: rootY)
                    
                    scenePoints[rootScene.id] = rootPoint
                    calculatedScenes.append(CalculatedScene(scene: rootScene, point: rootPoint))
                    processedSceneIds.insert(rootScene.id)
                    
                    processChildren(of: rootScene, at: rootPoint, grandParentPoint: centerPoint, isParentRootNode: true, allScenes: allScenes, scenePoints: &scenePoints, calculatedScenes: &calculatedScenes, processedSceneIds: &processedSceneIds)
                }
            }
        }
        // --- НОВОЕ: Расположение корневых сцен по кругу --- (Конец)

        // 2. Обработка оставшихся сцен, если они не были частью иерархии от известных корней
        // (например, "сироты" или группы, не связанные явно через parentSceneId от корня)
        // Это больше страховка, в идеале все должно быть связано.
        let remainingScenes = allScenes.filter { !processedSceneIds.contains($0.id) }
        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Начало)
        print("[CoordinateCalculator] Number of remaining (orphan) scenes: \(remainingScenes.count)")
        // --- ОТЛАДОЧНЫЙ ВЫВОД --- (Конец)
        var currentOrphanY: CGFloat = rootSpacing * 2 // Начинаем еще ниже, чтобы не пересекаться с кругом корней
        for orphanScene in remainingScenes {
            if processedSceneIds.contains(orphanScene.id) { continue }
            
            // Попробуем найти родителя, если он есть и был обработан
            var determinedParentPoint: CGPoint? = nil
            let parentId = orphanScene.parentSceneId // parentSceneId это Int
            if parentId != 0, let pPoint = scenePoints[parentId] { // Проверяем, что ID не 0 и точка существует
                determinedParentPoint = pPoint
            } else {
                 // Если родителя нет (ID = 0) или он не обработан, размещаем как новую "группу"
                determinedParentPoint = CGPoint(x: 0, y: currentOrphanY)
                currentOrphanY += rootSpacing
            }

            // Используем ! здесь, так как мы гарантируем, что determinedParentPoint будет установлен
            let orphanPoint = CGPoint(x: determinedParentPoint!.x + defaultDistance, y: determinedParentPoint!.y) 
            scenePoints[orphanScene.id] = orphanPoint
            calculatedScenes.append(CalculatedScene(scene: orphanScene, point: orphanPoint))
            processedSceneIds.insert(orphanScene.id)
            
            processChildren(of: orphanScene,
                            at: orphanPoint,
                            grandParentPoint: determinedParentPoint!,
                            isParentRootNode: true,
                            allScenes: allScenes,
                            scenePoints: &scenePoints,
                            calculatedScenes: &calculatedScenes,
                            processedSceneIds: &processedSceneIds)
        }
        
        // TODO: На этом этапе у нас есть базовые координаты.
        // Можно добавить шаг для разрешения коллизий, если они есть.
        // Можно добавить логику для "раздвигания" хабов, если они слишком близко.

        return calculatedScenes
    }

    private func processChildren(of parentScene: Scene,
                                 at parentPoint: CGPoint,
                                 grandParentPoint: CGPoint,
                                 isParentRootNode: Bool,
                                 allScenes: [Scene],
                                 scenePoints: inout [Int: CGPoint],
                                 calculatedScenes: inout [CalculatedScene],
                                 processedSceneIds: inout Set<Int>) {
        
        // Находим прямых детей этой parentScene (сгруппированных по parentSceneId)
        // И также "сиблингов" (которые в JSON имеют тот же parentSceneId, что и текущая сцена,
        // если parentScene сама является дочерней).
        // Для упрощения первой версии, будем считать детьми те, у кого parentScene.id == their.parentSceneId

        let children = allScenes.filter { $0.parentSceneId == parentScene.id && !processedSceneIds.contains($0.id) }
        
        if children.isEmpty { return }

        // --- НОВОЕ: Динамический радиус для детей --- (Начало)
        // Базовый радиус + небольшой коэффициент, умноженный на количество детей
        // Подберите коэффициенты для лучшего вида.
        let baseRadiusForChildren = defaultDistance 
        let perChildRadiusFactor: CGFloat = 1.0 // Агрессивно уменьшаем (было 2.0)
        let dynamicRadius = baseRadiusForChildren + (CGFloat(children.count) * perChildRadiusFactor)
        // --- НОВОЕ: Динамический радиус для детей --- (Конец)

        // --- MODIFIED: Angular placement logic --- (Начало)
        let angularSpreadRadians: CGFloat
        let baseAngleRadians: CGFloat

        if isParentRootNode {
            angularSpreadRadians = 2 * CGFloat.pi
            baseAngleRadians = 0 // Children of roots spread around 0 rad (e.g., positive X then around)
        } else {
            // For non-roots, children spread in a semicircle "away" from the grandparent
            let entryAngleFromGrandparent = atan2(parentPoint.y - grandParentPoint.y, parentPoint.x - grandParentPoint.x)
            angularSpreadRadians = CGFloat.pi // 180 degrees
            baseAngleRadians = entryAngleFromGrandparent // Center the semicircle on the entry angle
        }
        // --- MODIFIED: Angular placement logic --- (Конец)

        for (index, childScene) in children.enumerated() {
            if processedSceneIds.contains(childScene.id) { continue }

            var angle: CGFloat
            if children.count == 1 {
                angle = baseAngleRadians // Single child goes straight along the baseAngle
            } else {
                if isParentRootNode {
                    // Full circle spread for root's children
                    angle = baseAngleRadians + (CGFloat(index) / CGFloat(children.count)) * angularSpreadRadians
                } else {
                    // Semicircle spread for non-root's children
                    // Distribute children across angularSpread, centered on baseAngleRadians
                    // from -angularSpread/2 to +angularSpread/2 relative to baseAngleRadians
                    let angleOffset = (CGFloat(index) / CGFloat(children.count - 1) - 0.5) * angularSpreadRadians
                    angle = baseAngleRadians + angleOffset
                }
            }

            let childX = parentPoint.x + dynamicRadius * cos(angle)
            let childY = parentPoint.y + dynamicRadius * sin(angle)
            let childPoint = CGPoint(x: childX, y: childY)
            
            scenePoints[childScene.id] = childPoint
            calculatedScenes.append(CalculatedScene(scene: childScene, point: childPoint))
            processedSceneIds.insert(childScene.id)

            // Рекурсивно обрабатываем детей этого ребенка
            processChildren(of: childScene,
                            at: childPoint,
                            grandParentPoint: parentPoint,
                            isParentRootNode: false,
                            allScenes: allScenes,
                            scenePoints: &scenePoints,
                            calculatedScenes: &calculatedScenes,
                            processedSceneIds: &processedSceneIds)
        }
    }
    
    // Упрощенная версия для отладки - просто выводит все локации в линию
    func calculateCoordinatesLinearly() -> [CalculatedScene] {
        let allScenes = LocationReader.getLocations()
        var calculatedScenes: [CalculatedScene] = []
        var currentX: CGFloat = 0
        let spacing: CGFloat = 50.0

        for scene in allScenes {
            let point = CGPoint(x: currentX, y: 0)
            calculatedScenes.append(CalculatedScene(scene: scene, point: point))
            currentX += spacing
        }
        return calculatedScenes
    }
} 