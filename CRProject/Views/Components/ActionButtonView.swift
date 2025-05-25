import UIKit
import Foundation

class ActionButtonView: UIButton {
    private var onTap: (() -> Void)?
    private let iconImageView = UIImageView()
    private let actionTitleLabel = UILabel()
    private let successLabel = UILabel()
    private let failLabel = UILabel()
    private let topRowStack = UIStackView()
    private let mainStack = UIStackView()
    
    init(type: CombatActionType, chancePercent: Int, consequenceDescription: String, onTap: (() -> Void)? = nil) {
        super.init(frame: .zero)
        self.onTap = onTap
        setupUI(type: type, chancePercent: chancePercent, consequenceDescription: consequenceDescription)
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        addTarget(self, action: #selector(animateDown), for: .touchDown)
        addTarget(self, action: #selector(animateUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(type: CombatActionType, chancePercent: Int, consequenceDescription: String) {
        // Цвета для действий
        let (titleColor, iconColor): (UIColor, UIColor) = {
            switch type {
            case .attack: return (.systemOrange, .systemOrange)
            case .feed: return (.systemPink, .systemPink)
            case .dominate: return (.systemBlue, .systemBlue)
            case .drain: return (.systemRed, .systemRed)
            default: return (.white, .white)
            }
        }()
        // --- Иконка ---
        iconImageView.image = UIImage(systemName: type.icon)
        iconImageView.tintColor = iconColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        // --- Название действия ---
        actionTitleLabel.text = "\(type.displayName) \(chancePercent)%"
        actionTitleLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        actionTitleLabel.textColor = titleColor
        actionTitleLabel.textAlignment = .center
        // --- Success/Fail ---
        let consequenceLines = consequenceDescription.components(separatedBy: "\n")
        let successLine = consequenceLines.first ?? ""
        let failLine = consequenceLines.count > 1 ? consequenceLines[1] : ""
        successLabel.text = successLine.isEmpty ? "" : "\u{2713} " + successLine
        successLabel.font = UIFont(name: "Optima-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10)
        successLabel.textColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        successLabel.textAlignment = .center
        successLabel.numberOfLines = 0
        failLabel.text = failLine.isEmpty ? "" : "\u{2717} " + failLine
        failLabel.font = UIFont(name: "Optima-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10)
        failLabel.textColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        failLabel.textAlignment = .center
        failLabel.numberOfLines = 0
        // --- StackViews ---
        topRowStack.axis = .horizontal
        topRowStack.spacing = 6
        topRowStack.alignment = .center
        topRowStack.distribution = .fill
        topRowStack.translatesAutoresizingMaskIntoConstraints = false
        topRowStack.addArrangedSubview(iconImageView)
        topRowStack.addArrangedSubview(actionTitleLabel)
        mainStack.axis = .vertical
        mainStack.spacing = 4
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(topRowStack)
        mainStack.addArrangedSubview(successLabel)
        mainStack.addArrangedSubview(failLabel)
        addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        // Отключаем user interaction у всех subviews, чтобы не блокировать нажатия на кнопку
        mainStack.isUserInteractionEnabled = false
        topRowStack.isUserInteractionEnabled = false
        successLabel.isUserInteractionEnabled = false
        failLabel.isUserInteractionEnabled = false
        actionTitleLabel.isUserInteractionEnabled = false
        iconImageView.isUserInteractionEnabled = false
        // --- Стилизация кнопки ---
        backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.7) //rgb(0, 0, 0)
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = iconColor.withAlphaComponent(0.5).cgColor
        // Внутреннее свечение (glow)
        let glow = CALayer()
        glow.frame = bounds.insetBy(dx: 4, dy: 4)
        glow.cornerRadius = 8
        glow.backgroundColor = iconColor.withAlphaComponent(0.18).cgColor
        glow.shadowColor = iconColor.cgColor
        glow.shadowRadius = 8
        glow.shadowOpacity = 0.5
        glow.shadowOffset = .zero
        layer.insertSublayer(glow, at: 1)
        // Внутренняя тень (inner shadow)
        let innerShadow = CALayer()
        innerShadow.frame = bounds
        innerShadow.cornerRadius = 10
        innerShadow.backgroundColor = UIColor.clear.cgColor
        innerShadow.shadowColor = UIColor.black.cgColor
        innerShadow.shadowOffset = CGSize(width: 0, height: 2)
        innerShadow.shadowOpacity = 0.25
        innerShadow.shadowRadius = 6
        layer.insertSublayer(innerShadow, at: 2)
        // Ограничение максимальной и минимальной высоты кнопки
        heightAnchor.constraint(lessThanOrEqualToConstant: 145).isActive = true
        heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        // Фиксированная ширина для боевого экрана
        widthAnchor.constraint(equalToConstant: 260).isActive = true
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        // Тень к тексту
        actionTitleLabel.layer.shadowColor = UIColor.black.cgColor
        actionTitleLabel.layer.shadowOpacity = 0.7
        actionTitleLabel.layer.shadowRadius = 3
        actionTitleLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
    }
    
    @objc private func buttonTapped() {
        VibrationService.shared.lightTap()
        onTap?()
    }

    @objc private func animateDown() {
        UIView.animate(withDuration: 0.08, delay: 0, options: [.curveEaseIn], animations: {
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }, completion: nil)
    }

    @objc private func animateUp() {
        UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 3, options: [], animations: {
            self.transform = .identity
        }, completion: nil)
    }
} 
