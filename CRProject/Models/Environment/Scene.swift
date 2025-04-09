import Foundation
import Combine

extension Notification.Name {
    static let sceneCharactersChanged = Notification.Name("sceneCharactersChanged")
}

class Scene: SceneProtocol, Codable, ObservableObject, Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var parentSceneId: UUID?
    var isIndoor: Bool = false
    var sceneType: SceneType = .alchemistShop
    var runtimeID: UUID? = UUID()
    
    @Published private var _characters: [UUID: any Character] = [:]
    private var _childSceneIds: Set<UUID> = []
    
    var childSceneIds: [UUID] {
        get { Array(_childSceneIds) }
        set { _childSceneIds = Set(newValue) }
    }
    
    init(id: UUID, name: String, isIndoor: Bool, parentSceneId: UUID?, sceneType: SceneType) {
        self.id = id
        self.name = name
        self.isIndoor = isIndoor
        self.parentSceneId = parentSceneId
        self.sceneType = sceneType
    }
    
    init() {
        
    }
    private enum CodingKeys: String, CodingKey {
        case id, name, parentSceneId, isIndoor
    }
    
    func getCharacters() -> [any Character] {
        return Array(_characters.values)
    }
    
    func setCharacters(_ characters: [any Character]) {
        _characters = characters.reduce(into: [:]) { $0[$1.id] = $1 }
        // Post notification when characters are changed
        NotificationCenter.default.post(name: .sceneCharactersChanged, object: self)
    }
    
    func getCharacter(by id: UUID) -> (any Character)? {
        return _characters[id]
    }
    
    func addChildScene(_ childSceneId: UUID) {
        _childSceneIds.insert(childSceneId)
    }
    
    func removeChildScene(_ childSceneId: UUID) {
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

