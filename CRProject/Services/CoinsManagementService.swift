//
//  CoinsExchangeService.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 22.04.2025.
//

class CoinsManagementService : GameService {
    static let shared: CoinsManagementService = DependencyManager.shared.resolve()
    
    func moveCoins(from: NPC, to: NPC, amount: Int) {
        if from.coins.couldRemove(amount) {
            from.coins.remove(amount)
            to.coins.add(amount)
        }
    }
    
    func updateWorldEconomy() {
        var npcs = NPCReader.getNPCs()
        
        for npc in npcs {
            if npc.coins.value == 0 {
                npc.coins.add(Int.random(in: 1...500))
            }
        }
    }
}
