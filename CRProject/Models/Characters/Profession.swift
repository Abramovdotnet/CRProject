import Foundation
import SwiftUI

enum Profession: String, CaseIterable, Codable {
    case blacksmith      = "Blacksmith"
    case miller          = "Miller"
    case cooper          = "Cooper"
    case chandler        = "Chandler"
    case priest          = "Priest"
    case bowyer          = "Bowyer"
    case armorer         = "Armorer"
    case merchant        = "Merchant"
    case carpenter       = "Carpenter"
    case thatcher        = "Thatcher"
    case tanner          = "Tanner"
    case weaver          = "Weaver"
    case hunter          = "Hunter"
    case tailor          = "Tailor"
    case baker           = "Baker"
    case butcher         = "Butcher"
    case brewer          = "Brewer"
    case apothecary      = "Apothecary"
    case scribe          = "Scribe"
    case herald          = "Herald"
    case minstrel        = "Minstrel"
    case guardman        = "Guardman"
    case alchemist       = "Alchemist"
    case farrier         = "Farrier"
    case innkeeper        = "Innkeeper"
    case adventurer      = "Adventurer"
    case wenche          = "Wenche"
    case general         = "General"
    
    // MARK: - Icon and Color Properties
    
    var icon: String {
        switch self {
        case .blacksmith:    return "hammer.fill"
        case .miller:        return "windmill"
        case .cooper:        return "barrel.fill"
        case .chandler:      return "candle.fill"
        case .priest:        return "cross.fill"
        case .bowyer:        return "arrow.up.right"
        case .armorer:       return "shield.fill"
        case .merchant:      return "bag.fill"
        case .carpenter:     return "hammer"
        case .thatcher:      return "house.fill"
        case .weaver:        return "spool.fill"
        case .hunter:        return "arrow.up.right.circle.fill"
        case .tailor:        return "scissors"
        case .tanner:        return "leather"
        case .baker:         return "oven.fill"
        case .butcher:       return "knife.fill"
        case .brewer:        return "mug.fill"
        case .apothecary:    return "pills.fill"
        case .scribe:        return "pencil"
        case .herald:        return "megaphone.fill"
        case .minstrel:      return "music.note"
        case .guardman:      return "shield.checkered"
        case .alchemist:     return "flask.fill"
        case .farrier:       return "horseshoe"
        case .innkeeper:     return "bed.double.fill"
        case .adventurer:    return "map.fill"
        case .wenche:        return "person.fill"
        case .general:       return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .blacksmith:    return .orange
        case .miller:        return .brown
        case .cooper:        return .brown
        case .chandler:      return .yellow
        case .priest:        return .purple
        case .bowyer:        return .green
        case .armorer:       return .gray
        case .merchant:      return .blue
        case .carpenter:     return .brown
        case .thatcher:      return .brown
        case .tanner:        return .brown
        case .weaver:        return .pink
        case .hunter:        return .green
        case .tailor:        return .pink
        case .baker:         return .orange
        case .butcher:       return .red
        case .brewer:        return .brown
        case .apothecary:    return .green
        case .scribe:        return .blue
        case .herald:        return .purple
        case .minstrel:      return .purple
        case .guardman:      return .blue
        case .alchemist:     return .purple
        case .farrier:       return .brown
        case .innkeeper:     return .blue
        case .adventurer:    return .green
        case .wenche:        return .pink
        case .general:       return .red
        }
    }
}
