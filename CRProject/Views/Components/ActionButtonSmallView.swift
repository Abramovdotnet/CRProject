import UIKit

class ActionButtonSmallView: UIButton {
    private var onTap: (() -> Void)?
    private let iconGlowView = UIImageView()
    private let iconImageView = UIImageView()
    private let actionTitleLabel = UILabel()
    private let topRowStack = UIStackView()
    
    init(onTap: (() -> Void)? = nil) {
        super.init(frame: .zero)
        self.onTap = onTap
        self.translatesAutoresizingMaskIntoConstraints = false
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        addTarget(self, action: #selector(animateDown), for: .touchDown)
        addTarget(self, action: #selector(animateUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(type: CombatActionType) {
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
        // --- Radial Glow под иконкой ---
        iconGlowView.translatesAutoresizingMaskIntoConstraints = false
        iconGlowView.image = Self.makeRadialGlowImage(size: CGSize(width: 32, height: 32), color: iconColor)
        iconGlowView.contentMode = .scaleAspectFill
        iconGlowView.isUserInteractionEnabled = false
        // --- Иконка ---
        iconImageView.image = UIImage(systemName: type.icon)
        iconImageView.tintColor = iconColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        // --- Свечение для иконки (через тень, чуть слабее) ---
        iconImageView.layer.shadowColor = iconColor.cgColor
        iconImageView.layer.shadowRadius = 2
        iconImageView.layer.shadowOpacity = 0.3
        iconImageView.layer.shadowOffset = .zero
        // --- GlowView под иконкой ---
        iconImageView.addSubview(iconGlowView)
        iconImageView.sendSubviewToBack(iconGlowView)
        NSLayoutConstraint.activate([
            iconGlowView.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
            iconGlowView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            iconGlowView.widthAnchor.constraint(equalTo: iconImageView.widthAnchor, constant: 12),
            iconGlowView.heightAnchor.constraint(equalTo: iconImageView.heightAnchor, constant: 12)
        ])
        // --- Название действия ---
        actionTitleLabel.text = type.displayName
        actionTitleLabel.font = UIFont(name: "Optima-Regular", size: 13) ?? UIFont.systemFont(ofSize: 13)
        actionTitleLabel.textColor = titleColor
        actionTitleLabel.textAlignment = .center
        // --- StackView ---
        topRowStack.axis = .horizontal
        topRowStack.spacing = 6
        topRowStack.alignment = .center
        topRowStack.distribution = .fill
        topRowStack.translatesAutoresizingMaskIntoConstraints = false
        topRowStack.addArrangedSubview(iconImageView)
        topRowStack.addArrangedSubview(actionTitleLabel)
        addSubview(topRowStack)
        NSLayoutConstraint.activate([
            topRowStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            topRowStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            topRowStack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            topRowStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
        // --- Стилизация кнопки ---
        backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.7)
        layer.cornerRadius = 8
      
        // --- Свечение для кнопки ---
        self.layer.shadowColor = iconColor.cgColor
        self.layer.shadowRadius = 16
        self.layer.shadowOpacity = 0.4
        self.layer.shadowOffset = .zero
        // Фиксированная ширина
        widthAnchor.constraint(equalToConstant: 110).isActive = true
        // Делаю stackView и subviews неинтерактивными
        topRowStack.isUserInteractionEnabled = false
        iconGlowView.isUserInteractionEnabled = false
        iconImageView.isUserInteractionEnabled = false
        actionTitleLabel.isUserInteractionEnabled = false
        // Делаю всю кнопку кликабельной
        self.isUserInteractionEnabled = true
        // Тень к тексту
        actionTitleLabel.layer.shadowColor = UIColor.black.cgColor
        actionTitleLabel.layer.shadowOpacity = 0.7
        actionTitleLabel.layer.shadowRadius = 2
        actionTitleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
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
    
    // Позволяет добавить подзаголовок (например, шанс) к названию
    public func setSubtitle(_ subtitle: String?) {
        if let subtitle = subtitle, !subtitle.isEmpty {
            actionTitleLabel.text = "\(actionTitleLabel.text ?? "") \(subtitle)"
        }
    }
    
    // Новый универсальный инициализатор
    convenience init(title: String, icon: String, color: UIColor, onTap: (() -> Void)? = nil) {
        self.init()
        self.onTap = onTap
        self.translatesAutoresizingMaskIntoConstraints = false
        setupCustomUI(title: title, icon: icon, color: color)
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        addTarget(self, action: #selector(animateDown), for: .touchDown)
        addTarget(self, action: #selector(animateUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    private func setupCustomUI(title: String, icon: String, color: UIColor) {
        // Очищаем stack и удаляем из superview
        topRowStack.arrangedSubviews.forEach { topRowStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        topRowStack.removeFromSuperview()
        // --- Radial Glow под иконкой ---
        iconGlowView.translatesAutoresizingMaskIntoConstraints = false
        iconGlowView.image = Self.makeRadialGlowImage(size: CGSize(width: 32, height: 32), color: color)
        iconGlowView.contentMode = .scaleAspectFill
        iconGlowView.isUserInteractionEnabled = false
        iconGlowView.alpha = 0.8
        // --- Иконка ---
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = color
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        // --- Свечение для иконки (через тень, чуть слабее) ---
        iconImageView.layer.shadowColor = color.cgColor
        iconImageView.layer.shadowRadius = 2
        iconImageView.layer.shadowOpacity = 0.3
        iconImageView.layer.shadowOffset = .zero
        // --- GlowView под иконкой ---
        iconImageView.addSubview(iconGlowView)
        iconImageView.sendSubviewToBack(iconGlowView)
        NSLayoutConstraint.activate([
            iconGlowView.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
            iconGlowView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            iconGlowView.widthAnchor.constraint(equalTo: iconImageView.widthAnchor, constant: 12),
            iconGlowView.heightAnchor.constraint(equalTo: iconImageView.heightAnchor, constant: 12)
        ])
        // --- Название ---
        actionTitleLabel.text = title
        actionTitleLabel.font = UIFont(name: "Optima-Regular", size: 13) ?? UIFont.systemFont(ofSize: 13)
        actionTitleLabel.textColor = color
        actionTitleLabel.textAlignment = .center
        // --- StackView ---
        topRowStack.axis = .horizontal
        topRowStack.spacing = 6
        topRowStack.alignment = .center
        topRowStack.distribution = .fill
        topRowStack.translatesAutoresizingMaskIntoConstraints = false
        topRowStack.addArrangedSubview(iconImageView)
        topRowStack.addArrangedSubview(actionTitleLabel)
        addSubview(topRowStack)
        NSLayoutConstraint.activate([
            topRowStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            topRowStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            topRowStack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            topRowStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
        // --- Стилизация кнопки ---
        backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8)
        layer.cornerRadius = 8
        layer.borderWidth = 0.3
        layer.borderColor = color.withAlphaComponent(0.5).cgColor
 
        // --- Свечение для кнопки ---
        self.layer.shadowColor = color.cgColor
        self.layer.shadowRadius = 6
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = .zero
        widthAnchor.constraint(equalToConstant: 110).isActive = true
        topRowStack.isUserInteractionEnabled = false
        iconGlowView.isUserInteractionEnabled = false
        iconImageView.isUserInteractionEnabled = false
        actionTitleLabel.isUserInteractionEnabled = false
        self.isUserInteractionEnabled = true
        // Тень к тексту
        actionTitleLabel.layer.shadowColor = UIColor.black.cgColor
        actionTitleLabel.layer.shadowOpacity = 0.7
        actionTitleLabel.layer.shadowRadius = 2
        actionTitleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
    }
    
    // Генерация radial alpha glow
    private static func makeRadialGlowImage(size: CGSize, color: UIColor) -> UIImage? {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        let colors = [color.withAlphaComponent(0.35).cgColor, color.withAlphaComponent(0.0).cgColor] as CFArray
        let center = CGPoint(x: size.width/2, y: size.height/2)
        let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0,1])
        ctx.drawRadialGradient(grad!, startCenter: center, startRadius: 0, endCenter: center, endRadius: size.width/2, options: .drawsAfterEndLocation)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img?.withRenderingMode(.alwaysOriginal)
    }
} 
