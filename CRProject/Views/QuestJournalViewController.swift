import UIKit
import SwiftUI

// Допущение: У вас есть QuestService и модели Quest, QuestStage
// import QuestService // или как он у вас импортируется
// import QuestModels // или как они у вас импортируются

class QuestJournalViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Properties
    private var questService: QuestService = QuestService.shared
    private var activeQuests: [Quest] = []
    private var completedQuests: [Quest] = []
    private var selectedQuest: Quest?
    private let mainViewModel: MainSceneViewModel

    // UI Elements
    private let backgroundImageView = UIImageView()
    private var dustEffectView: UIHostingController<DustEmitterView>? // Для эффекта пыли
    private let topWidgetContainerView = UIView() // Контейнер для верхнего виджета
    private var topWidgetViewController: TopWidgetUIViewController? // Сам верхний виджет
    private let segmentedControl = UISegmentedControl(items: ["Active", "Completed"])
    private let questsTableView = UITableView()
    private let questDetailView = UIView() // Контейнер для деталей квеста
    private let questDetailScrollView = UIScrollView()
    private let questDetailContentView = UIView()
    private let questDetailIconView = UIView() // Иконка для заголовка квеста
    private let questTitleLabel = UILabel()
    private let questDescriptionView = UITextView() // UITextView для поддержки скролла если описание длинное
    private let currentObjectiveIconView = UIView() // Иконка для текущей цели
    private let currentObjectiveLabel = UILabel()
    private let questStagesTextView = UITextView() // Для отображения этапов квеста
    // Можно добавить другие UILabel для стадий, наград и т.д.

    // MARK: - Initializers (НОВЫЙ)
    init(mainViewModel: MainSceneViewModel) {
        self.mainViewModel = mainViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // self.view.backgroundColor = .clear // Убрали, так как будет фоновое изображение
        view.backgroundColor = .black // Черный фон как запасной вариант

        setupBackgroundImage() // Настройка фонового изображения
        setupTopWidget() // Настройка верхнего виджета
        setupDustEffect() // Настройка эффекта пыли
        setupStyles()
        setupViews()
        setupLayout()
        loadQuestData()
        setupSegmentedControlActions()
        
        // Устанавливаем первую вкладку по умолчанию
        segmentedControl.selectedSegmentIndex = 0
        filterQuests() // Показываем активные квесты при первом запуске
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Обновление frame для backgroundImageView с учетом extraSpace
        let extraSpace: CGFloat = 100 // Дополнительное пространство для растягивания фона
        backgroundImageView.frame = CGRect(
            x: -extraSpace / 2,
            y: -extraSpace / 2,
            width: view.bounds.width + extraSpace,
            height: view.bounds.height + extraSpace
        )
        // Убедимся, что фон всегда сзади
        view.sendSubviewToBack(backgroundImageView)
        // Устанавливаем frame для dustEffectView
        dustEffectView?.view.frame = view.bounds
        // Убедимся, что dustEffectView над фоном, но под остальными элементами (если нужно)
        // В LootView он добавляется последним из фоновых элементов, так что будет поверх backgroundImageView и overlayView (если бы он был)
        if let dustView = dustEffectView?.view {
            view.insertSubview(dustView, aboveSubview: backgroundImageView)
        }
    }

    // MARK: - Setup
    private func setupStyles() {
        // --- ОБЩИЕ СТИЛИ ---
        // view.backgroundColor больше не устанавливается здесь, управляется фоновым изображением

        // --- СТИЛИЗАЦИЯ ПОД LOOTVIEW ---
        let primaryTextColor = UIColor.white
        let secondaryTextColor = UIColor.lightGray
        let panelBackgroundColor = UIColor.black.withAlphaComponent(0.65)
        let panelCornerRadius: CGFloat = 12
        let panelBorderColor = UIColor.black.withAlphaComponent(0.8)
        let panelBorderWidth: CGFloat = 1

        // Единый стиль шрифта Optima, размер 12, как в LootView
        let optimaRegular12 = UIFont(name: "Optima-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
        // let optimaBold12 = UIFont(name: "Optima-Bold", size: 12) ?? UIFont.boldSystemFont(ofSize: 12) // Больше не используется
        // Новый шрифт Optima Italic 12pt
        let optimaItalic12 = UIFont(name: "Optima-Italic", size: 12) ?? UIFont.italicSystemFont(ofSize: 12)
        // Шрифт для этапов квеста
        let optimaRegular10 = UIFont(name: "Optima-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10)

        // Segmented Control
        segmentedControl.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        segmentedControl.selectedSegmentTintColor = UIColor.black.withAlphaComponent(0.7)
        // Для SegmentedControl используем Optima-Regular, 12pt
        segmentedControl.setTitleTextAttributes([.foregroundColor: primaryTextColor, .font: optimaRegular12], for: .normal)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: optimaRegular12], for: .selected)

        // Quests TableView (Левая панель)
        questsTableView.backgroundColor = panelBackgroundColor
        questsTableView.layer.cornerRadius = panelCornerRadius
        questsTableView.layer.borderColor = panelBorderColor.cgColor
        questsTableView.layer.borderWidth = panelBorderWidth
        questsTableView.separatorStyle = .singleLine
        questsTableView.separatorColor = UIColor.darkGray.withAlphaComponent(0.3)
        questsTableView.indicatorStyle = .white

        // Quest Detail View (Правая панель)
        questDetailView.backgroundColor = panelBackgroundColor
        questDetailView.layer.cornerRadius = panelCornerRadius
        questDetailView.layer.borderColor = panelBorderColor.cgColor
        questDetailView.layer.borderWidth = panelBorderWidth

        // Стилизация текстовых элементов в правой панели с Optima, 12pt
        questTitleLabel.font = optimaRegular12 // Заголовок обычным
        questTitleLabel.textColor = primaryTextColor
        questTitleLabel.numberOfLines = 0

        currentObjectiveLabel.font = optimaItalic12 // Изменено на Italic
        currentObjectiveLabel.textColor = primaryTextColor
        currentObjectiveLabel.numberOfLines = 0
        
        questDescriptionView.font = optimaItalic12 // Изменено на Italic
        questDescriptionView.textColor = secondaryTextColor
        questDescriptionView.backgroundColor = .clear
        questDescriptionView.isEditable = false
        questDescriptionView.isSelectable = true
        questDescriptionView.isScrollEnabled = false // Отключаем внутренний скролл
        // Приоритеты для questDescriptionView
        questDescriptionView.setContentHuggingPriority(.defaultHigh, for: .vertical) // Старается не быть больше контента
        questDescriptionView.setContentCompressionResistancePriority(.defaultLow, for: .vertical) // Легко сжимается

        // Стиль для UITextView с этапами квеста
        questStagesTextView.font = optimaRegular10
        questStagesTextView.textColor = secondaryTextColor // Можно сделать чуть светлее, если нужно выделить
        questStagesTextView.backgroundColor = .clear
        questStagesTextView.isEditable = false
        questStagesTextView.isSelectable = true
        questStagesTextView.isScrollEnabled = false // Отключаем внутренний скролл
        // Приоритеты для questStagesTextView
        questStagesTextView.setContentHuggingPriority(.defaultLow, for: .vertical) // Легко растягивается
        questStagesTextView.setContentCompressionResistancePriority(.required, for: .vertical) // Сопротивляется сжатию
        // --- КОНЕЦ СТИЛИЗАЦИИ ---
    }

    private func setupBackgroundImage() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false // Важно для AutoLayout, если используется
        backgroundImageView.image = UIImage(named: "questJournal")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = false // Позволяем изображению выходить за границы
        view.addSubview(backgroundImageView)
        // view.sendSubviewToBack(backgroundImageView) // Перенесено в viewDidLayoutSubviews для корректного порядка с dust
    }

    private func setupDustEffect() {
        let dustViewHostingController = UIHostingController(rootView: DustEmitterView())
        dustViewHostingController.view.backgroundColor = .clear
        dustViewHostingController.view.translatesAutoresizingMaskIntoConstraints = true // Для frame-based layout
        dustViewHostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight] // Чтобы растягивался
        
        addChild(dustViewHostingController)
        // Добавляем view эффекта пыли. Его frame будет установлен в viewDidLayoutSubviews.
        // Порядок добавления важен, если мы хотим, чтобы он был над фоном, но под UI.
        // Мы будем управлять его положением в viewDidLayoutSubviews.
        view.addSubview(dustViewHostingController.view) 
        dustViewHostingController.didMove(toParent: self)
        self.dustEffectView = dustViewHostingController
    }

    private func setupTopWidget() {
        topWidgetContainerView.translatesAutoresizingMaskIntoConstraints = false
        topWidgetContainerView.backgroundColor = .clear // Фон контейнера прозрачный
        view.addSubview(topWidgetContainerView)

        let widgetVC = TopWidgetUIViewController(viewModel: mainViewModel)
        addChild(widgetVC)
        topWidgetContainerView.addSubview(widgetVC.view)
        widgetVC.view.translatesAutoresizingMaskIntoConstraints = false
        widgetVC.didMove(toParent: self)
        self.topWidgetViewController = widgetVC

        // Констрейнты для контейнера виджета (как в LootView, но можно поднять выше)
        NSLayoutConstraint.activate([
            topWidgetContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 2), // Уменьшено с 10 до 2 для подъема
            topWidgetContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topWidgetContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            topWidgetContainerView.heightAnchor.constraint(equalToConstant: 35) // Высота как в LootView
        ])

        // Констрейнты для самого виджета внутри его контейнера (как в LootView)
        NSLayoutConstraint.activate([
            widgetVC.view.topAnchor.constraint(equalTo: topWidgetContainerView.topAnchor, constant: 2),
            widgetVC.view.leadingAnchor.constraint(equalTo: topWidgetContainerView.leadingAnchor, constant: 2),
            widgetVC.view.trailingAnchor.constraint(equalTo: topWidgetContainerView.trailingAnchor, constant: -2),
            widgetVC.view.bottomAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: -2)
        ])
    }

    private func setupViews() {
        // Segmented Control
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)

        // Quests TableView
        questsTableView.translatesAutoresizingMaskIntoConstraints = false
        questsTableView.dataSource = self
        questsTableView.delegate = self
        questsTableView.register(QuestCell.self, forCellReuseIdentifier: "QuestCell") // Кастомная ячейка
        view.addSubview(questsTableView)

        // Quest Detail View (Правая панель - теперь содержит UIScrollView)
        questDetailView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(questDetailView)

        // UIScrollView для правой панели
        questDetailScrollView.translatesAutoresizingMaskIntoConstraints = false
        questDetailView.addSubview(questDetailScrollView)

        // ContentView внутри UIScrollView
        questDetailContentView.translatesAutoresizingMaskIntoConstraints = false
        questDetailScrollView.addSubview(questDetailContentView)

        // Добавляем элементы в contentView
        questDetailIconView.translatesAutoresizingMaskIntoConstraints = false
        questDetailContentView.addSubview(questDetailIconView)

        questTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        questDetailContentView.addSubview(questTitleLabel)

        questDescriptionView.translatesAutoresizingMaskIntoConstraints = false
        questDetailContentView.addSubview(questDescriptionView)

        currentObjectiveLabel.translatesAutoresizingMaskIntoConstraints = false
        questDetailContentView.addSubview(currentObjectiveLabel)

        // Добавляем иконку текущей цели
        currentObjectiveIconView.translatesAutoresizingMaskIntoConstraints = false
        questDetailContentView.addSubview(currentObjectiveIconView)

        questStagesTextView.translatesAutoresizingMaskIntoConstraints = false
        questDetailContentView.addSubview(questStagesTextView)
    }

    private func setupLayout() {
        let padding: CGFloat = 15
        let halfWidth = (view.bounds.width / 2) - (padding * 1.5) // Примерное разделение

        NSLayoutConstraint.activate([
            // Segmented Control - теперь над questsTableView и той же ширины
            segmentedControl.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: padding),
            segmentedControl.leadingAnchor.constraint(equalTo: questsTableView.leadingAnchor), // Привязка к левому краю таблицы
            segmentedControl.widthAnchor.constraint(equalTo: questsTableView.widthAnchor), // Та же ширина, что и таблица
            segmentedControl.heightAnchor.constraint(equalToConstant: 35),

            // Quests TableView (слева)
            // questsTableView.topAnchor теперь привязан к низу segmentedControl
            questsTableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: padding / 2), // Небольшой отступ от segmentedControl
            questsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            questsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padding),
            questsTableView.widthAnchor.constraint(equalToConstant: max(250, halfWidth * 0.7)), // Ширина осталась прежней

            // Quest Detail View (справа)
            // questDetailView.topAnchor теперь привязан к topWidgetContainerView.bottomAnchor, как и segmentedControl
            questDetailView.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: padding),
            questDetailView.leadingAnchor.constraint(equalTo: questsTableView.trailingAnchor, constant: padding),
            questDetailView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            questDetailView.bottomAnchor.constraint(equalTo: questsTableView.bottomAnchor), // Синхронизируем с таблицей

            // UIScrollView внутри questDetailView
            questDetailScrollView.topAnchor.constraint(equalTo: questDetailView.topAnchor),
            questDetailScrollView.leadingAnchor.constraint(equalTo: questDetailView.leadingAnchor),
            questDetailScrollView.trailingAnchor.constraint(equalTo: questDetailView.trailingAnchor),
            questDetailScrollView.bottomAnchor.constraint(equalTo: questDetailView.bottomAnchor),

            // ContentView внутри questDetailScrollView
            questDetailContentView.topAnchor.constraint(equalTo: questDetailScrollView.topAnchor),
            questDetailContentView.leadingAnchor.constraint(equalTo: questDetailScrollView.leadingAnchor),
            questDetailContentView.trailingAnchor.constraint(equalTo: questDetailScrollView.trailingAnchor),
            questDetailContentView.bottomAnchor.constraint(equalTo: questDetailScrollView.bottomAnchor),
            questDetailContentView.widthAnchor.constraint(equalTo: questDetailScrollView.widthAnchor), // Важно для вертикального скролла

            // Элементы внутри questDetailContentView
            // Иконка квеста (слева от заголовка)
            questDetailIconView.leadingAnchor.constraint(equalTo: questDetailContentView.leadingAnchor, constant: padding),
            questDetailIconView.centerYAnchor.constraint(equalTo: questTitleLabel.centerYAnchor), // Выравниваем по центру заголовка
            // Размеры для иконки будут установлены через createStyledIconView, но можно задать placeholder
            questDetailIconView.widthAnchor.constraint(equalToConstant: 22), 
            questDetailIconView.heightAnchor.constraint(equalToConstant: 22),

            questTitleLabel.topAnchor.constraint(equalTo: questDetailContentView.topAnchor, constant: padding),
            questTitleLabel.leadingAnchor.constraint(equalTo: questDetailIconView.trailingAnchor, constant: padding / 2), // Теперь отступает от иконки
            questTitleLabel.trailingAnchor.constraint(equalTo: questDetailContentView.trailingAnchor, constant: -padding),

            // Иконка текущей цели (слева от currentObjectiveLabel)
            currentObjectiveIconView.leadingAnchor.constraint(equalTo: questDetailContentView.leadingAnchor, constant: padding),
            currentObjectiveIconView.centerYAnchor.constraint(equalTo: currentObjectiveLabel.centerYAnchor),
            currentObjectiveIconView.widthAnchor.constraint(equalToConstant: 18), // Чуть меньше основной иконки квеста
            currentObjectiveIconView.heightAnchor.constraint(equalToConstant: 18),

            currentObjectiveLabel.topAnchor.constraint(equalTo: questTitleLabel.bottomAnchor, constant: padding), // Увеличен отступ
            currentObjectiveLabel.leadingAnchor.constraint(equalTo: currentObjectiveIconView.trailingAnchor, constant: padding / 2), // Отступ от иконки цели
            currentObjectiveLabel.trailingAnchor.constraint(equalTo: questDetailContentView.trailingAnchor, constant: -padding),
            
            questDescriptionView.topAnchor.constraint(equalTo: currentObjectiveLabel.bottomAnchor, constant: padding),
            questDescriptionView.leadingAnchor.constraint(equalTo: questDetailContentView.leadingAnchor, constant: padding),
            questDescriptionView.trailingAnchor.constraint(equalTo: questDetailContentView.trailingAnchor, constant: -padding),
            // Ограничим максимальную высоту questDescriptionView, например, 4 строками текста (примерно)
            // Высота одной строки примерно 14-15 для шрифта 12pt. Умножим на 4.
            questDescriptionView.heightAnchor.constraint(lessThanOrEqualToConstant: 60),

            // Quest Stages TextView
            questStagesTextView.topAnchor.constraint(equalTo: questDescriptionView.bottomAnchor, constant: padding / 2),
            questStagesTextView.leadingAnchor.constraint(equalTo: questDetailContentView.leadingAnchor, constant: padding),
            questStagesTextView.trailingAnchor.constraint(equalTo: questDetailContentView.trailingAnchor, constant: -padding),
            // Нижняя привязка questStagesTextView к questDetailContentView определяет высоту скролла
            questStagesTextView.bottomAnchor.constraint(equalTo: questDetailContentView.bottomAnchor, constant: -padding)
        ])
    }
    
    private func setupSegmentedControlActions() {
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged(_:)), for: .valueChanged)
    }

    // MARK: - Data Handling
    private func loadQuestData() {
        // Это пример. Вам нужно будет получить реальные данные от QuestService
        // И отфильтровать их на активные и завершенные
        // activeQuests = questService.getActiveQuests() 
        // completedQuests = questService.getCompletedQuests()
        
        // Пока что моковые данные для примера отображения
        // Замените это на реальную загрузку из QuestService
        if let player = GameStateService.shared.player { // Доступ к player через questService
            activeQuests = player.activeQuests.values.compactMap { questState -> Quest? in
                return questService.allQuests[questState.questId]
            }
            completedQuests = (player.completedQuestIDs ?? Set()).compactMap { questId -> Quest? in
                return questService.allQuests[questId]
            }
        }
        
        // Обновляем таблицу
        questsTableView.reloadData()
        
        // Если есть квесты, выбираем первый по умолчанию
        if segmentedControl.selectedSegmentIndex == 0 && !activeQuests.isEmpty {
            selectQuest(activeQuests.first)
            questsTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
        } else if segmentedControl.selectedSegmentIndex == 1 && !completedQuests.isEmpty {
            selectQuest(completedQuests.first)
            questsTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
        } else {
            clearDetailView()
        }
    }
    
    @objc private func segmentedControlChanged(_ sender: UISegmentedControl) {
        filterQuests()
    }
    
    private func filterQuests() {
        questsTableView.reloadData()
        if segmentedControl.selectedSegmentIndex == 0 { // Активные
            if let firstQuest = activeQuests.first {
                selectQuest(firstQuest)
                if !activeQuests.isEmpty {
                    questsTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
                }
            } else {
                clearDetailView()
            }
        } else { // Завершенные
            if let firstQuest = completedQuests.first {
                selectQuest(firstQuest)
                 if !completedQuests.isEmpty {
                    questsTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
                }
            } else {
                clearDetailView()
            }
        }
    }

    private func selectQuest(_ quest: Quest?) {
        selectedQuest = quest
        updateDetailView()
    }

    private func updateDetailView() {
        guard let quest = selectedQuest, let player = GameStateService.shared.player else {
            clearDetailView()
            return
        }

        questTitleLabel.text = quest.title
        questDescriptionView.text = quest.description
        
        // --- Отображение иконки квеста ---
        // Удаляем старую иконку (если была)
        questDetailIconView.subviews.forEach { $0.removeFromSuperview() }

        // TODO: Получать имя иконки из quest.iconName когда это поле будет добавлено в модель Quest
        let defaultQuestIconName = "scroll" // Заглушка
        let iconView = createStyledIconView(
            sfSymbolName: defaultQuestIconName, 
            symbolColor: UIColor.white.withAlphaComponent(0.9), 
            backgroundColor: UIColor.black.withAlphaComponent(0.3),
            borderColor: UIColor.white.withAlphaComponent(0.5),
            iconSize: 20, // Чуть меньше, чем в ячейке
            symbolPointSize: 11
        )
        questDetailIconView.addSubview(iconView)
        // Констрейнты для iconView внутри questDetailIconView (чтобы она занимала все место)
        // createStyledIconView уже создает внутренние констрейнты для imageView внутри своего containerView.
        // Здесь мы просто добавляем созданный containerView (iconView) в questDetailIconView.
        // Размеры questDetailIconView уже заданы в setupLayout.
        // Чтобы iconView (который вернула createStyledIconView) заполнил questDetailIconView,
        // мы можем либо положиться на то, что questDetailIconView уже имеет правильный размер (22x22), 
        // а iconView тоже создается с размером 20x20 и будет отцентрирован,
        // либо добавить констрейнты для iconView к границам questDetailIconView.
        // Пока оставим так, createStyledIconView возвращает UIView с заданными размерами.
        // --- Конец отображения иконки квеста ---

        // --- Отображение иконки текущей цели ---
        currentObjectiveIconView.subviews.forEach { $0.removeFromSuperview() } // Очищаем старую иконку цели
        var currentObjectiveIconName: String? = nil

        if let questState = player.activeQuests[quest.id], 
           let stageDetails = quest.stages.first(where: { $0.id == questState.currentStageId }) {
            currentObjectiveLabel.text = "Текущая цель: \(stageDetails.objective)"
            // TODO: Определять имя иконки на основе типа цели/стадии
            currentObjectiveIconName = "target" // Заглушка
        } else if player.completedQuestIDs?.contains(quest.id) ?? false { // Если квест завершен
            currentObjectiveLabel.text = "Квест завершен."
            currentObjectiveIconName = "checkmark.seal" // Иконка для завершенного квеста
        } else { // Если квест не активен и не завершен (маловероятно для выбранного квеста, но на всякий случай)
            currentObjectiveLabel.text = ""
        }

        if let iconName = currentObjectiveIconName {
            let objectiveIcon = createStyledIconView(
                sfSymbolName: iconName, 
                symbolColor: UIColor.lightGray, // Можно настроить
                backgroundColor: .clear, // Без фона для этой иконки
                borderColor: .clear, // Без рамки
                iconSize: 18, 
                symbolPointSize: 10
            )
            currentObjectiveIconView.addSubview(objectiveIcon)
        }
        // --- Конец отображения иконки текущей цели ---

        // Отображение этапов
        let stagesText = NSMutableAttributedString()
        // Переопределяем цвета здесь, так как они из локальной области setupStyles()
        let localSecondaryTextColor = UIColor.lightGray 
        let localPrimaryTextColor = UIColor.white
        let localPassedStageColor = UIColor.darkGray // Цвет для пройденных этапов

        // Абзацный стиль для отступов между строками этапов
        let stageParagraphStyle = NSMutableParagraphStyle()
        // stageParagraphStyle.paragraphSpacing = 30.0 // Этот способ не дал нужного эффекта, убираем

        // Базовый размер шрифта для этапов (для расчета bounds аттачмента)
        let stageBaseFont = UIFont(name: "Optima-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10)

        // Атрибуты для этапов теперь включают paragraphStyle
        let currentStageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Optima-Bold", size: 10) ?? UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: localPrimaryTextColor,
            .paragraphStyle: stageParagraphStyle
        ]
        let passedStageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Optima-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10),
            .foregroundColor: localPassedStageColor,
            .paragraphStyle: stageParagraphStyle
        ]

        if player.completedQuestIDs?.contains(quest.id) ?? false {
            // Все этапы завершенного квеста отображаем как пройденные
            for stage in quest.stages.sorted(by: { $0.id < $1.id }) {
                let stageString = "\(stage.objective)"
                stagesText.append(NSAttributedString(string: stageString + "\n", attributes: passedStageAttributes))
            }
        } else if let questState = player.activeQuests[quest.id] {
            // Активный квест: показываем пройденные и текущий
            for stage in quest.stages.sorted(by: { $0.id < $1.id }) {
                guard stage.id <= questState.currentStageId else { continue } // Пропускаем будущие этапы
                
                let stageString = "\(stage.objective)"
                var attributes = passedStageAttributes
                var iconName = "checkmark" // Изменено на 'checkmark'
                var iconColor = UIColor.systemGreen
                // Размер символа иконки для этапа
                let symbolPointSizePoints: CGFloat = 10 // Немного увеличим для лучшей видимости
                // Размер области, которую иконка займет в строке (для bounds)
                let iconDisplaySizePoints: CGFloat = 12 

                if stage.id == questState.currentStageId {
                    attributes = currentStageAttributes
                    iconName = "arrow.right" // Изменено на 'arrow.right'
                    iconColor = localPrimaryTextColor // Белый для текущего этапа
                }

                // 1. Создаем UIImage для иконки напрямую
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: symbolPointSizePoints)
                if let baseImage = UIImage(systemName: iconName, withConfiguration: symbolConfig) {
                    let iconImage = baseImage.withTintColor(iconColor, renderingMode: .alwaysOriginal)
                    
                    let attachment = NSTextAttachment()
                    attachment.image = iconImage
                    // Настройка bounds для выравнивания по строке
                    let yOffset = -2.5 // Смещение вниз для лучшего выравнивания с текстом (Optima 10pt)
                    attachment.bounds = CGRect(x: 0, y: yOffset, width: iconDisplaySizePoints, height: iconDisplaySizePoints)
                    stagesText.append(NSAttributedString(attachment: attachment))
                    stagesText.append(NSAttributedString(string: " ")) // Пробел после иконки
                } else {
                    print("[QuestJournalVC] Failed to create UIImage for stage icon: \(iconName)")
                }

                stagesText.append(NSAttributedString(string: stageString + "\n", attributes: attributes))
                // Добавляем еще один перевод строки для увеличения вертикального пространства
                if stage.id != quest.stages.sorted(by: { $0.id < $1.id }).last?.id { // Не добавлять после последнего этапа
                    let emptyLineFont = UIFont.systemFont(ofSize: 6) // Маленький шрифт для пустой строки, чтобы отступ был не слишком большим
                    stagesText.append(NSAttributedString(string: "\n", attributes: [.font: emptyLineFont]))
                }
            }
        } // Будущие этапы для еще не взятых квестов не отображаем (если selectedQuest не может быть неактивным)
        
        // Отладочный print
        print("Updating stages. Text: \(stagesText.string)")
        questStagesTextView.attributedText = stagesText
    }
    
    private func clearDetailView() {
        questTitleLabel.text = "Нет выбранного квеста"
        questDescriptionView.text = ""
        currentObjectiveLabel.text = ""
        questStagesTextView.text = "" // Очищаем поле с этапами
        questDetailIconView.subviews.forEach { $0.removeFromSuperview() } // Очищаем иконку квеста
        currentObjectiveIconView.subviews.forEach { $0.removeFromSuperview() } // Очищаем иконку цели
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return segmentedControl.selectedSegmentIndex == 0 ? activeQuests.count : completedQuests.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "QuestCell", for: indexPath) as? QuestCell else {
            return UITableViewCell()
        }
        let quest = segmentedControl.selectedSegmentIndex == 0 ? activeQuests[indexPath.row] : completedQuests[indexPath.row]
        
        // Определяем параметры для иконки
        var iconName = "bookmark"
        var iconTintColor = UIColor.white
        var iconBgColor = UIColor.black.withAlphaComponent(0.7)
        var iconBorderColor = UIColor.white.withAlphaComponent(0.7)

        if segmentedControl.selectedSegmentIndex == 1 { // Завершенные
            iconName = "checkmark.seal.fill"
            iconTintColor = UIColor.systemGreen
            iconBgColor = UIColor.darkGray.withAlphaComponent(0.5)
            iconBorderColor = UIColor.systemGreen.withAlphaComponent(0.7)
        } else {
            // Активные квесты (можно добавить логику для "особо важных" или текущих)
            if quest.id == selectedQuest?.id { // Выбранный активный квест
                 iconName = "bookmark.fill"
                 iconTintColor = UIColor.systemYellow
                 iconBgColor = UIColor.black.withAlphaComponent(0.8) // Чуть темнее фон для выделения
                 iconBorderColor = UIColor.systemYellow.withAlphaComponent(0.8)
            }
        }
        print("[QuestJournalVC] cellForRowAt: Quest '\(quest.title)', iconName: \(iconName)") // DEBUG

        let styledIconView = createStyledIconView(sfSymbolName: iconName, 
                                                  symbolColor: iconTintColor, 
                                                  backgroundColor: iconBgColor, 
                                                  borderColor: iconBorderColor)
        
        if styledIconView == nil {
            print("[QuestJournalVC] cellForRowAt: styledIconView IS NIL for quest '\(quest.title)'") // DEBUG
        }

        cell.configure(with: quest.title, iconView: styledIconView)
        cell.backgroundColor = .clear
        
        // Стиль выделения - теперь зеленый
        let selectionView = UIView()
        selectionView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.25) // Полупрозрачный зеленый
        cell.selectedBackgroundView = selectionView
        
        return cell
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let quest = segmentedControl.selectedSegmentIndex == 0 ? activeQuests[indexPath.row] : completedQuests[indexPath.row]
        selectQuest(quest)
        // tableView.deselectRow(at: indexPath, animated: true) // Можно раскомментировать для снятия выделения
    }

    // Вспомогательная функция для создания стилизованных иконок
    private func createStyledIconView(sfSymbolName: String, 
                                      symbolColor: UIColor, 
                                      backgroundColor: UIColor, 
                                      borderColor: UIColor, 
                                      iconSize: CGFloat = 22, 
                                      symbolPointSize: CGFloat = 12) -> UIView {
        let containerView = UIView()
        print("[QuestJournalVC] createStyledIconView: Symbol name: \(sfSymbolName)") // DEBUG
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = iconSize / 2
        containerView.layer.backgroundColor = backgroundColor.cgColor
        containerView.layer.borderColor = borderColor.cgColor
        containerView.layer.borderWidth = 0.5

        // Настройка свечения (вместо стандартной тени)
        containerView.layer.shadowColor = symbolColor.withAlphaComponent(0.7).cgColor // Цвет свечения от цвета символа
        containerView.layer.shadowRadius = 5 // Радиус свечения
        containerView.layer.shadowOpacity = 0.8 // Непрозрачность свечения
        containerView.layer.shadowOffset = CGSize.zero // Без смещения для равномерного свечения
        containerView.layer.masksToBounds = false // Важно, чтобы свечение было видно

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: symbolPointSize)
        let symbolImage = UIImage(systemName: sfSymbolName, withConfiguration: config)
        imageView.image = symbolImage
        imageView.tintColor = symbolColor

        if symbolImage == nil {
            print("[QuestJournalVC] createStyledIconView: UIImage(systemName: '\(sfSymbolName)') IS NIL") // DEBUG
        }
        
        containerView.addSubview(imageView)

        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalToConstant: iconSize),
            containerView.heightAnchor.constraint(equalToConstant: iconSize),
            
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        return containerView
    }

    // Вспомогательная функция для рендеринга UIView в UIImage
    private func renderViewToImage(view: UIView, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        view.layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - QuestCell (кастомная ячейка для таблицы)
class QuestCell: UITableViewCell {
    private var questIconContainerView: UIView?
    private var iconConstraints: [NSLayoutConstraint] = []
    private var textLabelLeadingConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear

        let cellTitleFont = UIFont(name: "Optima-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
        let primaryTextColor = UIColor.white

        textLabel?.font = cellTitleFont
        textLabel?.textColor = primaryTextColor
        textLabel?.numberOfLines = 0
        textLabel?.lineBreakMode = .byTruncatingTail
        textLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        if let label = textLabel {
            let trailingConstraint = label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
            trailingConstraint.priority = .defaultHigh
            NSLayoutConstraint.activate([
                trailingConstraint,
                label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
                label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
            ])
        }

        let selectionView = UIView()
        selectionView.backgroundColor = UIColor.white.withAlphaComponent(0.15) 
        self.selectedBackgroundView = selectionView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with title: String, iconView: UIView?) {
        textLabel?.text = title

        // Деактивируем и удаляем старые констрейнты иконки и саму иконку
        NSLayoutConstraint.deactivate(iconConstraints)
        iconConstraints.removeAll()
        questIconContainerView?.removeFromSuperview()
        questIconContainerView = nil

        // Деактивируем старый leading констрейнт для textLabel
        textLabelLeadingConstraint?.isActive = false

        if let newIconView = iconView {
            self.questIconContainerView = newIconView
            contentView.addSubview(newIconView)
            // newIconView.translatesAutoresizingMaskIntoConstraints = false (уже установлено в createStyledIconView)

            let iconWidthConstraint = newIconView.widthAnchor.constraint(equalToConstant: 22)
            iconWidthConstraint.priority = .required // Явно устанавливаем приоритет

            let currentIconConstraints = [
                newIconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
                newIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                iconWidthConstraint, // Используем констрейнт с явно заданным приоритетом
                newIconView.heightAnchor.constraint(equalToConstant: 22) // Явно задаем высоту
            ]
            self.iconConstraints = currentIconConstraints
            NSLayoutConstraint.activate(currentIconConstraints)

            textLabelLeadingConstraint = textLabel?.leadingAnchor.constraint(equalTo: newIconView.trailingAnchor, constant: 10)
            textLabel?.setContentCompressionResistancePriority(.init(249), for: .horizontal) // Очень низкое сопротивление сжатию
        } else {
            textLabelLeadingConstraint = textLabel?.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15)
            textLabel?.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal) // Возвращаем высокое, если нет иконки
        }
        textLabelLeadingConstraint?.isActive = true
    }
} 
