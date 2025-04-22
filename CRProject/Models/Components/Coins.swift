//
//  Money.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 22.04.2025.
//

import Combine

class Coins : ObservableObject, Codable {
    private let MIN_VALUE: Int = 0
    var value: Int = 0
    
    func couldRemove(_ amount: Int) -> Bool {
        return amount <= value
    }
    
    func add(_ amount: Int) {
        value += amount
    }
    
    func remove(_ amount: Int) {
        if couldRemove(amount) {
            value -= amount
        }
    }
}
