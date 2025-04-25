import Foundation

class GossipGeneratorService {
    static let shared = GossipGeneratorService()
    
    private let npcInteractionEventsService: NPCInteractionEventsService
    private let gameTimeService: GameTimeService
    
    private init() {
        self.npcInteractionEventsService = DependencyManager.shared.resolve()
        self.gameTimeService = DependencyManager.shared.resolve()
    }
    
    func generateRawGossipEvents(for npc: NPC, maxEvents: Int = 10) -> [NPCInteractionEvent] {
        DebugLogService.shared.log("Checking gossip for \(npc.name). Relationship: \(npc.playerRelationship.value)", category: "Gossip")
        guard npc.playerRelationship.value >= 5 else {
            DebugLogService.shared.log("Relationship too low for gossip.", category: "Gossip")
            return []
        }
        
        let allRecentEvents = npcInteractionEventsService.npcInteractionEvents
        DebugLogService.shared.log("Total recent events found: \(allRecentEvents.count)", category: "Gossip")
        
        let filteredEvents = allRecentEvents.filter { event in
                // Only include events from the last day or two for more variety
                let isRecent = event.day >= gameTimeService.currentDay - 2
                // Exclude events where the current NPC was the primary or secondary actor
                let involvesSelf = event.currentNPC.id == npc.id || event.otherNPC?.id == npc.id
                // Exclude simple conversations
                let isConversation = event.interactionType == .conversation
                // Generally require two participants unless the event type inherently makes sense as gossip
                let isMeaningfulInteraction = event.otherNPC != nil || event.interactionType.isStandaloneGossipWorthy
                
                // Log why an event might be excluded
                if !isRecent { DebugLogService.shared.log("Excluding event (too old): \(event.interactionType) involving \(event.currentNPC.name)", category: "GossipFilter") }
                if involvesSelf { DebugLogService.shared.log("Excluding event (involves self): \(event.interactionType) involving \(event.currentNPC.name)", category: "GossipFilter") }
                if isConversation { DebugLogService.shared.log("Excluding event (is conversation): involving \(event.currentNPC.name)", category: "GossipFilter") }
                if !isMeaningfulInteraction { DebugLogService.shared.log("Excluding event (not meaningful interaction): \(event.interactionType) involving \(event.currentNPC.name)", category: "GossipFilter") }
                
                return isRecent && !involvesSelf && !isConversation && isMeaningfulInteraction
            }
        
        DebugLogService.shared.log("Events after filtering: \(filteredEvents.count)", category: "Gossip")
        
        let finalEvents = filteredEvents
            .shuffled() // Shuffle to get random order easily
            .prefix(maxEvents)
        
        return Array(finalEvents)
    }
    
    internal func generateGossipNode(for npc: NPC, event: NPCInteractionEvent) -> DialogueNode {
        let text = generateGossipText(for: npc, event: event)
        
        // Options will be overridden by the DialogueProcessor
        return DialogueNode(
            text: text,
            options: [], // Placeholder, will be replaced
            requirements: nil
        )
    }
    
    func generateGossipText(for npc: NPC, event: NPCInteractionEvent) -> String {
        let interactionDesc = getInteractionDescription(event.interactionType)
        let npc1Name = event.currentNPC.name
        let locationName = event.scene.name
        let timeDesc = getTimeDescription(hour: event.hour)
        
        var template: String
        var text: String
        
        // Choose template based on whether there are two NPCs involved
        if let npc2Name = event.otherNPC?.name {
            let twoPersonTemplates = getGossipTemplates(for: npc, event: event, requiresTwoPeople: true)
            template = twoPersonTemplates.randomElement() ?? "I heard {npc1} and {npc2} were {interaction} at {location} {time}."
            text = template
                .replacingOccurrences(of: "{npc1}", with: npc1Name)
                .replacingOccurrences(of: "{npc2}", with: npc2Name)
        } else {
            let singlePersonTemplates = getGossipTemplates(for: npc, event: event, requiresTwoPeople: false)
            template = singlePersonTemplates.randomElement() ?? "I heard {npc1} was {interaction} at {location} {time}."
            // Replace {npc2} placeholders in single person templates if they exist by mistake
            text = template
                .replacingOccurrences(of: "{npc1}", with: npc1Name)
                .replacingOccurrences(of: "{npc2}", with: "someone else") // Avoid "another person"
        }
        
        // Apply remaining placeholders
        text = text
            .replacingOccurrences(of: "{location}", with: locationName)
            .replacingOccurrences(of: "{time}", with: timeDesc)
            .replacingOccurrences(of: "{interaction}", with: interactionDesc)
        
        if event.hasSuccess {
            text += event.isSuccess ? " Apparently, it went well." : " But it didn't end well, I heard."
        }
        
        return text
    }
    
