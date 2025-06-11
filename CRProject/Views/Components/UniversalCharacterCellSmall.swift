import UIKit
import SwiftUI
import CoreMotion
import Combine

class UniversalCharacterCellSmall: UIView {
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
    private let desiredVictimIconContainer = UIView() // Новый контейнер для иконки жертвы
    private let desiredVictimGlow = UIImageView() // Glow для иконки жертвы
    
    // Store reference to current NPC for debugging
    var currentNPC: NPC?
    
    private let iconSize: CGFloat = 14 // Half of original 28
    
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
        // Card background with transparent background and subtle border
        cardBackground.frame = bounds // Use full bounds
        cardBackground.backgroundColor = UIColor.clear
        cardBackground.layer.cornerRadius = 6 // Half of original 12
        cardBackground.layer.borderWidth = 0 // Remove border
        cardBackground.clipsToBounds = false // Ensure shadow isn't clipped by card background
        cardBackground.layer.masksToBounds = false // Explicitly set masksToBounds to false
        addSubview(cardBackground)
        
        // Avatar setup - максимально заполняем рамку мини-виджета
        let newAvatarSize: CGFloat = bounds.width - 2 // Минимальный отступ 1px с каждой стороны
        let newAvatarRadius: CGFloat = 8 // Пропорционально меньший радиус для мини-виджета
        let avatarFrame = CGRect(x: (bounds.width - newAvatarSize) / 2, y: 1, width: newAvatarSize, height: newAvatarSize)
        
        // Setup shadow container
        avatarShadowContainer.frame = avatarFrame
        avatarShadowContainer.layer.cornerRadius = newAvatarRadius
        avatarShadowContainer.layer.shadowColor = UIColor.black.cgColor
        avatarShadowContainer.layer.shadowRadius = 9 // Half of original 18
        avatarShadowContainer.layer.shadowOpacity = 0.85
        avatarShadowContainer.layer.shadowOffset = CGSize(width: 0, height: 4) // Half of original (0,8)
        avatarShadowContainer.backgroundColor = .clear
        avatarShadowContainer.layer.shadowPath = UIBezierPath(roundedRect: avatarShadowContainer.bounds, cornerRadius: newAvatarRadius).cgPath // Квадратная форма с закругленными углами
        cardBackground.addSubview(avatarShadowContainer)

        // Setup avatar image view
        avatarImageView.frame = avatarFrame
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = newAvatarRadius
        avatarImageView.layer.borderWidth = 0.5 // Half of original 1
        avatarImageView.layer.borderColor = UIColor.black.cgColor
        cardBackground.addSubview(avatarImageView)
        
        // Selection glow
        selectionGlowLayer.frame = avatarFrame
        selectionGlowLayer.cornerRadius = newAvatarRadius
        selectionGlowLayer.shadowColor = UIColor.red.cgColor
        selectionGlowLayer.shadowRadius = 4 // Half of original 8
        selectionGlowLayer.shadowOpacity = 0 // Hidden by default
        selectionGlowLayer.shadowOffset = .zero
        cardBackground.layer.insertSublayer(selectionGlowLayer, below: avatarImageView.layer)
        
