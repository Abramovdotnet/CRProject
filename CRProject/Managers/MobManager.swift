//
//  ModManager.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 28.05.2025.
//

class MobManager {
    static let shared = MobManager()
    private var allItems: [Item] = []
    
    init() {
        allItems = ItemReader.shared.getItems()
    }
    
    func spawnMobAtScene(ofType type: MobType, at locationId: Int) {
        guard let scene = GameStateService.shared.currentScene else { return }
        let mob = createMobByType(type)
        scene.addCharacter(mob)
        
        print("\(mob.name) spawned at \(scene.name)")
    }
    
    func createMobByType(_ type: MobType) -> NPC {
        let id = generateMobId()
        let mob = NPC(mobType: type, id: id)
        mob.name = "\(type.name)"
        mob.isUnknown = false
        giveLoot(type: type, to: mob)
        return mob
    }
    
    private func generateMobId() -> Int {
        return Int.random(in: 10000..<Int.max)
    }
    
    private func giveLoot(type: MobType, to mob: NPC) {
        if type.isHumanoid {
            let randomLootCount = Int.random(in: 0...3)
            for _ in 0..<randomLootCount {
                if let randomItem = allItems.filter({ $0.cost < 300 && $0.type != .artefact && $0.type != .animalLoot }) .randomElement() {
                    mob.items.append(Item.createUnique(randomItem))
                }
            }
            
            mob.coins.value = Int.random(in: 3..<200)
        } else {
            if let fur = allItems.filter({ $0.type == .animalLoot && $0.name.lowercased().contains("fur") }) .first {
                mob.items.append(Item.createUnique(fur))
            }
            
            if let bones = allItems.filter({ $0.type == .animalLoot && $0.name.lowercased().contains("bones") }) .first {
                let bonesCount = Int.random(in: 1...3)
                for _ in 0..<bonesCount {
                    mob.items.append(Item.createUnique(bones))
                }
            }
        }
    }
}
