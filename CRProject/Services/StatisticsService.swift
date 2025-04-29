import Foundation
import Combine

class StatisticsService: GameService {
    @Published private(set) var daysSurvived: Int = 0
    @Published private(set) var feedings: Int = 0
    @Published private(set) var feedingsOverSleepingVictims: Int = 0
    @Published private(set) var feedingsOverDesiredVictims: Int = 0
    @Published private(set) var victimsDrained: Int = 0
    @Published private(set) var peopleKilled: Int = 0
    @Published private(set) var investigations: Int = 0
    @Published private(set) var peopleSeducted: Int = 0
    @Published private(set) var peopleDominated: Int = 0
    @Published private(set) var bartersCompleted: Int = 0
    @Published private(set) var bribes: Int = 0
    @Published private(set) var smithingRecipesUnlocked: Int = 0
    @Published private(set) var alchemyRecipesUnlocked: Int = 0
    @Published private(set) var propertiesBought: Int = 0
    @Published private(set) var _500CoinsDeals: Int = 0
    @Published private(set) var _1000CoinsDeals: Int = 0
    
    static let shared: StatisticsService = DependencyManager.shared.resolve()
    
    func increase1000CoinsDeals() {
        _1000CoinsDeals += 1
        
        if !AbilitiesSystem.shared.hasBribe && AbilitiesSystem.shared.canUnlock(Ability.bribe) {
            AbilitiesSystem.shared.unlockAbility(Ability.bribe)
        }
        
        if !AbilitiesSystem.shared.hasTrader && AbilitiesSystem.shared.canUnlock(Ability.trader) {
            AbilitiesSystem.shared.unlockAbility(Ability.trader)
        }
    }
    
    func increase500CoinsDeals() {
        _500CoinsDeals += 1
        
        if !AbilitiesSystem.shared.hasBribe && AbilitiesSystem.shared.canUnlock(Ability.bribe) {
            AbilitiesSystem.shared.unlockAbility(Ability.bribe)
        }
        
        if !AbilitiesSystem.shared.hasTrader && AbilitiesSystem.shared.canUnlock(Ability.trader) {
            AbilitiesSystem.shared.unlockAbility(Ability.trader)
        }
    }
    
    func increasePropertiesBought() {
        propertiesBought += 1
        
        if !AbilitiesSystem.shared.hasEnthralling && AbilitiesSystem.shared.canUnlock(Ability.enthralling) {
            AbilitiesSystem.shared.unlockAbility(Ability.enthralling)
        }
    }
    
    func increaseAlchemyRecipesUnlocked() {
        alchemyRecipesUnlocked += 1
        
        if !AbilitiesSystem.shared.hasAlchemyNovice && alchemyRecipesUnlocked >= 10 && alchemyRecipesUnlocked < 20 {
            if AbilitiesSystem.shared.canUnlock(Ability.alchemyNovice) {
                AbilitiesSystem.shared.unlockAbility(Ability.alchemyNovice)
            }
        }
        if !AbilitiesSystem.shared.hasAlchemyApprentice && alchemyRecipesUnlocked >= 20 && alchemyRecipesUnlocked < 40 {
            if AbilitiesSystem.shared.canUnlock(Ability.alchemyApprentice) {
                AbilitiesSystem.shared.unlockAbility(Ability.alchemyApprentice)
            }
        }

        if !AbilitiesSystem.shared.hasAlchemyExpert && alchemyRecipesUnlocked >= 40 && alchemyRecipesUnlocked < 60 {
            if AbilitiesSystem.shared.canUnlock(Ability.alchemyExpert) {
                AbilitiesSystem.shared.unlockAbility(Ability.alchemyExpert)
            }
        }

        if !AbilitiesSystem.shared.hasAlchemyMaster &&  alchemyRecipesUnlocked >= 60 {
            if AbilitiesSystem.shared.canUnlock(Ability.alchemyMaster) {
                AbilitiesSystem.shared.unlockAbility(Ability.alchemyMaster)
            }
        }
    }
    
