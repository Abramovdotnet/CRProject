import Foundation
import Combine

class QuestService: GameService {
    
    // Хранилище всех загруженных квестов
    var allQuests: [String: Quest] = [:]
    // Хранилище глобальных флагов квестов/состояния мира
    var globalFlags: [String: Int] = [:] // TODO: Возможно, перенести в GameStateService?
    
    // Доступ к состоянию игрока
    private var gameStateService: GameStateService = DependencyManager.shared.resolve()
    private var player: Player? { gameStateService.player }
    
    // --- Добавленные зависимости ---
    private let vampireNatureRevealService: VampireNatureRevealService = VampireNatureRevealService.shared
    private let gameTimeService: GameTimeService = GameTimeService.shared
    private let itemsManagementService: ItemsManagementService = ItemsManagementService.shared
    private let npcManager: NPCInteractionManager = NPCInteractionManager.shared // Добавлено для getRuntimeNpc

    // Для отслеживания изменений (если нужно)
    private var cancellables = Set<AnyCancellable>()

    static let shared = QuestService()

    init() {
        loadAllQuests()
        // Можно добавить подписку на события, если нужно реагировать на них для продвижения квестов
        // setupSubscribers()
    }

    // --- Загрузка квестов ---
    private func loadAllQuests() {
        DebugLogService.shared.log("QuestService: Loading all quests from manifest...", category: "Quest")
        
        guard let manifestURL = Bundle.main.url(forResource: "QuestManifest", withExtension: "json") else {
            DebugLogService.shared.log("QuestService Error: QuestManifest.json not found in bundle.", category: "Error")
            return
        }
        guard let manifestData = try? Data(contentsOf: manifestURL) else {
             DebugLogService.shared.log("QuestService Error: Could not load data from QuestManifest.json.", category: "Error")
            return
        }
        
        let questFilenames: [String]
        do {
            questFilenames = try JSONDecoder().decode([String].self, from: manifestData)
            DebugLogService.shared.log("QuestService: Loaded manifest with \(questFilenames.count) quest filenames.", category: "Quest")
        } catch {
            DebugLogService.shared.log("QuestService Error: Failed to decode QuestManifest.json: \(error)", category: "Error")
            return
        }

        allQuests.removeAll()
        var loadedCount = 0

        for filename in questFilenames {
            if let url = Bundle.main.url(forResource: filename, withExtension: "json") {
                if let data = try? Data(contentsOf: url) {
                    do {
                        let quest = try JSONDecoder().decode(Quest.self, from: data)
                        allQuests[quest.id] = quest
                        DebugLogService.shared.log("QuestService: Successfully loaded quest '\(quest.title)' (ID: \(quest.id)) from \(filename).json", category: "Quest")
                        loadedCount += 1
                    } catch {
                        DebugLogService.shared.log("QuestService Error: Decoding \(filename).json failed: \(error). URL: \(url)", category: "Error")
                    }
                } else {
                    DebugLogService.shared.log("QuestService Warning: Failed to load data from quest file URL: \(url)", category: "Error")
                }
            } else {
                DebugLogService.shared.log("QuestService Warning: Failed to find quest file \(filename).json in bundle.", category: "Error")
            }
        }
        
        DebugLogService.shared.log("QuestService: \(loadedCount) quests loaded successfully out of \(questFilenames.count) listed.", category: "Quest")
        DebugLogService.shared.log("QuestService: \(allQuests.count) quests in allQuests dictionary.", category: "Quest")
    }

    // --- Управление состоянием квестов ---
    func startQuest(questId: String, startingNPC: NPC? = nil) {
        guard let player = player else { return }
        guard let quest = allQuests[questId] else {
            DebugLogService.shared.log("QuestService Error: Quest with id \(questId) not found.", category: "Error")
            return
        }
        guard player.activeQuests[questId] == nil else {
            DebugLogService.shared.log("QuestService Info: Quest \(questId) is already active for the player.", category: "Quest")
            return
        }

        if checkPrerequisites(quest.prerequisites) {
            let initialStageId = quest.stages.first?.id ?? "INVALID_STAGE"
            if initialStageId == "INVALID_STAGE" {
                 DebugLogService.shared.log("QuestService Error: Quest \(questId) has no stages.", category: "Error")
                 return
            }
            
            let newState = PlayerQuestState(questId: questId, initialStageId: initialStageId)
            player.activeQuests[questId] = newState
            DebugLogService.shared.log("QuestService: Started quest '\(quest.title)' (\(questId)). Current stage: \(initialStageId)", category: "Quest")
            
            if let firstStage = quest.stages.first {
                executeActions(firstStage.activationActions, npcContext: startingNPC)
                triggerDialogueIfNeeded(for: quest, stage: firstStage, npcContext: startingNPC)
            }
        } else {
            DebugLogService.shared.log("QuestService Info: Prerequisites not met for quest \(questId).", category: "Quest")
        }
    }

