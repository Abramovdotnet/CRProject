import Foundation
import Combine

class Scene: SceneProtocol, Codable, ObservableObject {
    let id: UUID = UUID()
    var name: String = ""
    var parentSceneId: UUID?
    
    @Published private var _characters: [UUID: any Character] = [:]
    private var _childSceneIds: Set<UUID> = []
    
    var childSceneIds: [UUID] {
        get { Array(_childSceneIds) }
        set { _childSceneIds = Set(newValue) }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, parentSceneId
    }
    
    func getCharacters() -> [any Character] {
        return Array(_characters.values)
    }
    
    func setCharacters(_ characters: [any Character]) {
        _characters = characters.reduce(into: [:]) { $0[$1.id] = $1 }
    }
    
    func getCharacter(by id: UUID) -> (any Character)? {
        return _characters[id]
    }
    
    func addCharacter(_ character: any Character) {
        _characters[character.id] = character
    }
    
    func removeCharacter(by id: UUID) {
        _characters.removeValue(forKey: id)
    }
    
    func addChildScene(_ childSceneId: UUID) {
        _childSceneIds.insert(childSceneId)
    }
    
    func removeChildScene(_ childSceneId: UUID) {
        _childSceneIds.remove(childSceneId)
    }
}
