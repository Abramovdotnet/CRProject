import Foundation
import Combine
import SwiftUI

class DialogueViewModel: ObservableObject {
    @Published var currentDialogueText: String = ""
    @Published var options: [DialogueOption] = []
    @Published var showActionResult: Bool = false
    @Published var actionResultSuccess: Bool = false
    @Published var actionResultMessage: String = ""
    @Published var showLoveScene: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var isSpecificDialogueSet: Bool = false
    
    @Published var npc: NPC
    private let dialogueProcessor: DialogueProcessor
    private var cancellables = Set<AnyCancellable>()
    
    private let vampireNatureRevealService: VampireNatureRevealService = DependencyManager.shared.resolve()
    private let gameStateService: GameStateService = DependencyManager.shared.resolve()
    private let gameEventBusService: GameEventsBusService = DependencyManager.shared.resolve()
    private let investigationService: InvestigationService = DependencyManager.shared.resolve()
    private var questService: QuestService = DependencyManager.shared.resolve()
    private var player: Player? { gameStateService.player }
    var currentNPC: NPC?
    private let specificDialogueFilename: String?
    
    init(npc: NPC, player: Player, specificDialogueFilename: String? = nil) {
        self.npc = npc
        self.dialogueProcessor = DialogueProcessor(
            dialogueSystem: DialogueSystem.shared,
            player: player,
            npc: npc
        )
        self.currentNPC = npc
        self.specificDialogueFilename = specificDialogueFilename
        
        DebugLogService.shared.log("Initializing dialogue for NPC: \(npc.name), specific file: \(specificDialogueFilename ?? "None")", category: "Dialogue")
        loadInitialDialogue(specificFilename: specificDialogueFilename)
        npc.hasInteractedWithPlayer = true
    }
    
    private func loadInitialDialogue(specificFilename: String?) {
        DebugLogService.shared.log("Attempting to load dialogue. Specific file requested: \(specificFilename ?? "N/A")", category: "DialogueVM")
        
        var dialogueLoaded = false
        if let filename = specificFilename {
            DebugLogService.shared.log("Attempting to load specific dialogue file: \(filename)", category: "DialogueVM")
            if let specificDialogue = dialogueProcessor.loadSpecificDialogue(filename: filename, npc: self.npc) {
                DebugLogService.shared.log("✅ Successfully loaded specific dialogue: \(filename)", category: "DialogueVM")
                updateDialogue(text: specificDialogue.text, options: specificDialogue.options)
                dialogueLoaded = true
                isSpecificDialogueSet = true
            } else {
                DebugLogService.shared.log("❌ Failed to load specific dialogue: \(filename). Falling back to standard loading.", category: "Error")
            }
        }
        
        if !dialogueLoaded {
            DebugLogService.shared.log("Loading standard dialogue for NPC: \(npc.name), profession: \(npc.profession.rawValue)", category: "DialogueVM")
            if let dialogue = dialogueProcessor.loadDialogue(npc: npc) {
                DebugLogService.shared.log("✅ Successfully loaded standard dialogue for \(npc.profession.rawValue)", category: "DialogueVM")
                updateDialogue(text: dialogue.text, options: dialogue.options)
                dialogueLoaded = true
            } else {
                DebugLogService.shared.log("❌ Failed to load ANY dialogue for \(npc.profession.rawValue)", category: "Error")
            }
        }

        if !dialogueLoaded {
            currentDialogueText = "..."
            options = [getEndOption()]
        }
    }
    
    private func getEndOption() -> DialogueOption {
        let option = DialogueOption()
        option.type = .normal
        option.text = "Leave"
        option.nextNodeId = "end"
        return option
    }
    
    private func updateDialogue(text: String, options: [DialogueNodeOption]) {
        DebugLogService.shared.log("Updating dialogue VM - Text: \(text), Options count: \(options.count)", category: "DialogueVM")
        
        self.currentDialogueText = ""
        self.options = []
        self.currentDialogueText = text
        
        let mappedOptions = options.map { option in
            DialogueOption.create(text: option.text, 
                                type: option.type, 
                                nextNodeId: option.nextNode, 
                                failureNode: option.failureNode,
                                successActions: option.successActions,
                                failureActions: option.failureActions)
        }

        self.options = mappedOptions
        DebugLogService.shared.log("Assigned options count: \(self.options.count)", category: "DialogueVM")
    }
    