    private func checkPrerequisites(_ prerequisites: QuestPrerequisites?) -> Bool {
        guard let prerequisites = prerequisites else { return true }
        guard let player = player else {
            DebugLogService.shared.log("QuestService Error: Player object not available for prerequisite check.", category: "Error")
            return false
        }
        
        if let requiredQuests = prerequisites.requiredCompletedQuests, !requiredQuests.isEmpty {
            let completedQuests = player.completedQuestIDs ?? Set()
            for reqQuestId in requiredQuests {
                if !completedQuests.contains(reqQuestId) {
                    DebugLogService.shared.log("QuestService Prerequisite failed: Required quest \(reqQuestId) not completed.", category: "Quest")
                    return false
                }
            }
        }
        
        if let requiredItems = prerequisites.requiredItems, !requiredItems.isEmpty {
            for itemRequirement in requiredItems {
                let itemCount = player.items.filter { $0.id == itemRequirement.itemId }.count
                if itemCount < itemRequirement.quantity {
                    DebugLogService.shared.log("QuestService Prerequisite failed: Required item \(itemRequirement.itemId) quantity \(itemCount) < \(itemRequirement.quantity)", category: "Quest")
                    return false
                }
            }
        }
        
        if let activeQuestChecks = prerequisites.activeQuestStates, !activeQuestChecks.isEmpty {
            for questCheck in activeQuestChecks {
                let isQuestActive = player.activeQuests[questCheck.questId] != nil
                if isQuestActive != questCheck.shouldBeActive {
                    DebugLogService.shared.log("QuestService Prerequisite failed: Quest \(questCheck.questId) active state (\(isQuestActive)) does not match required (\(questCheck.shouldBeActive))", category: "Quest")
                    return false
                }
            }
        }
        
        if let requiredFlags = prerequisites.requiredGameFlags, !requiredFlags.isEmpty {
            for flagCondition in requiredFlags {
                let currentFlagValue = globalFlags[flagCondition.flagName] ?? 0
                if currentFlagValue != flagCondition.expectedValue {
                    DebugLogService.shared.log("QuestService Prerequisite failed: Game flag \(flagCondition.flagName) value (\(currentFlagValue)) != expected (\(flagCondition.expectedValue))", category: "Quest")
                    return false
                }
            }
        }
        
        DebugLogService.shared.log("QuestService: All prerequisites met.", category: "Quest")
        return true
    }

    func completeStage(questId: String, interactorNPC: NPC? = nil) {
         guard let player = player, var questState = player.activeQuests[questId] else { return }
         guard let quest = allQuests[questId],
               let currentStageIndex = quest.stages.firstIndex(where: { $0.id == questState.currentStageId }) else { return }
         
         let currentStage = quest.stages[currentStageIndex]

         if checkCompletionConditions(currentStage.completionConditions) {
             DebugLogService.shared.log("QuestService: Stage '\(currentStage.id)' for quest '\(quest.title)' completed.", category: "Quest")
             
             executeActions(currentStage.completionActions, npcContext: interactorNPC)
             questState.completedStages.insert(currentStage.id)

             if let nextStage = quest.stages[safe: currentStageIndex + 1] {
                 questState.currentStageId = nextStage.id
                 player.activeQuests[questId] = questState
                 DebugLogService.shared.log("QuestService: Advanced quest '\(quest.title)' to stage '\(nextStage.id)'", category: "Quest")
                 executeActions(nextStage.activationActions, npcContext: interactorNPC)
                 triggerDialogueIfNeeded(for: quest, stage: nextStage, npcContext: interactorNPC)
             } else {
                 completeQuest(questId: questId, completerNPC: interactorNPC)
             }
         } else {
              DebugLogService.shared.log("QuestService Info: Completion conditions not met for stage '\(currentStage.id)' of quest '\(quest.title)'.", category: "Quest")
         }
    }
    