    func increaseSmithingRecipesUnlocked() {
        smithingRecipesUnlocked += 1
        
        if !AbilitiesSystem.shared.hasSmithingNovice && smithingRecipesUnlocked >= 10 {
            if AbilitiesSystem.shared.canUnlock(Ability.smithingNovice) {
                AbilitiesSystem.shared.unlockAbility(Ability.smithingNovice)
            }
        }
        if !AbilitiesSystem.shared.hasSmithingApprentice && smithingRecipesUnlocked >= 20 {
            if AbilitiesSystem.shared.canUnlock(Ability.smithingApprentice) {
                AbilitiesSystem.shared.unlockAbility(Ability.smithingApprentice)
            }
        }
        if !AbilitiesSystem.shared.hasSmithingExpert && smithingRecipesUnlocked >= 40 {
            if AbilitiesSystem.shared.canUnlock(Ability.smithingExpert) {
                AbilitiesSystem.shared.unlockAbility(Ability.smithingExpert)
            }
        }
        if !AbilitiesSystem.shared.hasSmithingMaster && smithingRecipesUnlocked >= 60 {
            if AbilitiesSystem.shared.canUnlock(Ability.smithingMaster) {
                AbilitiesSystem.shared.unlockAbility(Ability.smithingMaster)
            }
        }
    }
    
    func increaseBribes() {
        bribes += 1
        
        if !AbilitiesSystem.shared.hasDomination && AbilitiesSystem.shared.canUnlock(Ability.domination) {
            AbilitiesSystem.shared.unlockAbility(Ability.domination)
        }
    }
    
    func increasefeedingsOverSleepingVictims() {
        feedingsOverSleepingVictims += 1
        
        if !AbilitiesSystem.shared.hasSeduction && AbilitiesSystem.shared.canUnlock(Ability.seduction) {
            AbilitiesSystem.shared.unlockAbility(Ability.seduction)
        }
        
        if !AbilitiesSystem.shared.hasWhisper && AbilitiesSystem.shared.canUnlock(Ability.whisper) {
            AbilitiesSystem.shared.unlockAbility(Ability.whisper)
        }
    }

    func increasefeedingsOverDesiredVictims() {
        feedingsOverDesiredVictims += 1
        
        if !AbilitiesSystem.shared.hasDomination && AbilitiesSystem.shared.canUnlock(Ability.domination) {
            AbilitiesSystem.shared.unlockAbility(Ability.domination)
        }
        
        if !AbilitiesSystem.shared.hasSeduction && AbilitiesSystem.shared.canUnlock(Ability.seduction) {
            AbilitiesSystem.shared.unlockAbility(Ability.seduction)
        }
        
        if !AbilitiesSystem.shared.hasWhisper && AbilitiesSystem.shared.canUnlock(Ability.whisper) {
            AbilitiesSystem.shared.unlockAbility(Ability.whisper)
        }
        
        if !AbilitiesSystem.shared.hasEnthralling && AbilitiesSystem.shared.canUnlock(Ability.enthralling) {
            AbilitiesSystem.shared.unlockAbility(Ability.enthralling)
        }
        if !AbilitiesSystem.shared.hasEnthralling && AbilitiesSystem.shared.canUnlock(Ability.enthralling) {
            AbilitiesSystem.shared.unlockAbility(Ability.enthralling)
        }
        
        if !AbilitiesSystem.shared.hasInvisibility && AbilitiesSystem.shared.canUnlock(Ability.invisibility) {
            AbilitiesSystem.shared.unlockAbility(Ability.invisibility)
        }
        
        if !AbilitiesSystem.shared.hasCommand && AbilitiesSystem.shared.canUnlock(Ability.command) {
            AbilitiesSystem.shared.unlockAbility(Ability.command)
        }
        
        if !AbilitiesSystem.shared.hasDayWalker && AbilitiesSystem.shared.canUnlock(Ability.dayWalker) {
            AbilitiesSystem.shared.unlockAbility(Ability.dayWalker)
        }
    }

