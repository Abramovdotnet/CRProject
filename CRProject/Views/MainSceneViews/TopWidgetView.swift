import SwiftUI
import UIKit
import Combine

// MARK: - Custom Progress Bar with glow effect
class CustomGlowProgressBar: UIView {
    private let backgroundLayer = CALayer()
    private let progressLayer = CALayer()
    private let glowLayer = CALayer()
    
    var progress: Float = 0.0 {
        didSet {
            updateProgress()
        }
    }
    
    var progressColor: UIColor = .red {
        didSet {
            updateColors()
        }
    }
    
    var trackColor: UIColor = UIColor(white: 0.3, alpha: 0.5) {
        didSet {
            backgroundLayer.backgroundColor = trackColor.cgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        // Background track
        backgroundLayer.cornerRadius = 2.5
        backgroundLayer.backgroundColor = trackColor.cgColor
        layer.addSublayer(backgroundLayer)
        
        // Glow layer (behind progress)
        glowLayer.cornerRadius = 2.5
        glowLayer.shadowOffset = .zero
        glowLayer.shadowRadius = 4
        glowLayer.shadowOpacity = 0.8
        layer.addSublayer(glowLayer)
        
        // Progress layer
        progressLayer.cornerRadius = 2.5
        progressLayer.backgroundColor = progressColor.cgColor
        layer.addSublayer(progressLayer)
        
        updateColors()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundLayer.frame = bounds
        glowLayer.frame = bounds
        
        updateProgress()
    }
    
    private func updateProgress() {
        let progressWidth = bounds.width * CGFloat(progress)
        progressLayer.frame = CGRect(x: 0, y: 0, width: progressWidth, height: bounds.height)
        
        // Update glow layer frame to match progress
        glowLayer.frame = CGRect(x: 0, y: 0, width: progressWidth, height: bounds.height)
    }
    
    private func updateColors() {
        progressLayer.backgroundColor = progressColor.cgColor
        glowLayer.backgroundColor = progressColor.cgColor
        glowLayer.shadowColor = progressColor.cgColor
    }
    
    func setProgress(_ progress: Float, animated: Bool) {
        if animated {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.3)
            self.progress = progress
            CATransaction.commit()
        } else {
            self.progress = progress
        }
    }
}

// MARK: - UIKit Implementation
class TopWidgetUIViewController: UIViewController {
    // Main properties
    private var viewModel: MainSceneViewModel
    private var awarenessService = VampireNatureRevealService.shared
    private var playerBloodMeter: BloodMeter?
    private var cancellables = Set<AnyCancellable>()
    
    // UI Components - заменяем ScrollView на обычный UIView
    private let contentView = UIView()
    private let contentStackView = UIStackView()
    
    // UI Elements
    private let dayNightImageView = UIImageView()
    private let timeLabel = UILabel()
    private let dayLabel = UILabel()
    private let lockImageView = UIImageView()
    // Добавляем разделитель (spacer), чтобы отделить левую часть виджета от правой
    private let flexibleSpacerView = UIView()
    private let awarenessImageView = UIImageView()
    private let awarenessLabel = UILabel()
    // Заменяем стандартный прогресс-бар на кастомный с регулируемой высотой
    private let awarenessProgressView = CustomGlowProgressBar()
    private let bloodImageView = UIImageView()
    private let bloodLabel = UILabel()
    // Заменяем стандартный прогресс-бар на кастомный с регулируемой высотой
    private let bloodProgressView = CustomGlowProgressBar()
    private let coinImageView = UIImageView()
    private let coinValueLabel = UILabel()
    
    // Debug buttons
    private let respawnButton = UIButton()
    private let resetAwarenessButton = UIButton()
    private let resetBloodButton = UIButton()
    private let resetDesiresButton = UIButton()
    private let maxAchievementsButton = UIButton()
    private let debugOverlayButton = UIButton()
    
    // Glow views для иконок (добавляем как в InfoPresentationLabelView)
    private let dayNightGlowView = UIImageView()
    private let awarenessGlowView = UIImageView()
    private let bloodGlowView = UIImageView()
    private let coinGlowView = UIImageView()
    
    // Static cache for glow images to avoid regenerating them
    private static var glowImageCache: [String: UIImage] = [:]
    private static let cacheQueue = DispatchQueue(label: "glowImageCache", qos: .utility)
    
    // Animation constants
    private let animationDuration: TimeInterval = 0.5
    
