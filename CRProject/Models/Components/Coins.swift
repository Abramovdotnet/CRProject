//
//  Money.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 22.04.2025.
//

import Combine

class Coins : ObservableObject, Codable {
    private let MIN_VALUE: Int = 0
    @Published var value: Int = 0
    
    // --- Codable Conformance ---
    enum CodingKeys: String, CodingKey {
        case value
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decode(Int.self, forKey: .value)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
    }
    
    // Add a default initializer if needed by ObservableObject or other contexts
    init() {
        self.value = 0
    }
    // --- End Codable --- 

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
