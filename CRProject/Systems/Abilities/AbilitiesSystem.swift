//
//  Ability.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 29.04.2025.
//

import SwiftUICore
import Combine

class AbilitiesSystem: ObservableObject {
    var id: Int = 0
    @Published var playerAbilities: [Ability] = []
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
    var hasLordOfBlood: Bool { playerAbilities.contains(.lordOfBlood) }
    var hasMasquerade: Bool { playerAbilities.contains(.masquerade) }
    var hasUnholyTongue: Bool { playerAbilities.contains(.unholyTongue) }
    var hasMysteriousPerson: Bool { playerAbilities.contains(.mysteriousPerson) }
    var hasDarkness: Bool { playerAbilities.contains(.darkness) }
    var hasMemoryErasure: Bool { playerAbilities.contains(.memoryErasure) }
    var hasOldFriend: Bool { playerAbilities.contains(.oldFriend) }
    var hasUndeadCasanova: Bool { playerAbilities.contains(.undeadCasanova) }
    var hasSonOfDracula: Bool { playerAbilities.contains(.sonOfDracula) }
    var hasGhost: Bool { playerAbilities.contains(.ghost) }
    
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
        return StatisticsService.shared.daysSurvived >= 5 && StatisticsService.shared.peopleSeducted >= 10 && StatisticsService.shared.feedingsOverDesiredVictims >= 5
    }
    
    func checkIsMeetsWhisperRequirements() -> Bool {
        return StatisticsService.shared.daysSurvived >= 10 && StatisticsService.shared.peopleSeducted >= 15 && StatisticsService.shared.feedingsOverDesiredVictims >= 10
    }
    
    func checkIsMeetsCommandRequirements() -> Bool {
        return StatisticsService.shared.peopleSeducted >= 5 && StatisticsService.shared.feedingsOverDesiredVictims >= 5
    }
    
    func checkIsMeetsDayWalkerRequirements() -> Bool {
        return StatisticsService.shared.daysSurvived >= 10 && StatisticsService.shared.feedingsOverDesiredVictims >= 10 && StatisticsService.shared.victimsDrained >= 3
    }
    
    func checkIsMeetsLordOfBloodRequirements() -> Bool {
        return StatisticsService.shared.daysSurvived >= 30 && StatisticsService.shared.feedingsOverDesiredVictims >= 30 && StatisticsService.shared.peopleDominated >= 30
    }
    
    func checkIsMeetsMasqueradeRequirements() -> Bool {
        return StatisticsService.shared.daysSurvived >= 30 && StatisticsService.shared.foodConsumed >= 100 && StatisticsService.shared.peopleSeducted >= 20
    }
    
    func checkIsMeetsUnholyTongueRequirements() -> Bool {
        return StatisticsService.shared.bribes >= 20
    }
    
    func checkIsMeetsMysteriousPersonRequirements() -> Bool {
        return StatisticsService.shared.bribes >= 10 && StatisticsService.shared.bartersCompleted >= 20
    }
    
    func checkIsMeetsDarknessRequirements() -> Bool {
        return StatisticsService.shared.feedingsOverDesiredVictims >= 15 && 
               StatisticsService.shared.daysSurvived >= 21 && 
               StatisticsService.shared.feedingsOverSleepingVictims >= 30
    }
    
    func checkIsMeetsMemoryErasureRequirements() -> Bool {
        return StatisticsService.shared.daysSurvived >= 40 && 
               StatisticsService.shared.peopleDominated >= 20
    }
    
    func checkIsMeetsOldFriendRequirements() -> Bool {
        return StatisticsService.shared.friendshipsCreated >= 10
    }
    
    func checkIsMeetsUndeadCasanovaRequirements() -> Bool {
        return StatisticsService.shared.friendshipsCreated >= 15 && 
               StatisticsService.shared.nightSpentsWithSomeone >= 20 &&
               StatisticsService.shared.feedingsOverDesiredVictims >= 20
    }
    
    func checkIsMeetsSonOfDraculaRequirements() -> Bool {
        return StatisticsService.shared.daysSurvived >= 100 && 
               StatisticsService.shared.victimsDrained >= 50
    }
    
    func checkIsMeetsGhostRequirements() -> Bool {
        return StatisticsService.shared.disappearances >= 30
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
        case .lordOfBlood: return checkIsMeetsLordOfBloodRequirements()
        case .masquerade: return checkIsMeetsMasqueradeRequirements()
        case .unholyTongue: return checkIsMeetsUnholyTongueRequirements()
        case .mysteriousPerson: return checkIsMeetsMysteriousPersonRequirements()
        case .darkness: return checkIsMeetsDarknessRequirements()
        case .memoryErasure: return checkIsMeetsMemoryErasureRequirements()
        case .oldFriend: return checkIsMeetsOldFriendRequirements()
        case .undeadCasanova: return checkIsMeetsUndeadCasanovaRequirements()
        case .sonOfDracula: return checkIsMeetsSonOfDraculaRequirements()
        case .ghost: return checkIsMeetsGhostRequirements()
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
    case lordOfBlood
    case masquerade
    case unholyTongue
    case mysteriousPerson
    case darkness
    case memoryErasure
    case oldFriend
    case undeadCasanova
    case sonOfDracula
    case ghost
    
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
         case .lordOfBlood: return "Lord of Blood"
         case .masquerade: return "Masquerade"
         case .unholyTongue: return "Unholy Tongue"
         case .mysteriousPerson: return "Mysterious Person"
         case .darkness: return "Darkness"
         case .memoryErasure: return "Memory Erasure"
         case .oldFriend: return "Old Friend"
         case .undeadCasanova: return "Undead Casanova"
         case .sonOfDracula: return "Son of Dracula"
         case .ghost: return "Ghost"
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
        case .lordOfBlood:
            return "Reduce regular blood loss twice"
        case .masquerade:
            return "Consuming food reduces awareness twice"
        case .unholyTongue:
            return "Increases persuasion success chance to 20%"
        case .mysteriousPerson:
            return "Convince persons to make fake alibies for you"
        case .darkness:
            return "Turn off all light sources to perform single actions out of witnesses sight"
        case .memoryErasure:
            return "Calm person if fleeing, reduce awareness and reset negative relationships to zero"
        case .oldFriend:
            return "Increase relationship gain rate twice"
        case .undeadCasanova:
            return "Persons who've spent nights with you gain permanent relationship bonuses and can help convince others that gossip about you is false once per day"
        case .sonOfDracula:
            return "Each drained victim permanently increases your blood pool by 1"
        case .ghost:
            return "Shadow Veil appearance/disappearance does not affect awareness"
        }
    }
    
    var requirement: String {
        switch self {
        case .seduction:
            return "Feed on 5 sleeping victims without witnesses. Feed over 1 desired victim."
        case .domination:
            return "Bribe 5 victims. Seduce 5 victims. Feed over 3 desired victims. Drain 1 victim"
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
            return "Survive 5 days. Seduce 10 victims. Feed over 5 desired victims"
        case .whisper:
            return "Survive 10 days. Seduce 15 victims. Feed over 10 desired victims"
        case .dayWalker:
            return "Survive 10 days. Feed over 10 desired victims. Drain 3 victims"
        case .lordOfBlood:
            return "Survive 30 days. Feed over 30 desired victims. Dominate 30 victims"
        case .masquerade:
            return "Survive 30 days. Consume food 100 times. Seduce 20 victims"
        case .unholyTongue:
            return "Bribe 20 victims"
        case .mysteriousPerson:
            return "Perform 10 successful bribes. Complete 20 barters"
        case .darkness:
            return "Feed on 15 desired victims. Survive 21 days. Feed over 30 sleeping victims"
        case .memoryErasure:
            return "Survive 40 days. Perform 20 dominations"
        case .oldFriend:
            return "Create 10 friendships"
        case .undeadCasanova:
            return "Create 15 friendships. Spend nights with someone 20 times. Feed on 20 desired victims"
        case .sonOfDracula:
            return "Survive 100 days. Drain 50 desired victims"
        case .ghost:
            return "Disappear 30 times"
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
            case .alchemyNovice: return "flask.fill"
            case .alchemyApprentice: return "testtube.2"
            case .alchemyExpert: return "pills.fill"
            case .alchemyMaster: return "allergens"
            case .bribe: return "dollarsign.circle.fill"
            case .trader: return "bag.fill"
            case .invisibility: return "eye.slash.fill"
            case .dayWalker: return "sunrise.fill"
            case .command: return "person.wave.2.fill"
            case .lordOfBlood: return "drop.fill"
            case .masquerade: return "theatermasks.fill"
            case .unholyTongue: return "mouth.fill"
            case .mysteriousPerson: return "person.crop.rectangle.stack"
            case .darkness: return "lightbulb.slash.fill"
            case .memoryErasure: return "brain.fill"
            case .oldFriend: return "person.2.fill"
            case .undeadCasanova: return "heart.circle.fill"
            case .sonOfDracula: return "drop.triangle.fill"
            case .ghost: return "figure.walk.motion"
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
            case .lordOfBlood:
                return .red
            case .masquerade:
                return .yellow
            case .unholyTongue:
                return .orange
            case .mysteriousPerson:
                return .mint
            case .darkness:
                return .purple
            case .memoryErasure:
                return .purple
            case .oldFriend:
                return .teal
            case .undeadCasanova:
                return .pink
            case .sonOfDracula:
                return .red
            case .ghost:
                return .gray
            }
        }
}
