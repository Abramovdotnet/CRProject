import UIKit
import SwiftUI
import CoreMotion
import Combine

class NPCCharacterCell: UICollectionViewCell {
    private let avatarImageView = UIImageView()
    private let avatarShadowContainer = UIView()
    private let professionIcon = UIImageView()
    private let activityIcon = UIImageView()
    let healthIndicator = CAShapeLayer()
    private let desiredVictimIndicator = UIImageView()
    private let healthPercentageLabel = UILabel()
    private let selectionGlowLayer = CALayer()
    private let questIndicatorIcon = UIImageView()
    
    // Glow views для иконок
    private let professionIconGlow = UIImageView()
    private let activityIconGlow = UIImageView()
    
    // Store reference to current NPC for debugging
    var currentNPC: NPC?
    
    private let iconSize: CGFloat = 28 // Было 22, увеличиваем до размера UniversalCharacterCell
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        self.isUserInteractionEnabled = true
        self.subviews.forEach { $0.isUserInteractionEnabled = false }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Avatar setup - теперь занимает весь bounds (убираем cardBackground)
        let newAvatarSize: CGFloat = bounds.width // Аватар занимает весь размер ячейки
        let newAvatarRadius: CGFloat = 12 // Сохраняем радиус закругления
        let avatarFrame = CGRect(x: 0, y: 0, width: newAvatarSize, height: newAvatarSize)
        
        // Setup shadow container - убираем тени
        avatarShadowContainer.frame = avatarFrame
        avatarShadowContainer.layer.cornerRadius = newAvatarRadius
        avatarShadowContainer.layer.shadowColor = UIColor.clear.cgColor
        avatarShadowContainer.layer.shadowRadius = 0
        avatarShadowContainer.layer.shadowOpacity = 0
        avatarShadowContainer.layer.shadowOffset = CGSize.zero
        avatarShadowContainer.backgroundColor = .clear
        contentView.addSubview(avatarShadowContainer)

        // Setup avatar image view
        avatarImageView.frame = avatarFrame
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true // Keep clipping for rounded rectangle shape
        avatarImageView.layer.cornerRadius = newAvatarRadius
        avatarImageView.layer.borderWidth = 1 // Increased border width
        avatarImageView.layer.borderColor = UIColor.black.cgColor // Added default black border color
        
        // Добавляем тень к контейнеру аватара
        avatarShadowContainer.layer.shadowColor = UIColor.black.cgColor
        avatarShadowContainer.layer.shadowRadius = 5
        avatarShadowContainer.layer.shadowOpacity = 0.8
        avatarShadowContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        avatarShadowContainer.layer.shadowPath = UIBezierPath(roundedRect: avatarShadowContainer.bounds, cornerRadius: newAvatarRadius).cgPath
        
        contentView.addSubview(avatarImageView) // Add image view on top of shadow view
        
        // Selection glow
        selectionGlowLayer.frame = avatarFrame
        selectionGlowLayer.cornerRadius = newAvatarRadius
        selectionGlowLayer.shadowColor = UIColor.red.cgColor
        selectionGlowLayer.shadowRadius = 8
        selectionGlowLayer.shadowOpacity = 0 // Hidden by default
        selectionGlowLayer.shadowOffset = .zero
        contentView.layer.insertSublayer(selectionGlowLayer, below: avatarImageView.layer)
        
