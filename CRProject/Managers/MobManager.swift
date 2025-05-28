//
//  ModManager.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 28.05.2025.
//

class MobManager {
    static let shared = MobManager()
    
    func spawnMobAtScene(ofType type: MobType, at locationId: Int) {
        guard let scene = GameStateService.shared.currentScene else { return }
        let mob = createMobByType(type)
        scene.addCharacter(mob)
        
        print("\(mob.name) spawned at \(scene.name)")
    }
    
    func createMobByType(_ type: MobType) -> NPC {
        let id = generateMobId()
        let mob = NPC(mobType: type, id: id)
        mob.name = "\(type)"
        mob.isUnknown = false
        return mob
    }
    
    private func generateMobId() -> Int {
        return Int.random(in: 10000..<Int.max)
    }
}