    func selectOption(_ option: DialogueOption) {
        DebugLogService.shared.log("Selected option leading to node: \(option.nextNodeId)", category: "DialogueVM")
        
        if option.nextNodeId == "end" {
            executeActions(option.successActions)
            shouldDismiss = true
            if let activeQuests = player?.activeQuests {
                for (questId, _) in activeQuests {
                    questService.completeStage(questId: questId, interactorNPC: self.currentNPC)
                }
            }
            return
        }

        switch option.type {
        case .persuasion:
            handlePersuasion(option: option)
        case .relationshipIncrease:
            executeActions(option.successActions)
            dialogueProcessor.normalizeRelationshipNode(option.text)
            handleRelationshipIncrease(nextNodeId: option.nextNodeId, option: option.text)
        case .relationshipDecrease:
            executeActions(option.successActions)
            dialogueProcessor.normalizeRelationshipNode(option.text)
            handleRelationshipDecrease(nextNodeId: option.nextNodeId, option: option.text)
        case .normal:
            executeActions(option.successActions) 
            if let (newText, newOptions) = dialogueProcessor.processNode(option.nextNodeId, npc: currentNPC) {
                updateDialogue(text: newText, options: newOptions)
            } else {
                shouldDismiss = true
            }
        }
        
        if let activeQuests = player?.activeQuests {
            for (questId, _) in activeQuests {
                questService.completeStage(questId: questId, interactorNPC: self.currentNPC)
            }
        }
    }
    
    private func handlePersuasion(option: DialogueOption) {
        guard let failureNodeId = option.failureNode else { 
            DebugLogService.shared.log("Error: failureNode is nil for .persuasion option: \(option.text). Proceeding to nextNode only.", category: "DialogueVM")
            if let (newText, newOptions) = dialogueProcessor.processNode(option.nextNodeId) {
                 updateDialogue(text: newText, options: newOptions)
             } else {
                 shouldDismiss = true
             }
            return 
        }
        let successNodeId = option.nextNodeId
        
        let success = dialogueProcessor.attemptPersuasion(npc: npc)
        
        npc.isIntimidated = true
        npc.intimidationDay = GameTimeService.shared.currentDay

        if success {
            executeActions(option.successActions)
            if let (newText, newOptions) = dialogueProcessor.processNode(successNodeId) {
                updateDialogue(text: newText, options: newOptions)
            } else {
                shouldDismiss = true
            }
            showActionResult(success: true, action: "Persuasion")
            VibrationService.shared.lightTap()
        } else {
            executeActions(option.failureActions)
            if let (newText, newOptions) = dialogueProcessor.processNode(failureNodeId) { 
                updateDialogue(text: newText, options: newOptions)
            } else {
                shouldDismiss = true
            }
            showActionResult(success: false, action: "Persuasion")
            VibrationService.shared.errorVibration()
        }
    }
    
    private func handleRelationshipIncrease(nextNodeId: String, option: String) {
        npc.playerRelationship.increase(amount: 1)
        GameStateService.shared.player?.processRelationshipDialogueNode(option: option)
        VibrationService.shared.lightTap()
        if let (newText, newOptions) = dialogueProcessor.processNode(nextNodeId) {
            updateDialogue(text: newText, options: newOptions)
        } else {
            shouldDismiss = true
        }
    }
    
    private func handleRelationshipDecrease(nextNodeId: String, option: String) {
        npc.playerRelationship.decrease(amount: 1)
        GameStateService.shared.player?.processRelationshipDialogueNode(option: option)
        VibrationService.shared.lightTap()
        if let (newText, newOptions) = dialogueProcessor.processNode(nextNodeId) {
            updateDialogue(text: newText, options: newOptions)
        } else {
            shouldDismiss = true
        }
    }
    
