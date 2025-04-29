//
//  Ability.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 29.04.2025.
//

import SwiftUICore

class AbilitiesSystem {
    var id: Int = 0
    var playerAbilities: [Ability] = []
    static var shared: AbilitiesSystem = AbilitiesSystem()
    
    var hasSeduction: Bool { playerAbilities.contains(.seduction) }
    var hasDomination: Bool { playerAbilities.contains(.domination) }
    var hasWhisper: Bool { playerAbilities.contains(.whisper) }
    var hasEnthralling: Bool { playerAbilities.contains(.enthralling) }
    var hasSmithingNovice: Bool { playerAbilities.contains(.smithingNovice) }
    var hasSmithingApprentice: Bool { playerAbilities.contains(.smithingApprentice) }
    var hasSmithingExpert: Bool { playerAbilities.contains(.smithingExpert) }
    var hasSmithingMaster: Bool { playerAbilities.contains(.smithingMaster) }
    var hasAlchemyNovice: Bool { playerAbilities.contains(.alchemyNovice) }
    var hasAlchemyApprentice: Bool { playerAbilities.contains(.alchemyApprentice) }
    var hasAlchemyExpert: Bool { playerAbilities.contains(.alchemyExpert) }
    var hasAlchemyMaster: Bool { playerAbilities.contains(.alchemyMaster) }
    var hasBribe: Bool { playerAbilities.contains(.bribe) }
    var hasTrader: Bool { playerAbilities.contains(.trader) }
    var hasInvisibility: Bool { playerAbilities.contains(.invisibility) }
    var hasCommand: Bool { playerAbilities.contains(.command) }
    var hasDayWalker: Bool { playerAbilities.contains(.dayWalker) }
    
    func unlockAbility(_ ability: Ability) {
        if !playerAbilities.contains(ability) {
            playerAbilities.append(ability)
            
            PopUpState.shared.show(title: "\(ability.name) ability unlocked", details: "\(ability.description)", image: .system(name: ability.icon, color: ability.color))
        }
    }
    
    func checkIsMeetsSeductionRequirements() -> Bool {
        return StatisticsService.shared.feedingsOverSleepingVictims >= 5 && StatisticsService.shared.feedingsOverDesiredVictims >= 1
    }
    
    func checkIsMeetsDominationRequirements() -> Bool {
        return StatisticsService.shared.peopleSeducted >= 5 && StatisticsService.shared.bribes >= 5 && StatisticsService.shared.feedingsOverDesiredVictims >= 3 && StatisticsService.shared.victimsDrained >= 1
    }
    
    func checkIsMeetsWhisperRequirements() -> Bool {
        return StatisticsService.shared.peopleSeducted >= 10 && StatisticsService.shared.feedingsOverSleepingVictims >= 5 && StatisticsService.shared.feedingsOverDesiredVictims >= 3
    }
    
    func checkIsMeetsEnthrallingRequirements() -> Bool {
        return StatisticsService.shared.peopleDominated >= 10 && StatisticsService.shared.propertiesBought >= 1 && StatisticsService.shared.feedingsOverDesiredVictims >= 10 && StatisticsService.shared.victimsDrained >= 5
    }
    
    func checkIsMeetsSmithingNoviceRequirements() -> Bool {
        return StatisticsService.shared.smithingRecipesUnlocked >= 10
    }
    
    func checkIsMeetsSmithingApprenticeRequirements() -> Bool {
        return hasSmithingNovice && StatisticsService.shared.smithingRecipesUnlocked >= 20
    }
    
    func checkIsMeetsSmithingExpertRequirements() -> Bool {
        return hasSmithingApprentice && StatisticsService.shared.smithingRecipesUnlocked >= 40
    }
    
    func checkIsMeetsSmithingMasterRequirements() -> Bool {
        return hasSmithingExpert && StatisticsService.shared.smithingRecipesUnlocked >= 60
    }
    
    func checkIsMeetsAlchemyNoviceRequirements() -> Bool {
        return StatisticsService.shared.alchemyRecipesUnlocked >= 10
    }
    
    func checkIsMeetsAlchemyApprenticeRequirements() -> Bool {
        return hasAlchemyNovice && StatisticsService.shared.alchemyRecipesUnlocked >= 20
    }
    
