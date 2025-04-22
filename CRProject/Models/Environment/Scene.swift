import Foundation
import Combine

extension Notification.Name {
    static let sceneCharactersChanged = Notification.Name("sceneCharactersChanged")
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
    
    init(id: Int, name: String, isParent: Bool, parentSceneId: Int, parentSceneName: String, parentSceneType: SceneType, isIndoor: Bool, sceneType: SceneType) {
        self.id = id
        self.name = name
        self.isParent = isParent
        self.parentSceneId = parentSceneId
        self.parentSceneName = parentSceneName
        self.parentSceneType = parentSceneType
        self.isIndoor = isIndoor
        self.sceneType = sceneType
    }
    
    init() {
        
    }
    private enum CodingKeys: String, CodingKey {
        case id, name, isParent, parentSceneId, isIndoor
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
        var characters = _characters.values.compactMap { $0 as? NPC }
        
        // First, determine if this is a lockable building type
        let isLockableBuilding = (sceneType != .district &&
                                 sceneType != .square &&
                                 sceneType != .road &&
                                 sceneType != .town &&
                                 sceneType != .tavern &&
                                 sceneType != .brothel)
        
        if isLockableBuilding {
            if characters == nil ||  characters.count == 0 {
                // Empty houses should be locked
                isLocked = true
            } else if isNight {
                // At night, lock if anyone is sleeping
                isLocked = characters.contains { $0.currentActivity == .sleep } && !characters.contains { $0.playerRelationship.state != .friend }
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

