import UIKit

class CombatParticipantCell: UICollectionViewCell {
    private let avatarImageView = UIImageView()
    private let avatarShadowContainer = UIView()
    private let professionIcon = UIImageView()
    private let combatIcon = UIImageView() // Вместо activityIcon
    let healthIndicator = CAShapeLayer()
    private let healthPercentageLabel = UILabel()
    private let selectionGlowLayer = CALayer()
    private let cardBackground = UIView()
    private let nameLabel = UILabel()
    
    private let iconSize: CGFloat = 22
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        cardBackground.frame = bounds
        cardBackground.backgroundColor = UIColor.clear
        cardBackground.layer.cornerRadius = 12
        cardBackground.layer.borderWidth = 0
        cardBackground.clipsToBounds = false
        cardBackground.layer.masksToBounds = false
        contentView.addSubview(cardBackground)
        
        let newAvatarSize: CGFloat = 84
        let newAvatarRadius: CGFloat = newAvatarSize / 2
        let avatarFrame = CGRect(x: (bounds.width - newAvatarSize) / 2, y: 8, width: newAvatarSize, height: newAvatarSize)
        
        avatarShadowContainer.frame = avatarFrame
        avatarShadowContainer.layer.cornerRadius = newAvatarRadius
        avatarShadowContainer.layer.shadowColor = UIColor.black.cgColor
        avatarShadowContainer.layer.shadowRadius = 10
        avatarShadowContainer.layer.shadowOpacity = 0.8
        avatarShadowContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        avatarShadowContainer.backgroundColor = .clear
        avatarShadowContainer.layer.shadowPath = UIBezierPath(roundedRect: avatarShadowContainer.bounds, cornerRadius: avatarShadowContainer.layer.cornerRadius).cgPath
        cardBackground.addSubview(avatarShadowContainer)
        
        avatarImageView.frame = avatarFrame
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = newAvatarRadius
        avatarImageView.layer.borderWidth = 1
        avatarImageView.layer.borderColor = UIColor.black.cgColor
        cardBackground.addSubview(avatarImageView)
        
        selectionGlowLayer.frame = avatarFrame
        selectionGlowLayer.cornerRadius = newAvatarRadius
        selectionGlowLayer.shadowColor = UIColor.red.cgColor
        selectionGlowLayer.shadowRadius = 8
        selectionGlowLayer.shadowOpacity = 0
        selectionGlowLayer.shadowOffset = .zero
        cardBackground.layer.insertSublayer(selectionGlowLayer, below: avatarImageView.layer)
        