        // Health indicator - красная полоса здоровья вокруг аватара (тонкая версия для мини виджета)
        let healthIndicatorSize = avatarFrame.width + 3 // Half of original +6
        let healthIndicatorX = avatarFrame.midX - healthIndicatorSize/2
        let healthIndicatorY = avatarFrame.midY - healthIndicatorSize/2
        healthIndicator.frame = CGRect(x: healthIndicatorX, y: healthIndicatorY, width: healthIndicatorSize, height: healthIndicatorSize)
        healthIndicator.lineWidth = 2 // Тоньше чем в большом виджете (было 3)
        healthIndicator.fillColor = UIColor.clear.cgColor
        healthIndicator.strokeColor = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1).cgColor
        healthIndicator.lineCap = .round
        healthIndicator.opacity = 0 // Скрыто по умолчанию, показывается при configure
        
        // Добавляем эффект свечения для индикатора здоровья (уменьшенный)
        healthIndicator.shadowColor = UIColor.red.cgColor
        healthIndicator.shadowRadius = 2 // Меньше чем в большом виджете (было 4)
        healthIndicator.shadowOpacity = 0.6 // Меньше чем в большом виджете (было 0.8)
        healthIndicator.shadowOffset = CGSize.zero
        
        cardBackground.layer.addSublayer(healthIndicator)
        
        // Health percentage теперь в центре нижней части (без кольца)
        // Стилизация лейбла - используем оригинальные размеры
        healthPercentageLabel.font = UIFont(name: "Optima", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .bold) // Оригинальный размер
        healthPercentageLabel.textColor = UIColor.white
        healthPercentageLabel.textAlignment = .center
        healthPercentageLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        healthPercentageLabel.layer.cornerRadius = 8 // Оригинальный размер
        healthPercentageLabel.clipsToBounds = true
        healthPercentageLabel.layer.shadowColor = UIColor.black.cgColor
        healthPercentageLabel.layer.shadowRadius = 3 // Оригинальный размер
        healthPercentageLabel.layer.shadowOpacity = 1
        healthPercentageLabel.layer.shadowOffset = CGSize(width: 0, height: 1) // Оригинальный размер
        
        // Позиционируем процент здоровья в центре нижней части - используем оригинальные размеры
        let healthLabelWidth: CGFloat = 50 // Оригинальный размер
        let healthLabelHeight: CGFloat = 20 // Оригинальный размер
        healthPercentageLabel.frame = CGRect(
            x: avatarFrame.midX - healthLabelWidth / 2,
            y: avatarFrame.maxY - healthLabelHeight - 8, // Оригинальный отступ
            width: healthLabelWidth,
            height: healthLabelHeight
        )
        cardBackground.addSubview(healthPercentageLabel)
        
        // Profession icon - скрываем в мини версии
        professionIcon.frame = CGRect(x: avatarFrame.minX + 2, y: avatarFrame.minY + 2, width: iconSize, height: iconSize)
        professionIcon.contentMode = .scaleAspectFit
        professionIcon.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        professionIcon.clipsToBounds = true
        professionIcon.layer.cornerRadius = iconSize / 2
        professionIcon.layer.borderWidth = 0
        professionIcon.layer.shadowColor = UIColor.black.cgColor
        professionIcon.layer.shadowRadius = 1.5
        professionIcon.layer.shadowOpacity = 0.8
        professionIcon.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        professionIcon.alpha = 0.0 // Скрываем
        professionIcon.isHidden = true // Полностью скрываем
        cardBackground.addSubview(professionIcon)
        
        // Activity icon - скрываем в мини версии
        activityIcon.frame = CGRect(x: avatarFrame.maxX - iconSize - 2, y: avatarFrame.minY + 2, width: iconSize, height: iconSize)
        activityIcon.contentMode = .scaleAspectFit
        activityIcon.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        activityIcon.clipsToBounds = true
        activityIcon.layer.cornerRadius = iconSize / 2
        activityIcon.layer.borderWidth = 0
        activityIcon.layer.shadowColor = UIColor.black.cgColor
        activityIcon.layer.shadowRadius = 1.5
        activityIcon.layer.shadowOpacity = 0.8
        activityIcon.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        activityIcon.alpha = 0.0 // Скрываем
        activityIcon.isHidden = true // Полностью скрываем
        cardBackground.addSubview(activityIcon)
        
        // Quest Indicator Icon
        let questIconCenterX = avatarFrame.midX
        let questIconY = healthIndicator.frame.maxY - iconSize + 2 // Half of original +4

        questIndicatorIcon.frame = CGRect(x: questIconCenterX - iconSize / 2, y: questIconY, width: iconSize, height: iconSize)
        questIndicatorIcon.contentMode = .scaleAspectFit
        questIndicatorIcon.clipsToBounds = false 
        questIndicatorIcon.layer.cornerRadius = iconSize / 2
        questIndicatorIcon.layer.borderWidth = 0.25 // Half of original 0.5
        questIndicatorIcon.layer.shadowRadius = 3 // Half of original 6
        questIndicatorIcon.layer.shadowOpacity = 0
        questIndicatorIcon.isHidden = true 
        cardBackground.addSubview(questIndicatorIcon)
        
        // Desired victim icon - делаем как professionIcon, только меньше
        let desiredX = avatarFrame.minX + 2
        let desiredY = avatarFrame.maxY - iconSize - 2
        desiredVictimIconContainer.frame = CGRect(x: desiredX, y: desiredY, width: iconSize, height: iconSize)
        desiredVictimIconContainer.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        desiredVictimIconContainer.layer.cornerRadius = iconSize/2
        desiredVictimIconContainer.clipsToBounds = true
        desiredVictimIconContainer.layer.borderWidth = 0
        desiredVictimIconContainer.layer.shadowColor = UIColor.black.cgColor
        desiredVictimIconContainer.layer.shadowRadius = 1
        desiredVictimIconContainer.layer.shadowOpacity = 0.5
        desiredVictimIconContainer.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        desiredVictimIconContainer.alpha = 1.0
        // Glow
        desiredVictimGlow.contentMode = .scaleAspectFill
        desiredVictimGlow.alpha = 0.8
        desiredVictimGlow.isUserInteractionEnabled = false
        desiredVictimGlow.frame = CGRect(x: -3, y: -3, width: iconSize + 6, height: iconSize + 6)
        desiredVictimIconContainer.addSubview(desiredVictimGlow)
        desiredVictimIconContainer.sendSubviewToBack(desiredVictimGlow)
        // SF Symbol
        desiredVictimIndicator.frame = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
        desiredVictimIndicator.contentMode = .center
        desiredVictimIndicator.backgroundColor = .clear
        desiredVictimIndicator.layer.cornerRadius = iconSize/2
        desiredVictimIndicator.clipsToBounds = true
        desiredVictimIconContainer.addSubview(desiredVictimIndicator)
        cardBackground.addSubview(desiredVictimIconContainer)
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
            avatarShadowContainer.layer.shadowOpacity = 0.8
        }
        let newImage = npc.isUnknown && !npc.isMob ?
            UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder") :
            UIImage(named: "npc\(npc.isMob ? npc.mobType.name : npc.id.description)") ?? UIImage(named: npc.sex == .male ? "defaultMalePlaceholder" : "defaultFemalePlaceholder")
        if avatarImageView.image != newImage {
            UIView.transition(with: avatarImageView,
                             duration: animationDuration,
                             options: .transitionCrossDissolve,
                             animations: {
                self.avatarImageView.image = newImage
            }, completion: nil)
        }
        UIView.animate(withDuration: animationDuration) {
            self.avatarImageView.layer.borderWidth = 0.5 // Half of original 1
            self.avatarImageView.layer.borderColor = UIColor.black.cgColor
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        // Всегда скрываем индикатор здоровья
        self.healthIndicator.opacity = 0.0
        self.healthIndicator.shadowOpacity = 0.0
        CATransaction.commit()
        self.healthIndicator.setNeedsDisplay()
        self.healthIndicator.setNeedsLayout()
        // Profession icon всегда скрыт в мини версии
        professionIcon.isHidden = true
        professionIcon.alpha = 0.0
        // Activity icon всегда скрыт в мини версии
        activityIcon.isHidden = true
        activityIcon.alpha = 0.0
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
        if !npc.isUnknown, let player = GameStateService.shared.getPlayer(),
           player.desiredVictim.isDesiredVictim(npc: npc) {
            UIView.animate(withDuration: animationDuration) {
                self.desiredVictimIconContainer.alpha = 1.0
                self.desiredVictimIconContainer.isHidden = false
            }
            UIView.transition(with: desiredVictimIndicator,
                             duration: animationDuration,
                             options: .transitionCrossDissolve,
                             animations: {
                let heartConfig = UIImage.SymbolConfiguration(pointSize: 6, weight: .bold)
                let heartImage = UIImage(systemName: "arrow.up.heart.fill", withConfiguration: heartConfig)
                self.desiredVictimIndicator.image = heartImage
                self.desiredVictimIndicator.tintColor = UIColor.systemRed
            }, completion: nil)
            // Glow
            self.desiredVictimGlow.image = Self.makeRadialGlowImage(size: CGSize(width: self.iconSize + 6, height: self.iconSize + 6), color: UIColor.systemRed)
        } else {
            UIView.animate(withDuration: animationDuration) {
                self.desiredVictimIconContainer.alpha = 0.0
            } completion: { _ in
                self.desiredVictimIconContainer.isHidden = true
            }
        }
        UIView.animate(withDuration: animationDuration) {
            self.cardBackground.alpha = npc.isAlive ? (isDisabled ? 0.8 : 1.0) : 0.8
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
        // --- Яркая черная тень вокруг аватара ---
        self.avatarShadowContainer.layer.shadowColor = UIColor.black.cgColor
        self.avatarShadowContainer.layer.shadowRadius = 9 // Half of original 18
        self.avatarShadowContainer.layer.shadowOpacity = 0.85
        self.avatarShadowContainer.layer.shadowOffset = CGSize(width: 0, height: 4) // Half of original (0,8)
        
        // --- Аватар ---
        avatarShadowContainer.layer.shadowOpacity = 0.8
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
            self.avatarImageView.layer.borderWidth = 0.5 // Half of original 1
            self.avatarImageView.layer.borderColor = UIColor.black.cgColor
        }
        // --- Индикатор здоровья ---
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        // Всегда скрываем индикатор здоровья
        healthIndicator.opacity = 0.0
        healthIndicator.shadowOpacity = 0.0
        CATransaction.commit()
        self.healthIndicator.setNeedsDisplay()
        self.healthIndicator.setNeedsLayout()
        // --- Профессия и активность скрыты в мини версии ---
        professionIcon.isHidden = true
        professionIcon.alpha = 0.0
        activityIcon.isHidden = true
        activityIcon.alpha = 0.0
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
        desiredVictimIconContainer.isHidden = true
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

    override func layoutSubviews() {
        super.layoutSubviews()
        cardBackground.frame = bounds
        let newAvatarSizeLayout: CGFloat = bounds.width - 2 // Минимальный отступ 1px с каждой стороны
        let newAvatarRadiusLayout: CGFloat = 8 // Пропорционально меньший радиус для мини-виджета
        let avatarFrameLayout = CGRect(x: (bounds.width - newAvatarSizeLayout) / 2, y: 1, width: newAvatarSizeLayout, height: newAvatarSizeLayout)
        avatarImageView.frame = avatarFrameLayout
        avatarImageView.layer.cornerRadius = newAvatarRadiusLayout
        avatarShadowContainer.frame = avatarFrameLayout
        avatarShadowContainer.layer.cornerRadius = newAvatarRadiusLayout
        avatarShadowContainer.layer.shadowPath = UIBezierPath(roundedRect: avatarShadowContainer.bounds, cornerRadius: newAvatarRadiusLayout).cgPath
        
        // Позиционируем иконки в углах аватара
        professionIcon.frame = CGRect(x: avatarFrameLayout.minX + 2, y: avatarFrameLayout.minY + 2, width: iconSize, height: iconSize) // Half of original +4
        professionIcon.layer.cornerRadius = iconSize / 2
        activityIcon.frame = CGRect(x: avatarFrameLayout.maxX - iconSize - 2, y: avatarFrameLayout.minY + 2, width: iconSize, height: iconSize) // Half of original -4, +4
        activityIcon.layer.cornerRadius = iconSize / 2
        
        // Позиционируем процент здоровья в центре нижней части - используем оригинальные размеры
        let healthLabelWidth: CGFloat = 50 // Оригинальный размер
        let healthLabelHeight: CGFloat = 20 // Оригинальный размер
        healthPercentageLabel.frame = CGRect(
            x: avatarFrameLayout.midX - healthLabelWidth / 2,
            y: avatarFrameLayout.maxY - healthLabelHeight - 8, // Оригинальный отступ
            width: healthLabelWidth,
            height: healthLabelHeight
        )
        
        let healthIndicatorSize = avatarFrameLayout.width + 3 // Half of original +6
        let healthIndicatorX = avatarFrameLayout.midX - healthIndicatorSize/2
        let healthIndicatorY = avatarFrameLayout.midY - healthIndicatorSize/2
        healthIndicator.frame = CGRect(x: healthIndicatorX, y: healthIndicatorY, width: healthIndicatorSize, height: healthIndicatorSize)
        selectionGlowLayer.frame = avatarFrameLayout
        selectionGlowLayer.cornerRadius = newAvatarRadiusLayout
        
        // Обновляем позицию и размер desiredVictimIconContainer и его subviews
        let desiredX = avatarFrameLayout.minX + 2
        let desiredY = avatarFrameLayout.maxY - iconSize - 2
        desiredVictimIconContainer.frame = CGRect(x: desiredX, y: desiredY, width: iconSize, height: iconSize)
        desiredVictimGlow.frame = CGRect(x: -3, y: -3, width: iconSize + 6, height: iconSize + 6)
        desiredVictimIndicator.frame = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
        
        // Индикатор здоровья всегда скрыт
        
        self.healthIndicator.isHidden = self.healthIndicator.opacity == 0.0
        self.selectionGlowLayer.isHidden = self.selectionGlowLayer.shadowOpacity == 0
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Проверка попадания в квадратный аватар с закругленными углами
        let avatarFrame = avatarImageView.frame
        if avatarFrame.contains(point) {
            return self
        }
        // Проверка попадания в проценты
        if healthPercentageLabel.frame.contains(point) {
            return self
        }
        // Проверка попадания в иконку профессии
        if professionIcon.frame.contains(point) {
            return self
        }
        // Проверка попадания в иконку активности
        if activityIcon.frame.contains(point) {
            return self
        }
        // Всё остальное — не кликабельно
        return nil
    }

    private static func makeRadialGlowImage(size: CGSize, color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        let rect = CGRect(origin: .zero, size: size)
        context.setFillColor(color.cgColor)
        context.setBlendMode(.sourceIn)
        context.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
} 