    func checkIsMeetsAlchemyExpertRequirements() -> Bool {
        return hasAlchemyApprentice && StatisticsService.shared.alchemyRecipesUnlocked >= 40
    }
    
    func checkIsMeetsAlchemyMasterRequirements() -> Bool {
        return hasAlchemyExpert && StatisticsService.shared.alchemyRecipesUnlocked >= 60
    }
    
    func checkIsMeetsBribeRequirements() -> Bool {
        return StatisticsService.shared._500CoinsDeals >= 10
    }
    
    func checkIsMeetsTraderRequirements() -> Bool {
        return StatisticsService.shared._1000CoinsDeals >= 20
    }
    
    func checkIsMeetsInvisibilityRequirements() -> Bool {
        return StatisticsService.shared.daysSurvived >= 5 && StatisticsService.shared.feedingsOverDesiredVictims >= 5
    }
    
    func checkIsMeetsCommandRequirements() -> Bool {
        return StatisticsService.shared.peopleSeducted >= 5 && StatisticsService.shared.feedingsOverDesiredVictims >= 5
    }
    
    func checkIsMeetsDayWalkerRequirements() -> Bool {
        return StatisticsService.shared.daysSurvived >= 10 && StatisticsService.shared.feedingsOverDesiredVictims >= 10 && StatisticsService.shared.victimsDrained >= 3
    }
    
    func canUnlock(_ ability: Ability) -> Bool {
        switch ability {
        case .seduction: return checkIsMeetsSeductionRequirements()
        case .domination: return checkIsMeetsDominationRequirements()
        case .whisper: return checkIsMeetsWhisperRequirements()
        case .enthralling: return checkIsMeetsEnthrallingRequirements()
        case .smithingNovice: return checkIsMeetsSmithingNoviceRequirements()
        case .smithingApprentice: return checkIsMeetsSmithingApprenticeRequirements()
        case .smithingExpert: return checkIsMeetsSmithingExpertRequirements()
        case .smithingMaster: return checkIsMeetsSmithingMasterRequirements()
        case .alchemyNovice: return checkIsMeetsAlchemyNoviceRequirements()
        case .alchemyApprentice: return checkIsMeetsAlchemyApprenticeRequirements()
        case .alchemyExpert: return checkIsMeetsAlchemyExpertRequirements()
        case .alchemyMaster: return checkIsMeetsAlchemyMasterRequirements()
        case .bribe: return checkIsMeetsBribeRequirements()
        case .trader: return checkIsMeetsTraderRequirements()
        case .invisibility: return checkIsMeetsInvisibilityRequirements()
        case .command: return checkIsMeetsCommandRequirements()
        case .dayWalker: return checkIsMeetsDayWalkerRequirements()
        }
    }
    
    func checkForNewUnlocks() -> [Ability] {
        return Ability.allCases.filter {
            !playerAbilities.contains($0) && canUnlock($0)
        }
    }
}

enum Ability: String, CaseIterable {
    case seduction
    case domination
    case whisper
    case command
    case enthralling
    case smithingNovice
    case smithingApprentice
    case smithingExpert
    case smithingMaster
    case alchemyNovice
    case alchemyApprentice
    case alchemyExpert
    case alchemyMaster
    case bribe
    case trader
    case invisibility
    case dayWalker
    
    var name: String {
         switch self {
         case .seduction: return "Seduction"
         case .domination: return "Domination"
         case .whisper: return "Vampiric Whisper"
         case .command: return "Command"
         case .enthralling: return "Eternal Enthrallment"
         case .smithingNovice: return "Novice Smithing"
         case .smithingApprentice: return "Apprentice Smithing"
         case .smithingExpert: return "Expert Smithing"
         case .smithingMaster: return "Master Smithing"
         case .alchemyNovice: return "Novice Alchemy"
         case .alchemyApprentice: return "Apprentice Alchemy"
         case .alchemyExpert: return "Expert Alchemy"
         case .alchemyMaster: return "Master Alchemy"
         case .bribe: return "Silver Tongue"
         case .trader: return "Master Trader"
         case .invisibility: return "Shadow Veil"
         case .dayWalker: return "Day Walker"
         }
     }
    
