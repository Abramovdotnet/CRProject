//
//  SmithingSystem.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 25.04.2025.
//

class Recipe : Codable, Identifiable {
    var id: Int { resultItemId } // Using resultItemId as the unique identifier
    var profession: Profession = .blacksmith
    var requiredResources: [RecipeResource] = []
    var professionLevel: Int = 0
    var resultItemId: Int = 0
    
    init(profession: Profession, requiredResources: [RecipeResource], professionLevel: Int, resultItemId: Int) {
        self.profession = profession
        self.requiredResources = requiredResources
        self.professionLevel = professionLevel
        self.resultItemId = resultItemId
    }
    
    enum CodingKeys: String, CodingKey {
        case profession
        case requiredResources
        case professionLevel
        case resultItemId
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
    }
}

class RecipeResource : Codable {
    var resourceId: Int = 0
    var count: Int = 0
}