    private func checkCompletionConditions(_ conditions: [QuestCondition]) -> Bool {
        guard let player = player else { return false }
        
        for condition in conditions {
            var conditionMet = false
            switch condition.type {
            case .talkToNPC:
                guard let flagName = condition.parameters["flagName"]?.stringValue,
                      let expectedValue = condition.parameters["value"]?.intValue else {
                    DebugLogService.shared.log("QuestService Error: Invalid parameters for .talkToNPC condition (must use flagName & value): \(condition.parameters)", category: "Error")
                    continue
                }
                let currentFlagValue = globalFlags[flagName] ?? 0
                conditionMet = currentFlagValue == expectedValue
                if !conditionMet { DebugLogService.shared.log("Quest condition .talkToNPC (via flag '\(flagName)') failed: Value \(currentFlagValue), expected \(expectedValue)", category: "QuestCondition") }

            case .getItem:
                guard let itemId = condition.parameters["itemId"]?.intValue,
                      let requiredCount = condition.parameters["count"]?.intValue else {
                    DebugLogService.shared.log("QuestService Error: Invalid parameters for .getItem condition: \(condition.parameters)", category: "Error")
                    continue
                }
                let currentCount = player.items.filter { $0.id == itemId }.count
                conditionMet = currentCount >= requiredCount
                if !conditionMet { DebugLogService.shared.log("Quest condition .getItem failed: Need \(requiredCount) of item \(itemId), have \(currentCount)", category: "QuestCondition") }
                
            case .reachLocation:
                guard let locationId = condition.parameters["locationId"]?.intValue else {
                    DebugLogService.shared.log("QuestService Error: Invalid parameters for .reachLocation condition: \(condition.parameters)", category: "Error")
                    continue
                }
                conditionMet = player.currentLocationId == locationId
                 if !conditionMet { DebugLogService.shared.log("Quest condition .reachLocation failed: Need location \(locationId), current \(player.currentLocationId)", category: "QuestCondition") }

            case .useItem:
                DebugLogService.shared.log("QuestService TODO: Check condition .useItem - Parameters: \(condition.parameters). Consider using gameFlag set by item use.", category: "QuestCondition")
                // conditionMet = true // ВРЕМЕННО для теста

            case .defeatNPC:
                 DebugLogService.shared.log("QuestService TODO: Check condition .defeatNPC - Parameters: \(condition.parameters). Consider gameFlag set by NPC defeat event.", category: "QuestCondition")
                 // conditionMet = true // ВРЕМЕННО для теста

            case .completeDialogueNode:
                guard let flagName = condition.parameters["flagName"]?.stringValue,
                      let expectedValue = condition.parameters["value"]?.intValue else {
                    DebugLogService.shared.log("QuestService Error: Invalid parameters for .completeDialogueNode (must use flagName & value): \(condition.parameters)", category: "Error")
                    continue
                }
                let currentFlagValue = globalFlags[flagName] ?? 0
                conditionMet = currentFlagValue == expectedValue
                if !conditionMet { DebugLogService.shared.log("Quest condition .completeDialogueNode (via flag '\(flagName)') failed: Value \(currentFlagValue), expected \(expectedValue)", category: "QuestCondition") }

            case .checkGameFlag:
                 guard let flagName = condition.parameters["flagName"]?.stringValue,
                       let requiredValue = condition.parameters["value"]?.intValue else {
                     DebugLogService.shared.log("QuestService Error: Invalid parameters for .checkGameFlag condition: \(condition.parameters)", category: "Error")
                     continue
                 }
                 let currentValue = globalFlags[flagName] ?? 0
                 conditionMet = currentValue == requiredValue
                  if !conditionMet { DebugLogService.shared.log("Quest condition .checkGameFlag failed: Flag '\(flagName)' is \(currentValue), required \(requiredValue)", category: "QuestCondition") }
            }

            if !conditionMet {
                return false
            }
        }
        return true
    }

    private func completeQuest(questId: String, completerNPC: NPC? = nil) {
        guard let player = player else { return }
        guard let quest = allQuests[questId] else { return }

        DebugLogService.shared.log("QuestService: Quest '\(quest.title)' (\(questId)) COMPLETED! NPC Context: \(completerNPC?.name ?? "N/A")", category: "Quest")
        
        if let rewards = quest.rewards {
            applyRewards(rewards, player: player)
        }
        
        if player.completedQuestIDs == nil {
            player.completedQuestIDs = []
        }
        player.completedQuestIDs?.insert(questId)
        DebugLogService.shared.log("QuestService: Added \(questId) to player's completed quests.", category: "Quest")
        
        player.activeQuests.removeValue(forKey: questId)
    }
    
