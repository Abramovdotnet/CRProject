import Foundation
import UIKit
import Combine

class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    
    private let gameEventsBusService: GameEventsBusService
    private let gameTimeService: GameTimeService
    private var cancellables = Set<AnyCancellable>()
    
    init(gameEventsBusService: GameEventsBusService = DependencyManager.shared.resolve(),
         gameTimeService: GameTimeService = DependencyManager.shared.resolve()) {
        self.gameEventsBusService = gameEventsBusService
        self.gameTimeService = gameTimeService
        
        setupObservers()
    }
    
    private func setupObservers() {
        // Subscribe to messages from GameEventsBusService
        gameEventsBusService.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMessages in
                self?.messages = newMessages
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func addMessage(message: String? = nil, type: MessageType) {
        gameEventsBusService.addMessage(message: message, type: type)
    }
    
    func addMessageWithIcon(
        message: String? = nil,
        type: MessageType,
        location: String? = nil,
        primaryNPC: NPC? = nil,
        player: Player? = nil,
        secondaryNPC: NPC? = nil,
        interactionType: NPCInteraction? = nil,
        hasSuccess: Bool = false,
        isSuccess: Bool? = nil,
        isDiscussion: Bool = false,
        messageLocation: String? = nil,
        rumorInteractionType: NPCInteraction? = nil,
        rumorPrimaryNPC: NPC? = nil,
        rumorSecondaryNPC: NPC? = nil
    ) {
        gameEventsBusService.addMessageWithIcon(
            message: message,
            type: type,
            location: location,
            primaryNPC: primaryNPC,
            player: player,
            secondaryNPC: secondaryNPC,
            interactionType: interactionType,
            hasSuccess: hasSuccess,
            isSuccess: isSuccess,
            isDiscussion: isDiscussion,
            messageLocation: messageLocation,
            rumorInteractionType: rumorInteractionType,
            rumorPrimaryNPC: rumorPrimaryNPC,
            rumorSecondaryNPC: rumorSecondaryNPC
        )
    }
    
    func clearChatHistory() {
        gameEventsBusService.clearChatHistory()
    }
    
    // Helper methods for common message types
    func addSystemMessage(_ message: String? = nil) {
        gameEventsBusService.addSystemMessage(message)
    }
    
    func addWarningMessage(_ message: String? = nil) {
        gameEventsBusService.addWarningMessage(message)
    }
    
    func addEventMessage(_ message: String? = nil) {
        gameEventsBusService.addEventMessage(message)
    }
    
    func addDialogueMessage(message: String? = nil) {
        gameEventsBusService.addDialogueMessage(message: message)
    }
    
    func addDangerMessage(message: String? = nil) {
        gameEventsBusService.addDangerMessage(message: message)
    }
    
    func addCommonMessage(message: String? = nil) {
        gameEventsBusService.addCommonMessage(message: message)
    }
    
    // MARK: - Message Formatting Helpers
    
    private var chatFont: UIFont {
        return UIFont(name: "Optima-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10)
    }
    
    func getTypeColor(for type: MessageType) -> UIColor {
        switch type {
        case .common: return UIColor.white.withAlphaComponent(0.9)
        case .warning: return UIColor.yellow.withAlphaComponent(0.9)
        case .system: return UIColor.blue.withAlphaComponent(0.9)
        case .dialogue: return UIColor.green.withAlphaComponent(0.9)
        case .event: return UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.9)
        case .danger: return UIColor.red.withAlphaComponent(0.9)
        }
    }
    
    // MARK: - Interaction Color Scheme
    
    private func getInteractionColor(for interactionType: NPCInteraction) -> UIColor {
        switch interactionType {
        // Обсуждения слухов и общение - фиолетовый
        case .conversation, .awareAboutCasualty, .awareAboutVampire, .vampireMilitaryReport:
            return UIColor.systemPurple
            
        // Конфликты - красный
        case .drunkFight, .gambleFight, .argue, .arrest, .theft, .findOutCasualty, .gameOver, .patrol:
            return UIColor.systemRed
            
        // Романтические отношения - розовый (включая "spent time with")
        case .prostitution, .makingLove, .flirt:
            return UIColor(red: 1.0, green: 0.4, blue: 0.8, alpha: 0.9)
            
        // Одиночные действия - зеленый
        case .cleaning, .drinking, .eating, .lookingAtMirror, .suspicioning, .learning, .reading, 
             .praying, .tossingCards, .workingOnSmithingOrder, .workingOnAlchemyPotion, 
             .checkingCoins, .moans, .harvestingFlowers, .cleaningWeapon, .bathing:
            return UIColor.systemGreen
            
        // Деловые/рабочие взаимодействия - стандартный белый цвет
        case .service, .smithingCraft, .alchemyCraft, .askForProtection, .trade, .observing:
            return UIColor.white.withAlphaComponent(0.9)
            
        // Остальные действия - стандартный белый цвет  
        default:
            return UIColor.white.withAlphaComponent(0.9)
        }
    }
    
    // MARK: - Icon Creation Methods
    
    private func createStyledIcon(systemName: String, color: UIColor, size: CGFloat = 12) -> UIImage? {
        let iconSize = CGSize(width: size, height: size)
        
        return UIGraphicsImageRenderer(size: iconSize).image { context in
            // Draw the SF Symbol icon first
            if let symbolImage = UIImage(systemName: systemName) {
                // Configure the symbol with proper weight and scale
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: size * 0.8, weight: .medium, scale: .medium)
                let configuredSymbol = symbolImage.withConfiguration(symbolConfig)
                
                let symbolRect = CGRect(
                    x: (iconSize.width - size * 0.8) / 2,
                    y: (iconSize.height - size * 0.8) / 2,
                    width: size * 0.8,
                    height: size * 0.8
                )
                
                // Apply color and subtle glow
                context.cgContext.setShadow(offset: .zero, blur: 1.5, color: color.withAlphaComponent(0.6).cgColor)
                configuredSymbol.withTintColor(color, renderingMode: .alwaysOriginal).draw(in: symbolRect)
            }
        }
    }
    
    private func createIconAttachment(for interactionType: NPCInteraction, size: CGFloat = 14) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        
        let iconName: String
        let iconColor: UIColor
        
        switch interactionType {
        case .conversation:
            iconName = "bubble.left.and.bubble.right"
            iconColor = .systemBlue
        case .trade:
            iconName = "cart"
            iconColor = .systemGreen
        case .observing:
            iconName = "eye"
            iconColor = .systemYellow
        case .theft:
            iconName = "hand.point.up"
            iconColor = .systemRed
        case .awareAboutVampire:
            iconName = "exclamationmark.triangle"
            iconColor = .systemOrange
        case .prostitution:
            iconName = "heart"
            iconColor = UIColor(red: 1.0, green: 0.4, blue: 0.8, alpha: 0.9)
        case .vampireMilitaryReport:
            iconName = "shield.lefthalf.filled"
            iconColor = .systemBlue
        case .drunkFight, .gambleFight:
            iconName = "flame"
            iconColor = .systemRed
        case .argue:
            iconName = "exclamationmark.bubble"
            iconColor = .systemOrange
        case .service:
            iconName = "hand.raised"
            iconColor = .systemBlue
        case .patrol:
            iconName = "figure.walk"
            iconColor = .systemIndigo
        case .makingLove:
            iconName = "heart.fill"
            iconColor = UIColor(red: 1.0, green: 0.4, blue: 0.8, alpha: 0.9)
        case .flirt:
            iconName = "heart.circle"
            iconColor = UIColor(red: 1.0, green: 0.4, blue: 0.8, alpha: 0.9)
        case .smithingCraft:
            iconName = "hammer"
            iconColor = .systemBrown
        case .alchemyCraft:
            iconName = "testtube.2"
            iconColor = .systemPurple
        case .findOutCasualty:
            iconName = "exclamationmark.circle"
            iconColor = .systemRed
        case .askForProtection:
            iconName = "shield"
            iconColor = .systemBlue
        case .arrest:
            iconName = "hand.point.up.left"
            iconColor = .systemRed
        case .cleaning:
            iconName = "sparkles"
            iconColor = .systemCyan
        case .drinking:
            iconName = "cup.and.saucer"
            iconColor = .systemBrown
        case .eating:
            iconName = "fork.knife"
            iconColor = .systemGreen
        case .lookingAtMirror:
            iconName = "mirror"
            iconColor = .systemGray
        case .suspicioning:
            iconName = "questionmark.circle"
            iconColor = .systemYellow
        case .learning:
            iconName = "book"
            iconColor = .systemBlue
        case .reading:
            iconName = "book.pages"
            iconColor = .systemBlue
        case .praying:
            iconName = "hands.sparkles"
            iconColor = .systemYellow
        case .tossingCards:
            iconName = "rectangle.stack"
            iconColor = .systemGray
        case .workingOnSmithingOrder:
            iconName = "hammer.circle"
            iconColor = .systemBrown
        case .workingOnAlchemyPotion:
            iconName = "flask"
            iconColor = .systemPurple
        case .checkingCoins:
            iconName = "dollarsign.circle"
            iconColor = .systemYellow
        case .moans:
            iconName = "face.dashed"
            iconColor = .systemGray
        case .harvestingFlowers:
            iconName = "leaf"
            iconColor = .systemGreen
        case .cleaningWeapon:
            iconName = "sword"
            iconColor = .systemGray
        case .bathing:
            iconName = "drop"
            iconColor = .systemBlue
        default:
            iconName = "circle"
            iconColor = .systemGray
        }
        
        if let styledIcon = createStyledIcon(systemName: iconName, color: iconColor, size: size) {
            attachment.image = styledIcon
        }
        
        // Better alignment with text baseline - move down more to center with text
        attachment.bounds = CGRect(x: 0, y: -3, width: size, height: size)
        
        return attachment
    }
    
    private func createCoinIcon(size: CGFloat = 14) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        
        if let styledIcon = createStyledIcon(systemName: "dollarsign.circle", color: .systemYellow, size: size) {
            attachment.image = styledIcon
        }
        
        // Better alignment with text baseline - move down more to center with text
        attachment.bounds = CGRect(x: 0, y: -3, width: size, height: size)
        return attachment
    }
    
    private func createDiscussionIcon(size: CGFloat = 14) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        
        if let styledIcon = createStyledIcon(systemName: "bubble.left.and.bubble.right", color: .systemCyan, size: size) {
            attachment.image = styledIcon
        }
        
        // Better alignment with text baseline - move down more to center with text
        attachment.bounds = CGRect(x: 0, y: -3, width: size, height: size)
        return attachment
    }
    
    func buildAttributedString(for message: ChatMessage, isPlayer: Bool = false) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        // Timestamp
        let timestampAttributes: [NSAttributedString.Key: Any] = [
            .font: chatFont,
            .foregroundColor: UIColor(Theme.textColor)
        ]
        attributedString.append(NSAttributedString(string: "\(message.timestampHourString) ", attributes: timestampAttributes))
        
        if !message.message.isEmpty {
            // Simple message
            let messageAttributes: [NSAttributedString.Key: Any] = [
                .font: chatFont,
                .foregroundColor: getTypeColor(for: message.type)
            ]
            attributedString.append(NSAttributedString(string: message.message, attributes: messageAttributes))
        } else if message.isDiscussion, let interactionType = message.rumorInteractionType {
            // Discussion message
            buildDiscussionMessage(attributedString: attributedString, message: message, interactionType: interactionType, isPlayer: isPlayer)
        } else if let interactionType = message.interactionType {
            // Interaction message
            buildInteractionMessage(attributedString: attributedString, message: message, interactionType: interactionType, isPlayer: isPlayer)
        }
        
        return attributedString
    }
    
    private func buildDiscussionMessage(attributedString: NSMutableAttributedString, message: ChatMessage, interactionType: NPCInteraction, isPlayer: Bool) {
        // Для обсуждений используем фиолетовый цвет для всего текста
        let discussionColor = UIColor.systemPurple
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: chatFont,
            .foregroundColor: discussionColor
        ]
        
        // Character name
        let characterName = isPlayer ? (message.player?.name ?? "") : (message.primaryNPC?.name ?? "")
        attributedString.append(NSAttributedString(string: "\(characterName) discussed with \(message.secondaryNPC?.name ?? "") how \(message.rumorPrimaryNPC?.name ?? "") ", attributes: textAttributes))
        
        // Add styled discussion icon
        attributedString.append(NSAttributedString(attachment: createDiscussionIcon()))
        attributedString.append(NSAttributedString(string: " ", attributes: textAttributes))
        
        // Add interaction description without brackets and highlighting
        attributedString.append(NSAttributedString(string: "\(interactionType.description) ", attributes: textAttributes))
        
        // Add secondary rumor NPC and location
        attributedString.append(NSAttributedString(string: "\(message.rumorSecondaryNPC?.name ?? "") at \(message.messageLocation ?? "")", attributes: textAttributes))
    }
    
    private func buildInteractionMessage(attributedString: NSMutableAttributedString, message: ChatMessage, interactionType: NPCInteraction, isPlayer: Bool) {
        // Получаем цвет для данного типа взаимодействия
        let interactionColor = getInteractionColor(for: interactionType)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: chatFont,
            .foregroundColor: interactionColor
        ]
        
        // Character name
        let characterName = isPlayer ? (message.player?.name ?? "") : (message.primaryNPC?.name ?? "")
        attributedString.append(NSAttributedString(string: "\(characterName) ", attributes: textAttributes))
        
        // Add success/failure indicator (keep this for important feedback)
        if message.hasSuccess {
            let successColor = message.isSuccess == true ? UIColor.green : UIColor.red
            let successText = message.isSuccess == true ? "successfully" : "unsuccessfully"
            let successAttributes: [NSAttributedString.Key: Any] = [
                .font: chatFont,
                .foregroundColor: successColor
            ]
            attributedString.append(NSAttributedString(string: "\(successText) ", attributes: successAttributes))
        }
        
        // Add coin exchange indicator with styled icon
        if interactionType.hasCoinsExchange {
            attributedString.append(NSAttributedString(attachment: createCoinIcon()))
            attributedString.append(NSAttributedString(string: " ", attributes: textAttributes))
        }
        
        // Add styled interaction icon
        attributedString.append(NSAttributedString(attachment: createIconAttachment(for: interactionType)))
        attributedString.append(NSAttributedString(string: " ", attributes: textAttributes))
        
        // Add interaction description without brackets and highlighting
        attributedString.append(NSAttributedString(string: "\(interactionType.description) ", attributes: textAttributes))
        
        // Add secondary NPC name if present
        if let secondaryNPC = message.secondaryNPC {
            attributedString.append(NSAttributedString(string: "\(secondaryNPC.name)", attributes: textAttributes))
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
} 