        // Health indicator - красная полоса здоровья вокруг аватара
        let healthIndicatorSize = avatarFrame.width + 6
        let healthIndicatorX = avatarFrame.midX - healthIndicatorSize/2
        let healthIndicatorY = avatarFrame.midY - healthIndicatorSize/2
        healthIndicator.frame = CGRect(x: healthIndicatorX, y: healthIndicatorY, width: healthIndicatorSize, height: healthIndicatorSize)
        healthIndicator.lineWidth = 3
        healthIndicator.fillColor = UIColor.clear.cgColor
        healthIndicator.strokeColor = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1).cgColor
        healthIndicator.lineCap = .round
        healthIndicator.opacity = 0 // Скрыто по умолчанию, показывается при configure
        
        // Добавляем эффект свечения для индикатора здоровья
        healthIndicator.shadowColor = UIColor.red.cgColor
        healthIndicator.shadowRadius = 4
        healthIndicator.shadowOpacity = 0.8
        healthIndicator.shadowOffset = CGSize.zero
        
        contentView.layer.addSublayer(healthIndicator)
        
        // Health percentage теперь в центре нижней части кольца здоровья
        // Стилизация лейбла
        healthPercentageLabel.font = UIFont(name: "Optima", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .bold) // Увеличиваем размер и делаем жирным
        healthPercentageLabel.textColor = UIColor.white
        healthPercentageLabel.textAlignment = .center
        healthPercentageLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7) // Добавляем фон для лучшей читаемости
        healthPercentageLabel.layer.cornerRadius = 8
        healthPercentageLabel.clipsToBounds = true
        healthPercentageLabel.layer.shadowColor = UIColor.black.cgColor
        healthPercentageLabel.layer.shadowRadius = 3
        healthPercentageLabel.layer.shadowOpacity = 1
        healthPercentageLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        
        // Profession icon - позиционируем в левом верхнем углу аватара
        professionIcon.frame = CGRect(x: avatarFrame.minX + 4, y: avatarFrame.minY + 4, width: iconSize, height: iconSize)
        professionIcon.contentMode = .scaleAspectFit
        professionIcon.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        professionIcon.clipsToBounds = true
        professionIcon.layer.cornerRadius = iconSize / 2
        professionIcon.layer.borderWidth = 0 // Убираем белую обводку
        professionIcon.layer.shadowColor = UIColor.black.cgColor
        professionIcon.layer.shadowRadius = 3
        professionIcon.layer.shadowOpacity = 0.8
        professionIcon.layer.shadowOffset = CGSize(width: 0, height: 1)
        professionIcon.alpha = 1.0
        
        // Glow для profession icon - добавляем как subview к иконке
        professionIconGlow.translatesAutoresizingMaskIntoConstraints = false
        professionIconGlow.contentMode = .scaleAspectFill
        professionIconGlow.alpha = 0.8
        professionIconGlow.isUserInteractionEnabled = false
        professionIcon.addSubview(professionIconGlow)
        professionIcon.sendSubviewToBack(professionIconGlow)
        
        contentView.addSubview(professionIcon)
        
        // Health percentage - позиционируем в центре нижней части кольца
        let healthLabelWidth: CGFloat = 50
        let healthLabelHeight: CGFloat = 20
        healthPercentageLabel.frame = CGRect(
            x: avatarFrame.midX - healthLabelWidth / 2,
            y: avatarFrame.maxY - healthLabelHeight - 8,
            width: healthLabelWidth,
            height: healthLabelHeight
        )
        contentView.addSubview(healthPercentageLabel)
        
        // Activity icon - позиционируем в правом верхнем углу аватара
        activityIcon.frame = CGRect(x: avatarFrame.maxX - iconSize - 4, y: avatarFrame.minY + 4, width: iconSize, height: iconSize)
        activityIcon.contentMode = .scaleAspectFit
        activityIcon.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        activityIcon.clipsToBounds = true
        activityIcon.layer.cornerRadius = iconSize / 2
        activityIcon.layer.borderWidth = 0 // Убираем белую обводку
        activityIcon.layer.shadowColor = UIColor.black.cgColor
        activityIcon.layer.shadowRadius = 3
        activityIcon.layer.shadowOpacity = 0.8
        activityIcon.layer.shadowOffset = CGSize(width: 0, height: 1)
        activityIcon.alpha = 1.0
        
        // Glow для activity icon - добавляем как subview к иконке
        activityIconGlow.translatesAutoresizingMaskIntoConstraints = false
        activityIconGlow.contentMode = .scaleAspectFill
        activityIconGlow.alpha = 0.8
        activityIconGlow.isUserInteractionEnabled = false
        activityIcon.addSubview(activityIconGlow)
        activityIcon.sendSubviewToBack(activityIconGlow)
        
        contentView.addSubview(activityIcon)
        
        // Настраиваем constraints для glow views
        NSLayoutConstraint.activate([
            // Profession icon glow constraints
            professionIconGlow.centerXAnchor.constraint(equalTo: professionIcon.centerXAnchor),
            professionIconGlow.centerYAnchor.constraint(equalTo: professionIcon.centerYAnchor),
            professionIconGlow.widthAnchor.constraint(equalTo: professionIcon.widthAnchor, constant: 12),
            professionIconGlow.heightAnchor.constraint(equalTo: professionIcon.heightAnchor, constant: 12),
            
            // Activity icon glow constraints
            activityIconGlow.centerXAnchor.constraint(equalTo: activityIcon.centerXAnchor),
            activityIconGlow.centerYAnchor.constraint(equalTo: activityIcon.centerYAnchor),
            activityIconGlow.widthAnchor.constraint(equalTo: activityIcon.widthAnchor, constant: 12),
            activityIconGlow.heightAnchor.constraint(equalTo: activityIcon.heightAnchor, constant: 12)
        ])
        
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
        contentView.addSubview(questIndicatorIcon)
        
        // Desired victim indicator - positioned at bottom of avatar with red glow
        let desiredX = avatarFrame.midX - iconSize/2
        let desiredY = avatarFrame.maxY - iconSize/2 + 4 // Перемещаем к нижнему краю
        desiredVictimIndicator.frame = CGRect(x: desiredX, y: desiredY, width: iconSize, height: iconSize)
        desiredVictimIndicator.contentMode = .scaleAspectFit
        desiredVictimIndicator.layer.shadowColor = UIColor.red.cgColor // Red shadow
        desiredVictimIndicator.layer.shadowRadius = 10 // Increased from 5 to 10
        desiredVictimIndicator.layer.shadowOpacity = 1.0 // Increased from 0.8 to 1.0
        desiredVictimIndicator.layer.shadowOffset = CGSize(width: 0, height: 0)
        desiredVictimIndicator.backgroundColor = UIColor.black.withAlphaComponent(0.3) // More transparent background
        desiredVictimIndicator.layer.cornerRadius = iconSize/2
        desiredVictimIndicator.clipsToBounds = false // Allow glow to extend beyond bounds
        contentView.addSubview(desiredVictimIndicator)
        
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
        
        // Показываем/скрываем иконки и процент здоровья в зависимости от того, известен ли NPC
        UIView.animate(withDuration: animationDuration) {
            self.professionIcon.alpha = npc.isUnknown ? 0.0 : 1.0
            self.activityIcon.alpha = npc.isUnknown ? 0.0 : 1.0
            self.healthPercentageLabel.alpha = npc.isUnknown ? 0.0 : 1.0
        }
        professionIcon.isHidden = npc.isUnknown
        activityIcon.isHidden = npc.isUnknown
        healthPercentageLabel.isHidden = npc.isUnknown
        
        // Убираем анимацию границ, так как cardBackground больше нет
        // Тень отключена
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
            self.avatarImageView.layer.borderWidth = 1
            self.avatarImageView.layer.borderColor = UIColor.black.cgColor
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        self.healthIndicator.opacity = 0.0 // Всегда скрыто
        
        // Убираем логику кольца здоровья
        CATransaction.commit()
        self.healthIndicator.setNeedsDisplay()
        self.healthIndicator.setNeedsLayout()
        if !npc.isUnknown {
            let healthValue = Int(npc.bloodMeter.currentBlood)
            
            // Use animated health value change with color transition
            if healthPercentageLabel.text != "\(healthValue)%" {
                animateHealthValueChange(to: healthValue, duration: animationDuration * 2)
            } else {
                // If value hasn't changed, just update color
                let healthColor = getHealthColor(for: Double(healthValue))
                let strokeAttributes: [NSAttributedString.Key: Any] = [
                    .strokeColor: healthColor,
                    .foregroundColor: healthColor,
                    .strokeWidth: -1.0,
                    .font: healthPercentageLabel.font as Any
                ]
                let attributedText = NSAttributedString(string: "\(healthValue)%", attributes: strokeAttributes)
                UIView.animate(withDuration: animationDuration) {
                    self.healthPercentageLabel.attributedText = attributedText
                }
            }
            
            healthPercentageLabel.isHidden = false
            healthPercentageLabel.alpha = 1.0
        } else {
            UIView.animate(withDuration: animationDuration) {
                self.healthPercentageLabel.alpha = 0.0
            }
        }
        self.healthPercentageLabel.setNeedsDisplay()
        self.healthPercentageLabel.setNeedsLayout()
        if !npc.isUnknown {
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 10) // Уменьшаем размер символов для меньших контейнеров
            let newProfessionImage = UIImage(systemName: npc.profession.icon, withConfiguration: iconConfig)
            let color = convertSwiftUIColorToUIColor(npc.profession.color)
            
            // Устанавливаем glow изображение для profession icon
            professionIconGlow.image = Self.makeRadialGlowImage(size: CGSize(width: iconSize + 12, height: iconSize + 12), color: color)
            
            UIView.transition(with: professionIcon,
                             duration: animationDuration,
                             options: .transitionCrossDissolve,
                             animations: {
                self.professionIcon.image = newProfessionImage
                self.professionIcon.tintColor = color
                self.professionIcon.contentMode = .center
            }, completion: nil)
            UIView.animate(withDuration: animationDuration) {
                self.professionIcon.alpha = 1.0
                self.professionIconGlow.alpha = 0.8
            }
            professionIcon.isHidden = false
        } else {
            UIView.animate(withDuration: animationDuration) {
                self.professionIcon.alpha = 0.0
                self.professionIconGlow.alpha = 0.0
            }
        }
        if !npc.isUnknown {
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 10) // Уменьшаем размер символов для меньших контейнеров
            let newActivityImage = UIImage(systemName: npc.currentActivity.icon, withConfiguration: iconConfig)
            let color = convertSwiftUIColorToUIColor(npc.currentActivity.color)
            
            // Устанавливаем glow изображение для activity icon
            activityIconGlow.image = Self.makeRadialGlowImage(size: CGSize(width: iconSize + 12, height: iconSize + 12), color: color)
            
            // Добавляем цветное свечение для иконки активности
            activityIcon.layer.shadowColor = color.cgColor
            activityIcon.layer.shadowRadius = 4
            activityIcon.layer.shadowOpacity = 0.6
            activityIcon.layer.shadowOffset = .zero
            
            UIView.transition(with: activityIcon,
                             duration: animationDuration,
                             options: .transitionCrossDissolve,
                             animations: {
                self.activityIcon.image = newActivityImage
                self.activityIcon.tintColor = color
                self.activityIcon.contentMode = .center
            }, completion: nil)
            UIView.animate(withDuration: animationDuration) {
                self.activityIcon.alpha = 1.0
                self.activityIconGlow.alpha = 0.8
            }
            
            // Убираем свечение рамки карточки, так как cardBackground больше нет
            
            activityIcon.isHidden = false
        } else {
            UIView.animate(withDuration: animationDuration) {
                self.activityIcon.alpha = 0.0
                self.activityIconGlow.alpha = 0.0
            }
            
            // Убираем свечение для неизвестных NPC, так как cardBackground больше нет
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
        // Убираем анимацию прозрачности cardBackground, так как его больше нет
        UIView.animate(withDuration: animationDuration) {
            self.contentView.alpha = npc.isAlive ? (isDisabled ? 0.8 : 1.0) : 0.8
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
        // --- Надёжно скрываем слой selectionGlowLayer ---
        self.selectionGlowLayer.isHidden = !isSelected
        
        // Принудительно обновляем layout чтобы healthPercentageLabel.bounds были правильными
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

    // MARK: - Новый метод для Player
    func configure(with player: Player, isDisabled: Bool) {
        // Всегда ведём себя как isSelected = true
        let animationDuration: TimeInterval = 0.2
        // --- Убираем glow и фон, так как cardBackground больше нет ---
        // --- Тень отключена ---
        
        // --- Аватар ---
        let newImage = UIImage(named: "player1") ?? UIImage(named: "defaultMalePlaceholder")
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
        // --- Индикатор здоровья убран ---
        // --- Профессия скрыта ---
        professionIcon.isHidden = true
        // --- Активность: всегда "drop" красного цвета ---
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 10) // Уменьшаем размер символов для меньших контейнеров
        let dropImage = UIImage(systemName: "drop", withConfiguration: iconConfig)
        
        // Устанавливаем glow изображение для activity icon
        activityIconGlow.image = Self.makeRadialGlowImage(size: CGSize(width: iconSize + 12, height: iconSize + 12), color: UIColor.systemRed)
        
        // Добавляем красное свечение для иконки активности игрока
        activityIcon.layer.shadowColor = UIColor.systemRed.cgColor
        activityIcon.layer.shadowRadius = 4
        activityIcon.layer.shadowOpacity = 0.6
        activityIcon.layer.shadowOffset = .zero
        
        UIView.transition(with: activityIcon,
                         duration: animationDuration,
                         options: .transitionCrossDissolve,
                         animations: {
            self.activityIcon.image = dropImage
            self.activityIcon.tintColor = UIColor.systemRed
            self.activityIcon.contentMode = .center
        }, completion: nil)
        UIView.animate(withDuration: animationDuration) {
            self.activityIcon.alpha = 1.0
            self.activityIconGlow.alpha = 0.8
        }
        
        // Убираем свечение рамки карточки для игрока, так как cardBackground больше нет
        
        activityIcon.isHidden = false
        // --- Здоровье ---
        let healthValue = Int(player.bloodMeter.currentBlood)
        
        // Use animated health value change with color transition for player
        if healthPercentageLabel.text != "\(healthValue)%" {
            animateHealthValueChange(to: healthValue, duration: animationDuration * 2)
        } else {
            // If value hasn't changed, just update color
            let healthColor = getHealthColor(for: Double(healthValue))
            let strokeAttributes: [NSAttributedString.Key: Any] = [
                .strokeColor: healthColor,
                .foregroundColor: healthColor,
                .strokeWidth: -1.0,
                .font: healthPercentageLabel.font as Any
            ]
            let attributedText = NSAttributedString(string: "\(healthValue)%", attributes: strokeAttributes)
            UIView.animate(withDuration: animationDuration) {
                self.healthPercentageLabel.attributedText = attributedText
            }
        }
        
        healthPercentageLabel.isHidden = false
        healthPercentageLabel.alpha = 1.0
        // --- Индикаторы жертвы и квеста скрыты ---
        desiredVictimIndicator.isHidden = true
        questIndicatorIcon.isHidden = true
        // --- Анимация прозрачности contentView ---
        UIView.animate(withDuration: animationDuration) {
            self.contentView.alpha = player.isAlive ? (isDisabled ? 0.5 : 1.0) : 0.4
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
        let newAvatarSizeLayout: CGFloat = bounds.width // Аватар занимает весь размер ячейки
        let newAvatarRadiusLayout: CGFloat = 12 // Сохраняем радиус закругления
        let avatarFrameLayout = CGRect(x: 0, y: 0, width: newAvatarSizeLayout, height: newAvatarSizeLayout)
        avatarImageView.frame = avatarFrameLayout
        avatarImageView.layer.cornerRadius = newAvatarRadiusLayout
        avatarShadowContainer.frame = avatarFrameLayout
        avatarShadowContainer.layer.cornerRadius = newAvatarRadiusLayout
        avatarShadowContainer.layer.shadowPath = UIBezierPath(roundedRect: avatarShadowContainer.bounds, cornerRadius: newAvatarRadiusLayout).cgPath
        
        // Позиционируем иконки в углах аватара
        professionIcon.frame = CGRect(x: avatarFrameLayout.minX + 4, y: avatarFrameLayout.minY + 4, width: iconSize, height: iconSize)
        activityIcon.frame = CGRect(x: avatarFrameLayout.maxX - iconSize - 4, y: avatarFrameLayout.minY + 4, width: iconSize, height: iconSize)
        
        // Позиционируем процент здоровья в центре нижней части кольца
        let healthLabelWidth: CGFloat = 50
        let healthLabelHeight: CGFloat = 20
        healthPercentageLabel.frame = CGRect(
            x: avatarFrameLayout.midX - healthLabelWidth / 2,
            y: avatarFrameLayout.maxY - healthLabelHeight - 8,
            width: healthLabelWidth,
            height: healthLabelHeight
        )
        
        selectionGlowLayer.frame = avatarFrameLayout
        selectionGlowLayer.cornerRadius = newAvatarRadiusLayout
        self.selectionGlowLayer.isHidden = self.selectionGlowLayer.shadowOpacity == 0
        
        let healthIndicatorSize = avatarFrameLayout.width + 6
        let healthIndicatorX = avatarFrameLayout.midX - healthIndicatorSize/2
        let healthIndicatorY = avatarFrameLayout.midY - healthIndicatorSize/2
        healthIndicator.frame = CGRect(x: healthIndicatorX, y: healthIndicatorY, width: healthIndicatorSize, height: healthIndicatorSize)
        healthIndicator.opacity = 0 // Всегда скрыто
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Проверка попадания в квадратный аватар с закругленными углами
        let avatarFrame = avatarImageView.frame
        if avatarFrame.contains(point) {
            return self
        }
        // Проверка попадания в иконки в углах аватара
        if professionIcon.frame.contains(point) || activityIcon.frame.contains(point) {
            return self
        }
        // Проверка попадания в процент здоровья
        if healthPercentageLabel.frame.contains(point) {
            return self
        }
        // Всё остальное — не кликабельно
        return nil
    }

    private func getHealthColor(for healthPercentage: Double) -> UIColor {
        // Interpolate between white and red based on health percentage
        // 100% = white, 0% = red
        let normalizedHealth = max(0.0, min(1.0, healthPercentage / 100.0))
        
        // White (1,1,1) to Red (1,0,0)
        let red: CGFloat = 1.0
        let green: CGFloat = normalizedHealth
        let blue: CGFloat = normalizedHealth
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    private func animateHealthValueChange(to newValue: Int, duration: TimeInterval = 0.3) {
        guard let currentText = healthPercentageLabel.text else {
            // If we can't get current text, just set the new value directly
            let healthText = "\(newValue)%"
            healthPercentageLabel.text = healthText
            let healthColor = getHealthColor(for: Double(newValue))
            let strokeAttributes: [NSAttributedString.Key: Any] = [
                .strokeColor: healthColor,
                .foregroundColor: healthColor,
                .strokeWidth: -1.0,
                .font: healthPercentageLabel.font as Any
            ]
            healthPercentageLabel.attributedText = NSAttributedString(string: healthText, attributes: strokeAttributes)
            return
        }
        
        let currentValueString = currentText.replacingOccurrences(of: "%", with: "")
        guard let currentValue = Int(currentValueString) else {
            // If we can't parse current value, just set the new value directly
            let healthText = "\(newValue)%"
            healthPercentageLabel.text = healthText
            let healthColor = getHealthColor(for: Double(newValue))
            let strokeAttributes: [NSAttributedString.Key: Any] = [
                .strokeColor: healthColor,
                .foregroundColor: healthColor,
                .strokeWidth: -1.0,
                .font: healthPercentageLabel.font as Any
            ]
            healthPercentageLabel.attributedText = NSAttributedString(string: healthText, attributes: strokeAttributes)
            return
        }
        
        // Animate from current value to new value
        let valueDifference = newValue - currentValue
        let steps = max(1, abs(valueDifference))
        let stepDuration = duration / Double(steps)
        
        for i in 1...steps {
            let delay = stepDuration * Double(i - 1)
            let intermediateValue = currentValue + (valueDifference * i / steps)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let healthText = "\(intermediateValue)%"
                let healthColor = self.getHealthColor(for: Double(intermediateValue))
                
                let strokeAttributes: [NSAttributedString.Key: Any] = [
                    .strokeColor: healthColor,
                    .foregroundColor: healthColor,
                    .strokeWidth: -1.0,
                    .font: self.healthPercentageLabel.font as Any
                ]
                
                UIView.transition(with: self.healthPercentageLabel,
                                 duration: stepDuration * 0.8,
                                 options: .transitionCrossDissolve,
                                 animations: {
                    self.healthPercentageLabel.text = healthText
                    self.healthPercentageLabel.attributedText = NSAttributedString(string: healthText, attributes: strokeAttributes)
                }, completion: nil)
            }
        }
    }
    
    // Генерация radial alpha glow для иконок
    private static func makeRadialGlowImage(size: CGSize, color: UIColor) -> UIImage? {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        let colors = [color.withAlphaComponent(0.4).cgColor, color.withAlphaComponent(0.0).cgColor] as CFArray
        let center = CGPoint(x: size.width/2, y: size.height/2)
        let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0,1])
        ctx.drawRadialGradient(grad!, startCenter: center, startRadius: 0, endCenter: center, endRadius: size.width/2, options: .drawsAfterEndLocation)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img?.withRenderingMode(.alwaysOriginal)
    }
} 
