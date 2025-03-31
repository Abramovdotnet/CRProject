import Foundation

@dynamicMemberLookup
class NPCBuilder {
    private var npc = NPC()
    
    subscript<T>(dynamicMember keyPath: WritableKeyPath<NPC, T>) -> ((T) -> NPCBuilder) {
        return { value in
            self.npc[keyPath: keyPath] = value
            return self
        }
    }
    
    func build() -> NPC {
        return npc
    }
}
