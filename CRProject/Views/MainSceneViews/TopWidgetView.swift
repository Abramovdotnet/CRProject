import SwiftUI
import UIKit
import Combine

// MARK: - Custom Progress View with adjustable height
class CustomHeightUIProgressView: UIProgressView {
    var heightConstraint: NSLayoutConstraint?
    var shadowLayer: CALayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if heightConstraint == nil {
            heightConstraint = constraints.first { $0.firstAttribute == .height }
            if heightConstraint == nil {
                heightConstraint = heightAnchor.constraint(equalToConstant: 10)
                heightConstraint?.isActive = true
            } else {
                heightConstraint?.constant = 10
            }
        }
        
        // Закругляем все подвиды для эллиптической формы
        layer.cornerRadius = 5
        clipsToBounds = true
        
        subviews.forEach { 
            $0.layer.cornerRadius = 5 
        }
        
        // Теневой слой для прогресс-бара (отдельно от самого прогресс-бара)
        if shadowLayer == nil {
            shadowLayer = CALayer()
            shadowLayer?.frame = bounds
            shadowLayer?.cornerRadius = 5
            shadowLayer?.backgroundColor = UIColor.clear.cgColor
            shadowLayer?.shadowColor = progressTintColor?.cgColor
            shadowLayer?.shadowOffset = CGSize(width: 0, height: 0)
            shadowLayer?.shadowOpacity = 0.9
            shadowLayer?.shadowRadius = 5
            
            // Добавляем теневой слой за прогресс-баром
            if let shadowLayer = shadowLayer {
                layer.superlayer?.insertSublayer(shadowLayer, below: layer)
            }
        }
        
