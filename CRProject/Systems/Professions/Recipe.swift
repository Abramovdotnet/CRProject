//
//  SmithingSystem.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 25.04.2025.
//

import Foundation
import Combine

class Recipe : Codable, Identifiable, ObservableObject {
    var id: Int { resultItemId } // Using resultItemId as the unique identifier
    var profession: Profession = .blacksmith
    @Published var requiredResources: [RecipeResource] = []
    var professionLevel: Int = 0
    var resultItemId: Int = 0
    var productionTime: Int = 0
    
    init(profession: Profession, requiredResources: [RecipeResource], professionLevel: Int, resultItemId: Int, productionTime: Int = 1) {
        self.profession = profession
        self.requiredResources = requiredResources
        self.professionLevel = professionLevel
        self.resultItemId = resultItemId
        self.productionTime = productionTime
    }
    
    enum CodingKeys: String, CodingKey {
        case profession
        case requiredResources
        case professionLevel
        case resultItemId
        case productionTime
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle case-insensitive profession decoding
        let professionString = try container.decode(String.self, forKey: .profession)
        if let profession = Profession.allCases.first(where: { $0.rawValue.lowercased() == professionString.lowercased() }) {
            self.profession = profession
        } else {
            throw DecodingError.dataCorruptedError(forKey: .profession, in: container, debugDescription: "Invalid profession value: \(professionString)")
        }
        
        requiredResources = try container.decode([RecipeResource].self, forKey: .requiredResources)
        professionLevel = try container.decode(Int.self, forKey: .professionLevel)
        resultItemId = try container.decode(Int.self, forKey: .resultItemId)
        productionTime = try container.decode(Int.self, forKey: .productionTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(profession.rawValue, forKey: .profession)
        try container.encode(requiredResources, forKey: .requiredResources)
        try container.encode(professionLevel, forKey: .professionLevel)
        try container.encode(resultItemId, forKey: .resultItemId)
        try container.encode(productionTime, forKey: .productionTime)
    }
}

class RecipeResource : Codable, ObservableObject {
    @Published var resourceId: Int = 0
    @Published var count: Int = 0
    @Published var availableCount: Int = 0
    
    init(resourceId: Int, count: Int) {
        self.resourceId = resourceId
        self.count = count
    }
    
    enum CodingKeys: String, CodingKey {
        case resourceId
        case count
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resourceId = try container.decode(Int.self, forKey: .resourceId)
        count = try container.decode(Int.self, forKey: .count)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(resourceId, forKey: .resourceId)
        try container.encode(count, forKey: .count)
    }
}
