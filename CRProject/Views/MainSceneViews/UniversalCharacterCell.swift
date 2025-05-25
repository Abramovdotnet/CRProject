import UIKit
import SwiftUI
import CoreMotion
import Combine

class UniversalCharacterCell: UIView {
    private let avatarImageView = UIImageView()
    private let avatarShadowContainer = UIView()
    private let professionIcon = UIImageView()
    private let activityIcon = UIImageView()
    let healthIndicator = CAShapeLayer()
    private let desiredVictimIndicator = UIImageView()
    private let healthPercentageLabel = UILabel()
    private let selectionGlowLayer = CALayer()
    private let cardBackground = UIView()
    private let questIndicatorIcon = UIImageView()
    
    // Store reference to current NPC for debugging
    var currentNPC: NPC?
    
    private let iconSize: CGFloat = 22 // Define iconSize as a class constant
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Card background with transparent background and subtle border
        cardBackground.frame = bounds // Use full bounds
        cardBackground.backgroundColor = UIColor.clear
        cardBackground.layer.cornerRadius = 12
        cardBackground.layer.borderWidth = 0 // Remove border
        cardBackground.clipsToBounds = false // Ensure shadow isn't clipped by card background
        cardBackground.layer.masksToBounds = false // Explicitly set masksToBounds to false
        addSubview(cardBackground)
        
        // Avatar setup - increased size by 20%
        let newAvatarSize: CGFloat = 84
        let newAvatarRadius: CGFloat = newAvatarSize / 2
        let avatarFrame = CGRect(x: (bounds.width - newAvatarSize) / 2, y: 8, width: newAvatarSize, height: newAvatarSize)
        
        // Setup shadow container
        avatarShadowContainer.frame = avatarFrame
        avatarShadowContainer.layer.cornerRadius = newAvatarRadius
        avatarShadowContainer.layer.shadowColor = UIColor.black.cgColor
        avatarShadowContainer.layer.shadowRadius = 10 // Increased radius further
        avatarShadowContainer.layer.shadowOpacity = 0.8 // Increased opacity further
        avatarShadowContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        avatarShadowContainer.backgroundColor = .clear // Ensure it doesn't obscure anything
        avatarShadowContainer.layer.shadowPath = UIBezierPath(roundedRect: avatarShadowContainer.bounds, cornerRadius: avatarShadowContainer.layer.cornerRadius).cgPath // Set shadow path
        cardBackground.addSubview(avatarShadowContainer) // Add shadow view first

        // Setup avatar image view
        avatarImageView.frame = avatarFrame
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true // Keep clipping for circular shape
        avatarImageView.layer.cornerRadius = newAvatarRadius
        avatarImageView.layer.borderWidth = 1 // Increased border width
        avatarImageView.layer.borderColor = UIColor.black.cgColor // Added default black border color
        cardBackground.addSubview(avatarImageView) // Add image view on top of shadow view
        
        // Selection glow
        selectionGlowLayer.frame = avatarFrame
        selectionGlowLayer.cornerRadius = newAvatarRadius
        selectionGlowLayer.shadowColor = UIColor.red.cgColor
        selectionGlowLayer.shadowRadius = 8
        selectionGlowLayer.shadowOpacity = 0 // Hidden by default
        selectionGlowLayer.shadowOffset = .zero
        cardBackground.layer.insertSublayer(selectionGlowLayer, below: avatarImageView.layer)
        