    private func showActionResult(success: Bool, action: String) {
        actionResultSuccess = success
        actionResultMessage = "\(action) \(success ? "succeeded" : "failed")"
        showActionResult = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.showActionResult = false
        }
    }
    
    private func jailPlayer() {
        guard let jailLocation = LocationReader.getLocations().first(where: { $0.sceneType == .dungeon }) else { return }
        try? GameStateService.shared.changeLocation(to: jailLocation.id)
        guard let player = GameStateService.shared.player else { return }
        player.arrestPlayer()
    }
    
    private func loveForSale() {
        VibrationService.shared.lightTap()

        npc.spentNightWithPlayer = true
        withAnimation(.easeIn(duration: 0.5)) {
            showLoveScene = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            
            withAnimation(.easeOut(duration: 0.5)) {
                self.showLoveScene = false
            }
        }

        GameEventsBusService.shared.addMessageWithIcon(
            type: .common,
            location: GameStateService.shared.currentScene?.name ?? "Unknown",
            player: GameStateService.shared.player!,
            secondaryNPC: npc,
            interactionType: NPCInteraction.prostitution,
            hasSuccess: false,
            isSuccess: nil
        )
    }
    
    private func executeActions(_ actions: [DialogueAction]?) {
        guard let actions = actions, !actions.isEmpty else { return }
        guard let player = gameStateService.player else { return }

        for action in actions {
            switch action.type {
            case .modifyStat:
                executeModifyStatAction(action.parameters, player: player, npc: npc)
            
            case .triggerGameEvent:
                executeTriggerGameEventAction(action.parameters, player: player, npc: npc)

            case .markQuestInteractionComplete:
                DebugLogService.shared.log("DialogueVM: Encountered markQuestInteractionComplete action. Intended for QuestService. Params: \(action.parameters)", category: "DialogueAction")
                break
            }
        }
    }
    
    private func executeModifyStatAction(_ parameters: [String: DialogueAction.ActionParameterValue], player: Player, npc: NPC) {
        guard let targetValue = parameters["target"]?.stringValue, 
              let target = ActionTarget(rawValue: targetValue), 
              let statValue = parameters["stat"]?.stringValue, 
              let stat = StatIdentifier(rawValue: statValue) 
              else {
            DebugLogService.shared.log("Error: Invalid parameters for modifyStat action: \(parameters)", category: "DialogueVM")
            return
        }
        
        let value = parameters["value"]?.intValue

        switch target {
        case .npc:
            switch stat {
            case .relationship:
                guard let changeValue = value else { 
                    DebugLogService.shared.log("DialogueVM Error: Missing value for relationship modifyStat: \(parameters)", category: "Error")
                    return 
                }
                if changeValue > 0 {
                    npc.playerRelationship.increase(amount: changeValue)
                } else if changeValue < 0 {
                    npc.playerRelationship.decrease(amount: abs(changeValue))
                }
            case .isIntimidated:
                guard let v = value else { 
                    DebugLogService.shared.log("DialogueVM Error: Missing value for isIntimidated modifyStat: \(parameters)", category: "Error")
                    return 
                }
                npc.isIntimidated = (v != 0)
                if npc.isIntimidated {
                    npc.intimidationDay = GameTimeService.shared.currentDay
                }
            case .isSpecialBehaviorSet:
                guard let v = value else { 
                    DebugLogService.shared.log("DialogueVM Error: Missing value for isSpecialBehaviorSet modifyStat: \(parameters)", category: "Error")
                    return 
                }
                npc.isNpcInteractionBehaviorSet = (v != 0)
                DebugLogService.shared.log("DialogueVM: NPC \(npc.id) isSpecialBehaviorSet set to \(npc.isNpcInteractionBehaviorSet)", category: "DialogueAction")
            case .specialBehaviorTime:
                guard let timeValue = value else { 
                    DebugLogService.shared.log("DialogueVM Error: Missing value for specialBehaviorTime modifyStat: \(parameters)", category: "Error")
                    return 
                }
                npc.npcInteractionSpecialTime = timeValue
                DebugLogService.shared.log("DialogueVM: NPC \(npc.id) specialBehaviorTime set to \(npc.npcInteractionSpecialTime)", category: "DialogueAction")
            case .activity:
                if let activityName = parameters["activityName"]?.stringValue,
                   let newActivity = NPCActivityType(rawValue: activityName) {
                    npc.currentActivity = newActivity
                    DebugLogService.shared.log("DialogueVM: NPC \(npc.id) currentActivity set to \(newActivity.rawValue)", category: "DialogueAction")
                } else {
                    DebugLogService.shared.log("DialogueVM Error: Invalid or missing activityName for .activity stat. Provided: \(parameters["activityName"]?.stringValue ?? "nil")", category: "Error")
                }
            default:
                DebugLogService.shared.log("Warning: Unhandled NPC stat for modifyStat: \(stat)", category: "DialogueVM")
            }
            
        case .player:
            switch stat {
            case .coins:
                guard let changeValue = value else {
                    DebugLogService.shared.log("DialogueVM Error: Missing value for coins modifyStat (player): \(parameters)", category: "Error")
                    return
                }
                if changeValue > 0 {
                    CoinsManagementService.shared.moveCoins(from: player, to: npc, amount: changeValue)
                } else if changeValue < 0 {
                    CoinsManagementService.shared.moveCoins(from: npc, to: player, amount: changeValue)
                }
            default:
                 DebugLogService.shared.log("Warning: Unhandled Player stat for modifyStat: \(stat)", category: "DialogueVM")
            }
            
        case .global:
            switch stat {
            case .awareness:
                guard let awarenessValue = value else {
                    DebugLogService.shared.log("DialogueVM Error: Missing value for awareness modifyStat: \(parameters)", category: "Error")
                    return
                }
                if awarenessValue > 0 {
                    vampireNatureRevealService.increaseAwareness(amount: Float(awarenessValue))
                } else if awarenessValue < 0 {
                    vampireNatureRevealService.decreaseAwareness(amount: Float(abs(awarenessValue)))
                }
            case .questStatus:
                 DebugLogService.shared.log("Quest Status modification triggered: Quest \(parameters["questId"]?.stringValue ?? "N/A"), Status \(value ?? -1)", category: "DialogueVM")
                 break
            case .gameFlag:
                 guard let flagName = parameters["flagName"]?.stringValue,
                       let flagValue = value else {
                     DebugLogService.shared.log("DialogueVM Error: Missing flagName or value for gameFlag modifyStat: \(parameters)", category: "Error")
                     return
                 }
                 DebugLogService.shared.log("DialogueVM: Processing modifyStat for gameFlag. Flag: \(flagName), Value: \(flagValue)", category: "DialogueVM")
                 questService.setGlobalFlag(name: flagName, value: flagValue)
                 break
            default:
                 DebugLogService.shared.log("Warning: Unhandled Global stat for modifyStat: \(stat)", category: "DialogueVM")
            }
        }
    }
    
    private func executeTriggerGameEventAction(_ parameters: [String: DialogueAction.ActionParameterValue], player: Player, npc: NPC) {
        guard let eventName = parameters["eventName"]?.stringValue else {
             DebugLogService.shared.log("Error: Missing eventName for triggerGameEvent action: \(parameters)", category: "DialogueVM")
            return
        }
        
        DebugLogService.shared.log("Executing triggerGameEvent: \(eventName) with params: \(parameters)", category: "DialogueVM")

        switch eventName {
        case "JailPlayer":
            jailPlayer()
        case "TimeAdvance":
            GameTimeService.shared.advanceTime()
        case "LoveScene":
            loveForSale()
        case "requestQuestStart":
            if let questId = parameters["questId"]?.stringValue {
                DebugLogService.shared.log("DialogueVM: Event 'requestQuestStart' received for quest: \(questId). Starting NPC: \(self.npc.name)", category: "QuestIntegration")
                questService.startQuest(questId: questId, startingNPC: self.npc)
            } else {
                DebugLogService.shared.log("DialogueVM Error: Missing questId for requestQuestStart event. Parameters: \(parameters)", category: "Error")
            }
        case "StatisticIncrement":
            if let statName = parameters["statName"]?.stringValue {
                if statName == "bribes" {
                    StatisticsService.shared.increaseBribes()
                } else if statName == "nightSpentsWithSomeone" {
                    StatisticsService.shared.increaseNightSpentsWithSomeone()
                } else {
                    DebugLogService.shared.log("Warning: Unhandled statName '\(statName)' for StatisticIncrement action.", category: "DialogueVM")
                }
            } else {
                DebugLogService.shared.log("Error: Missing statName for StatisticIncrement action: \(parameters)", category: "DialogueVM")
            }
        default:
            DebugLogService.shared.log("Warning: Unhandled eventName '\(eventName)' for triggerGameEvent action.", category: "DialogueVM")
        }
    }
}

class DialogueOption: Identifiable {
    var id = UUID()
    var text: String = ""
    var type: DialogueOptionType = .normal
    var nextNodeId: String = ""
    var failureNode: String?
    var successActions: [DialogueAction]?
    var failureActions: [DialogueAction]?
    
    static func create(text: String, 
                       type: DialogueOptionType, 
                       nextNodeId: String? = nil, 
                       failureNode: String? = nil, 
                       successActions: [DialogueAction]? = nil,
                       failureActions: [DialogueAction]? = nil) -> DialogueOption {
        let option = DialogueOption()
        option.id = UUID()
        option.text = text
        option.type = type
        option.nextNodeId = nextNodeId ?? ""
        option.failureNode = failureNode
        option.successActions = successActions
        option.failureActions = failureActions
        return option
    }
}
