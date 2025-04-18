import Foundation
import SwiftUI

enum Profession: String, CaseIterable, Codable {
    case blacksmith      = "Blacksmith"
    case priest          = "Priest"
    case merchant        = "Merchant"
    case carpenter       = "Carpenter"
    case tailor          = "Tailor"
    case guardman        = "Guardman"
    case alchemist       = "Alchemist"
    case adventurer      = "Adventurer"
    case cityGuard      = "City guard"
    case gardener        = "Gardener"
    case maintenanceWorker = "Maintenance worker"
    case cleaner         = "Cleaner"
    case apprentice      = "Apprentice"
    case lordLady       = "Lord/Lady"
    case administrator   = "Administrator"
    case stableHand     = "Stable hand"
    case kitchenStaff   = "Kitchen staff"
    case militaryOfficer = "Military officer"
    case servant        = "Servant"
    case monk           = "Monk"
    case religiousScholar = "Religious scholar"
    case generalLaborer = "General laborer"
    case bookseller     = "Bookseller"
    case herbalist      = "Herbalist"
    case barmaid        = "Barmaid"
    case entertainer    = "Entertainer"
    case tavernKeeper   = "Tavern keeper"
    case dockWorker     = "Dock worker"
    case sailor         = "Sailor"
    case shipCaptain    = "Ship captain"
    case pilgrim        = "Pilgrim"
    case courtesan      = "Courtesan"
    case mercenary      = "Mercenary"
    case thug           = "Thug"
    case noProfession   = "No profession"
    
    // MARK: - Icon and Color Properties
    
    var icon: String {
        switch self {
        case .blacksmith:    return "hammer.fill"
        case .priest:        return "cross.fill"
        case .merchant:      return "bag.fill"
        case .carpenter:     return "hammer"
        case .tailor:        return "scissors"
        case .guardman:      return "shield.checkered"
        case .alchemist:     return "flask.fill"
        case .adventurer:    return "map.fill"
        case .cityGuard:     return "shield.checkered"
        case .gardener:      return "leaf.fill"
        case .maintenanceWorker: return "wrench.fill"
        case .cleaner:       return "paintbrush.fill"
        case .apprentice:    return "book.fill"
        case .lordLady:     return "crown.fill"
        case .administrator: return "person.fill.badge.plus"
        case .stableHand:   return "horseshoe"
        case .kitchenStaff: return "fork.knife"
        case .militaryOfficer: return "star.fill"
        case .servant:      return "person.fill"
        case .monk:         return "person.fill.checkmark"
        case .religiousScholar: return "book.closed.fill"
        case .generalLaborer: return "person.fill"
        case .bookseller:   return "book.fill"
        case .herbalist:    return "leaf.fill"
        case .barmaid:      return "mug.fill"
        case .entertainer:  return "music.note"
        case .tavernKeeper: return "bed.double.fill"
        case .dockWorker:   return "hammer.fill"
        case .sailor:       return "sailboat.fill"
        case .shipCaptain:  return "person.fill.badge.plus"
        case .pilgrim:      return "person.fill.checkmark"
        case .courtesan:    return "heart.fill"
        case .mercenary:    return "person.badge.shield.checkmark.fill"
        case .thug:         return "figure.wrestling"
        case .noProfession: return "person.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .blacksmith:    return .orange
        case .priest:        return .purple
        case .merchant:      return .blue
        case .carpenter:     return .brown
        case .tailor:        return .pink
        case .guardman:      return .blue
        case .alchemist:     return .purple
        case .adventurer:    return .green
        case .cityGuard:     return .blue
        case .gardener:      return .green
        case .maintenanceWorker: return .gray
        case .cleaner:       return .gray
        case .apprentice:    return .blue
        case .lordLady:     return .purple
        case .administrator: return .blue
        case .stableHand:   return .brown
        case .kitchenStaff: return .orange
        case .militaryOfficer: return .red
        case .servant:      return .gray
        case .monk:         return .purple
        case .religiousScholar: return .purple
        case .generalLaborer: return .gray
        case .bookseller:   return .blue
        case .herbalist:    return .green
        case .barmaid:      return .pink
        case .entertainer:  return .purple
        case .tavernKeeper: return .blue
        case .dockWorker:   return .brown
        case .sailor:       return .blue
        case .shipCaptain:  return .blue
        case .pilgrim:      return .purple
        case .courtesan:    return .pink
        case .mercenary:    return .red
        case .thug:         return .red
        case .noProfession: return .gray
        }
    }
}