        // Обновляем размер и положение теневого слоя
        shadowLayer?.frame = frame
        shadowLayer?.position = center
    }
    
    // Обновление цвета тени при изменении цвета прогресса
    override var progressTintColor: UIColor? {
        didSet {
            shadowLayer?.shadowColor = progressTintColor?.cgColor
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
    private let sceneTypeImageView = UIImageView()
    private let sceneNameLabel = UILabel()
    private let peopleImageView = UIImageView()
    private let peopleCountLabel = UILabel()
    // Добавляем разделитель (spacer), чтобы отделить левую часть виджета от правой
    private let flexibleSpacerView = UIView()
    private let awarenessImageView = UIImageView()
    private let awarenessLabel = UILabel()
    // Заменяем стандартный прогресс-бар на кастомный с регулируемой высотой
    private let awarenessProgressView = CustomHeightUIProgressView()
    private let bloodImageView = UIImageView()
    private let bloodLabel = UILabel()
    // Заменяем стандартный прогресс-бар на кастомный с регулируемой высотой
    private let bloodProgressView = CustomHeightUIProgressView()
    private let coinImageView = UIImageView()
    private let coinValueLabel = UILabel()
    
    // Debug buttons
    private let respawnButton = UIButton()
    private let resetAwarenessButton = UIButton()
    private let resetBloodButton = UIButton()
    private let resetDesiresButton = UIButton()
    private let maxAchievementsButton = UIButton()
    private let debugOverlayButton = UIButton()
    
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
        
        // Day/Night Icon
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
        
        // Scene Type Image
        sceneTypeImageView.contentMode = .scaleAspectFit
        sceneTypeImageView.tintColor = .white
        
        // Scene Name Label - используем точное соответствие SwiftUI Color.yellow
        sceneNameLabel.textColor = UIColor.systemYellow
        sceneNameLabel.font = UIFont(name: "Optima", size: 12)
        sceneNameLabel.lineBreakMode = .byTruncatingTail // Добавит ... если название не поместится
        
        // People Image
        peopleImageView.contentMode = .scaleAspectFit
        peopleImageView.tintColor = .white
        peopleImageView.image = UIImage(systemName: "person.3.fill")
        
        // People Count Label
        peopleCountLabel.textColor = .white
        peopleCountLabel.font = UIFont(name: "Optima", size: 12)
        peopleCountLabel.textAlignment = .center // Центрируем текст внутри фиксированного пространства
        
        // Awareness Image
        awarenessImageView.contentMode = .scaleAspectFit
        awarenessImageView.tintColor = UIColor(red: 0.4, green: 0.1, blue: 0.5, alpha: 1.0)
        awarenessImageView.image = UIImage(systemName: "figure.walk.triangle.fill")
        
        // Awareness Label
        awarenessLabel.textColor = .white
        awarenessLabel.font = UIFont(name: "Optima", size: 12)
        awarenessLabel.textAlignment = .center // Центрируем текст внутри фиксированного пространства
        
        // Awareness Progress - Улучшенный стильный дизайн
        awarenessProgressView.trackTintColor = UIColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 0.95)
        awarenessProgressView.progressTintColor = UIColor(red: 0.65, green: 0.28, blue: 0.95, alpha: 1.0)
        awarenessProgressView.layer.cornerRadius = 5
        awarenessProgressView.clipsToBounds = true
        awarenessProgressView.progress = 0.0
        awarenessProgressView.isHidden = false
        
        // Добавляем рамку для визуального выделения
        awarenessProgressView.layer.borderColor = UIColor(red: 0.65, green: 0.35, blue: 0.95, alpha: 0.3).cgColor
        awarenessProgressView.layer.borderWidth = 0.3
        
        // Blood Image
        bloodImageView.contentMode = .scaleAspectFit
        bloodImageView.tintColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        bloodImageView.image = UIImage(systemName: "drop.fill")
        
        // Blood Label
        bloodLabel.textColor = .white
        bloodLabel.font = UIFont(name: "Optima", size: 12)
        bloodLabel.textAlignment = .center
        
        // Blood Progress - Улучшенный стильный дизайн
        bloodProgressView.trackTintColor = UIColor(red: 0.15, green: 0.03, blue: 0.03, alpha: 0.95)
        bloodProgressView.progressTintColor = UIColor(red: 1.0, green: 0.28, blue: 0.18, alpha: 1.0)
        bloodProgressView.layer.cornerRadius = 5
        bloodProgressView.clipsToBounds = true
        bloodProgressView.progress = 0.5
        bloodProgressView.isHidden = false
        
        // Добавляем рамку для визуального выделения
        bloodProgressView.layer.borderColor = UIColor(red: 1.0, green: 0.35, blue: 0.2, alpha: 0.3).cgColor
        bloodProgressView.layer.borderWidth = 0.3
        
        // Coin Image
        coinImageView.contentMode = .scaleAspectFit
        coinImageView.tintColor = .green
        coinImageView.image = UIImage(systemName: "cedisign")
        
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
        
        // Add items in order to the stack view - сначала базовые элементы
        contentStackView.addArrangedSubview(dayNightImageView)
        contentStackView.addArrangedSubview(timeLabel)
        contentStackView.addArrangedSubview(dayLabel)
        contentStackView.addArrangedSubview(sceneTypeImageView)
        contentStackView.addArrangedSubview(sceneNameLabel)
        
        // Далее блок NPC counter
        contentStackView.addArrangedSubview(peopleImageView)
        contentStackView.addArrangedSubview(peopleCountLabel)
        
        // Добавляем хороший отступ перед шкалами для визуального разделения
        let smallSpacer = UIView()
        smallSpacer.widthAnchor.constraint(equalToConstant: 12).isActive = true
        contentStackView.addArrangedSubview(smallSpacer)
        
        // Группа крови - плотное размещение элементов
        contentStackView.addArrangedSubview(bloodLabel)
        // Нет отступа между значением и шкалой
        contentStackView.addArrangedSubview(bloodProgressView)
        // Нет отступа между шкалой и иконкой
        contentStackView.addArrangedSubview(bloodImageView)
        
        // Добавляем разделитель между группами шкал
        let spacerBetweenBars = UIView()
        spacerBetweenBars.widthAnchor.constraint(equalToConstant: 12).isActive = true
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
        coinsSpacer.widthAnchor.constraint(equalToConstant: 10).isActive = true
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
        contentStackView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        // Set fixed sizes for images and progress bars
        let imageSize: CGFloat = 16  // Уменьшаем с 20 до 16
        let progressBarWidth: CGFloat = 80  // Уменьшаем с 100 до 80
        let healthBarWidth: CGFloat = 80  // Уменьшаем с 120 до 80
        
        // Задаем приоритеты и размеры элементов, начиная с наиболее важных
        
        // Название локации должно иметь большую важность и быть всегда видимым
        sceneNameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        sceneNameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        // Уменьшаем размер, чтобы уменьшить общую ширину
        sceneNameLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true  // Уменьшаем с 100 до 80
        sceneNameLabel.lineBreakMode = .byTruncatingTail
        
        // Остальные текстовые элементы с фиксированной шириной
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true  // Уменьшаем с 48 до 40
        
        dayLabel.setContentHuggingPriority(.required, for: .horizontal)
        dayLabel.widthAnchor.constraint(equalToConstant: 45).isActive = true  // Уменьшаем с 55 до 45
        
        peopleCountLabel.setContentHuggingPriority(.required, for: .horizontal)
        peopleCountLabel.widthAnchor.constraint(equalToConstant: 20).isActive = true  // Уменьшаем с 25 до 20
        
        awarenessLabel.setContentHuggingPriority(.required, for: .horizontal)
        awarenessLabel.widthAnchor.constraint(equalToConstant: 35).isActive = true  // Увеличиваем с 30 до 35
        
        bloodLabel.setContentHuggingPriority(.required, for: .horizontal)
        bloodLabel.widthAnchor.constraint(equalToConstant: 35).isActive = true  // Увеличиваем с 30 до 35
        
        coinValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        coinValueLabel.widthAnchor.constraint(equalToConstant: 35).isActive = true  // Уменьшаем с 45 до 35
        
        // Фиксируем размеры иконок
        [dayNightImageView, lockImageView, sceneTypeImageView, peopleImageView,
         awarenessImageView, bloodImageView, coinImageView].forEach { imageView in
            imageView.widthAnchor.constraint(equalToConstant: imageSize).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: imageSize).isActive = true
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
        
        // Увеличиваем приоритет и ширину для прогресс-бара крови (здоровья)
        bloodProgressView.setContentHuggingPriority(.defaultLow + 5, for: .horizontal) // Снижаем с 10 до 5 чтобы обе шкалы имели равный приоритет
        bloodProgressView.setContentCompressionResistancePriority(.required - 10, for: .horizontal) // Снижаем приоритет сжатия
        // Устанавливаем фиксированную ширину для шкалы здоровья с высоким приоритетом
        let bloodWidthConstraint = bloodProgressView.widthAnchor.constraint(equalToConstant: healthBarWidth)
        bloodWidthConstraint.priority = .defaultHigh // Снижаем с required-1 до defaultHigh
        bloodWidthConstraint.isActive = true
        
        // Задаем минимальную ширину для прогресс-бара здоровья, чтобы он всегда был виден
        bloodProgressView.widthAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true // Уменьшаем с 80 до 50
        
        // Фиксированный размер для кнопок отладки с приоритетом
        [respawnButton, resetAwarenessButton, resetBloodButton, 
         resetDesiresButton, maxAchievementsButton, debugOverlayButton].forEach { button in
            button.widthAnchor.constraint(equalToConstant: imageSize).isActive = true
            button.heightAnchor.constraint(equalToConstant: imageSize).isActive = true
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
                self?.animateTextChange(for: self?.timeLabel, to: " \(hour):00")
            }
            .store(in: &cancellables)
        
        viewModel.$currentDay
            .sink { [weak self] day in
                self?.animateTextChange(for: self?.dayLabel, to: "Day \(day)")
            }
            .store(in: &cancellables)
        
        viewModel.$currentScene
            .sink { [weak self] scene in
                self?.updateSceneUI(scene: scene)
            }
            .store(in: &cancellables)
        
        viewModel.$npcs
            .sink { [weak self] npcs in
                self?.animateTextChange(for: self?.peopleCountLabel, to: "\(npcs.count)")
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
        timeLabel.text = " \(viewModel.currentHour):00"
        dayLabel.text = "Day \(viewModel.currentDay)"
        updateSceneUI(scene: viewModel.currentScene)
        peopleCountLabel.text = "\(viewModel.npcs.count)"
        updateAwarenessUI(level: awarenessService.awarenessLevel)
        
        // Обязательно обновляем значение для шкалы здоровья
        let bloodValue = playerBloodMeter?.bloodPercentage ?? 0
        updateBloodUI(percentage: bloodValue)
        
        coinValueLabel.text = "\(viewModel.playerCoinsValue)"
        
        // Явно устанавливаем видимость для всех элементов
        bloodImageView.isHidden = false
        bloodLabel.isHidden = false
        bloodProgressView.isHidden = false
    }
    
    private func updateDayNightUI(isNight: Bool) {
        // Анимируем смену иконки день/ночь
        UIView.transition(with: dayNightImageView, duration: animationDuration, options: .transitionCrossDissolve, animations: {
            self.dayNightImageView.image = UIImage(systemName: isNight ? "moon.fill" : "sun.max.fill")
            self.dayNightImageView.tintColor = isNight ? .white : .yellow
        }, completion: nil)
    }
    
    private func updateSceneUI(scene: Scene?) {
        // Анимируем изменение иконки локации
        UIView.animate(withDuration: animationDuration) {
            self.lockImageView.alpha = scene?.isLocked == true ? 1.0 : 0.0
        } completion: { _ in
            self.lockImageView.isHidden = scene?.isLocked != true
        }
        
        UIView.transition(with: sceneTypeImageView, duration: animationDuration, options: .transitionCrossDissolve, animations: {
            self.sceneTypeImageView.image = UIImage(systemName: scene?.sceneType.iconName ?? "")
        }, completion: nil)
        
        animateTextChange(for: sceneNameLabel, to: scene?.name ?? "Unknown")
    }
    
    private func updateAwarenessUI(level: Float) {
        // Анимируем изменения awareness
        animateTextChange(for: awarenessLabel, to: "\(Int(level))%")
        
        // Явно устанавливаем видимость прогресс-бара
        awarenessProgressView.isHidden = false
        
        // Изменяем цвет в зависимости от уровня
        UIView.animate(withDuration: animationDuration) {
            if level > 70 {
                // Опасный уровень - более яркий красноватый цвет
                self.awarenessProgressView.progressTintColor = UIColor(red: 0.8, green: 0.15, blue: 0.7, alpha: 1.0)
            } else if level > 40 {
                // Средний уровень - стандартный фиолетовый цвет
                self.awarenessProgressView.progressTintColor = UIColor(red: 0.65, green: 0.28, blue: 0.95, alpha: 1.0)
            } else {
                // Безопасный уровень - более спокойный фиолетовый
                self.awarenessProgressView.progressTintColor = UIColor(red: 0.5, green: 0.25, blue: 0.75, alpha: 1.0)
            }
        }
        
        // Плавно анимируем прогресс бар
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut) {
            self.awarenessProgressView.setProgress(level / 100.0, animated: true)
        }
        
        // После анимации принудительно обновляем состояние
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            self.awarenessProgressView.setNeedsDisplay()
            self.awarenessProgressView.layoutIfNeeded()
        }
    }
    
    private func updateBloodUI(percentage: Float) {
        // Анимируем изменения blood meter
        animateTextChange(for: bloodLabel, to: "\(Int(percentage))%")
        
        // Явно устанавливаем видимость прогресс-бара
        bloodProgressView.isHidden = false
        
        // Изменяем цвет в зависимости от уровня
        UIView.animate(withDuration: animationDuration) {
            if percentage < 30 {
                // Опасно низкий уровень - более темный красный
                self.bloodProgressView.progressTintColor = UIColor(red: 0.8, green: 0.15, blue: 0.15, alpha: 1.0)
            } else if percentage < 50 {
                // Средний уровень - стандартный красный
                self.bloodProgressView.progressTintColor = UIColor(red: 1.0, green: 0.2, blue: 0.15, alpha: 1.0)
            } else {
                // Высокий уровень - более яркий красный
                self.bloodProgressView.progressTintColor = UIColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 1.0)
            }
        }
        
        // Плавно анимируем прогресс бар
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut) {
            self.bloodProgressView.setProgress(percentage / 100.0, animated: true)
        }
        
        // После анимации принудительно обновляем состояние
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            self.bloodProgressView.setNeedsDisplay()
            self.bloodProgressView.layoutIfNeeded()
        }
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
        
        // Принудительно обновляем bloodProgressView для гарантии его видимости
        bloodProgressView.isHidden = false
        awarenessProgressView.isHidden = false
        bloodProgressView.setNeedsDisplay()
        bloodProgressView.layoutIfNeeded()
        awarenessProgressView.setNeedsDisplay()
        awarenessProgressView.layoutIfNeeded()
    }
    
    // После полной загрузки интерфейса проверяем видимость элементов 
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Повторно проверяем и обновляем UI элементы
        bloodProgressView.isHidden = false
        awarenessProgressView.isHidden = false
        
        // Обновляем значения прогресс-баров
        if let bloodPercentage = playerBloodMeter?.bloodPercentage {
            bloodProgressView.progress = bloodPercentage / 100.0
        }
        
        // Обновляем шкалу awareness
        let awarenessLevel = awarenessService.awarenessLevel
        awarenessProgressView.progress = awarenessLevel / 100.0
        
        // Принудительно обновляем UI
        bloodProgressView.setNeedsDisplay()
        bloodProgressView.layoutIfNeeded()
        awarenessProgressView.setNeedsDisplay() 
        awarenessProgressView.layoutIfNeeded()
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