        // Health indicator - initially hidden, positioned on outer border with glow
        // Create a slightly larger frame to position at the outer edge
        let healthIndicatorSize = avatarFrame.width + 6 // Adjusted based on new avatarFrame
        let healthIndicatorX = avatarFrame.midX - healthIndicatorSize/2
        let healthIndicatorY = avatarFrame.midY - healthIndicatorSize/2
        healthIndicator.frame = CGRect(x: healthIndicatorX, y: healthIndicatorY, width: healthIndicatorSize, height: healthIndicatorSize)
        healthIndicator.lineWidth = 3
        healthIndicator.fillColor = UIColor.clear.cgColor
        healthIndicator.strokeColor = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1).cgColor
        healthIndicator.lineCap = .round
        healthIndicator.opacity = 0 // Hidden by default
        
        // Add glow effect to health indicator
        healthIndicator.shadowColor = UIColor.red.cgColor
        healthIndicator.shadowRadius = 4
        healthIndicator.shadowOpacity = 0.8
        healthIndicator.shadowOffset = CGSize.zero
        
        cardBackground.layer.addSublayer(healthIndicator)
        
        // Create a consistent font to use for both name and health - using Optima to match Theme.bodyFont
        let textFont = UIFont(name: "Optima", size: 11) ?? UIFont.systemFont(ofSize: 11, weight: .regular)
        
        // Health percentage positioned right at the bottom edge of the avatar
        let healthWidth: CGFloat = 40
        let healthHeight: CGFloat = 18
        let healthX = avatarFrame.midX - healthWidth/2
        let healthY = avatarFrame.maxY // Position right at the bottom edge
        healthPercentageLabel.frame = CGRect(x: healthX, y: healthY, width: healthWidth, height: healthHeight)
        healthPercentageLabel.font = textFont // Match the name font
        healthPercentageLabel.textColor = UIColor.white
        healthPercentageLabel.textAlignment = .center
        healthPercentageLabel.backgroundColor = UIColor.clear // Remove background
        healthPercentageLabel.clipsToBounds = false
        healthPercentageLabel.layer.shadowColor = UIColor.black.cgColor
        healthPercentageLabel.layer.shadowRadius = 2
        healthPercentageLabel.layer.shadowOpacity = 1
        healthPercentageLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        cardBackground.addSubview(healthPercentageLabel)
        
        // Profession icon - positioned on the left edge of the avatar
        let avatarRadius = avatarFrame.width / 2 // Adjusted based on new avatarFrame
        let profX = avatarFrame.minX - 10 // Closer to avatar (adjusted from -15)
        let profY = avatarFrame.maxY - iconSize - 8 // Maintained same vertical position
        
        // Add circular background with stroke for profession icon
        professionIcon.frame = CGRect(x: profX, y: profY, width: iconSize, height: iconSize)
        professionIcon.contentMode = .scaleAspectFit
        professionIcon.backgroundColor = UIColor.clear
        professionIcon.clipsToBounds = false // Allow glow effect to be visible
        professionIcon.layer.shadowColor = UIColor.black.cgColor
        professionIcon.layer.shadowRadius = 2
        professionIcon.layer.shadowOpacity = 1
        professionIcon.layer.shadowOffset = CGSize(width: 0, height: 1)
        
        // Add circular background and border
        professionIcon.layer.cornerRadius = iconSize / 2
        professionIcon.layer.borderWidth = 0.5
        professionIcon.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        professionIcon.layer.backgroundColor = UIColor.black.withAlphaComponent(0.7).cgColor
        professionIcon.alpha = 1.0 // Ensure 100% opacity
        
        // Add glow effect to match color - slightly reduced
        professionIcon.layer.shadowColor = UIColor.black.cgColor
        professionIcon.layer.shadowRadius = 3 // Reduced from 4
        professionIcon.layer.shadowOpacity = 0.6 // Reduced from 0.8
        professionIcon.layer.shadowOffset = CGSize.zero
        
        cardBackground.addSubview(professionIcon)
        
        // Activity icon - positioned on the right edge of the avatar
        let activityX = avatarFrame.maxX - iconSize + 10 // Closer to avatar (adjusted from +15)
        let activityY = avatarFrame.maxY - iconSize - 8 // Maintained same vertical position
        
        // Add circular background with stroke for activity icon
        activityIcon.frame = CGRect(x: activityX, y: activityY, width: iconSize, height: iconSize)
        activityIcon.contentMode = .scaleAspectFit
        activityIcon.backgroundColor = UIColor.clear
        activityIcon.clipsToBounds = false // Allow glow effect to be visible
        activityIcon.layer.shadowColor = UIColor.black.cgColor
        activityIcon.layer.shadowRadius = 2
        activityIcon.layer.shadowOpacity = 1
        activityIcon.layer.shadowOffset = CGSize(width: 0, height: 1)
        
        // Add circular background and border
        activityIcon.layer.cornerRadius = iconSize / 2
        activityIcon.layer.borderWidth = 0.5
        activityIcon.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        activityIcon.layer.backgroundColor = UIColor.black.withAlphaComponent(0.7).cgColor
        activityIcon.alpha = 1.0 // Ensure 100% opacity
        
        // Add glow effect to match color - slightly reduced
        activityIcon.layer.shadowColor = UIColor.black.cgColor
        activityIcon.layer.shadowRadius = 3 // Reduced from 4
        activityIcon.layer.shadowOpacity = 0.6 // Reduced from 0.8
        activityIcon.layer.shadowOffset = CGSize.zero
        
        cardBackground.addSubview(activityIcon)
        
        // Quest Indicator Icon
        let questIconCenterX = avatarFrame.midX // Adjusted based on new avatarFrame
        // Position calculation depends on healthIndicator frame, which is now updated
        let questIconY = healthIndicator.frame.maxY - iconSize + 4

        questIndicatorIcon.frame = CGRect(x: questIconCenterX - iconSize / 2, y: questIconY, width: iconSize, height: iconSize)
        questIndicatorIcon.contentMode = .scaleAspectFit
        // questIndicatorIcon.backgroundColor = UIColor.black.withAlphaComponent(0.7) // Будет установлено в configure
        questIndicatorIcon.clipsToBounds = false 
        questIndicatorIcon.layer.cornerRadius = iconSize / 2
        questIndicatorIcon.layer.borderWidth = 0.5
        // questIndicatorIcon.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor // Будет установлено в configure
        questIndicatorIcon.layer.shadowRadius = 6 // Увеличим радиус свечения
        questIndicatorIcon.layer.shadowOpacity = 0 // По умолчанию свечение выключено
        questIndicatorIcon.isHidden = true 
        cardBackground.addSubview(questIndicatorIcon)
        
        // Desired victim indicator - positioned at top of avatar with red glow
        let desiredX = avatarFrame.midX - iconSize/2 // Adjusted based on new avatarFrame
        let desiredY = avatarFrame.minY - iconSize/2 - 4 // Adjusted based on new avatarFrame
        desiredVictimIndicator.frame = CGRect(x: desiredX, y: desiredY, width: iconSize, height: iconSize)
        desiredVictimIndicator.contentMode = .scaleAspectFit
        desiredVictimIndicator.layer.shadowColor = UIColor.red.cgColor // Red shadow
        desiredVictimIndicator.layer.shadowRadius = 10 // Increased from 5 to 10
        desiredVictimIndicator.layer.shadowOpacity = 1.0 // Increased from 0.8 to 1.0
        desiredVictimIndicator.layer.shadowOffset = CGSize(width: 0, height: 0)
        desiredVictimIndicator.backgroundColor = UIColor.black.withAlphaComponent(0.3) // More transparent background
        desiredVictimIndicator.layer.cornerRadius = iconSize/2
        desiredVictimIndicator.clipsToBounds = false // Allow glow to extend beyond bounds
        cardBackground.addSubview(desiredVictimIndicator)
        
        // Add pulsating animation to victim indicator with more dramatic effect
        let pulseAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        pulseAnimation.duration = 0.5 // Уменьшено с 0.8 до 0.5
        pulseAnimation.fromValue = 0.3
        pulseAnimation.toValue = 1.0
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = Float.infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        desiredVictimIndicator.layer.add(pulseAnimation, forKey: "pulseAnimation")
        
        // Add shadow radius animation for more dramatic glow effect
        let glowAnimation = CABasicAnimation(keyPath: "shadowRadius")
        glowAnimation.duration = 0.5 // Уменьшено с 0.8 до 0.5
        glowAnimation.fromValue = 6
        glowAnimation.toValue = 12
        glowAnimation.autoreverses = true
        glowAnimation.repeatCount = Float.infinity
        glowAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        desiredVictimIndicator.layer.add(glowAnimation, forKey: "glowAnimation")
    }

    func configure(with npc: NPC, isSelected: Bool, isDisabled: Bool) {
        self.currentNPC = npc
        let animationDuration: TimeInterval = 0.2
        UIView.animate(withDuration: animationDuration) {
            if isSelected {
                self.cardBackground.layer.borderColor = UIColor.clear.cgColor
                self.cardBackground.layer.borderWidth = 0
            } else {
                self.cardBackground.layer.borderColor = UIColor.clear.cgColor
                self.cardBackground.layer.borderWidth = 0
            }
        }
        if npc.isUnknown && isSelected {
            avatarShadowContainer.layer.shadowOpacity = 0.8
        } else {
            avatarShadowContainer.layer.shadowOpacity = isSelected ? 0 : 0.8
        }
        let newImage = npc.isUnknown ?
            UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder") :
            UIImage(named: "npc\(npc.id)") ?? UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")
        if avatarImageView.image != newImage {
            UIView.transition(with: avatarImageView,
                             duration: animationDuration,
                             options: .transitionCrossDissolve,
                             animations: {
                self.avatarImageView.image = newImage
            }, completion: nil)
        }
        UIView.animate(withDuration: animationDuration) {
            if npc.isUnknown && isSelected {
                self.avatarImageView.layer.borderWidth = 1
                self.avatarImageView.layer.borderColor = UIColor.black.cgColor
            } else {
                self.avatarImageView.layer.borderWidth = isSelected ? 0 : 1
                self.avatarImageView.layer.borderColor = UIColor.black.cgColor
            }
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        healthIndicator.opacity = isSelected ? 1.0 : 0.0
        healthIndicator.shadowOpacity = isSelected ? 0.8 : 0.0
        CATransaction.commit()
        if !npc.isUnknown {
            let center = CGPoint(x: healthIndicator.bounds.midX, y: healthIndicator.bounds.midY)
            let radius = healthIndicator.bounds.width / 2 - 2
            let startAngle = -CGFloat.pi / 2
            let endAngle = startAngle + 2 * .pi * CGFloat(npc.bloodMeter.currentBlood / 100)
            let path = UIBezierPath(arcCenter: center, radius: radius,
                                   startAngle: startAngle, endAngle: endAngle,
                                   clockwise: true)
            CATransaction.begin()
            CATransaction.setAnimationDuration(animationDuration)
            healthIndicator.path = path.cgPath
            CATransaction.commit()
        }
        if !npc.isUnknown {
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 12)
            let newProfessionImage = UIImage(systemName: npc.profession.icon, withConfiguration: iconConfig)
            let color = convertSwiftUIColorToUIColor(npc.profession.color)
            UIView.transition(with: professionIcon,
                             duration: animationDuration,
                             options: .transitionCrossDissolve,
                             animations: {
                self.professionIcon.image = newProfessionImage
                self.professionIcon.tintColor = color
                self.professionIcon.contentMode = .center
            }, completion: nil)
            UIView.animate(withDuration: animationDuration) {
                self.professionIcon.layer.borderColor = color.cgColor
                self.professionIcon.alpha = 1.0
            }
            CATransaction.begin()
            CATransaction.setAnimationDuration(animationDuration)
            professionIcon.layer.shadowColor = color.cgColor
            professionIcon.layer.shadowRadius = 3
            professionIcon.layer.shadowOpacity = 0.6
            professionIcon.layer.shadowOffset = CGSize.zero
            CATransaction.commit()
            professionIcon.isHidden = false
        } else {
            UIView.animate(withDuration: animationDuration) {
                self.professionIcon.alpha = 0.0
            }
        }
        if !npc.isUnknown {
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 12)
            let newActivityImage = UIImage(systemName: npc.currentActivity.icon, withConfiguration: iconConfig)
            let color = convertSwiftUIColorToUIColor(npc.currentActivity.color)
            UIView.transition(with: activityIcon,
                             duration: animationDuration,
                             options: .transitionCrossDissolve,
                             animations: {
                self.activityIcon.image = newActivityImage
                self.activityIcon.tintColor = color
                self.activityIcon.contentMode = .center
            }, completion: nil)
            UIView.animate(withDuration: animationDuration) {
                self.activityIcon.layer.borderColor = color.cgColor
                self.activityIcon.alpha = 1.0
            }
            CATransaction.begin()
            CATransaction.setAnimationDuration(animationDuration)
            activityIcon.layer.shadowColor = color.cgColor
            activityIcon.layer.shadowRadius = 3
            activityIcon.layer.shadowOpacity = 0.6
            activityIcon.layer.shadowOffset = CGSize.zero
            CATransaction.commit()
            activityIcon.isHidden = false
        } else {
            UIView.animate(withDuration: animationDuration) {
                self.activityIcon.alpha = 0.0
            }
        }
        if !npc.isUnknown {
            let healthValue = Int(npc.bloodMeter.currentBlood)
            let healthText = "\(healthValue)%"
            if healthPercentageLabel.text != healthText {
                UIView.transition(with: healthPercentageLabel,
                                 duration: animationDuration,
                                 options: .transitionCrossDissolve,
                                 animations: {
                    self.healthPercentageLabel.text = healthText
                }, completion: nil)
            }
            healthPercentageLabel.isHidden = false
            UIView.animate(withDuration: animationDuration) {
                if npc.bloodMeter.currentBlood < 30 {
                    self.healthPercentageLabel.textColor = UIColor.red
                } else if npc.bloodMeter.currentBlood < 60 {
                    self.healthPercentageLabel.textColor = UIColor.orange
                } else {
                    self.healthPercentageLabel.textColor = UIColor.white
                }
            }
        } else {
            UIView.animate(withDuration: animationDuration) {
                self.healthPercentageLabel.alpha = 0.0
            }
        }
        if !npc.isUnknown, let player = GameStateService.shared.getPlayer(),
           player.desiredVictim.isDesiredVictim(npc: npc) {
            UIView.animate(withDuration: animationDuration) {
                self.desiredVictimIndicator.alpha = 1.0
                self.desiredVictimIndicator.isHidden = false
            }
            UIView.transition(with: desiredVictimIndicator,
                             duration: animationDuration,
                             options: .transitionCrossDissolve,
                             animations: {
                let iconConfig = UIImage.SymbolConfiguration(pointSize: 12)
                self.desiredVictimIndicator.image = UIImage(named: "sphere1")
                self.desiredVictimIndicator.tintColor = UIColor.white
            }, completion: nil)
            CATransaction.begin()
            CATransaction.setAnimationDuration(animationDuration)
            if isSelected {
                desiredVictimIndicator.layer.shadowColor = UIColor.systemRed.cgColor
                desiredVictimIndicator.layer.shadowRadius = 15
                desiredVictimIndicator.layer.shadowOpacity = 1.0
            } else {
                desiredVictimIndicator.layer.shadowColor = UIColor.systemRed.cgColor
                desiredVictimIndicator.layer.shadowRadius = 12
                desiredVictimIndicator.layer.shadowOpacity = 1.0
            }
            CATransaction.commit()
            if desiredVictimIndicator.layer.animation(forKey: "pulseAnimation") == nil {
                let pulseAnimation = CABasicAnimation(keyPath: "shadowOpacity")
                pulseAnimation.duration = 0.5
                pulseAnimation.fromValue = 0.3
                pulseAnimation.toValue = 1.0
                pulseAnimation.autoreverses = true
                pulseAnimation.repeatCount = Float.infinity
                pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                desiredVictimIndicator.layer.add(pulseAnimation, forKey: "pulseAnimation")
                let glowAnimation = CABasicAnimation(keyPath: "shadowRadius")
                glowAnimation.duration = 0.5
                glowAnimation.fromValue = isSelected ? 10 : 8
                glowAnimation.toValue = isSelected ? 18 : 15
                glowAnimation.autoreverses = true
                glowAnimation.repeatCount = Float.infinity
                glowAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                desiredVictimIndicator.layer.add(glowAnimation, forKey: "glowAnimation")
            }
        } else {
            UIView.animate(withDuration: animationDuration) {
                self.desiredVictimIndicator.alpha = 0.0
            } completion: { _ in
                self.desiredVictimIndicator.isHidden = true
                self.desiredVictimIndicator.layer.removeAnimation(forKey: "pulseAnimation")
                self.desiredVictimIndicator.layer.removeAnimation(forKey: "glowAnimation")
            }
        }
        UIView.animate(withDuration: animationDuration) {
            self.cardBackground.alpha = npc.isAlive ? (isDisabled ? 0.5 : 1.0) : 0.4
        }
        guard !npc.isUnknown else {
            questIndicatorIcon.isHidden = true
            questIndicatorIcon.layer.removeAnimation(forKey: "questGlowAnimation")
            return
        }
        let npcCanGiveNewQuest = npc.hasNewQuests 
        let npcIsAwaitingAction = npc.questStageUpdateAvaiting
        var shouldShowIcon = false
        var iconTintColor = UIColor.clear
        var iconShadowColor = UIColor.clear
        if npcIsAwaitingAction {
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: iconSize * 0.55)
            questIndicatorIcon.image = UIImage(systemName: "exclamationmark", withConfiguration: symbolConfig)
            iconTintColor = UIColor.systemBlue
            iconShadowColor = UIColor.systemBlue.withAlphaComponent(0.9)
            shouldShowIcon = true
        } else if npcCanGiveNewQuest {
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: iconSize * 0.55)
            questIndicatorIcon.image = UIImage(systemName: "exclamationmark", withConfiguration: symbolConfig)
            iconTintColor = UIColor.systemYellow
            iconShadowColor = UIColor.systemYellow.withAlphaComponent(0.9)
            shouldShowIcon = true
        }
        questIndicatorIcon.tintColor = iconTintColor
        questIndicatorIcon.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        questIndicatorIcon.layer.borderColor = iconTintColor.cgColor
        questIndicatorIcon.layer.shadowColor = iconShadowColor.cgColor
        questIndicatorIcon.isHidden = !shouldShowIcon
        if shouldShowIcon {
            if questIndicatorIcon.layer.animation(forKey: "questGlowAnimation") == nil {
                let glow = CABasicAnimation(keyPath: "shadowOpacity")
                glow.fromValue = 0.6
                glow.toValue = 1.0
                glow.autoreverses = true
                glow.duration = 0.7
                glow.repeatCount = .infinity
                questIndicatorIcon.layer.add(glow, forKey: "questGlowAnimation")
            }
            questIndicatorIcon.layer.shadowOpacity = 1.0
        } else {
            questIndicatorIcon.layer.removeAnimation(forKey: "questGlowAnimation")
            questIndicatorIcon.layer.shadowOpacity = 0
        }
        UIView.animate(withDuration: animationDuration) {
            self.selectionGlowLayer.shadowOpacity = isSelected ? 0.7 : 0
        }
        if isSelected {
            healthIndicator.opacity = 1.0
        }
    }

    // MARK: - Новый метод для Player
    func configure(with player: Player, isDisabled: Bool) {
        // Всегда ведём себя как isSelected = true
        let animationDuration: TimeInterval = 0.2
        // --- Glow и фон ---
        UIView.animate(withDuration: animationDuration) {
            self.cardBackground.layer.borderColor = UIColor.clear.cgColor
            self.cardBackground.layer.borderWidth = 0
        }
        avatarShadowContainer.layer.shadowOpacity = 0.8
        // --- Аватар ---
        let newImage = UIImage(named: "playerAvatar") ?? UIImage(named: "defaultMalePlaceholder")
        if avatarImageView.image != newImage {
            UIView.transition(with: avatarImageView,
                             duration: animationDuration,
                             options: .transitionCrossDissolve,
                             animations: {
                self.avatarImageView.image = newImage
            }, completion: nil)
        }
        UIView.animate(withDuration: animationDuration) {
            self.avatarImageView.layer.borderWidth = 1
            self.avatarImageView.layer.borderColor = UIColor.black.cgColor
        }
        // --- Индикатор здоровья ---
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        healthIndicator.opacity = 1.0
        healthIndicator.shadowOpacity = 0.8
        // Кольцо здоровья
        let center = CGPoint(x: healthIndicator.bounds.midX, y: healthIndicator.bounds.midY)
        let radius = healthIndicator.bounds.width / 2 - 2
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * .pi * CGFloat(player.bloodMeter.currentBlood / 100)
        let path = UIBezierPath(arcCenter: center, radius: radius,
                               startAngle: startAngle, endAngle: endAngle,
                               clockwise: true)
        healthIndicator.path = path.cgPath
        CATransaction.commit()
        // --- Профессия скрыта ---
        professionIcon.isHidden = true
        // --- Активность: всегда "drop" красного цвета ---
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 12)
        let dropImage = UIImage(systemName: "drop", withConfiguration: iconConfig)
        UIView.transition(with: activityIcon,
                         duration: animationDuration,
                         options: .transitionCrossDissolve,
                         animations: {
            self.activityIcon.image = dropImage
            self.activityIcon.tintColor = UIColor.systemRed
            self.activityIcon.contentMode = .center
        }, completion: nil)
        UIView.animate(withDuration: animationDuration) {
            self.activityIcon.layer.borderColor = UIColor.systemRed.cgColor
            self.activityIcon.alpha = 1.0
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        activityIcon.layer.shadowColor = UIColor.systemRed.cgColor
        activityIcon.layer.shadowRadius = 3
        activityIcon.layer.shadowOpacity = 0.6
        activityIcon.layer.shadowOffset = CGSize.zero
        CATransaction.commit()
        activityIcon.isHidden = false
        // --- Здоровье ---
        let healthValue = Int(player.bloodMeter.currentBlood)
        let healthText = "\(healthValue)%"
        if healthPercentageLabel.text != healthText {
            UIView.transition(with: healthPercentageLabel,
                             duration: animationDuration,
                             options: .transitionCrossDissolve,
                             animations: {
                self.healthPercentageLabel.text = healthText
            }, completion: nil)
        }
        healthPercentageLabel.isHidden = false
        UIView.animate(withDuration: animationDuration) {
            if player.bloodMeter.currentBlood < 30 {
                self.healthPercentageLabel.textColor = UIColor.red
            } else if player.bloodMeter.currentBlood < 60 {
                self.healthPercentageLabel.textColor = UIColor.orange
            } else {
                self.healthPercentageLabel.textColor = UIColor.white
            }
        }
        // --- Индикаторы жертвы и квеста скрыты ---
        desiredVictimIndicator.isHidden = true
        questIndicatorIcon.isHidden = true
        // --- Анимация прозрачности карточки ---
        UIView.animate(withDuration: animationDuration) {
            self.cardBackground.alpha = player.isAlive ? (isDisabled ? 0.5 : 1.0) : 0.4
        }
        // --- Glow ---
        UIView.animate(withDuration: animationDuration) {
            self.selectionGlowLayer.shadowOpacity = 0.7
        }
    }

    private func convertSwiftUIColorToUIColor(_ color: Color) -> UIColor {
        if color == .red { return UIColor.systemRed }
        if color == .blue { return UIColor.systemBlue }
        if color == .green { return UIColor.systemGreen }
        if color == .yellow { return UIColor.systemYellow }
        if color == .orange { return UIColor.systemOrange }
        if color == .purple { return UIColor.systemPurple }
        if color == .pink { return UIColor.systemPink }
        if color == .gray { return UIColor.systemGray }
        if color == .brown { 
            if #available(iOS 15.0, *) {
                return UIColor.systemBrown
            } else {
                return UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
            }
        }
        if color == .mint { 
            if #available(iOS 15.0, *) {
                return UIColor.systemMint
            } else {
                return UIColor(red: 0, green: 0.8, blue: 0.6, alpha: 1.0)
            }
        }
        return UIColor.white
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardBackground.frame = bounds
        let newAvatarSizeLayout: CGFloat = 84
        let newAvatarRadiusLayout: CGFloat = newAvatarSizeLayout / 2
        let avatarFrameLayout = CGRect(x: (bounds.width - newAvatarSizeLayout) / 2, y: 8, width: newAvatarSizeLayout, height: newAvatarSizeLayout)
        avatarImageView.frame = avatarFrameLayout
        avatarShadowContainer.frame = avatarFrameLayout
        avatarShadowContainer.layer.cornerRadius = newAvatarRadiusLayout
        avatarShadowContainer.layer.shadowPath = UIBezierPath(roundedRect: avatarShadowContainer.bounds, cornerRadius: avatarShadowContainer.layer.cornerRadius).cgPath
        let healthWidth: CGFloat = 40
        let healthHeight: CGFloat = 18
        let healthX = avatarFrameLayout.midX - healthWidth/2
        let healthY = avatarFrameLayout.maxY
        healthPercentageLabel.frame = CGRect(x: healthX, y: healthY, width: healthWidth, height: healthHeight)
        let avatarRadiusLayout = avatarFrameLayout.width / 2
        let profX = avatarFrameLayout.minX - 10
        let profY = avatarFrameLayout.maxY - iconSize - 8
        professionIcon.frame = CGRect(x: profX, y: profY, width: iconSize, height: iconSize)
        professionIcon.layer.cornerRadius = iconSize / 2
        let activityX = avatarFrameLayout.maxX - iconSize + 10
        let activityY = avatarFrameLayout.maxY - iconSize - 8
        activityIcon.frame = CGRect(x: activityX, y: activityY, width: iconSize, height: iconSize)
        activityIcon.layer.cornerRadius = iconSize / 2
        let healthIndicatorSize = avatarFrameLayout.width + 6
        let healthIndicatorX = avatarFrameLayout.midX - healthIndicatorSize/2
        let healthIndicatorY = avatarFrameLayout.midY - healthIndicatorSize/2
        healthIndicator.frame = CGRect(x: healthIndicatorX, y: healthIndicatorY, width: healthIndicatorSize, height: healthIndicatorSize)
        selectionGlowLayer.frame = avatarFrameLayout
        if let npc = currentNPC {
            healthIndicator.opacity = 1.0
            if !npc.isUnknown {
                let center = CGPoint(x: healthIndicator.bounds.midX, y: healthIndicator.bounds.midY)
                let radius = healthIndicator.bounds.width / 2 - 2
                let startAngle = -CGFloat.pi / 2
                let endAngle = startAngle + 2 * .pi * CGFloat(npc.bloodMeter.currentBlood / 100)
                let path = UIBezierPath(arcCenter: center, radius: radius,
                                        startAngle: startAngle, endAngle: endAngle,
                                        clockwise: true)
                healthIndicator.path = path.cgPath
            }
        }
    }
} 