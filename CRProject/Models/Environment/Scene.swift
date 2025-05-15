import Foundation
import Combine

extension Notification.Name {
    static let sceneCharactersChanged = Notification.Name("sceneCharactersChanged")
}

// Новая структура для связей, переименована во избежание конфликтов
struct SceneConnection: Codable, Hashable {
    let connectedSceneId: Int
    var travelTime: Double = 1.0 // Время в пути, по умолчанию 1.0
}

class Scene: SceneProtocol, Codable, ObservableObject, Identifiable {
    var id: Int = 0
    var name: String = ""
    var isParent: Bool = false
    var parentSceneId: Int = 0
    var parentSceneName: String = ""
    var parentSceneType: SceneType = .house
    var isIndoor: Bool = false
    var sceneType: SceneType = .house
    var runtimeID: Int = 0
    var isLocked: Bool = false

    // Новые свойства для координат и связей
    var x: Int = 0
    var y: Int = 0
    @Published var connections: [SceneConnection] = []

    @Published private var _characters: [Int: any Character] = [:]
    private var _childSceneIds: Set<Int> = []
    private var _hubSceneIds: Set<Int> = []
    
    var childSceneIds: [Int] {
        get { Array(_childSceneIds) }
        set { _childSceneIds = Set(newValue) }
    }
    
    var hubSceneIds: [Int] {
        get { Array(_hubSceneIds) }
        set { _hubSceneIds = Set(newValue) }
    }
    
    init(id: Int, name: String, isParent: Bool, parentSceneId: Int, parentSceneName: String, parentSceneType: SceneType, isIndoor: Bool, sceneType: SceneType, x: Int = 0, y: Int = 0, connections: [SceneConnection] = []) {
        self.id = id
        self.name = name
        self.isParent = isParent
        self.parentSceneId = parentSceneId
        self.parentSceneName = parentSceneName
        self.parentSceneType = parentSceneType
        self.isIndoor = isIndoor
        self.sceneType = sceneType
        self.x = x
        self.y = y
        self.connections = connections
    }
    
    init() {
        
    }

    // Обновляем CodingKeys
    private enum CodingKeys: String, CodingKey {
        case id, name, isParent, parentSceneId, isIndoor, sceneType
        case x, y, connections
        case _childSceneIds = "childSceneIds"
        case _hubSceneIds = "hubSceneIds"
    }
    
    // Обновляем init(from decoder: Decoder)
    required convenience init(from decoder: Decoder) throws {
        self.init() // Вызываем пустой init для установки значений по умолчанию
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isParent = try container.decodeIfPresent(Bool.self, forKey: .isParent) ?? false
        parentSceneId = try container.decodeIfPresent(Int.self, forKey: .parentSceneId) ?? 0
        isIndoor = try container.decodeIfPresent(Bool.self, forKey: .isIndoor) ?? false
        sceneType = try container.decodeIfPresent(SceneType.self, forKey: .sceneType) ?? .house

        // Декодируем новые поля, если они есть, иначе останутся значения по умолчанию
        x = try container.decodeIfPresent(Int.self, forKey: .x) ?? 0
        y = try container.decodeIfPresent(Int.self, forKey: .y) ?? 0
        connections = try container.decodeIfPresent([SceneConnection].self, forKey: .connections) ?? []
        
        _childSceneIds = try container.decodeIfPresent(Set<Int>.self, forKey: ._childSceneIds) ?? []
        _hubSceneIds = try container.decodeIfPresent(Set<Int>.self, forKey: ._hubSceneIds) ?? []

        // parentSceneName и parentSceneType не в CodingKeys, они, видимо, устанавливаются постфактум.
        // runtimeID и isLocked также не в CodingKeys, предполагается, что они не из JSON.
    }

    // Обновляем encode(to encoder: Encoder)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isParent, forKey: .isParent)
        try container.encode(parentSceneId, forKey: .parentSceneId)
        try container.encode(isIndoor, forKey: .isIndoor)
        try container.encode(sceneType, forKey: .sceneType)

        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(connections, forKey: .connections)
        
        try container.encode(_childSceneIds, forKey: ._childSceneIds)
        try container.encode(_hubSceneIds, forKey: ._hubSceneIds)
        // runtimeID и isLocked не кодируем, так как они управляются логикой игры, а не являются частью статических данных локации из JSON
    }
    
    func getCharacters() -> [any Character] {
        return Array(_characters.values)
    }
    
    func getNPCs() -> [NPC] {
        return _characters.values.compactMap { $0 as? NPC }
    }
    
    func removeCharacter(id: Int) {
        if _characters.contains(where: { $0.key == id }) {
            _characters.removeValue(forKey: id)
            
            NotificationCenter.default.post(name: .sceneCharactersChanged, object: self)
        }
    }
    
    func npcCount() -> Int {
        return _characters.count
    }
    
    func closeOpenLock(isNight: Bool) {
        let characters = _characters.values.compactMap { $0 as? NPC }
        
        // First, determine if this is a lockable building type
        let isLockableBuilding = (sceneType != .district &&
                                 sceneType != .square &&
                                 sceneType != .road &&
                                 sceneType != .town &&
                                 sceneType != .tavern &&
                                 sceneType != .brothel &&
                                 sceneType != .dungeon)
        
        if isLockableBuilding {
            if characters.count == 0 {
                // Empty houses should be locked
                isLocked = true
            } else if isNight {
                // At night, lock if anyone is sleeping
                isLocked = characters.contains { $0.currentActivity == .sleep } || !characters.contains { $0.playerRelationship.state != .friend }
            } else {
                // During day, lock if everyone is sleeping
                isLocked = characters.allSatisfy { $0.currentActivity == .sleep } && !characters.contains { $0.playerRelationship.state != .friend } 
            }
        } else {
            // Public places are never locked
            isLocked = false
        }
    }
    
    func addCharacter(_ character: any Character) {
        _characters[character.id] = character
        character.currentLocationId = self.id
        
        NotificationCenter.default.post(name: .sceneCharactersChanged, object: self)
    }
    
    func hasCharacter(with id: Int) -> Bool {
        return _characters.contains(where: { $0.key == id })
    }
    
    func setCharacters(_ characters: [any Character]) {
        _characters = characters.reduce(into: [:]) { $0[$1.id] = $1 }
        
        for character in characters {
            character.currentLocationId = self.id
        }
        
        // Post notification when characters are changed
        NotificationCenter.default.post(name: .sceneCharactersChanged, object: self)
    }
    
    func getCharacter(by id: Int) -> (any Character)? {
        return _characters[id]
    }
    
    func addChildScene(_ childSceneId: Int) {
        _childSceneIds.insert(childSceneId)
    }
    
    func removeChildScene(_ childSceneId: Int) {
        _childSceneIds.remove(childSceneId)
    }
}

extension Scene: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Scene, rhs: Scene) -> Bool {
        return lhs.id == rhs.id
    }
}

