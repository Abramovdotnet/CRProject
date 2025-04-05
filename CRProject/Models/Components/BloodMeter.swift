//
//  BloodMeter.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//

import Foundation

class BloodMeter : ObservableObject, Codable {
    private var _currentBlood: Float
    private var maxBlood: Float = 100
    
    var currentBlood: Float {
        get { _currentBlood }
        set { _currentBlood = min(max(newValue, 0), maxBlood) }
    }
    
    var bloodPercentage: Float {
        return (_currentBlood / maxBlood) * 100
    }
    
    init(initialBlood: Float) {
        self._currentBlood = min(max(initialBlood, 0), maxBlood)
    }
    
    func addBlood(_ amount: Float) {
        guard amount > 0 else { return }
        _currentBlood = min(_currentBlood + amount, maxBlood)
    }
    
    func useBlood(_ amount: Float) {
        guard amount > 0 else { return }
        
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
        let availableBlood = _currentBlood
        _currentBlood = 0
        return availableBlood
    }
    
    enum CodingKeys: String, CodingKey {
        case _currentBlood, maxBlood
    }
}
