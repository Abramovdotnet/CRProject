//
//  NPCCell.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 07.05.2025.
//


import UIKit
import SwiftUI
import CoreMotion
import Combine

class NPCCell: UICollectionViewCell {
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
        contentView.addSubview(cardBackground)
        
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
        // Store reference to current NPC
        self.currentNPC = npc
        
        // Длительность анимации для всех изменений
        let animationDuration: TimeInterval = 0.2
        
        // Card background - adjust for selection state (removed red border)
        UIView.animate(withDuration: animationDuration) {
            if isSelected {
                self.cardBackground.layer.borderColor = UIColor.clear.cgColor // Remove red border
                self.cardBackground.layer.borderWidth = 0
            } else {
                self.cardBackground.layer.borderColor = UIColor.clear.cgColor
                self.cardBackground.layer.borderWidth = 0
            }
        }
        
        // Explicitly set shadow container opacity based on selection state
        if npc.isUnknown && isSelected {
            avatarShadowContainer.layer.shadowOpacity = 0.8 // Show shadow if unknown AND selected
        } else {
            avatarShadowContainer.layer.shadowOpacity = isSelected ? 0 : 0.8 // Standard logic for other cases
        }
        
        // Avatar image - плавная смена изображения
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
        
        // Set avatar border based on selection
        UIView.animate(withDuration: animationDuration) {
            if npc.isUnknown && isSelected {
                self.avatarImageView.layer.borderWidth = 1 // Keep border if unknown AND selected
                self.avatarImageView.layer.borderColor = UIColor.black.cgColor
            } else {
                self.avatarImageView.layer.borderWidth = isSelected ? 0 : 1 // Standard logic for other cases
                self.avatarImageView.layer.borderColor = UIColor.black.cgColor // Ensure black for unselected
            }
        }
        
        // Health indicator - ensure it's visible when selected with glow effect
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        healthIndicator.opacity = isSelected ? 1.0 : 0.0
        healthIndicator.shadowOpacity = isSelected ? 0.8 : 0.0
        CATransaction.commit()
        
        // Update the health indicator path - positioned at outer border of avatar
        if !npc.isUnknown {
            let center = CGPoint(x: healthIndicator.bounds.midX, y: healthIndicator.bounds.midY)
            // Use the radius of health indicator (which is slightly larger than avatar)
            let radius = healthIndicator.bounds.width / 2 - 2
            let startAngle = -CGFloat.pi / 2
            let endAngle = startAngle + 2 * .pi * CGFloat(npc.bloodMeter.currentBlood / 100)
            
            let path = UIBezierPath(arcCenter: center, radius: radius,
                                   startAngle: startAngle, endAngle: endAngle,
                                   clockwise: true)
            
            // Анимация изменения пути для индикатора здоровья
            CATransaction.begin()
            CATransaction.setAnimationDuration(animationDuration)
            healthIndicator.path = path.cgPath
            CATransaction.commit()
        }
        
        // Profession icon - плавная смена иконки
        if !npc.isUnknown {
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 12)
            let newProfessionImage = UIImage(systemName: npc.profession.icon, withConfiguration: iconConfig)
            
            // Convert SwiftUI Color to UIColor
            let color = convertSwiftUIColorToUIColor(npc.profession.color)
            
            UIView.transition(with: professionIcon,
                             duration: animationDuration,
                             options: .transitionCrossDissolve,
                             animations: {
                self.professionIcon.image = newProfessionImage
                self.professionIcon.tintColor = color
                
                // Центрируем иконку внутри фона
                self.professionIcon.contentMode = .center
            }, completion: nil)
            
            // Анимация изменения цвета рамки и тени
            UIView.animate(withDuration: animationDuration) {
                // Set circular background border color to match the profession color
                self.professionIcon.layer.borderColor = color.cgColor
                
                // Плавное появление профессии
                self.professionIcon.alpha = 1.0
            }
            
            // Add glow effect to match color with анимацией
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
        
        // Activity icon - плавная смена иконки
        if !npc.isUnknown {
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 12)
            let newActivityImage = UIImage(systemName: npc.currentActivity.icon, withConfiguration: iconConfig)
            