    init(viewModel: MainSceneViewModel) {
        self.viewModel = viewModel
        self.playerBloodMeter = GameStateService.shared.player?.bloodMeter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        updateUI()
        
        // Устанавливаем начальное значение для bloodProgressView
        if let bloodPercentage = playerBloodMeter?.bloodPercentage {
            bloodProgressView.progress = bloodPercentage / 100.0
        } else {
            bloodProgressView.progress = 0.0
        }
        
        // Явно устанавливаем видимость
        bloodProgressView.isHidden = false
        
        // Настраиваем свечения после установки UI иерархии
        setupAllIconGlows()
    }
    
    // Настройка всех свечений после создания UI иерархии
    private func setupAllIconGlows() {
        // Заменяем простые SF символы на светящиеся иконки с круглым фоном как в InfoPresentationLabelView
        setupGlowingIcon(imageView: dayNightImageView, symbolName: "sun.max.fill", color: .yellow)
        setupGlowingIcon(imageView: awarenessImageView, symbolName: "figure.walk.triangle.fill", 
                         color: UIColor(red: 0.65, green: 0.28, blue: 0.95, alpha: 1.0))
        setupGlowingIcon(imageView: bloodImageView, symbolName: "drop.fill", 
                         color: UIColor(Theme.bloodProgressColor))
        setupGlowingIcon(imageView: coinImageView, symbolName: "cedisign", color: .green)
    }
    
    // Создание светящейся иконки точно как в InfoPresentationLabelView.createGlowingIconView
    private func setupGlowingIcon(imageView: UIImageView, symbolName: String, color: UIColor) {
        let iconSize: CGFloat = 28 // Точно как в InfoPresentationLabelView
        
        // Настраиваем main icon view - точно как в InfoPresentationLabelView
        imageView.frame = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
        imageView.contentMode = .center // Точно как в InfoPresentationLabelView
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = iconSize / 2
        imageView.layer.borderWidth = 0 // Убираем белую обводку
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowRadius = 2 // Уменьшаем с 3 до 2
        imageView.layer.shadowOpacity = 0.5 // Уменьшаем с 0.8 до 0.5
        imageView.layer.shadowOffset = CGSize(width: 0, height: 1)
        imageView.alpha = 1.0
        imageView.tintColor = color
        
        // Create SF Symbol with proper configuration - точно как в InfoPresentationLabelView
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 10) // Точно как в InfoPresentationLabelView
        let symbolImage = UIImage(systemName: symbolName, withConfiguration: iconConfig)
        imageView.image = symbolImage
        
        // Glow для иконки - добавляем как subview к иконке (без constraints) - точно как в InfoPresentationLabelView
        let glowView = UIImageView()
        glowView.contentMode = .scaleAspectFill
        glowView.alpha = 0.8
        glowView.isUserInteractionEnabled = false
        glowView.tag = 999 // Тег для поиска glow view
        imageView.addSubview(glowView)
        imageView.sendSubviewToBack(glowView)
        
        // Устанавливаем размеры glow views напрямую (без constraints) - точно как в InfoPresentationLabelView
        let glowSize = iconSize + 12
        glowView.frame = CGRect(x: -6, y: -6, width: glowSize, height: glowSize)
        
        // Set size constraints для imageView
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
        