    private func applyRewards(_ rewards: QuestRewards, player: Player) {
        DebugLogService.shared.log("QuestService: Applying rewards: \(rewards)", category: "Quest")
        if let coins = rewards.coins {
            player.coins.add(coins)
            DebugLogService.shared.log("QuestService: Granting \(coins) coins.", category: "Reward")
        }
        if let items = rewards.items {
            for itemReward in items {
                itemsManagementService.giveItem(itemId: itemReward.itemId, to: player)
                DebugLogService.shared.log("QuestService: Granting item \(itemReward.itemId) x\(itemReward.quantity) using ItemsManagementService.", category: "Reward")
            }
        }
        executeActions(rewards.rewardActions, npcContext: nil)
    }

    private func triggerDialogueIfNeeded(for quest: Quest, stage: QuestStage, npcContext: NPC? = nil) {
        guard let dialogueFilename = stage.dialogueFilename else { return }

        if let startingNPC = npcContext, quest.startingNPCId == startingNPC.id {
            if let firstStage = quest.stages.first, firstStage.id == stage.id {
                DebugLogService.shared.log("QuestService: Auto-trigger for dialogue '\(dialogueFilename)' on starting stage '\(stage.id)' of quest '\(quest.id)' with starting NPC '\(startingNPC.name)' SKIPPED to prevent immediate restart.", category: "Quest")
                return
            }
        }

        if let restrictedProf = stage.restrictToProfession,
           let currentNPC = npcContext {
            if currentNPC.profession.rawValue != restrictedProf {
                DebugLogService.shared.log("QuestService: Auto-trigger for dialogue '\(dialogueFilename)' on stage '\(stage.id)' of quest '\(quest.id)' SKIPPED. NPC context ('\(currentNPC.name)' - '\(currentNPC.profession.rawValue)') does not match stage's restrictToProfession ('\(restrictedProf)').", category: "Quest")
                return
            }
        }
        
        if let associatedId = stage.associatedNPCId,
           let currentNPC = npcContext {
            if currentNPC.id != associatedId {
                 DebugLogService.shared.log("QuestService: Auto-trigger for dialogue '\(dialogueFilename)' on stage '\(stage.id)' of quest '\(quest.id)' SKIPPED. NPC context id ('\(currentNPC.id)') does not match stage's associatedNPCId ('\(associatedId)').", category: "Quest")
                return
            }
        }

        DebugLogService.shared.log("QuestService: Triggering dialogue '\(dialogueFilename)' for quest '\(quest.id)' stage '\(stage.id)'. NPC Context: \(npcContext?.name ?? "N/A")", category: "Quest")
        
        var userInfo: [String: Any] = [
            "specificDialogueFilename": dialogueFilename,
            "questContext": true,
            "forceOpen": false
        ]
        
        if let targetId = stage.associatedNPCId {
            userInfo["targetNPCId"] = targetId
        }
        
        if let interactingId = npcContext?.id {
             userInfo["interactingNPCId"] = interactingId
        }
        
        NotificationCenter.default.post(
            name: Notification.Name("openDialogueTrigger"),
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func executeActions(_ actions: [DialogueAction]?, npcContext: NPC? = nil) {
         guard let actions = actions, !actions.isEmpty else { return }
         guard let player = player else { return }

         DebugLogService.shared.log("QuestService: Executing \(actions.count) actions. NPC Context: \(npcContext?.name ?? "N/A")", category: "QuestAction")

         for action in actions {
             switch action.type {
             case .modifyStat:
                 executeModifyStatAction(action.parameters, player: player, npc: npcContext)
             case .triggerGameEvent:
                 executeTriggerGameEventAction(action.parameters, player: player, npc: npcContext)
             case .markQuestInteractionComplete:
                 executeMarkInteractionComplete(action.parameters, player: player, npc: npcContext)
             }
         }
    }

    private func executeModifyStatAction(_ parameters: [String: DialogueAction.ActionParameterValue], player: Player, npc: NPC?) {
        guard let targetValue = parameters["target"]?.stringValue,
              let target = ActionTarget(rawValue: targetValue),
              let statValue = parameters["stat"]?.stringValue,
              let stat = StatIdentifier(rawValue: statValue) else {
            DebugLogService.shared.log("QuestService Error: Invalid parameters for modifyStat action: \(parameters)", category: "Error")
            return
        }
        
        let value = parameters["value"]?.intValue

        switch target {
        case .npc:
            guard let npc = npc else {
                DebugLogService.shared.log("QuestService Error: NPC target specified for modifyStat, but no NPC context provided. Action: \(parameters)", category: "Error")
                return
            }
            switch stat {
            case .relationship:
                guard let changeValue = value else {
                     DebugLogService.shared.log("QuestService Error: Missing value for relationship modifyStat action: \(parameters)", category: "Error")
                     return
                }
                if changeValue > 0 {
                    npc.playerRelationship.increase(amount: changeValue)
                } else if changeValue < 0 {
                    npc.playerRelationship.decrease(amount: abs(changeValue))
                }
            case .isIntimidated:
                 let isIntimidated = value != 0
                 npc.isIntimidated = isIntimidated
                 if npc.isIntimidated {
                     npc.intimidationDay = gameTimeService.currentDay
                 }
            case .isSpecialBehaviorSet:
                npc.isNpcInteractionBehaviorSet = (value != 0)
                DebugLogService.shared.log("QuestService: NPC \(npc.id) isSpecialBehaviorSet set to \(npc.isNpcInteractionBehaviorSet)", category: "QuestAction")
            case .specialBehaviorTime:
                npc.npcInteractionSpecialTime = value ?? 0
                DebugLogService.shared.log("QuestService: NPC \(npc.id) specialBehaviorTime set to \(npc.npcInteractionSpecialTime)", category: "QuestAction")
            case .activity:
                if let activityName = parameters["activityName"]?.stringValue,
                   let newActivity = NPCActivityType(rawValue: activityName) {
                    npc.currentActivity = newActivity
                    DebugLogService.shared.log("QuestService: NPC \(npc.id) currentActivity set to \(newActivity.rawValue)", category: "QuestAction")
                } else {
                    DebugLogService.shared.log("QuestService Error: Invalid or missing activityName for .activity stat: \(parameters["activityName"]?.stringValue ?? "nil")", category: "Error")
                }
            default:
                DebugLogService.shared.log("QuestService Warning: Unhandled NPC stat for modifyStat: \(stat)", category: "QuestAction")
            }
            
        case .player:
            switch stat {
            case .coins:
                guard let changeValue = value else {
                     DebugLogService.shared.log("QuestService Error: Missing value for coins modifyStat action: \(parameters)", category: "Error")
                     return
                }
                if changeValue > 0 {
                    player.coins.add(changeValue)
                } else if changeValue < 0 {
                    if player.coins.couldRemove(abs(changeValue)) {
                        player.coins.remove(abs(changeValue))
                    } else {
                         DebugLogService.shared.log("QuestService Warning: Not enough coins to remove \(abs(changeValue)) for action: \(parameters)", category: "QuestAction")
                    }
                }
            case .health:
                 guard let changeValue = value else {
                     DebugLogService.shared.log("QuestService Error: Missing value for health modifyStat action: \(parameters)", category: "Error")
                     return
                 }
                 DebugLogService.shared.log("QuestService TODO: Modify player health by \(changeValue)", category: "QuestAction")
            default:
                 DebugLogService.shared.log("QuestService Warning: Unhandled Player stat for modifyStat: \(stat)", category: "QuestAction")
            }
            
        case .global:
            switch stat {
            case .awareness:
                guard let changeValue = value else {
                     DebugLogService.shared.log("QuestService Error: Missing value for awareness modifyStat action: \(parameters)", category: "Error")
                     return
                }
                if changeValue > 0 {
                    vampireNatureRevealService.increaseAwareness(amount: Float(changeValue))
                } else if changeValue < 0 {
                    vampireNatureRevealService.decreaseAwareness(amount: Float(abs(changeValue)))
                }
            case .questStatus:
                 DebugLogService.shared.log("QuestService Info: questStatus modification via action is likely handled by core logic. Action: \(parameters)", category: "QuestAction")
                 break
            case .gameFlag:
                 guard let flagName = parameters["flagName"]?.stringValue,
                       let flagValue = value else {
                     DebugLogService.shared.log("QuestService Error: Missing flagName or value for gameFlag modifyStat action: \(parameters)", category: "Error")
                     return
                 }
                 globalFlags[flagName] = flagValue
                 DebugLogService.shared.log("QuestService: Global flag '\(flagName)' set to \(flagValue)", category: "QuestAction")
            default:
                 DebugLogService.shared.log("QuestService Warning: Unhandled Global stat for modifyStat: \(stat)", category: "QuestAction")
            }
        }
    }

    private func executeTriggerGameEventAction(_ parameters: [String: DialogueAction.ActionParameterValue], player: Player, npc: NPC?) {
        guard let eventName = parameters["eventName"]?.stringValue else {
             DebugLogService.shared.log("QuestService Error: Missing eventName for triggerGameEvent action: \(parameters)", category: "Error")
            return
        }
        
        DebugLogService.shared.log("QuestService: Executing triggerGameEvent '\(eventName)' with params: \(parameters). NPC Context: \(npc?.name ?? "N/A")", category: "QuestAction")

        switch eventName {
        case "JailPlayer":
            DebugLogService.shared.log("QuestService TODO: Implement JailPlayer event trigger.", category: "QuestAction")
        case "TimeAdvance":
            gameTimeService.advanceTime()
        case "LoveScene":
             DebugLogService.shared.log("QuestService Warning: LoveScene event trigger might be UI specific. Ignored in QuestService. Params: \(parameters)", category: "QuestAction")
        case "requestDialogue":
            guard let dialogueFilename = parameters["dialogueFilename"]?.stringValue else {
                DebugLogService.shared.log("QuestService Error: Missing dialogueFilename for requestDialogue event: \(parameters)", category: "Error")
                return
            }
            let targetNPCId = parameters["targetNPCId"]?.intValue
            let forceOpen = parameters["forceOpen"]?.boolValue ?? false

            var userInfo: [String: Any] = [
                "specificDialogueFilename": dialogueFilename,
                "forceOpen": forceOpen,
                "questContext": true
            ]
            if let npcId = targetNPCId {
                userInfo["targetNPCId"] = npcId
            }
            
            if let interactingNPCId = npc?.id {
                userInfo["interactingNPCId"] = interactingNPCId
            }

            DebugLogService.shared.log("QuestService: Posting .openDialogueTrigger notification with userInfo: \(userInfo)", category: "QuestAction")
            NotificationCenter.default.post(name: Notification.Name("openDialogueTrigger"), object: nil, userInfo: userInfo)

        case "StatisticIncrement":
            if let statName = parameters["statName"]?.stringValue {
                if statName == "bribes" {
                    StatisticsService.shared.increaseBribes()
                } else if statName == "nightSpentsWithSomeone" {
                    StatisticsService.shared.increaseNightSpentsWithSomeone()
                } else {
                    DebugLogService.shared.log("QuestService Warning: Unhandled statName '\(statName)' for StatisticIncrement action.", category: "QuestAction")
                }
            } else {
                DebugLogService.shared.log("QuestService Error: Missing statName for StatisticIncrement action: \(parameters)", category: "Error")
            }
        default:
            DebugLogService.shared.log("QuestService Warning: Unhandled eventName '\(eventName)' for triggerGameEvent action.", category: "QuestAction")
        }
    }

    private func executeMarkInteractionComplete(_ parameters: [String: DialogueAction.ActionParameterValue], player: Player, npc: NPC?) {
        guard let questId = parameters["questId"]?.stringValue,
              let stageId = parameters["stageId"]?.stringValue,
              let interactionId = parameters["interactionId"]?.stringValue else {
            DebugLogService.shared.log("QuestService Error: Missing parameters for markQuestInteractionComplete action: \(parameters)", category: "Error")
            return
        }
        
        guard let npcId = npc?.id else {
             DebugLogService.shared.log("QuestService Error: Missing NPC context for markQuestInteractionComplete action: \(parameters)", category: "Error")
             return
        }
        
        let interactionKey = "quest:\(questId)|stage:\(stageId)|interaction:\(interactionId)|npc:\(npcId)"
        player.completedQuestInteractions.insert(interactionKey)
        DebugLogService.shared.log("QuestService: Marked quest interaction as complete: \(interactionKey)", category: "QuestAction")
    }
    
    func setGlobalFlag(name: String, value: Int) {
        globalFlags[name] = value
        DebugLogService.shared.log("QuestService: Global flag '\(name)' set to \(value)", category: "QuestFlag")
    }
    
    func getGlobalFlag(name: String) -> Int {
        return globalFlags[name] ?? 0
    }
    
    func getAvailableQuestDialogueForNPC(npcId: Int, player: Player) -> String? {
        for quest in allQuests.values {
            guard quest.startingNPCId == npcId else { continue }
            guard player.activeQuests[quest.id] == nil else { continue }
            guard !(player.completedQuestIDs?.contains(quest.id) ?? false) else { continue }

            if checkPrerequisites(quest.prerequisites) {
                if let firstStageDialogue = quest.stages.first?.dialogueFilename {
                    DebugLogService.shared.log("QuestService: Found available quest ('\(quest.id)') dialogue '\(firstStageDialogue)' for NPC \(npcId)", category: "QuestIntegration")
                    return firstStageDialogue
                } else {
                    DebugLogService.shared.log("QuestService Warning: Available quest ('\(quest.id)') for NPC \(npcId) has no dialogueFilename for its first stage.", category: "QuestIntegration")
                }
            }
        }
        return nil
    }

    func getActiveQuestDialogueForNPC(npcId: Int, player: Player) -> String? {
        DebugLogService.shared.log("[DEBUG] getActiveQuestDialogueForNPC called for NPC ID: \(npcId)", category: "QuestIntegration")

        guard let currentNPCObject = NPCReader.getRuntimeNPC(by: npcId) else {
            DebugLogService.shared.log("[DEBUG] NPC object not found for ID: \(npcId)", category: "QuestIntegration")
            return nil
        }
        let npcProfessionString = currentNPCObject.profession.rawValue
        DebugLogService.shared.log("[DEBUG] NPC ID: \(npcId), Profession: \(npcProfessionString)", category: "QuestIntegration")

        guard !player.activeQuests.isEmpty else {
            DebugLogService.shared.log("[DEBUG] Player has no active quests.", category: "QuestIntegration")
            return nil
        }
        DebugLogService.shared.log("[DEBUG] Player active quests: \(player.activeQuests.map { $0.key + ": " + $0.value.currentStageId })", category: "QuestIntegration")

        for (questId, questState) in player.activeQuests {
            DebugLogService.shared.log("[DEBUG] Checking quest: \(questId), current stage in state: \(questState.currentStageId)", category: "QuestIntegration")
            guard let quest = allQuests[questId],
                  let currentStage = quest.stages.first(where: { $0.id == questState.currentStageId }) else {
                DebugLogService.shared.log("[DEBUG] Quest data or current stage data not found for quest: \(questId), stageId: \(questState.currentStageId)", category: "QuestIntegration")
                continue
            }
            DebugLogService.shared.log("[DEBUG] Quest: \(questId), Stage: \(currentStage.id), DialogueFile: \(currentStage.dialogueFilename ?? "nil"), AssocNPC: \(currentStage.associatedNPCId?.description ?? "nil"), RestrictProf: \(currentStage.restrictToProfession ?? "nil")", category: "QuestIntegration")

            guard let stageDialogueFile = currentStage.dialogueFilename else {
                DebugLogService.shared.log("[DEBUG] Stage '\(currentStage.id)' of quest '\(questId)' has nil dialogueFilename. Skipping.", category: "QuestIntegration")
                continue
            }

            if let associatedId = currentStage.associatedNPCId {
                DebugLogService.shared.log("[DEBUG] Stage has associatedNPCId: \(associatedId). Current NPC ID: \(npcId)", category: "QuestIntegration")
                if npcId == associatedId {
                    DebugLogService.shared.log("[DEBUG] Match on associatedNPCId! Returning dialogue: \(stageDialogueFile)", category: "QuestIntegration")
                    return stageDialogueFile
                } else {
                    DebugLogService.shared.log("[DEBUG] No match on associatedNPCId. Skipping to next active quest or stage condition.", category: "QuestIntegration")
                    continue // Эта ветка пропускает дальнейшие проверки для ДАННОЙ СТАДИИ, если associatedId есть, но не совпал
                }
            }

            if let restrictedProfession = currentStage.restrictToProfession {
                DebugLogService.shared.log("[DEBUG] Stage has restrictToProfession: \(restrictedProfession). Current NPC Profession: \(npcProfessionString)", category: "QuestIntegration")
                if npcProfessionString == restrictedProfession {
                    DebugLogService.shared.log("[DEBUG] Match on restrictToProfession! Returning dialogue: \(stageDialogueFile)", category: "QuestIntegration")
                    return stageDialogueFile
                } else {
                    DebugLogService.shared.log("[DEBUG] No match on restrictToProfession. Skipping to next active quest.", category: "QuestIntegration")
                    continue // Эта ветка пропускает дальнейшие проверки для ДАННОЙ СТАДИИ, если профессия не совпала
                }
            }
            
            DebugLogService.shared.log("[DEBUG] Stage '\(currentStage.id)' has no associatedNPCId AND no restrictToProfession. Checking startingNPCId.", category: "QuestIntegration")
            if currentStage.associatedNPCId == nil && currentStage.restrictToProfession == nil {
                if quest.startingNPCId == npcId {
                    DebugLogService.shared.log("[DEBUG] Match on startingNPCId for generic stage! Returning dialogue: \(stageDialogueFile)", category: "QuestIntegration")
                    return stageDialogueFile
                } else {
                    DebugLogService.shared.log("[DEBUG] No match on startingNPCId for generic stage.", category: "QuestIntegration")
                }
            }
            DebugLogService.shared.log("[DEBUG] End of checks for stage '\(currentStage.id)'. No dialogue returned for this stage yet.", category: "QuestIntegration")
        }
        DebugLogService.shared.log("[DEBUG] No active quest dialogue found for NPC \(npcId) after checking all active quests.", category: "QuestIntegration")
        return nil
    }

    // MARK: - Quest Availability and NPC Interaction Checks

    /// Checks if an NPC has any new quests available for the player that are not yet started
    /// and for which all prerequisites are met.
    func hasAvailableNewQuests(for npcId: Int) -> Bool {
        guard let player = player else { return false }

        for quest in allQuests.values {
            // 1. Check if the quest is started by this NPC
            guard quest.startingNPCId == npcId else { continue }

            // 2. Check if the quest is already active or completed
            if player.activeQuests[quest.id] != nil || (player.completedQuestIDs?.contains(quest.id) ?? false) {
                continue
            }

            // 3. Check prerequisites for starting the quest
            if checkPrerequisites(quest.prerequisites) {
                // Found an available new quest for this NPC
                DebugLogService.shared.log("QuestService: NPC \(npcId) has available new quest '\(quest.title)' (ID: \(quest.id))", category: "QuestCheck")
                return true
            }
        }
        return false
    }

    /// Checks if the given NPC is involved in any active quest and is awaiting player dialogue/interaction
    /// for the current stage of that quest.
    func isNPCAwaitingPlayerActionInActiveQuests(for npcId: Int) -> Bool {
        guard let player = player else { return false }
        guard let interactingNPC = NPCReader.getRuntimeNPC(by: npcId) else {
             DebugLogService.shared.log("QuestService Error: Could not get runtime NPC with ID \(npcId) for action check.", category: "Error")
            return false
        }

        for questState in player.activeQuests.values {
            guard let quest = allQuests[questState.questId],
                  let currentStage = quest.stages.first(where: { $0.id == questState.currentStageId }) else {
                continue
            }

            // A. Check if the stage has a dialogue and conditions are not yet met
            if currentStage.dialogueFilename != nil {
                // 1. Direct association: Stage is specifically for this NPC
                if let associatedId = currentStage.associatedNPCId {
                    if associatedId == npcId {
                        // If completion conditions are NOT met, NPC is awaiting action
                        if !checkCompletionConditions(currentStage.completionConditions) {
                             DebugLogService.shared.log("QuestService: NPC \(npcId) is awaiting action for quest '\(quest.title)' (stage '\(currentStage.id)') due to associatedNPCId.", category: "QuestCheck")
                            return true
                        }
                    }
                } 
                // 2. Profession restriction: Stage is for any NPC of this profession, and no specific NPC is associated
                else if let restrictProfession = currentStage.restrictToProfession {
                    if interactingNPC.profession.rawValue.capitalized == restrictProfession.capitalized {
                        // If completion conditions are NOT met, NPC is awaiting action
                        if !checkCompletionConditions(currentStage.completionConditions) {
                            DebugLogService.shared.log("QuestService: NPC \(npcId) (profession \(interactingNPC.profession.rawValue)) is awaiting action for quest '\(quest.title)' (stage '\(currentStage.id)') due to restrictToProfession.", category: "QuestCheck")
                            return true
                        }
                    }
                }
                // 3. General quest dialogue with the starting NPC (if no other association)
                // This case is implicitly handled by getActiveQuestDialogueForNPC if called,
                // but for just checking if *this* NPC is relevant, we need specific checks.
                // If a dialogue exists and there are no specific restrictions (associatedNPCId or restrictToProfession)
                // AND this NPC is the quest starting NPC, they might be relevant.
                // However, this logic can become complex. For now, we focus on explicit associations.
                // Awaiting player action usually means specific dialogue or conditions linked to this NPC.
            }
        }
        return false
    }
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
