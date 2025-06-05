import UIKit

class ActionButtonRoundedSmallView: UIButton {
    private var onTap: (() -> Void)?
    private let iconGlowView = UIImageView()
    private let iconImageView = UIImageView()
    
    // Универсальный инициализатор только с иконкой
    convenience init(icon: String, color: UIColor, size: CGFloat = 44, onTap: (() -> Void)? = nil) {
        self.init()
        self.onTap = onTap
        self.translatesAutoresizingMaskIntoConstraints = false
        setupRoundedUI(icon: icon, color: color, size: size)
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        addTarget(self, action: #selector(animateDown), for: .touchDown)
        addTarget(self, action: #selector(animateUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
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
    
    private func setupRoundedUI(icon: String, color: UIColor, size: CGFloat) {
        // --- Radial Glow под иконкой ---
        iconGlowView.translatesAutoresizingMaskIntoConstraints = false
        iconGlowView.image = Self.makeRadialGlowImage(size: CGSize(width: 32, height: 32), color: color)
        iconGlowView.contentMode = .scaleAspectFill
        iconGlowView.isUserInteractionEnabled = false
        iconGlowView.alpha = 0.8
        
        // --- Иконка ---
        let iconSize = size * 0.5 // Иконка занимает половину размера кнопки
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = color
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // --- Свечение для иконки (через тень, чуть слабее) ---
        iconImageView.layer.shadowColor = color.cgColor
        iconImageView.layer.shadowRadius = 2
        iconImageView.layer.shadowOpacity = 0.3
        iconImageView.layer.shadowOffset = .zero
        
        // --- GlowView под иконкой ---
        iconImageView.addSubview(iconGlowView)
        iconImageView.sendSubviewToBack(iconGlowView)
        
        // Добавляем иконку в кнопку
        addSubview(iconImageView)
        
        NSLayoutConstraint.activate([
            // Glow view constraints
            iconGlowView.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
            iconGlowView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            iconGlowView.widthAnchor.constraint(equalTo: iconImageView.widthAnchor, constant: 12),
            iconGlowView.heightAnchor.constraint(equalTo: iconImageView.heightAnchor, constant: 12),
            
            // Icon constraints - центрируем в кнопке
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: iconSize),
            
            // Button size constraints - делаем кнопку круглой
            widthAnchor.constraint(equalToConstant: size),
            heightAnchor.constraint(equalToConstant: size)
        ])
        
        // --- Стилизация кнопки (круглая) ---
        backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8)
        layer.cornerRadius = size / 2 // Делаем полностью круглой
        layer.borderWidth = 0 // Убираем обводку
        layer.borderColor = UIColor.clear.cgColor // Делаем цвет прозрачным
 
        // --- Свечение для кнопки ---
        self.layer.shadowColor = color.cgColor
        self.layer.shadowRadius = 6
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = .zero
        
        // Делаю subviews неинтерактивными
        iconGlowView.isUserInteractionEnabled = false
        iconImageView.isUserInteractionEnabled = false
        // Делаю всю кнопку кликабельной
        self.isUserInteractionEnabled = true
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
    
    // Обновление иконки и цвета
    func updateIcon(_ icon: String, color: UIColor) {
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = color
        iconGlowView.image = Self.makeRadialGlowImage(size: CGSize(width: 32, height: 32), color: color)
        
        // Обновляем цвета (убираем borderColor)
        layer.shadowColor = color.cgColor
        iconImageView.layer.shadowColor = color.cgColor
    }
    
    // Генерация radial alpha glow (точно такая же как в оригинале)
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