        // Generate glow image
        Self.getCachedGlowImage(size: CGSize(width: iconSize + 12, height: iconSize + 12), color: color) { glowImage in
            DispatchQueue.main.async {
                glowView.image = glowImage
            }
        }
    }
    
    // Обновление только символа и цвета существующей иконки без пересоздания
    private func updateGlowingIcon(imageView: UIImageView, symbolName: String, color: UIColor) {
        // Обновляем цвет tint
        imageView.tintColor = color
        
        // Обновляем символ
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 10)
        let symbolImage = UIImage(systemName: symbolName, withConfiguration: iconConfig)
        imageView.image = symbolImage
        
        // Находим glow view и обновляем его
        if let glowView = imageView.subviews.first(where: { $0.tag == 999 }) as? UIImageView {
            let iconSize: CGFloat = 28
            Self.getCachedGlowImage(size: CGSize(width: iconSize + 12, height: iconSize + 12), color: color) { glowImage in
                DispatchQueue.main.async {
                    glowView.image = glowImage
                }
            }
        }
    }
    
    // Простые SF символы как в InfoPresentationLabelView (createSymbolView)
    private func setupSimpleSymbol(imageView: UIImageView, symbolName: String, color: UIColor) {
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = color
        
        // Create SF Symbol with proper configuration - точно как в InfoPresentationLabelView
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium, scale: .medium)
        let symbolImage = UIImage(systemName: symbolName, withConfiguration: symbolConfig)
        imageView.image = symbolImage
        
        // Set size constraints - точно как в InfoPresentationLabelView
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Setup ContentView (замена ScrollView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear
        view.addSubview(contentView)
        
        // Setup ContentStackView
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.spacing = 2  // Уменьшаем расстояние между элементами с 5 до 2
        contentView.addSubview(contentStackView)
        
        // Configure UI elements
        setupUIElements()
        
        // Add everything to stack
        addElementsToStack()
        
        // Setup layout constraints
        setupConstraints()
    }
    
    private func setupUIElements() {
        // Configure all UI elements with initial state
        
        // Day/Night Icon - простая иконка с легким свечением
        dayNightImageView.contentMode = .scaleAspectFit
        dayNightImageView.tintColor = .white
        
        // Time Label
        timeLabel.textColor = .white
        timeLabel.font = UIFont(name: "Optima", size: 12)
        timeLabel.textAlignment = .left
        
        // Day Label
        dayLabel.textColor = .white
        dayLabel.font = UIFont(name: "Optima", size: 12)
        dayLabel.textAlignment = .left
        
        // Lock Image
        lockImageView.contentMode = .scaleAspectFit
        lockImageView.tintColor = UIColor(red: 0.9, green: 0.8, blue: 0.8, alpha: 1.0)
        lockImageView.isHidden = true
        
        // Awareness Image - будет настроено в setupCircularIcon
        awarenessImageView.contentMode = .scaleAspectFit
        
        // Awareness Label
        awarenessLabel.textColor = .white
        awarenessLabel.font = UIFont(name: "Optima", size: 12)
        awarenessLabel.textAlignment = .center
        
        // Awareness Progress - простой стиль с свечением
        awarenessProgressView.trackColor = UIColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 0.95)
        awarenessProgressView.progressColor = UIColor(red: 0.65, green: 0.28, blue: 0.95, alpha: 1.0)
        awarenessProgressView.progress = 0.0
        
        // Blood Image - будет настроено в setupCircularIcon
        bloodImageView.contentMode = .scaleAspectFit
        
        // Blood Label
        bloodLabel.textColor = .white
        bloodLabel.font = UIFont(name: "Optima", size: 12)
        bloodLabel.textAlignment = .center
        
        // Blood Progress - простой стиль с свечением
        bloodProgressView.trackColor = UIColor(red: 0.15, green: 0.03, blue: 0.03, alpha: 0.95)
        bloodProgressView.progressColor = UIColor(Theme.bloodProgressColor)
        bloodProgressView.progress = 0.5
        
        // Coin Image - будет настроено в setupCircularIcon
        coinImageView.contentMode = .scaleAspectFit
        
        // Coin Value Label
        coinValueLabel.textColor = .green
        coinValueLabel.font = UIFont(name: "Optima", size: 12)
        coinValueLabel.textAlignment = .left
        
        // Debug Buttons
        setupDebugButtons()
    }
    
    private func setupDebugButtons() {
        // Respawn NPCs button
        configureDebugButton(respawnButton, systemName: "figure.walk", action: #selector(respawnNPCs))
        
        // Reset Awareness button
        configureDebugButton(resetAwarenessButton, systemName: "figure.walk.diamond", action: #selector(resetAwareness))
        
        // Reset Blood Pool button
        configureDebugButton(resetBloodButton, systemName: "heart.fill", action: #selector(resetBloodPool))
        
        // Reset Desires button
        configureDebugButton(resetDesiresButton, systemName: "w.circle", action: #selector(resetDesires))
        
        // Max Achievements button
        configureDebugButton(maxAchievementsButton, systemName: "sparkles", action: #selector(maxOutAchievements))
        
        // Debug Overlay button
        configureDebugButton(debugOverlayButton, systemName: "hammer.fill", action: #selector(toggleDebugOverlay))
    }
    
    private func configureDebugButton(_ button: UIButton, systemName: String, action: Selector) {
        button.setImage(UIImage(systemName: systemName), for: .normal)
        // Используем системный желтый цвет вместо кастомного
        button.tintColor = UIColor.systemYellow
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    private func addElementsToStack() {
        // Очищаем существующие элементы на случай повторного вызова
        for view in contentStackView.arrangedSubviews {
            contentStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        // Add items in order to the stack view - сначала базовые элементы (убираем локацию и NPC count)
        contentStackView.addArrangedSubview(dayNightImageView)
        contentStackView.addArrangedSubview(timeLabel)
        contentStackView.addArrangedSubview(dayLabel)
        
        // Добавляем хороший отступ перед шкалами для визуального разделения
        let smallSpacer = UIView()
        smallSpacer.widthAnchor.constraint(equalToConstant: 20).isActive = true  // Увеличиваем отступ с 12 до 20
        contentStackView.addArrangedSubview(smallSpacer)
        
        // Группа крови - плотное размещение элементов
        contentStackView.addArrangedSubview(bloodLabel)
        // Нет отступа между значением и шкалой
        contentStackView.addArrangedSubview(bloodProgressView)
        // Нет отступа между шкалой и иконкой
        contentStackView.addArrangedSubview(bloodImageView)
        
        // Добавляем разделитель между группами шкал
        let spacerBetweenBars = UIView()
        spacerBetweenBars.widthAnchor.constraint(equalToConstant: 20).isActive = true  // Увеличиваем отступ с 12 до 20
        contentStackView.addArrangedSubview(spacerBetweenBars)
        
        // Группа awareness - плотное размещение элементов
        contentStackView.addArrangedSubview(awarenessLabel)
        // Нет отступа между значением и шкалой
        contentStackView.addArrangedSubview(awarenessProgressView)
        // Нет отступа между шкалой и иконкой
        contentStackView.addArrangedSubview(awarenessImageView)
        
        // Добавляем spacer только если есть достаточно места
        contentStackView.addArrangedSubview(flexibleSpacerView)
        
        // Добавляем отступ перед Coins
        let coinsSpacer = UIView()
        coinsSpacer.widthAnchor.constraint(equalToConstant: 15).isActive = true  // Увеличиваем отступ с 10 до 15
        contentStackView.addArrangedSubview(coinsSpacer)
        
        // Опциональные элементы могут быть скрыты если не хватает места
        contentStackView.addArrangedSubview(coinImageView)
        contentStackView.addArrangedSubview(coinValueLabel)
        
        // Опционально добавляем lockImageView если сцена заблокирована
        if !lockImageView.isHidden {
            contentStackView.addArrangedSubview(lockImageView)
        }
        
        // Добавляем debug кнопки в конец для удобства
        let debugButtonStack = UIStackView(arrangedSubviews: [
            respawnButton, resetAwarenessButton, resetBloodButton,
            resetDesiresButton, maxAchievementsButton, debugOverlayButton
        ])
        debugButtonStack.axis = .horizontal
        debugButtonStack.spacing = 1 // Минимальное расстояние между кнопками
        contentStackView.addArrangedSubview(debugButtonStack)
        debugButtonStack.setContentHuggingPriority(.required, for: .horizontal)
    }
    
    private func setupConstraints() {
        // Привязываем contentView к краям view
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Привязываем contentStackView к верхнему краю contentView, подняв на 2 пикселя выше
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 3), // Было 5, уменьшаем до 3
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -2),
        ])
        
        // Устанавливаем только высоту stackView без привязки к верху и низу
        contentStackView.heightAnchor.constraint(equalToConstant: 35).isActive = true // Увеличиваем с 30 до 35 под новые иконки
        
        // Set fixed sizes for progress bars
        let progressBarWidth: CGFloat = 120  // Увеличиваем с 80 до 120 благодаря освободившемуся месту
        let healthBarWidth: CGFloat = 120  // Увеличиваем с 80 до 120 благодаря освободившемуся месту
        let debugButtonSize: CGFloat = 20  // Размер debug кнопок (меньше основных иконок)
        
        // Задаем приоритеты и размеры элементов, начиная с наиболее важных
        
        // Остальные текстовые элементы с фиксированной шириной (убираем настройки для sceneNameLabel и peopleCountLabel)
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true  // Увеличиваем с 40 до 50 для отображения минут
        
        dayLabel.setContentHuggingPriority(.required, for: .horizontal)
        dayLabel.widthAnchor.constraint(equalToConstant: 45).isActive = true  // Уменьшаем с 55 до 45
        
        awarenessLabel.setContentHuggingPriority(.required, for: .horizontal)
        awarenessLabel.widthAnchor.constraint(equalToConstant: 35).isActive = true  // Увеличиваем с 30 до 35
        
        bloodLabel.setContentHuggingPriority(.required, for: .horizontal)
        bloodLabel.widthAnchor.constraint(equalToConstant: 35).isActive = true  // Увеличиваем с 30 до 35
        
        coinValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        coinValueLabel.widthAnchor.constraint(equalToConstant: 35).isActive = true  // Уменьшаем с 45 до 35
        
        // Устанавливаем приоритеты для иконок (размеры устанавливаются в setupGlowingIcon - 28x28)
        [dayNightImageView, lockImageView, awarenessImageView, bloodImageView, coinImageView].forEach { imageView in
            imageView.setContentHuggingPriority(.required, for: .horizontal)
        }
        
        // Настраиваем flexibleSpacerView, чтобы он растягивался и занимал всё свободное пространство
        flexibleSpacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        flexibleSpacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        // Ограничиваем максимальную ширину spacer для экономии места
        flexibleSpacerView.widthAnchor.constraint(lessThanOrEqualToConstant: 50).isActive = true
        
        // Прогресс-бары должны иметь возможность сжиматься при необходимости, но поддерживать минимальную ширину
        awarenessProgressView.setContentHuggingPriority(.defaultLow + 5, for: .horizontal)
        awarenessProgressView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        // Вместо жесткого констрейнта делаем приоритетный с уменьшенной шириной
        let awarenessWidthConstraint = awarenessProgressView.widthAnchor.constraint(equalToConstant: progressBarWidth)
        awarenessWidthConstraint.priority = .defaultHigh
        awarenessWidthConstraint.isActive = true
        // Устанавливаем минимальную ширину для шкалы awareness
        awarenessProgressView.widthAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        // Устанавливаем высоту для awareness progress bar
        awarenessProgressView.heightAnchor.constraint(equalToConstant: 5).isActive = true
        
        // Увеличиваем приоритет и ширину для прогресс-бара крови (здоровья)
        bloodProgressView.setContentHuggingPriority(.defaultLow + 5, for: .horizontal) // Снижаем с 10 до 5 чтобы обе шкалы имели равный приоритет
        bloodProgressView.setContentCompressionResistancePriority(.required - 10, for: .horizontal) // Снижаем приоритет сжатия
        // Устанавливаем фиксированную ширину для шкалы здоровья с высоким приоритетом
        let bloodWidthConstraint = bloodProgressView.widthAnchor.constraint(equalToConstant: healthBarWidth)
        bloodWidthConstraint.priority = .defaultHigh // Снижаем с required-1 до defaultHigh
        bloodWidthConstraint.isActive = true
        
        // Задаем минимальную ширину для прогресс-бара здоровья, чтобы он всегда был виден
        bloodProgressView.widthAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true // Уменьшаем с 80 до 50
        // Устанавливаем высоту для blood progress bar
        bloodProgressView.heightAnchor.constraint(equalToConstant: 5).isActive = true
        
        // Фиксированный размер для кнопок отладки с приоритетом
        [respawnButton, resetAwarenessButton, resetBloodButton, 
         resetDesiresButton, maxAchievementsButton, debugOverlayButton].forEach { button in
            button.widthAnchor.constraint(equalToConstant: debugButtonSize).isActive = true
            button.heightAnchor.constraint(equalToConstant: debugButtonSize).isActive = true
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        }
        
        // Уменьшаем общий spacing в stack view для более компактного вида
        contentStackView.spacing = 1
    }
    
    private func setupBindings() {
        // Observe ViewModel properties
        viewModel.$isNight
            .sink { [weak self] isNight in
                self?.updateDayNightUI(isNight: isNight)
            }
            .store(in: &cancellables)
        
        viewModel.$currentHour
            .sink { [weak self] hour in
                self?.animateTextChange(for: self?.timeLabel, to: " \(hour):\(String(format: "%02d", self?.viewModel.currentMinute ?? 0))")
            }
            .store(in: &cancellables)
        
        viewModel.$currentMinute
            .sink { [weak self] minute in
                self?.animateTextChange(for: self?.timeLabel, to: " \(self?.viewModel.currentHour ?? 0):\(String(format: "%02d", minute))")
            }
            .store(in: &cancellables)
        
        viewModel.$currentDay
            .sink { [weak self] day in
                self?.animateTextChange(for: self?.dayLabel, to: "Day \(day)")
            }
            .store(in: &cancellables)
        
        viewModel.$playerCoinsValue
            .sink { [weak self] value in
                self?.animateTextChange(for: self?.coinValueLabel, to: "\(value)")
            }
            .store(in: &cancellables)
        
        // Observe awareness service
        awarenessService.$awarenessLevel
            .sink { [weak self] level in
                self?.updateAwarenessUI(level: level)
            }
            .store(in: &cancellables)
        
        // Observe blood meter if available
        playerBloodMeter?.$bloodPercentage
            .sink { [weak self] percentage in
                self?.updateBloodUI(percentage: percentage)
            }
            .store(in: &cancellables)
        
        // Handle player updates (for the case when player is set later)
        NotificationCenter.default.publisher(for: Notification.Name("PlayerUpdated"))
            .sink { [weak self] _ in
                self?.updatePlayerBindings()
            }
            .store(in: &cancellables)
    }
    
    private func updatePlayerBindings() {
        // Update blood meter bindings if player changes
        if let player = GameStateService.shared.player {
            self.playerBloodMeter = player.bloodMeter
            
            // Create new observation for blood percentage
            playerBloodMeter?.$bloodPercentage
                .sink { [weak self] percentage in
                    self?.updateBloodUI(percentage: percentage)
                }
                .store(in: &cancellables)
                
            // Immediately update blood UI with current value
            self.updateBloodUI(percentage: player.bloodMeter.bloodPercentage)
        }
    }
    
    // MARK: - UI Update Methods with Animations
    
    private func updateUI() {
        updateDayNightUI(isNight: viewModel.isNight)
        timeLabel.text = " \(viewModel.currentHour):\(String(format: "%02d", viewModel.currentMinute))"
        dayLabel.text = "Day \(viewModel.currentDay)"
        updateAwarenessUI(level: awarenessService.awarenessLevel)
        
        // Обязательно обновляем значение для шкалы здоровья
        let bloodValue = playerBloodMeter?.bloodPercentage ?? 0
        updateBloodUI(percentage: bloodValue)
        
        coinValueLabel.text = "\(viewModel.playerCoinsValue)"
    }
    
    private func updateDayNightUI(isNight: Bool) {
        // Обновляем круглую иконку день/ночь
        let backgroundColor: UIColor = isNight ? .white : .yellow
        let symbolName = isNight ? "moon.fill" : "sun.max.fill"
        
        UIView.transition(with: dayNightImageView, duration: animationDuration, options: .transitionCrossDissolve, animations: {
            self.updateGlowingIcon(imageView: self.dayNightImageView, symbolName: symbolName, color: backgroundColor)
        }, completion: nil)
    }
    
    private func updateAwarenessUI(level: Float) {
        // Анимируем изменения awareness
        animateTextChange(for: awarenessLabel, to: "\(Int(level))%")
        
        // Изменяем цвет в зависимости от уровня, сохраняя стиль свечения как в NPCCell
        UIView.animate(withDuration: animationDuration) {
            if level > 70 {
                // Опасный уровень - более яркий красно-фиолетовый цвет
                self.awarenessProgressView.progressColor = UIColor(red: 0.8, green: 0.15, blue: 0.7, alpha: 1.0)
            } else if level > 40 {
                // Средний уровень - стандартный фиолетовый цвет
                self.awarenessProgressView.progressColor = UIColor(red: 0.65, green: 0.28, blue: 0.95, alpha: 1.0)
            } else {
                // Безопасный уровень - более спокойный фиолетовый
                self.awarenessProgressView.progressColor = UIColor(red: 0.5, green: 0.25, blue: 0.75, alpha: 1.0)
            }
        }
        
        // Плавно анимируем прогресс бар
        awarenessProgressView.setProgress(level / 100.0, animated: true)
    }
    
    private func updateBloodUI(percentage: Float) {
        // Анимируем изменения blood meter
        animateTextChange(for: bloodLabel, to: "\(Int(percentage))%")
        
        // Изменяем цвет в зависимости от уровня, но используем Theme.bloodProgressColor как базовый
        UIView.animate(withDuration: animationDuration) {
            if percentage < 30 {
                // Опасно низкий уровень - более темный красный
                self.bloodProgressView.progressColor = UIColor(red: 0.8, green: 0.15, blue: 0.15, alpha: 1.0)
            } else if percentage < 50 {
                // Средний уровень - базовый цвет из Theme
                self.bloodProgressView.progressColor = UIColor(Theme.bloodProgressColor)
            } else {
                // Высокий уровень - более яркий красный
                self.bloodProgressView.progressColor = UIColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 1.0)
            }
        }
        
        // Плавно анимируем прогресс бар
        bloodProgressView.setProgress(percentage / 100.0, animated: true)
    }
    
    // Вспомогательная функция для анимации изменения текста
    private func animateTextChange(for label: UILabel?, to newText: String) {
        guard let label = label, label.text != newText else { return }
        
        UIView.transition(with: label, duration: animationDuration/2, options: .transitionCrossDissolve, animations: {
            label.text = newText
        }, completion: nil)
    }
    
    // MARK: - Action Methods
    
    @objc private func respawnNPCs() {
                    viewModel.respawnNPCs()
                }
    
    @objc private func resetAwareness() {
                    viewModel.resetAwareness()
                }
                
    @objc private func resetBloodPool() {
                    viewModel.resetBloodPool()
                }
                
    @objc private func resetDesires() {
                    viewModel.resetDesires()
                }
                
    @objc private func maxOutAchievements() {
                    StatisticsService.shared.maxOutAchievements()
                }
                
    @objc private func toggleDebugOverlay() {
                    viewModel.toggleDebugOverlay()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Проверяем ширину всех элементов и скрываем опциональные, если не хватает места
        let availableWidth = view.frame.width
        let contentWidth = contentStackView.frame.width
        
        // Если не хватает места, скрываем некоторые элементы
        if contentWidth > availableWidth {
            // Скрываем flexibleSpacer в первую очередь
            flexibleSpacerView.isHidden = true
            
            // В крайнем случае, скрываем monetization элементы, но оставляем шкалы видимыми
            if contentStackView.frame.width > availableWidth {
                coinImageView.isHidden = true
                coinValueLabel.isHidden = true
            }
        } else {
            // Если места достаточно, показываем все элементы
            flexibleSpacerView.isHidden = false
            coinImageView.isHidden = false
            coinValueLabel.isHidden = false
        }
    }
    
    // После полной загрузки интерфейса проверяем видимость элементов 
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Обновляем значения прогресс-баров
        if let bloodPercentage = playerBloodMeter?.bloodPercentage {
            bloodProgressView.progress = bloodPercentage / 100.0
        }
        
        // Обновляем шкалу awareness
        let awarenessLevel = awarenessService.awarenessLevel
        awarenessProgressView.progress = awarenessLevel / 100.0
    }
    
    // MARK: - Glow Effect Methods (copied from InfoPresentationLabelView)
    
    // Кэшированная генерация radial alpha glow для иконок
    private static func getCachedGlowImage(size: CGSize, color: UIColor, completion: @escaping (UIImage?) -> Void) {
        // Создаем уникальный ключ на основе размера и компонентов цвета
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let cacheKey = String(format: "%.0fx%.0f_%.3f_%.3f_%.3f_%.3f", size.width, size.height, red, green, blue, alpha)
        
        // Проверяем кэш в основном потоке
        if let cachedImage = glowImageCache[cacheKey] {
            completion(cachedImage)
            return
        }
        
        // Генерируем изображение в фоновом потоке
        cacheQueue.async {
            let glowImage = makeRadialGlowImage(size: size, color: color)
            
            // Сохраняем в кэш
            if let image = glowImage {
                glowImageCache[cacheKey] = image
            }
            
            // Возвращаем результат
            completion(glowImage)
        }
    }
    
    // Оптимизированная генерация radial alpha glow для иконок
    private static func makeRadialGlowImage(size: CGSize, color: UIColor) -> UIImage? {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        
        // Оптимизация: используем более эффективный способ создания градиента
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [color.withAlphaComponent(0.4).cgColor, color.withAlphaComponent(0.0).cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let radius = size.width * 0.5
        
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: .drawsAfterEndLocation)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image?.withRenderingMode(.alwaysOriginal)
    }
    
    // Method to clear cache if needed (for memory management)
    static func clearGlowImageCache() {
        cacheQueue.async {
            glowImageCache.removeAll()
        }
    }
}

// MARK: - SwiftUI Representable Wrapper
struct TopWidgetView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: MainSceneViewModel
    
    func makeUIViewController(context: Context) -> TopWidgetUIViewController {
        return TopWidgetUIViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: TopWidgetUIViewController, context: Context) {
        // Updates are handled via Combine publishers
    }
}