    var description: String {
        switch self {
        case .seduction:
            return "Seducees victim to follow you and allowing you to feed without dramatic consequences"
        case .domination:
            return "Dominate victim to follow you, and allowing you to feed or manipulate without dramatic consequences"
        case .whisper:
            return "Whisper commands that lure victims to your hiding place"
        case .command:
            return "Force victim to follow your desired behavior"
        case .enthralling:
            return "Permanently enthralls a victim as your eternal servant"
        case .smithingNovice:
            return "Reduce crafting time to 10%"
        case .smithingApprentice:
            return "Reduce crafting time to 20%"
        case .smithingExpert:
            return "Reduce resources required to 10%"
        case .smithingMaster:
            return "Reduce resources required to 20%"
        case .alchemyNovice:
            return "Reduce brewing time to 10%"
        case .alchemyApprentice:
            return "Reduce brewing time to 20%"
        case .alchemyExpert:
            return "Reduce resources required to 10%"
        case .alchemyMaster:
            return "Reduce resources required to 20%"
        case .bribe:
            return "Bribe characters to overlook your activities"
        case .trader:
            return "Get better prices when buying and selling goods"
        case .invisibility:
            return "Disappear in shadows"
        case .dayWalker:
            return "Walk under direct sun if blood pool is higher than 70%"
        }
    }
    
    var requirement: String {
        switch self {
        case .seduction:
            return "Feed on 5 sleeping victims without witnesses. Feed over 1 desired victim."
        case .domination:
            return "Bribe 5 victims. Seduce 5 victims. Feed over 3 desired victims. Drain 1 victim"
        case .whisper:
            return "Use seduction 10 times. Feed over 5 sleeping characters and 3 desired victims"
        case .command:
            return "Use seduction over 5 victims. Feed over 5 desired victims"
        case .enthralling:
            return "Use domination over 10 victims. Feed over 10 desired victims. Drain 5 victims. Own a property"
        case .smithingNovice:
            return "Unlock 10 smithing recipes"
        case .smithingApprentice:
            return "Unlock 20 smithing recipes"
        case .smithingExpert:
            return "Unlock 40 smithing recipes"
        case .smithingMaster:
            return "Unlock 60 smithing recipes"
        case .alchemyNovice:
            return "Unlock 10 alchemy recipes"
        case .alchemyApprentice:
            return "Unlock 20 alchemy recipes"
        case .alchemyExpert:
            return "Unlock 40 alchemy recipes"
        case .alchemyMaster:
            return "Unlock 60 alchemy recipes"
        case .bribe:
            return "Trade 10 times with overall income more that 500 coins at once"
        case .trader:
            return "Trade 20 times with overall income more than 1000 coins at once"
        case .invisibility:
            return "Survive 5 days. Feed over 5 desired victims"
        case .dayWalker:
            return "Survive 10 days. Feed over 10 desired victims. Drain 3 victims"
        }
    }
    
    var icon: String {
            switch self {
            case .seduction: return "heart.fill"
            case .domination: return "brain.head.profile"
            case .whisper: return "waveform"
            case .enthralling: return "link"
            case .smithingNovice: return "hammer.fill"
            case .smithingApprentice: return "hammer.circle.fill"
            case .smithingExpert: return "wrench.and.screwdriver.fill"
            case .smithingMaster: return "sparkles"
            case .alchemyNovice: return "vial"
            case .alchemyApprentice: return "testtube.2"
            case .alchemyExpert: return "pills.fill"
            case .alchemyMaster: return "allergens"
            case .bribe: return "dollarsign.circle.fill"
            case .trader: return "bag.fill"
            case .invisibility: return "eye.slash.fill"
            case .dayWalker: return "sunrise.fill"
            case .command: return "person.wave.2.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .seduction, .domination, .whisper, .enthralling:
                return .pink
            case .smithingNovice, .smithingApprentice, .smithingExpert, .smithingMaster:
                return .orange
            case .alchemyNovice, .alchemyApprentice, .alchemyExpert, .alchemyMaster:
                return .purple
            case .bribe, .trader:
                return .green
            case .invisibility:
                return .indigo
            case .dayWalker:
                return .white
            case .command:
                return .blue
            }
        }
}
