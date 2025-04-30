//
//  BloodMeter.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//

import Foundation

class BloodMeter : ObservableObject, Codable {
    private var maxBlood: Float = 100
    
    @Published var currentBlood: Float = 0
    @Published var bloodPercentage: Float = 0
    
    init(initialBlood: Float) {
        self.currentBlood = min(max(initialBlood, 0), maxBlood)
        calculateBloodPercentage()
    }
    
    func addBlood(_ amount: Float) {
        guard amount > 0 else { return }
        currentBlood = min(currentBlood + amount, maxBlood)
        calculateBloodPercentage()
    }
    
    func useBlood(_ amount: Float) {
        guard amount > 0 else { return }
        if currentBlood <= amount {
            currentBlood = 0
        } else {
            currentBlood -= amount
        }
        calculateBloodPercentage()
    }
    
    func hasEnoughBlood(_ amount: Float) -> Bool {
        return amount <= currentBlood
    }
    
    func emptyBlood() -> Float {
        let availableBlood = currentBlood
        currentBlood = 0
        calculateBloodPercentage()
        return availableBlood
    }
    
    func calculateBloodPercentage() {
        bloodPercentage = (currentBlood / maxBlood) * 100
    }
    
    enum CodingKeys: String, CodingKey {
        case _currentBlood, maxBlood
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentBlood = try container.decode(Float.self, forKey: ._currentBlood)
        maxBlood = try container.decode(Float.self, forKey: .maxBlood)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currentBlood, forKey: ._currentBlood)
        try container.encode(maxBlood, forKey: .maxBlood)
    }
}