    private func getInteractionDescription(_ type: NPCInteraction) -> String {
        // More evocative descriptions
        switch type {
        case .drunkFight, .gambleFight: return "causing a scene"
        case .argue: return "in a shouting match"
        case .conversation: return "having a quiet word" // Filtered out
        case .flirt: return "making eyes at eachother"
        case .prostitution: return "looking for quite place"
        case .makingLove: return "occupied... privately"
        case .trade: return "making a deal"
        case .service: return "attending to a customer"
        case .patrol: return "keeping watch"
        case .smithingCraft, .workingOnSmithingOrder: return "hammering away at the forge"
        case .alchemyCraft, .workingOnAlchemyPotion: return "brewing something up"
        case .awareAboutVampire: return "spreading dire warnings about mysterious vampire"
        case .findOutCasualty, .awareAboutCasualty: return "involved with that grim discovery"
        case .askForProtection: return "desperately seeking protection"
        case .observing: return "just lurking and observing"
        case .cleaning: return "tidying up the place"
        case .drinking: return "drinking heavily"
        case .eating: return "having a meal"
        case .learning, .reading: return "lost in a book"
        case .praying: return "deep in prayer"
        case .tossingCards: return "gambling"
        case .suspicioning: return "acting very suspiciously"
        // Add more specific descriptions
        default: return "involved in some odd business" // More intriguing default
        }
    }
    
    // Updated to filter templates based on participant count
    private func getGossipTemplates(for npc: NPC, event: NPCInteractionEvent, requiresTwoPeople: Bool) -> [String] {
        var baseTemplates: [String] = []
        var professionTemplates: [String] = []
        var genderTemplates: [String] = []
        var eventSpecificTemplates: [String] = []
        
        // --- Define Templates (Separated for clarity) ---
        
        // Templates suitable for one OR two people (often mentioning just npc1)
        let generalSingleOrDual = [
             "You wouldn't believe what I just heard! {npc1} was {interaction} at {location} {time}.",
             "Word has it {npc1} was seen {interaction} over at {location} {time}."
        ]
        
        // Templates specifically requiring two people
        let generalDualOnly = [
            "I just got some interesting news about {npc1} and {npc2} {interaction} at {location} {time}.",
            "Did you hear about what happened at {location} {time}? {npc1} was there with {npc2}, apparently {interaction}."
        ]
        
        // Courtesan templates
        let courtesanSingleOrDual = [
            "You know, I hear all sorts of things. Just today, someone mentioned {npc1} was {interaction} at {location} {time}."
        ]
        let courtesanDualOnly = [
             "One of my clients just told me about {npc1} and {npc2} {interaction} at {location} {time}.",
             "The gossip around here is that {npc1} and {npc2} were {interaction} at {location} {time}."
        ]
        
        // Female templates
        let femaleSingleOrDual = [
             "Between you and me, I heard something quite interesting about {npc1} {interaction} at {location} {time}."
        ]
        let femaleDualOnly = [
            "Oh my, you won't believe what I just heard! Apparently {npc1} and {npc2} were {interaction} at {location} {time}."
        ]
        
        // Event-specific templates (can be single or dual based on phrasing)
        switch event.interactionType {
        case .drunkFight, .gambleFight:
             eventSpecificTemplates += [
                 "Things got heated involving {npc1} at {location} {time}. Sounds like a nasty fight.",
                 "Word is {npc1} and {npc2} came to blows over something at {location} {time}." // Dual
             ]
        case .flirt, .makingLove:
             eventSpecificTemplates += [
                 "Seems like sparks were flying around {npc1} at {location} {time}.",
                 "I heard {npc1} was getting quite cozy with {npc2} at {location} {time}." // Dual
             ]
        // Add more event-specific templates here...
        default:
             break
        }
        
        // --- Combine templates based on requiresTwoPeople flag ---
        
        if requiresTwoPeople {
            baseTemplates += generalSingleOrDual + generalDualOnly
            if npc.profession == .courtesan { professionTemplates += courtesanSingleOrDual + courtesanDualOnly }
            if npc.sex == .female { genderTemplates += femaleSingleOrDual + femaleDualOnly }
            // Filter event specific templates for those implying two people (e.g., containing {npc2})
            eventSpecificTemplates = eventSpecificTemplates.filter { $0.contains("{npc2}") }
        } else {
            baseTemplates += generalSingleOrDual
            if npc.profession == .courtesan { professionTemplates += courtesanSingleOrDual }
            if npc.sex == .female { genderTemplates += femaleSingleOrDual }
            // Filter event specific templates for those suitable for one person (e.g., not containing {npc2})
             eventSpecificTemplates = eventSpecificTemplates.filter { !$0.contains("{npc2}") }
        }
        
        // Combine all applicable template lists
        var allTemplates = baseTemplates + professionTemplates + genderTemplates + eventSpecificTemplates
        
        // Ensure there's at least one template
        if allTemplates.isEmpty {
            allTemplates.append(requiresTwoPeople ? "I heard {npc1} and {npc2} were {interaction} at {location} {time}." : "I heard {npc1} was {interaction} at {location} {time}.")
        }
                
        return allTemplates
    }
    
    private func getTimeDescription(hour: Int) -> String {
        switch hour {
        case 0...5:
            return "in the early hours"
        case 6...11:
            return "this morning"
        case 12...17:
            return "this afternoon"
        case 18...23:
            return "this evening"
        default:
            return "recently"
        }
    }
}

extension NPCInteraction {
    // Add a helper property to define which single-NPC interactions are gossip-worthy
    var isStandaloneGossipWorthy: Bool {
        switch self {
        case .workingOnSmithingOrder, .workingOnAlchemyPotion, .suspicioning, .checkingCoins: // Add specific single-person events if they should be gossip
            return true // Example: Maybe observing is interesting gossip
        default:
            return false
        }
    }
}