        let healthIndicatorSize = avatarFrame.width + 6
        let healthIndicatorX = avatarFrame.midX - healthIndicatorSize/2
        let healthIndicatorY = avatarFrame.midY - healthIndicatorSize/2
        healthIndicator.frame = CGRect(x: healthIndicatorX, y: healthIndicatorY, width: healthIndicatorSize, height: healthIndicatorSize)
        healthIndicator.lineWidth = 3
        healthIndicator.fillColor = UIColor.clear.cgColor
        healthIndicator.strokeColor = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1).cgColor
        healthIndicator.lineCap = .round
        healthIndicator.opacity = 0
        healthIndicator.shadowColor = UIColor.red.cgColor
        healthIndicator.shadowRadius = 4
        healthIndicator.shadowOpacity = 0.8
        healthIndicator.shadowOffset = CGSize.zero
        cardBackground.layer.addSublayer(healthIndicator)
        
        let textFont = UIFont(name: "Optima", size: 11) ?? UIFont.systemFont(ofSize: 11, weight: .regular)
        
        let healthWidth: CGFloat = 40
        let healthHeight: CGFloat = 18
        let healthX = avatarFrame.midX - healthWidth/2
        let healthY = avatarFrame.maxY
        healthPercentageLabel.frame = CGRect(x: healthX, y: healthY, width: healthWidth, height: healthHeight)
        healthPercentageLabel.font = textFont
        healthPercentageLabel.textColor = UIColor.white
        healthPercentageLabel.textAlignment = .center
        healthPercentageLabel.backgroundColor = UIColor.clear
        healthPercentageLabel.clipsToBounds = false
        healthPercentageLabel.layer.shadowColor = UIColor.black.cgColor
        healthPercentageLabel.layer.shadowRadius = 2
        healthPercentageLabel.layer.shadowOpacity = 1
        healthPercentageLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        cardBackground.addSubview(healthPercentageLabel)
        
        // Profession icon (слева)
        let avatarRadius = avatarFrame.width / 2
        let profX = avatarFrame.minX - 10
        let profY = avatarFrame.maxY - iconSize - 8
        professionIcon.frame = CGRect(x: profX, y: profY, width: iconSize, height: iconSize)
        professionIcon.contentMode = .scaleAspectFit
        professionIcon.backgroundColor = UIColor.clear
        professionIcon.clipsToBounds = false
        professionIcon.layer.shadowColor = UIColor.black.cgColor
        professionIcon.layer.shadowRadius = 2
        professionIcon.layer.shadowOpacity = 1
        professionIcon.layer.shadowOffset = CGSize(width: 0, height: 1)
        professionIcon.layer.cornerRadius = iconSize / 2
        professionIcon.layer.borderWidth = 0.5
        professionIcon.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        professionIcon.layer.backgroundColor = UIColor.black.withAlphaComponent(0.7).cgColor
        professionIcon.alpha = 1.0
        professionIcon.layer.shadowColor = UIColor.black.cgColor
        professionIcon.layer.shadowRadius = 3
        professionIcon.layer.shadowOpacity = 0.6
        professionIcon.layer.shadowOffset = CGSize.zero
        cardBackground.addSubview(professionIcon)
        
        // Combat icon (справа)
        let combatX = avatarFrame.maxX - iconSize + 10
        let combatY = avatarFrame.maxY - iconSize - 8
        combatIcon.frame = CGRect(x: combatX, y: combatY, width: iconSize, height: iconSize)
        combatIcon.contentMode = .scaleAspectFit
        combatIcon.backgroundColor = UIColor.clear
        combatIcon.clipsToBounds = false
        combatIcon.layer.shadowColor = UIColor.black.cgColor
        combatIcon.layer.shadowRadius = 2
        combatIcon.layer.shadowOpacity = 1
        combatIcon.layer.shadowOffset = CGSize(width: 0, height: 1)
        combatIcon.layer.cornerRadius = iconSize / 2
        combatIcon.layer.borderWidth = 0.5
        combatIcon.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        combatIcon.layer.backgroundColor = UIColor.black.withAlphaComponent(0.7).cgColor
        combatIcon.alpha = 1.0
        combatIcon.layer.shadowColor = UIColor.black.cgColor
        combatIcon.layer.shadowRadius = 3
        combatIcon.layer.shadowOpacity = 0.6
        combatIcon.layer.shadowOffset = CGSize.zero
        cardBackground.addSubview(combatIcon)
        
        // Name label (под аватаром)
        nameLabel.frame = CGRect(x: 0, y: avatarFrame.maxY + 22, width: bounds.width, height: 18)
        nameLabel.font = UIFont(name: "Optima-Bold", size: 13) ?? UIFont.boldSystemFont(ofSize: 13)
        nameLabel.textColor = UIColor.white
        nameLabel.textAlignment = .center
        nameLabel.backgroundColor = UIColor.clear
        nameLabel.layer.shadowColor = UIColor.black.cgColor
        nameLabel.layer.shadowRadius = 2
        nameLabel.layer.shadowOpacity = 1
        nameLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        cardBackground.addSubview(nameLabel)
    }
    
    func configure(with participant: CombatParticipant, isSelected: Bool, isDisabled: Bool) {
        // Card background selection
        let animationDuration: TimeInterval = 0.2
        UIView.animate(withDuration: animationDuration) {
            self.cardBackground.layer.borderColor = UIColor.clear.cgColor
            self.cardBackground.layer.borderWidth = 0
        }
        avatarShadowContainer.layer.shadowOpacity = isSelected ? 0.8 : 0.8
        // Аватар
        let imageName: String
        if participant.isPlayer {
            imageName = "player1" // Используйте имя ассета для игрока
        } else {
            imageName = "npc\(participant.id)"
        }
        let newImage = UIImage(named: imageName) ?? UIImage(named: "defaultMalePlaceholder")
        if avatarImageView.image != newImage {
            UIView.transition(with: avatarImageView, duration: animationDuration, options: .transitionCrossDissolve, animations: {
                self.avatarImageView.image = newImage
            }, completion: nil)
        }
        // Glow
        UIView.animate(withDuration: animationDuration) {
            self.avatarImageView.layer.borderWidth = isSelected ? 0 : 1
            self.avatarImageView.layer.borderColor = UIColor.black.cgColor
        }
        // Health indicator
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        healthIndicator.opacity = isSelected ? 1.0 : 0.0
        healthIndicator.shadowOpacity = isSelected ? 0.8 : 0.0
        // Индикатор здоровья
        let center = CGPoint(x: healthIndicator.bounds.midX, y: healthIndicator.bounds.midY)
        let radius = healthIndicator.bounds.width / 2 - 2
        let startAngle = -CGFloat.pi / 2
        let percent = max(0, min(1, CGFloat(participant.health) / 100.0))
        let endAngle = startAngle + 2 * .pi * percent
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        healthIndicator.path = path.cgPath
        CATransaction.commit()
        // Profession icon
        let profIcon = UIImage(systemName: "person.fill") // Можно заменить на профессию, если есть
        professionIcon.image = profIcon
        professionIcon.tintColor = UIColor.systemGray
        // Combat icon (меч или щит)
        let combatIconName = participant.isPlayer ? "shield.fill" : "sword"
        let combatIconImage = UIImage(systemName: combatIconName)
        combatIcon.image = combatIconImage
        combatIcon.tintColor = participant.isPlayer ? UIColor.systemBlue : UIColor.systemRed
        // Имя
        nameLabel.text = participant.name
        // Health %
        let healthValue = Int(participant.health)
        let healthText = "\(healthValue)%"
        if healthPercentageLabel.text != healthText {
            UIView.transition(with: healthPercentageLabel, duration: animationDuration, options: .transitionCrossDissolve, animations: {
                self.healthPercentageLabel.text = healthText
            }, completion: nil)
        }
        healthPercentageLabel.isHidden = false
        UIView.animate(withDuration: animationDuration) {
            if participant.health < 30 {
                self.healthPercentageLabel.textColor = UIColor.red
            } else if participant.health < 60 {
                self.healthPercentageLabel.textColor = UIColor.orange
            } else {
                self.healthPercentageLabel.textColor = UIColor.white
            }
        }
        // Disabled state
        UIView.animate(withDuration: animationDuration) {
            self.cardBackground.alpha = isDisabled ? 0.5 : 1.0
        }
        // Selection glow
        UIView.animate(withDuration: animationDuration) {
            self.selectionGlowLayer.shadowOpacity = isSelected ? 0.7 : 0
        }
    }
} 
