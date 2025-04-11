import Combine
import Foundation

class NPCActivityManager {
    static let shared = NPCActivityManager()
    private let gameTime: GameTimeService = DependencyManager.shared.resolve()
    private var cancellables = Set<AnyCancellable>()
    
    // Activity probabilities (0-100)
    private struct ActivityWeights {
        var work: Int
        var leisure: Int
        var essential: Int // sleep/eat
    }
    
    private var phaseWeights: [DayPhase: ActivityWeights] = [
        .earlyMorning: ActivityWeights(work: 20, leisure: 10, essential: 70),
        .morning: ActivityWeights(work: 80, leisure: 10, essential: 10),
        .afternoon: ActivityWeights(work: 70, leisure: 20, essential: 10),
        .evening: ActivityWeights(work: 30, leisure: 60, essential: 10),
        .night: ActivityWeights(work: 10, leisure: 40, essential: 50),
        .lateNight: ActivityWeights(work: 5, leisure: 15, essential: 80)
    ]
    
    init() {
        // React to time changes
        NotificationCenter.default.publisher(for: .timeAdvanced)
            .sink { [weak self] _ in
                self?.handleTimeChange()
            }
            .store(in: &cancellables)
    }
    
    private func handleTimeChange() {
        // Could update weights or other time-sensitive data here
    }
    
    func getActivity(for npc: NPC) -> NPCActivityType {
        let currentHour = gameTime.currentHour
        let phase = gameTime.dayPhase
        let weights = phaseWeights[phase] ?? ActivityWeights(work: 50, leisure: 30, essential: 20)
        
        // Determine activity category
        let categoryRoll = Int.random(in: 1...100)
        let activityCategory: ActivityCategory
        
        if npc.profession == .noProfession {
            activityCategory = .leisure
        } else {
            if categoryRoll <= weights.essential {
                activityCategory = .essential
            } else if categoryRoll <= (weights.essential + weights.work) {
                activityCategory = .work
            } else {
                activityCategory = .leisure
            }
        }
        
        // Get specific activity
        switch activityCategory {
        case .essential:
            return getEssentialActivity(currentHour: currentHour)
        case .work:
            return getWorkActivity(for: npc.profession, phase: phase)
        case .leisure:
            return getLeisureActivity(for: npc.profession, phase: phase)
        case .action:
            return getActionActivity(for: npc)
        }
    }
    
    func getActionActivity(for npc: NPC) -> NPCActivityType{
        if npc.bloodMeter.currentBlood <= 40 && npc.isIntimidated {
            return .duzzled
        } else if npc.bloodMeter.currentBlood > 40 && npc.isIntimidated {
            return .seducted
        } else if npc.isVampireAttachWitness {
            return .fleeing
        } else {
            return npc.currentActivity
        }
    }
    
    private func getEssentialActivity(currentHour: Int) -> NPCActivityType {
        // 70% chance to sleep at night, 30% during day
        let isSleepTime = currentHour >= 22 || currentHour < 6
        let sleepRoll = Int.random(in: 1...100)
        
        if isSleepTime && sleepRoll <= 70 || !isSleepTime && sleepRoll <= 30 {
            return .sleep
        } else {
            return .eat
        }
    }
    
    private func getWorkActivity(for profession: Profession, phase: DayPhase) -> NPCActivityType {
        let activities = profession.primaryWorkActivities()
        
        // Add some randomness - 20% chance to do secondary work activity
        if activities.count > 1 && Int.random(in: 1...100) <= 20 {
            return activities.randomElement() ?? .idle
        }
        
        // Default to first work activity
        return activities.first ?? .idle
    }
    
    private func getLeisureActivity(for profession: Profession, phase: DayPhase) -> NPCActivityType {
        var leisureActivities = profession.primaryLeisureActivities()
        
        // Night-specific additions
        if phase == .night || phase == .lateNight {
            if profession.typicalActivities().contains(.drink) {
                leisureActivities.append(.drink)
            }
            if profession.typicalActivities().contains(.gamble) {
                leisureActivities.append(.gamble)
            }
        }
        
        // 10% chance to do something unusual
        if Int.random(in: 1...100) <= 10 {
            return profession.typicalActivities().filter {
                !leisureActivities.contains($0) && $0 != .sleep && $0 != .eat
            }.randomElement() ?? leisureActivities.randomElement() ?? .idle
        }
        
        return leisureActivities.randomElement() ?? .idle
    }
    
    private enum ActivityCategory {
        case essential
        case work
        case leisure
        case action
    }
}
