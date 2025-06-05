import UIKit
import SwiftUI
import Combine

class AbilitiesViewController: UIViewController {
    private let scene: Scene
    private let mainViewModel: MainSceneViewModel
    
    // Background components
    private let backgroundImageView = UIImageView()
    private var dustEffectView: UIHostingController<DustEmitterView>?
    
    // Top widget
    private let topWidgetContainerView = UIView()
    private var topWidgetViewController: TopWidgetUIViewController?
    
    // Abilities container (левый столбец)
    private let abilitiesContainerView = UIView()
    private var currentCategoryIndex = 0
    
    // Statistics container
    private let statisticsContainerView = UIView()
    
    // Services
    private let statisticsService = StatisticsService.shared
    private let abilitiesSystem = AbilitiesSystem.shared
    
    // Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(scene: Scene, mainViewModel: MainSceneViewModel) {
        self.scene = scene
        self.mainViewModel = mainViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.clipsToBounds = false
        
        setupBackground()
        setupTopWidget()
        setupAbilitiesContainer()
        setupStatisticsContainer()
        setupLayout()
        setupObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupStatisticsContent()
        setupAbilitiesContent()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Background и dust effect теперь управляются constraints - никаких костылей не нужно
    }
    
    // MARK: - Setup Methods
    
    private func setupBackground() {
        // Background image
        backgroundImageView.image = UIImage(named: "vampiricWall")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = false
        backgroundImageView.alpha = 0.7
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        
        // Привязываем к полному размеру view (не safe area) с небольшим отступом для покрытия всех краев
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: -20),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -20),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20)
        ])
        
        // Dust effect
        let dustViewHostingController = UIHostingController(rootView: DustEmitterView())
        dustViewHostingController.view.backgroundColor = .clear
        dustViewHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(dustViewHostingController)
        view.insertSubview(dustViewHostingController.view, aboveSubview: backgroundImageView)
        
        NSLayoutConstraint.activate([
            dustViewHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            dustViewHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dustViewHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dustViewHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        dustViewHostingController.didMove(toParent: self)
        self.dustEffectView = dustViewHostingController
    }
    
    private func setupTopWidget() {
        topWidgetContainerView.backgroundColor = .clear
        view.addSubview(topWidgetContainerView)
        
        let widgetVC = TopWidgetUIViewController(viewModel: mainViewModel)
        addChild(widgetVC)
        topWidgetContainerView.addSubview(widgetVC.view)
        widgetVC.didMove(toParent: self)
        self.topWidgetViewController = widgetVC
    }
    
    private func setupAbilitiesContainer() {
        abilitiesContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        abilitiesContainerView.layer.cornerRadius = 12
        abilitiesContainerView.clipsToBounds = false // Не обрезаем свечение
        view.addSubview(abilitiesContainerView)
    }
    
    private func setupStatisticsContainer() {
        statisticsContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        statisticsContainerView.layer.cornerRadius = 12
        view.addSubview(statisticsContainerView)
    }
    
    private func setupLayout() {
        topWidgetContainerView.translatesAutoresizingMaskIntoConstraints = false
        topWidgetViewController?.view.translatesAutoresizingMaskIntoConstraints = false
        abilitiesContainerView.translatesAutoresizingMaskIntoConstraints = false
        statisticsContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Top widget
            topWidgetContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topWidgetContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topWidgetContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            topWidgetContainerView.heightAnchor.constraint(equalToConstant: 35),
            
            // Top widget content
            topWidgetViewController!.view.topAnchor.constraint(equalTo: topWidgetContainerView.topAnchor),
            topWidgetViewController!.view.leadingAnchor.constraint(equalTo: topWidgetContainerView.leadingAnchor),
            topWidgetViewController!.view.trailingAnchor.constraint(equalTo: topWidgetContainerView.trailingAnchor),
            topWidgetViewController!.view.bottomAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor),
            
            // Abilities container (левая сторона экрана)
            abilitiesContainerView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 20),
            abilitiesContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            abilitiesContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.55),
            abilitiesContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Statistics container (правая сторона экрана)
            statisticsContainerView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 20),
            statisticsContainerView.leadingAnchor.constraint(equalTo: abilitiesContainerView.trailingAnchor, constant: 20),
            statisticsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statisticsContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupObservers() {
        // Observe statistics changes
        statisticsService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateStatisticsContent()
            }
            .store(in: &cancellables)
        
        // Observe abilities changes
        abilitiesSystem.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.setupAbilitiesContent()
            }
            .store(in: &cancellables)
    }
    
    private func setupStatisticsContent() {
        // Заголовок
        let titleLabel = UILabel()
        titleLabel.text = "Statistics"
        titleLabel.font = UIFont(name: "Optima-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .systemRed
        titleLabel.textAlignment = .center
        titleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        titleLabel.layer.cornerRadius = 8
        titleLabel.clipsToBounds = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        statisticsContainerView.addSubview(titleLabel)
        
        // ScrollView для статистик
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        statisticsContainerView.addSubview(scrollView)
        
        // Content view
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Главный StackView для всех категорий статистик
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.spacing = 12
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStackView)
        
        // Survival Stats
        let survivalSection = createStatSection(
            title: "Survival",
            stats: [
                ("Days Survived", "\(statisticsService.daysSurvived)"),
                ("Times Arrested", "\(statisticsService.timesArrested)"),
                ("Disappearances", "\(statisticsService.disappearances)")
            ],
            color: .systemGreen
        )
        mainStackView.addArrangedSubview(survivalSection)
        
        // Feeding Stats
        let feedingSection = createStatSection(
            title: "Feeding",
            stats: [
                ("Total Feedings", "\(statisticsService.feedings)"),
                ("Victims Drained", "\(statisticsService.victimsDrained)"),
                ("People Killed", "\(statisticsService.peopleKilled)"),
                ("Sleeping Victims", "\(statisticsService.feedingsOverSleepingVictims)"),
                ("Desired Victims", "\(statisticsService.feedingsOverDesiredVictims)"),
                ("Food Consumed", "\(statisticsService.foodConsumed)")
            ],
            color: .systemRed
        )
        mainStackView.addArrangedSubview(feedingSection)
        
        // Social Stats
        let socialSection = createStatSection(
            title: "Social",
            stats: [
                ("People Seduced", "\(statisticsService.peopleSeducted)"),
                ("People Dominated", "\(statisticsService.peopleDominated)"),
                ("Bribes Paid", "\(statisticsService.bribes)"),
                ("Investigations", "\(statisticsService.investigations)"),
                ("Friendships Created", "\(statisticsService.friendshipsCreated)"),
                ("Allies Created", "\(statisticsService.alliesCreated)"),
                ("Nights With Someone", "\(statisticsService.nightSpentsWithSomeone)")
            ],
            color: .systemBlue
        )
        mainStackView.addArrangedSubview(socialSection)
        
        // Commerce Stats
        let commerceSection = createStatSection(
            title: "Commerce",
            stats: [
                ("Barters Completed", "\(statisticsService.bartersCompleted)"),
                ("500+ Coins Deals", "\(statisticsService._500CoinsDeals)"),
                ("1000+ Coins Deals", "\(statisticsService._1000CoinsDeals)"),
                ("Properties Bought", "\(statisticsService.propertiesBought)")
            ],
            color: .systemPurple
        )
        mainStackView.addArrangedSubview(commerceSection)
        
        // Crafting Stats
        let craftingSection = createStatSection(
            title: "Crafting",
            stats: [
                ("Smithing Recipes", "\(statisticsService.smithingRecipesUnlocked)"),
                ("Alchemy Recipes", "\(statisticsService.alchemyRecipesUnlocked)")
            ],
            color: .systemOrange
        )
        mainStackView.addArrangedSubview(craftingSection)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: statisticsContainerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: statisticsContainerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: statisticsContainerView.trailingAnchor, constant: -16),
            titleLabel.heightAnchor.constraint(equalToConstant: 40),
            
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: statisticsContainerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: statisticsContainerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: statisticsContainerView.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Main stack view
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func createStatSection(title: String, stats: [(String, String)], color: UIColor) -> UIView {
        let sectionView = UIView()
        
        // Заголовок секции
        let sectionTitleLabel = UILabel()
        sectionTitleLabel.text = title
        sectionTitleLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .semibold)
        sectionTitleLabel.textColor = color
        sectionTitleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        sectionTitleLabel.textAlignment = .center
        sectionTitleLabel.layer.cornerRadius = 4
        sectionTitleLabel.clipsToBounds = true
        sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        sectionView.addSubview(sectionTitleLabel)
        
        // StackView для статистик
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        sectionView.addSubview(stackView)
        
        for stat in stats {
            let statView = createSimpleStatView(name: stat.0, value: stat.1)
            stackView.addArrangedSubview(statView)
        }
        
        NSLayoutConstraint.activate([
            sectionTitleLabel.topAnchor.constraint(equalTo: sectionView.topAnchor),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor),
            sectionTitleLabel.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor),
            sectionTitleLabel.heightAnchor.constraint(equalToConstant: 24),
            
            stackView.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 6),
            stackView.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: sectionView.bottomAnchor)
        ])
        
        return sectionView
    }
    
    private func createSimpleStatView(name: String, value: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        containerView.layer.cornerRadius = 6
        
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = UIFont(name: "Optima-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .medium)
        nameLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont(name: "Optima-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12, weight: .bold)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(nameLabel)
        containerView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            valueLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 8),
            
            containerView.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        return containerView
    }
    
    private func updateStatisticsContent() {
        // Обновляем статистики при изменении данных
        setupStatisticsContent()
    }
    
    private func setupAbilitiesContent() {
        // Очищаем предыдущий контент
        abilitiesContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        // Создаем табы
        let tabsStackView = UIStackView()
        tabsStackView.axis = .horizontal
        tabsStackView.distribution = .fillEqually
        tabsStackView.spacing = 0
        tabsStackView.translatesAutoresizingMaskIntoConstraints = false
        abilitiesContainerView.addSubview(tabsStackView)
        
        let tabTitles = ["Vampiric Powers", "Social Skills", "Crafting Skills"]
        for (index, title) in tabTitles.enumerated() {
            let tabView = createTabButton(title: title, index: index)
            tabsStackView.addArrangedSubview(tabView)
        }
        
        // Контейнер для списка способностей
        let contentScrollView = UIScrollView()
        contentScrollView.showsVerticalScrollIndicator = false
        contentScrollView.clipsToBounds = true // Возвращаем обрезание для самого скролла
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        abilitiesContainerView.addSubview(contentScrollView)
        
        // Контейнер для свечения (позволяет свечению выходить за границы)
        let shadowContainerView = UIView()
        shadowContainerView.clipsToBounds = false
        shadowContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentScrollView.addSubview(shadowContainerView)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        shadowContainerView.addSubview(contentView)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16 // Увеличиваем расстояние между карточками для свечения
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        // Добавляем способности для текущей категории
        let abilities = getAbilitiesForCategory(currentCategoryIndex)
        for ability in abilities {
            let abilityView = createAbilityCard(ability: ability)
            stackView.addArrangedSubview(abilityView)
        }
        
        // Constraints
        NSLayoutConstraint.activate([
            // Tabs
            tabsStackView.topAnchor.constraint(equalTo: abilitiesContainerView.topAnchor, constant: 16),
            tabsStackView.leadingAnchor.constraint(equalTo: abilitiesContainerView.leadingAnchor, constant: 16),
            tabsStackView.trailingAnchor.constraint(equalTo: abilitiesContainerView.trailingAnchor, constant: -16),
            tabsStackView.heightAnchor.constraint(equalToConstant: 40),
            
            // Content scroll view
            contentScrollView.topAnchor.constraint(equalTo: tabsStackView.bottomAnchor, constant: 16),
            contentScrollView.leadingAnchor.constraint(equalTo: abilitiesContainerView.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: abilitiesContainerView.trailingAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: abilitiesContainerView.bottomAnchor),
            
            // Shadow container view
            shadowContainerView.topAnchor.constraint(equalTo: contentScrollView.topAnchor),
            shadowContainerView.leadingAnchor.constraint(equalTo: contentScrollView.leadingAnchor),
            shadowContainerView.trailingAnchor.constraint(equalTo: contentScrollView.trailingAnchor),
            shadowContainerView.bottomAnchor.constraint(equalTo: contentScrollView.bottomAnchor),
            shadowContainerView.widthAnchor.constraint(equalTo: contentScrollView.widthAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: shadowContainerView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: shadowContainerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: shadowContainerView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: shadowContainerView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: shadowContainerView.widthAnchor),
            
            // Stack view
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func createTabButton(title: String, index: Int) -> UIView {
        let isSelected = currentCategoryIndex == index
        
        // Определяем цвет и иконку для каждой категории
        let (color, icon): (UIColor, String) = {
            switch index {
            case 0: return (.systemRed, "flame") // Vampiric Powers
            case 1: return (.systemBlue, "person.2") // Social Skills
            case 2: return (.systemOrange, "hammer") // Crafting Skills
            default: return (.white, "questionmark")
            }
        }()
        
        // Создаем контейнер для таба
        let tabContainer = UIView()
        tabContainer.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: isSelected ? 0.8 : 0.6)
        tabContainer.layer.cornerRadius = 8
        tabContainer.layer.borderWidth = isSelected ? 1.0 : 0.3
        tabContainer.layer.borderColor = color.withAlphaComponent(isSelected ? 0.8 : 0.3).cgColor
        
        // Свечение для контейнера
        if isSelected {
            tabContainer.layer.shadowColor = color.cgColor
            tabContainer.layer.shadowRadius = 8
            tabContainer.layer.shadowOpacity = 0.6
            tabContainer.layer.shadowOffset = .zero
        } else {
            tabContainer.layer.shadowColor = color.cgColor
            tabContainer.layer.shadowRadius = 4
            tabContainer.layer.shadowOpacity = 0.2
            tabContainer.layer.shadowOffset = .zero
        }
        
        // Радиальное свечение под иконкой
        let iconGlowView = UIImageView()
        iconGlowView.translatesAutoresizingMaskIntoConstraints = false
        iconGlowView.image = makeRadialGlowImage(size: CGSize(width: 24, height: 24), color: color)
        iconGlowView.contentMode = .scaleAspectFill
        iconGlowView.alpha = isSelected ? 0.8 : 0.4
        
        // Иконка
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = isSelected ? color : color.withAlphaComponent(0.7)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Свечение для иконки
        iconImageView.layer.shadowColor = color.cgColor
        iconImageView.layer.shadowRadius = isSelected ? 3 : 1
        iconImageView.layer.shadowOpacity = isSelected ? 0.5 : 0.2
        iconImageView.layer.shadowOffset = .zero
        
        // Добавляем glow под иконку
        iconImageView.addSubview(iconGlowView)
        iconImageView.sendSubviewToBack(iconGlowView)
        
        // Название таба
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont(name: "Optima-Regular", size: 11) ?? UIFont.systemFont(ofSize: 11)
        titleLabel.textColor = isSelected ? color : color.withAlphaComponent(0.7)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Тень для текста
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOpacity = 0.7
        titleLabel.layer.shadowRadius = 1
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        
        // Основной StackView
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(titleLabel)
        
        tabContainer.addSubview(stackView)
        
        // Создаем кнопку для обработки нажатий
        let button = UIButton()
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = index
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        
        // Добавляем анимации для кнопки
        button.addTarget(self, action: #selector(animateTabDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(animateTabUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        tabContainer.addSubview(button)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Иконка
            iconImageView.widthAnchor.constraint(equalToConstant: 14),
            iconImageView.heightAnchor.constraint(equalToConstant: 14),
            
            // Glow под иконкой
            iconGlowView.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
            iconGlowView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            iconGlowView.widthAnchor.constraint(equalTo: iconImageView.widthAnchor, constant: 10),
            iconGlowView.heightAnchor.constraint(equalTo: iconImageView.heightAnchor, constant: 10),
            
            // StackView
            stackView.centerXAnchor.constraint(equalTo: tabContainer.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: tabContainer.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: tabContainer.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: tabContainer.trailingAnchor, constant: -8),
            
            // Кнопка
            button.topAnchor.constraint(equalTo: tabContainer.topAnchor),
            button.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor)
        ])
        
        return tabContainer
    }
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        currentCategoryIndex = sender.tag
        setupAbilitiesContent() // Перезагружаем контент
    }
    
    @objc private func animateTabDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.08, delay: 0, options: [.curveEaseIn], animations: {
            sender.superview?.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }, completion: nil)
    }
    
    @objc private func animateTabUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 3, options: [], animations: {
            sender.superview?.transform = .identity
        }, completion: nil)
    }
    
    private func getAbilitiesForCategory(_ categoryIndex: Int) -> [Ability] {
        switch categoryIndex {
        case 0: // Vampiric Powers
            return [
                .seduction,
                .domination,
                .whisper,
                .command,
                .enthralling,
                .invisibility,
                .dayWalker,
                .lordOfBlood,
                .masquerade,
                .memoryErasure,
                .undeadCasanova,
                .sonOfDracula,
                .lionAmongSheep
            ]
        case 1: // Social Skills
            return [
                .bribe,
                .trader,
                .unholyTongue,
                .mysteriousPerson,
                .oldFriend,
                .insight,
                .dreamstealer,
                .kingSalamon,
                .noble
            ]
        case 2: // Crafting Skills
            return [
                .smithingNovice,
                .smithingApprentice,
                .smithingExpert,
                .smithingMaster,
                .alchemyNovice,
                .alchemyApprentice,
                .alchemyExpert,
                .alchemyMaster
            ]
        default:
            return []
        }
    }
    
    private func createAbilityCard(ability: Ability) -> UIView {
        let isUnlocked = abilitiesSystem.playerAbilities.contains(ability)
        let canUnlock = abilitiesSystem.canUnlock(ability)
        let progress = calculateAbilityProgress(ability)
        let abilityColor = convertSwiftUIColorToUIColor(ability.color)
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        
        if isUnlocked {
            // Разблокированная способность
            containerView.layer.borderColor = abilityColor.cgColor
            containerView.layer.shadowColor = abilityColor.cgColor
            containerView.layer.shadowOffset = CGSize(width: 0, height: 0)
            containerView.layer.shadowRadius = 12
            containerView.layer.shadowOpacity = 0.7
        } else if canUnlock {
            // Готова к разблокировке
            containerView.layer.borderColor = abilityColor.withAlphaComponent(0.8).cgColor
            containerView.layer.shadowColor = abilityColor.cgColor
            containerView.layer.shadowOffset = CGSize(width: 0, height: 0)
            containerView.layer.shadowRadius = 8
            containerView.layer.shadowOpacity = 0.5
        } else {
            // Заблокированная - тоже со свечением, но слабее
            containerView.layer.borderColor = abilityColor.withAlphaComponent(0.3).cgColor
            containerView.layer.shadowColor = abilityColor.cgColor
            containerView.layer.shadowOffset = CGSize(width: 0, height: 0)
            containerView.layer.shadowRadius = 4
            containerView.layer.shadowOpacity = 0.2
        }
        
        // Главный StackView (вертикальный)
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.spacing = 8
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Верхняя часть (иконка + название)
        let topRowStack = UIStackView()
        topRowStack.axis = .horizontal
        topRowStack.spacing = 8
        topRowStack.alignment = .center
        topRowStack.distribution = .fill
        
        // Радиальное свечение под иконкой (улучшенное)
        let iconGlowView = UIImageView()
        iconGlowView.translatesAutoresizingMaskIntoConstraints = false
        iconGlowView.image = makeRadialGlowImage(size: CGSize(width: 40, height: 40), color: abilityColor)
        iconGlowView.contentMode = .scaleAspectFill
        iconGlowView.alpha = isUnlocked ? 0.8 : (canUnlock ? 0.6 : 0.3)
        
        // Иконка способности
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: ability.icon)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = isUnlocked ? abilityColor : (canUnlock ? abilityColor.withAlphaComponent(0.7) : .gray)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Свечение для иконки
        iconImageView.layer.shadowColor = abilityColor.cgColor
        iconImageView.layer.shadowRadius = 3
        iconImageView.layer.shadowOpacity = isUnlocked ? 0.7 : (canUnlock ? 0.5 : 0.2)
        iconImageView.layer.shadowOffset = .zero
        
        // Добавляем glow под иконку
        iconImageView.addSubview(iconGlowView)
        iconImageView.sendSubviewToBack(iconGlowView)
        
        // Название способности
        let nameLabel = UILabel()
        nameLabel.text = ability.name
        nameLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = isUnlocked ? abilityColor : (canUnlock ? abilityColor.withAlphaComponent(0.8) : .lightGray)
        nameLabel.numberOfLines = 2
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        // Тень для текста
        nameLabel.layer.shadowColor = UIColor.black.cgColor
        nameLabel.layer.shadowOpacity = 0.7
        nameLabel.layer.shadowRadius = 1
        nameLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        
        topRowStack.addArrangedSubview(iconImageView)
        topRowStack.addArrangedSubview(nameLabel)
        
        // Прогресс-бар контейнер (всегда видимый)
        let progressContainer = UIView()
        progressContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        progressContainer.layer.cornerRadius = 4
        progressContainer.layer.borderWidth = 0.5
        progressContainer.layer.borderColor = abilityColor.withAlphaComponent(0.3).cgColor
        progressContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Прогресс-бар заполнение
        let progressBar = UIView()
        progressBar.backgroundColor = abilityColor.withAlphaComponent(isUnlocked ? 1.0 : 0.8)
        progressBar.layer.cornerRadius = 3
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        
        // Свечение для прогресс-бара (только если есть прогресс)
        if progress > 0 {
            progressBar.layer.shadowColor = abilityColor.cgColor
            progressBar.layer.shadowRadius = 2
            progressBar.layer.shadowOpacity = 0.6
            progressBar.layer.shadowOffset = .zero
        }
        
        progressContainer.addSubview(progressBar)
        
        // Текст прогресса
        let progressLabel = UILabel()
        progressLabel.text = formatProgressText(ability, progress: progress, isUnlocked: isUnlocked, canUnlock: canUnlock)
        progressLabel.font = UIFont(name: "Optima-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10)
        progressLabel.textColor = isUnlocked ? .white : (canUnlock ? abilityColor.withAlphaComponent(0.9) : .lightGray)
        progressLabel.textAlignment = .center
        progressLabel.numberOfLines = 0
        
        // Тень для текста прогресса
        progressLabel.layer.shadowColor = UIColor.black.cgColor
        progressLabel.layer.shadowOpacity = 0.8
        progressLabel.layer.shadowRadius = 1
        progressLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        
        // Описание способности
        let descriptionLabel = UILabel()
        descriptionLabel.text = ability.description
        descriptionLabel.font = UIFont(name: "Optima-Regular", size: 11) ?? UIFont.systemFont(ofSize: 11)
        descriptionLabel.textColor = isUnlocked ? UIColor.white.withAlphaComponent(0.9) : UIColor.lightGray.withAlphaComponent(0.7)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        // Собираем все вместе
        mainStackView.addArrangedSubview(topRowStack)
        mainStackView.addArrangedSubview(progressContainer)
        mainStackView.addArrangedSubview(progressLabel)
        mainStackView.addArrangedSubview(descriptionLabel)
        
        containerView.addSubview(mainStackView)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Контейнер
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            // Иконка
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Glow под иконкой (больше размер)
            iconGlowView.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
            iconGlowView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            iconGlowView.widthAnchor.constraint(equalTo: iconImageView.widthAnchor, constant: 20),
            iconGlowView.heightAnchor.constraint(equalTo: iconImageView.heightAnchor, constant: 20),
            
            // Прогресс контейнер
            progressContainer.heightAnchor.constraint(equalToConstant: 8),
            
            // Прогресс-бар (убираем минимальное заполнение)
            progressBar.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor),
            progressBar.topAnchor.constraint(equalTo: progressContainer.topAnchor),
            progressBar.bottomAnchor.constraint(equalTo: progressContainer.bottomAnchor),
            progressBar.widthAnchor.constraint(equalTo: progressContainer.widthAnchor, multiplier: progress), // убрали max(0.05, progress)
            
            // Главный StackView
            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        return containerView
    }
    
    private func calculateAbilityProgress(_ ability: Ability) -> CGFloat {
        let stats = StatisticsService.shared
        let isUnlocked = abilitiesSystem.playerAbilities.contains(ability)
        
        if isUnlocked {
            return 1.0
        }
        
        switch ability {
        case .seduction:
            let sleepingProgress = min(1.0, CGFloat(stats.feedingsOverSleepingVictims) / 5.0)
            let desiredProgress = min(1.0, CGFloat(stats.feedingsOverDesiredVictims) / 1.0)
            return (sleepingProgress + desiredProgress) / 2.0
            
        case .domination:
            let bribeProgress = min(1.0, CGFloat(stats.bribes) / 5.0)
            let seductionProgress = min(1.0, CGFloat(stats.peopleSeducted) / 5.0)
            let desiredProgress = min(1.0, CGFloat(stats.feedingsOverDesiredVictims) / 3.0)
            let drainProgress = min(1.0, CGFloat(stats.victimsDrained) / 1.0)
            return (bribeProgress + seductionProgress + desiredProgress + drainProgress) / 4.0
            
        case .command:
            let seductionProgress = min(1.0, CGFloat(stats.peopleSeducted) / 5.0)
            let desiredProgress = min(1.0, CGFloat(stats.feedingsOverDesiredVictims) / 5.0)
            return (seductionProgress + desiredProgress) / 2.0
            
        case .enthralling:
            let dominationProgress = min(1.0, CGFloat(stats.peopleDominated) / 10.0)
            let desiredProgress = min(1.0, CGFloat(stats.feedingsOverDesiredVictims) / 10.0)
            let drainProgress = min(1.0, CGFloat(stats.victimsDrained) / 5.0)
            let propertyProgress = min(1.0, CGFloat(stats.propertiesBought) / 1.0)
            return (dominationProgress + desiredProgress + drainProgress + propertyProgress) / 4.0
            
        case .smithingNovice:
            return min(1.0, CGFloat(stats.smithingRecipesUnlocked) / 10.0)
        case .smithingApprentice:
            return min(1.0, CGFloat(stats.smithingRecipesUnlocked) / 20.0)
        case .smithingExpert:
            return min(1.0, CGFloat(stats.smithingRecipesUnlocked) / 40.0)
        case .smithingMaster:
            return min(1.0, CGFloat(stats.smithingRecipesUnlocked) / 60.0)
            
        case .alchemyNovice:
            return min(1.0, CGFloat(stats.alchemyRecipesUnlocked) / 10.0)
        case .alchemyApprentice:
            return min(1.0, CGFloat(stats.alchemyRecipesUnlocked) / 20.0)
        case .alchemyExpert:
            return min(1.0, CGFloat(stats.alchemyRecipesUnlocked) / 40.0)
        case .alchemyMaster:
            return min(1.0, CGFloat(stats.alchemyRecipesUnlocked) / 60.0)
            
        case .bribe:
            return min(1.0, CGFloat(stats._500CoinsDeals) / 10.0)
        case .trader:
            return min(1.0, CGFloat(stats._1000CoinsDeals) / 20.0)
            
        case .invisibility:
            let daysProgress = min(1.0, CGFloat(stats.daysSurvived) / 5.0)
            let seductionProgress = min(1.0, CGFloat(stats.peopleSeducted) / 10.0)
            let desiredProgress = min(1.0, CGFloat(stats.feedingsOverDesiredVictims) / 5.0)
            return (daysProgress + seductionProgress + desiredProgress) / 3.0
            
        case .whisper:
            let daysProgress = min(1.0, CGFloat(stats.daysSurvived) / 10.0)
            let seductionProgress = min(1.0, CGFloat(stats.peopleSeducted) / 15.0)
            let desiredProgress = min(1.0, CGFloat(stats.feedingsOverDesiredVictims) / 10.0)
            return (daysProgress + seductionProgress + desiredProgress) / 3.0
            
        case .dayWalker:
            let daysProgress = min(1.0, CGFloat(stats.daysSurvived) / 10.0)
            let desiredProgress = min(1.0, CGFloat(stats.feedingsOverDesiredVictims) / 10.0)
            let drainProgress = min(1.0, CGFloat(stats.victimsDrained) / 3.0)
            return (daysProgress + desiredProgress + drainProgress) / 3.0
            
        case .lordOfBlood:
            let daysProgress = min(1.0, CGFloat(stats.daysSurvived) / 30.0)
            let desiredProgress = min(1.0, CGFloat(stats.feedingsOverDesiredVictims) / 30.0)
            let dominationProgress = min(1.0, CGFloat(stats.peopleDominated) / 30.0)
            return (daysProgress + desiredProgress + dominationProgress) / 3.0
            
        case .masquerade:
            let daysProgress = min(1.0, CGFloat(stats.daysSurvived) / 30.0)
            let foodProgress = min(1.0, CGFloat(stats.foodConsumed) / 100.0)
            let seductionProgress = min(1.0, CGFloat(stats.peopleSeducted) / 20.0)
            return (daysProgress + foodProgress + seductionProgress) / 3.0
            
        case .unholyTongue:
            return min(1.0, CGFloat(stats.bribes) / 20.0)
            
        case .mysteriousPerson:
            let bribeProgress = min(1.0, CGFloat(stats.bribes) / 10.0)
            let barterProgress = min(1.0, CGFloat(stats.bartersCompleted) / 20.0)
            return (bribeProgress + barterProgress) / 2.0
            
        case .memoryErasure:
            let daysProgress = min(1.0, CGFloat(stats.daysSurvived) / 40.0)
            let dominationProgress = min(1.0, CGFloat(stats.peopleDominated) / 20.0)
            return (daysProgress + dominationProgress) / 2.0
            
        case .oldFriend:
            return min(1.0, CGFloat(stats.friendshipsCreated) / 5.0)
            
        case .undeadCasanova:
            let friendshipProgress = min(1.0, CGFloat(stats.friendshipsCreated) / 15.0)
            let nightProgress = min(1.0, CGFloat(stats.nightSpentsWithSomeone) / 20.0)
            let desiredProgress = min(1.0, CGFloat(stats.feedingsOverDesiredVictims) / 20.0)
            return (friendshipProgress + nightProgress + desiredProgress) / 3.0
            
        case .sonOfDracula:
            let daysProgress = min(1.0, CGFloat(stats.daysSurvived) / 100.0)
            let drainProgress = min(1.0, CGFloat(stats.victimsDrained) / 50.0)
            return (daysProgress + drainProgress) / 2.0
            
        case .insight:
            return min(1.0, CGFloat(stats.investigations) / 100.0)
            
        case .lionAmongSheep:
            let alliesProgress = min(1.0, CGFloat(stats.alliesCreated) / 10.0)
            let desiredProgress = min(1.0, CGFloat(stats.feedingsOverDesiredVictims) / 40.0)
            return (alliesProgress + desiredProgress) / 2.0
            
        case .dreamstealer:
            return min(1.0, CGFloat(stats.peopleSeducted) / 20.0)
            
        case .kingSalamon:
            return min(1.0, CGFloat(stats.peopleDominated) / 10.0)
            
        case .noble:
            return min(1.0, CGFloat(stats.friendshipsCreated) / 1.0)
        }
    }
    
    private func formatProgressText(_ ability: Ability, progress: CGFloat, isUnlocked: Bool, canUnlock: Bool) -> String {
        if isUnlocked {
            return "✓ UNLOCKED"
        }
        
        if canUnlock {
            return "★ READY TO UNLOCK"
        }
        
        let percentage = Int(progress * 100)
        return "Progress: \(percentage)%"
    }
    
    // Генерация radial alpha glow (улучшенная версия)
    private func makeRadialGlowImage(size: CGSize, color: UIColor) -> UIImage? {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        
        // Более интенсивный градиент
        let colors = [
            color.withAlphaComponent(0.5).cgColor,
            color.withAlphaComponent(0.3).cgColor,
            color.withAlphaComponent(0.1).cgColor,
            color.withAlphaComponent(0.0).cgColor
        ] as CFArray
        
        let center = CGPoint(x: size.width/2, y: size.height/2)
        let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.3, 0.7, 1])
        ctx.drawRadialGradient(grad!, startCenter: center, startRadius: 0, endCenter: center, endRadius: size.width/2, options: .drawsAfterEndLocation)
        
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img?.withRenderingMode(.alwaysOriginal)
    }
    
    // Метод для конвертации SwiftUI Color в UIColor
    private func convertSwiftUIColorToUIColor(_ color: Color) -> UIColor {
        if color == .red { return .systemRed }
        if color == .blue { return .systemBlue }
        if color == .green { return .systemGreen }
        if color == .purple { return .systemPurple }
        if color == .orange { return .systemOrange }
        if color == .yellow { return .systemYellow }
        if color == .pink { return .systemPink }
        if color == .cyan { return .systemCyan }
        if color == .mint { return .systemMint }
        if color == .teal { return .systemTeal }
        if color == .indigo { return .systemIndigo }
        return .white
    }
} 