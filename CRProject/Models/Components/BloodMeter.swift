//
//  BloodMeter.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//

import Foundation

class BloodMeter : ObservableObject, Codable {
    private var _currentBlood: Float
    private let MAX_BLOOD: Float = 100
    
    var currentBlood: Float { get { return _currentBlood }}
    var maxBlood: Float { get { return MAX_BLOOD }}
    var bloodPercentage: Float { get { return _currentBlood / MAX_BLOOD * 100.0 }}
    
    init(initialBlood: Float = 100.0) {
        self._currentBlood = min(max(initialBlood, 0), MAX_BLOOD)
      }
    
    func addBlood(_ amount: Float) {
        guard amount > 0 else { return }
        _currentBlood = min(_currentBlood + amount, MAX_BLOOD)
    }
    
    func useBlood(_ amount: Float) {
        guard amount > 0 else { return }
        guard amount <= _currentBlood else { return }
        
        _currentBlood -= amount
    }
    
    func hasEnoughBlood(_ amount: Float) -> Bool {
        return amount <= _currentBlood
    }
    
    func setBlood(_ amount: Float) {
        _currentBlood = min(max(amount, 0), MAX_BLOOD)
    }
}