    func increasePeopleSeducted() {
        peopleSeducted += 1
        
        if !AbilitiesSystem.shared.hasDomination && AbilitiesSystem.shared.canUnlock(Ability.domination) {
            AbilitiesSystem.shared.unlockAbility(Ability.domination)
        }
        
        if !AbilitiesSystem.shared.hasWhisper && AbilitiesSystem.shared.canUnlock(Ability.whisper) {
            AbilitiesSystem.shared.unlockAbility(Ability.whisper)
        }
        
        if !AbilitiesSystem.shared.hasCommand && AbilitiesSystem.shared.canUnlock(Ability.command) {
            AbilitiesSystem.shared.unlockAbility(Ability.command)
        }
    }
    
    func increasePeopleDominated() {
        peopleDominated += 1
        
        if !AbilitiesSystem.shared.hasEnthralling && AbilitiesSystem.shared.canUnlock(Ability.enthralling) {
            AbilitiesSystem.shared.unlockAbility(Ability.enthralling)
        }
    }
    
    func increaseBartersCompleted() {
        bartersCompleted += 1
    }
    
    func incrementDaysSurvived() {
        daysSurvived += 1
        
        if !AbilitiesSystem.shared.hasInvisibility && AbilitiesSystem.shared.canUnlock(Ability.invisibility) {
            AbilitiesSystem.shared.unlockAbility(Ability.invisibility)
        }
        
        if !AbilitiesSystem.shared.hasDayWalker && AbilitiesSystem.shared.canUnlock(Ability.dayWalker) {
            AbilitiesSystem.shared.unlockAbility(Ability.dayWalker)
        }
    }
    
    func incrementFeedings() {
        feedings += 1
    }
    
    func incrementVictimsDrained() {
        victimsDrained += 1
        
        if !AbilitiesSystem.shared.hasDayWalker && AbilitiesSystem.shared.canUnlock(Ability.dayWalker) {
            AbilitiesSystem.shared.unlockAbility(Ability.dayWalker)
        }
        
        if !AbilitiesSystem.shared.hasEnthralling && AbilitiesSystem.shared.canUnlock(Ability.enthralling) {
            AbilitiesSystem.shared.unlockAbility(Ability.enthralling)
        }
        
        if !AbilitiesSystem.shared.hasDomination && AbilitiesSystem.shared.canUnlock(Ability.domination) {
            AbilitiesSystem.shared.unlockAbility(Ability.domination)
        }
    }
    
    func incrementPeopleKilled() {
        peopleKilled += 1
    }
    
    func incrementInvestigations() {
        investigations += 1
    }
    
    func reset() {
        daysSurvived = 0
        feedings = 0
        victimsDrained = 0
        peopleKilled = 0
        investigations = 0
    }
    
    func maxOutAchievements() {
        daysSurvived = 100
        feedings = 100
        victimsDrained = 100
        peopleKilled = 100
        investigations = 100
        feedingsOverSleepingVictims = 100
        feedingsOverDesiredVictims = 100
        peopleSeducted = 100
        peopleDominated = 100
        bartersCompleted = 100
        bribes = 100
        _500CoinsDeals = 100
        _1000CoinsDeals = 100
        smithingRecipesUnlocked = 100
        alchemyRecipesUnlocked = 100
        propertiesBought = 100
        
        increaseBribes()
        incrementFeedings()
        incrementInvestigations()
        increase500CoinsDeals()
        increase1000CoinsDeals()
        incrementDaysSurvived()
        incrementPeopleKilled()
        increasePeopleDominated()
        increasePeopleSeducted()
        incrementVictimsDrained()
        increaseBartersCompleted()
        increasefeedingsOverDesiredVictims()
        increasefeedingsOverSleepingVictims()
        increaseAlchemyRecipesUnlocked()
        increaseSmithingRecipesUnlocked()
        increasePropertiesBought()
    }
}
