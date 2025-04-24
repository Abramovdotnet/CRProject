//
//  BloodMeter.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//

import Foundation

class BloodMeter : ObservableObject, Codable {
    @Published private var _currentBlood: Float
    private var maxBlood: Float = 100
    
    var currentBlood: Float {
        get { _currentBlood }
        set {
            objectWillChange.send()
            _currentBlood = min(max(newValue, 0), maxBlood)
        }
    }
    
    var bloodPercentage: Float {
        return (_currentBlood / maxBlood) * 100
    }
    
    init(initialBlood: Float) {
        self._currentBlood = min(max(initialBlood, 0), maxBlood)
    }
    
    func addBlood(_ amount: Float) {
        guard amount > 0 else { return }
        objectWillChange.send()
        _currentBlood = min(_currentBlood + amount, maxBlood)
    }
    
    func useBlood(_ amount: Float) {
        guard amount > 0 else { return }
        objectWillChange.send()
        if _currentBlood <= amount {
            _currentBlood = 0
        } else {
            _currentBlood -= amount
        }
    }
    
    func hasEnoughBlood(_ amount: Float) -> Bool {
        return amount <= _currentBlood
    }
    
    func emptyBlood() -> Float {
        objectWillChange.send()
        let availableBlood = _currentBlood
        _currentBlood = 0
        return availableBlood
    }
    
    enum CodingKeys: String, CodingKey {
        case _currentBlood, maxBlood
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _currentBlood = try container.decode(Float.self, forKey: ._currentBlood)
        maxBlood = try container.decode(Float.self, forKey: .maxBlood)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_currentBlood, forKey: ._currentBlood)
        try container.encode(maxBlood, forKey: .maxBlood)
    }
}