            // Convert SwiftUI Color to UIColor
            let color = convertSwiftUIColorToUIColor(npc.currentActivity.color)
            
            UIView.transition(with: activityIcon,
                             duration: animationDuration,
                             options: .transitionCrossDissolve,
                             animations: {
                self.activityIcon.image = newActivityImage
                self.activityIcon.tintColor = color
                
                // Центрируем иконку внутри фона
                self.activityIcon.contentMode = .center
            }, completion: nil)
            
            // Анимация изменения цвета рамки и тени
            UIView.animate(withDuration: animationDuration) {
                // Set circular background border color to match the activity color
                self.activityIcon.layer.borderColor = color.cgColor
                
                // Плавное появление активности
                self.activityIcon.alpha = 1.0
            }
            
            // Add glow effect to match color with анимацией
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
        
        // Health percentage - плавное обновление текста
        if !npc.isUnknown {
            // Format health percentage to ensure it displays correctly - full number without truncation
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
            
            // Color the health percentage based on blood level with анимацией
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
        
        // Desired victim indicator - плавное появление/исчезновение
        if !npc.isUnknown, let player = GameStateService.shared.getPlayer(),
           player.desiredVictim.isDesiredVictim(npc: npc) {
            
            // Плавное появление индикатора
            UIView.animate(withDuration: animationDuration) {
                self.desiredVictimIndicator.alpha = 1.0
                self.desiredVictimIndicator.isHidden = false
            }
            
            // Установка иконки с уменьшенным размером и плавным появлением
            UIView.transition(with: desiredVictimIndicator,
                             duration: animationDuration,
                             options: .transitionCrossDissolve,
                             animations: {
                let iconConfig = UIImage.SymbolConfiguration(pointSize: 12)
                self.desiredVictimIndicator.image = UIImage(named: "sphere1")
                self.desiredVictimIndicator.tintColor = UIColor.white // Reset tint to show original image colors
            }, completion: nil)
            
            // Усиливаем эффект свечения когда NPC выбран with анимацией
            CATransaction.begin()
            CATransaction.setAnimationDuration(animationDuration)
            if isSelected {
                desiredVictimIndicator.layer.shadowColor = UIColor.systemRed.cgColor
                desiredVictimIndicator.layer.shadowRadius = 15 // Увеличено с 8 до 15
                desiredVictimIndicator.layer.shadowOpacity = 1.0
            } else {
                desiredVictimIndicator.layer.shadowColor = UIColor.systemRed.cgColor
                desiredVictimIndicator.layer.shadowRadius = 12 // Увеличено с 6 до 12
                desiredVictimIndicator.layer.shadowOpacity = 1.0 // Увеличено с 0.9 до 1.0
            }
            CATransaction.commit()
            
            // Make sure animation is running with enhanced effects
            if desiredVictimIndicator.layer.animation(forKey: "pulseAnimation") == nil {
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
                glowAnimation.fromValue = isSelected ? 10 : 8
                glowAnimation.toValue = isSelected ? 18 : 15
                glowAnimation.autoreverses = true
                glowAnimation.repeatCount = Float.infinity
                glowAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                desiredVictimIndicator.layer.add(glowAnimation, forKey: "glowAnimation")
            }
        } else {
            // Плавное исчезновение индикатора
            UIView.animate(withDuration: animationDuration) {
                self.desiredVictimIndicator.alpha = 0.0
            } completion: { _ in
                self.desiredVictimIndicator.isHidden = true
                // Remove animation if hidden
                self.desiredVictimIndicator.layer.removeAnimation(forKey: "pulseAnimation")
                self.desiredVictimIndicator.layer.removeAnimation(forKey: "glowAnimation")
            }
        }
        
        // Disabled state - плавное изменение прозрачности
        UIView.animate(withDuration: animationDuration) {
            self.cardBackground.alpha = npc.isAlive ? (isDisabled ? 0.5 : 1.0) : 0.4
        }
        
        // Update Quest Indicator Icon
        guard !npc.isUnknown else { // Не показывать для неизвестных NPC
            questIndicatorIcon.isHidden = true
            questIndicatorIcon.layer.removeAnimation(forKey: "questGlowAnimation") // Остановить анимацию
            return // Выходим, если NPC неизвестен, чтобы не вызывать QuestService
        }

        // Читаем предварительно вычисленные квестовые флаги из объекта NPC
        // Предполагаем, что npc.hasNewQuests и npc.questStageUpdateAvaiting теперь Bool
        let npcCanGiveNewQuest = npc.hasNewQuests 
        let npcIsAwaitingAction = npc.questStageUpdateAvaiting

        var shouldShowIcon = false
        var iconTintColor = UIColor.clear
        var iconShadowColor = UIColor.clear

        if npcIsAwaitingAction {
            // Уменьшаем размер символа, чтобы он не касался краев
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: iconSize * 0.55) // 55% от размера иконки
            questIndicatorIcon.image = UIImage(systemName: "exclamationmark", withConfiguration: symbolConfig)
            iconTintColor = UIColor.systemBlue
            iconShadowColor = UIColor.systemBlue.withAlphaComponent(0.9)
            shouldShowIcon = true
        } else if npcCanGiveNewQuest {
            // Уменьшаем размер символа
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: iconSize * 0.55) // 55% от размера иконки
            questIndicatorIcon.image = UIImage(systemName: "exclamationmark", withConfiguration: symbolConfig)
            iconTintColor = UIColor.systemYellow
            iconShadowColor = UIColor.systemYellow.withAlphaComponent(0.9)
            shouldShowIcon = true
        }

        questIndicatorIcon.tintColor = iconTintColor
        // Устанавливаем цвет фона такой же, как у символа, но с некоторой прозрачностью
        // questIndicatorIcon.backgroundColor = iconTintColor.withAlphaComponent(0.7) 
        // Устанавливаем темный фон, как у других иконок
        questIndicatorIcon.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        questIndicatorIcon.layer.borderColor = iconTintColor.cgColor // Устанавливаем цвет контура
        questIndicatorIcon.layer.shadowColor = iconShadowColor.cgColor
        questIndicatorIcon.isHidden = !shouldShowIcon

        if shouldShowIcon {
            // Добавляем или обновляем анимацию свечения, только если она еще не запущена
            if questIndicatorIcon.layer.animation(forKey: "questGlowAnimation") == nil {
                let glow = CABasicAnimation(keyPath: "shadowOpacity")
                glow.fromValue = 0.6 // Увеличим начальное значение для более сильного свечения
                glow.toValue = 1.0   // Максимальное значение для полного свечения
                glow.autoreverses = true
                glow.duration = 0.7 // Немного ускорим
                glow.repeatCount = .infinity
                questIndicatorIcon.layer.add(glow, forKey: "questGlowAnimation")
            }
            questIndicatorIcon.layer.shadowOpacity = 1.0 // Устанавливаем начальную видимость свечения на максимум
        } else {
            questIndicatorIcon.layer.removeAnimation(forKey: "questGlowAnimation")
            questIndicatorIcon.layer.shadowOpacity = 0 // Выключаем свечение
        }

        // Selection state - animate the glow
        UIView.animate(withDuration: animationDuration) {
            // Плавная анимация для тени/свечения (только glow, без рамки)
            self.selectionGlowLayer.shadowOpacity = isSelected ? 0.7 : 0
        }
    }
    
    // Helper method to convert SwiftUI Color to UIColor
    private func convertSwiftUIColorToUIColor(_ color: Color) -> UIColor {
        // Use modern system colors for better appearance
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
                return UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0) // Brown approximation
            }
        }
        
        // Additional colors used in NPCActivityType
        if color == .mint { 
            if #available(iOS 15.0, *) {
                return UIColor.systemMint
            } else {
                return UIColor(red: 0, green: 0.8, blue: 0.6, alpha: 1.0) // Mint approximation
            }
        }
        
        // Default fallback - white with slight blue tint
        return UIColor.white
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        if let npc = currentNPC {
        }
        
        currentNPC = nil
        avatarImageView.image = nil
        selectionGlowLayer.shadowOpacity = 0
        healthIndicator.opacity = 0
        healthIndicator.isHidden = false // Ensure it's not hidden for future use
        healthPercentageLabel.text = "" // Clear text before reuse
        professionIcon.image = nil
        activityIcon.image = nil
        desiredVictimIndicator.isHidden = true
        healthPercentageLabel.isHidden = true
        
        // Stop animation
        desiredVictimIndicator.layer.removeAnimation(forKey: "pulseAnimation")
        desiredVictimIndicator.layer.removeAnimation(forKey: "glowAnimation")
        
        // Reset background style (removed border setting)
        // cardBackground.layer.borderColor = UIColor.gray.withAlphaComponent(0.2).cgColor
        // cardBackground.layer.borderWidth = 1
        
        // Reset avatar border
        avatarImageView.layer.borderWidth = 1 // Use new border width
        avatarImageView.layer.borderColor = UIColor.black.cgColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update positions in case of frame changes
        cardBackground.frame = bounds // Use full bounds
        
        // Increased avatar size by 20%
        let newAvatarSizeLayout: CGFloat = 84
        let newAvatarRadiusLayout: CGFloat = newAvatarSizeLayout / 2
        let avatarFrameLayout = CGRect(x: (bounds.width - newAvatarSizeLayout) / 2, y: 8, width: newAvatarSizeLayout, height: newAvatarSizeLayout)
        avatarImageView.frame = avatarFrameLayout
        avatarShadowContainer.frame = avatarFrameLayout // Update shadow container frame as well
        avatarShadowContainer.layer.cornerRadius = newAvatarRadiusLayout // Ensure corner radius updates
        avatarShadowContainer.layer.shadowPath = UIBezierPath(roundedRect: avatarShadowContainer.bounds, cornerRadius: avatarShadowContainer.layer.cornerRadius).cgPath // Update shadow path on layout change
        
        // Health percentage positioned right at the bottom edge of the avatar
        let healthWidth: CGFloat = 40
        let healthHeight: CGFloat = 18
        let healthX = avatarFrameLayout.midX - healthWidth/2 // Use layout frame
        let healthY = avatarFrameLayout.maxY // Use layout frame
        healthPercentageLabel.frame = CGRect(x: healthX, y: healthY, width: healthWidth, height: healthHeight)
        
        // Profession icon - positioned on the left edge of the avatar
        let avatarRadiusLayout = avatarFrameLayout.width / 2 // Use layout frame
        let profX = avatarFrameLayout.minX - 10 // Use layout frame
        let profY = avatarFrameLayout.maxY - iconSize - 8 // Use layout frame
        professionIcon.frame = CGRect(x: profX, y: profY, width: iconSize, height: iconSize)
        professionIcon.layer.cornerRadius = iconSize / 2 // Ensure circular shape in layout updates
        
        // Activity icon - positioned on the right edge of the avatar
        let activityX = avatarFrameLayout.maxX - iconSize + 10 // Use layout frame
        let activityY = avatarFrameLayout.maxY - iconSize - 8 // Use layout frame
        activityIcon.frame = CGRect(x: activityX, y: activityY, width: iconSize, height: iconSize)
        activityIcon.layer.cornerRadius = iconSize / 2 // Ensure circular shape in layout updates
        
        // Position health indicator circle on the outer border of the avatar
        let healthIndicatorSize = avatarFrameLayout.width + 6 // Use layout frame
        let healthIndicatorX = avatarFrameLayout.midX - healthIndicatorSize/2 // Use layout frame
        let healthIndicatorY = avatarFrameLayout.midY - healthIndicatorSize/2 // Use layout frame
        healthIndicator.frame = CGRect(x: healthIndicatorX, y: healthIndicatorY, width: healthIndicatorSize, height: healthIndicatorSize)
        
        // Update the selection glow layer frame to match the avatar
        selectionGlowLayer.frame = avatarFrameLayout // Use layout frame
        
        // Always check if this cell should show health indicator
        if let npc = currentNPC, NPCInteractionManager.shared.selectedNPC?.id == npc.id {
            healthIndicator.opacity = 1.0
            
            // Update health indicator path - use outer border position
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
