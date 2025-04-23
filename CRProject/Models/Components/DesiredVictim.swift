//
//  DesiredVictim.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 14.04.2025.
//

import Foundation

class DesiredVictim {
    enum AgeRange: CaseIterable {
        case young      // 18-30
        case middleAge  // 31-50
        case mature     // 51-70
        
        var range: ClosedRange<Int> {
            switch self {
            case .young: return 18...30
            case .middleAge: return 31...50
            case .mature: return 51...70
            }
        }
        
        var rangeDescription: String {
            switch self {
            case .young: return "18-30"
            case .middleAge: return "31-50"
            case .mature: return "51-70"
            }
        }
        
        static func getRange(for age: Int) -> AgeRange? {
            return AgeRange.allCases.first { $0.range.contains(age) }
        }
    }
    
    // Desired characteristics
    private(set) var desiredProfession: Profession?
    private(set) var desiredMorality: Morality?
    private(set) var desiredAgeRange: AgeRange?
    private(set) var desiredSex: Sex?
    
    init() {
        updateDesiredVictim()
    }
    
    /// Sets random characteristics for the desired victim
    func updateDesiredVictim() {
        // Get all available professions and remove noProfession
        let availableProfessions = Profession.allCases
        
        // Randomly decide how many characteristics to use (3-5)
        let numberOfCharacteristics = Int.random(in: 1...3)
        
        // Reset all characteristics
        desiredProfession = nil
        desiredMorality = nil
        desiredAgeRange = nil
        desiredSex = nil
        
        // Create array of available characteristic types
        var characteristicTypes = [
            "profession",
            "morality",
            "ageRange",
            "sex",
            "motivation"
        ].shuffled()
        
        // Select random characteristics based on the number chosen
        for _ in 0..<numberOfCharacteristics {
            guard let characteristicType = characteristicTypes.popLast() else { break }
            
            switch characteristicType {
            case "profession":
                desiredProfession = availableProfessions.randomElement()
            case "morality":
                desiredMorality = Morality.allCases.randomElement()
            case "ageRange":
                desiredAgeRange = AgeRange.allCases.randomElement()
            case "sex":
                desiredSex = Sex.allCases.randomElement()
            default:
                break
            }
        }
    }
    
    /// Checks if an NPC matches the desired characteristics
    /// - Parameter npc: The NPC to check
    /// - Returns: true if the NPC matches all set characteristics
    func isDesiredVictim(npc: NPC) -> Bool {
        // Check each characteristic that has been set
        if let desiredProfession = desiredProfession,
           npc.profession != desiredProfession {
            return false
        }
        
        if let desiredMorality = desiredMorality,
           npc.morality != desiredMorality {
            return false
        }
        
        if let desiredAgeRange = desiredAgeRange,
           !desiredAgeRange.range.contains(npc.age) {
            return false
        }
        
        if let desiredSex = desiredSex,
           npc.sex != desiredSex {
            return false
        }
        
        // If all set characteristics match (or none were set), return true
        return true
    }
    
    /// Gets a description of the desired characteristics
    /// - Returns: A string describing the desired victim characteristics
    func getDescription() -> String {
        var descriptions: [String] = []
        
        if let sex = desiredSex {
            descriptions.append("\(sex == .male ? "male" : "female")")
        }
        
        if let ageRange = desiredAgeRange {
            switch ageRange {
            case .young:
                descriptions.append("young (18-30)")
            case .middleAge:
                descriptions.append("middle-aged (31-50)")
            case .mature:
                descriptions.append("mature (51-70)")
            }
        }
        
        if let profession = desiredProfession {
            descriptions.append(profession.rawValue.lowercased())
        }
        
        if let morality = desiredMorality {
            descriptions.append(morality.rawValue.lowercased())
        }
        
        return descriptions.joined(separator: ", ")
    }
} 
