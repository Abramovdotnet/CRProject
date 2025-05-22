import UIKit
import SwiftUI // <<< Added for UIHostingController

// Структура для хранения данных, необходимых для отрисовки одного маркера
struct MarkerDrawingData {
    let scene: Scene
    let frame: CGRect
    let coloredRectangleFrame: CGRect
    let iconFrame: CGRect
    let nameLabelFrame: CGRect
    let typeLabelFrame: CGRect
    let nameText: String
    let typeText: String
    let iconImageName: String
    let baseBackgroundColor: UIColor
    let nameLabelColor: UIColor
    let typeLabelColor: UIColor
    let iconTintColor: UIColor
    var isLocked: Bool
    var isCurrent: Bool
}

// Новый класс View, который будет заниматься отрисовкой всех маркеров и линий
class MarkerView: UIView {
    var markerDrawDataList: [MarkerDrawingData] = []
    var linesView: MapLinesView! // <<< ВОЗВРАЩАЕМ СВОЙСТВО
    // var currentDrawingSceneId: Int? // ID текущей сцены для подсветки - управляется через isCurrent в MarkerDrawingData

    // Свойства, которые раньше были в WorldMapViewController, но нужны для отрисовки
    // и передаются из него.
    var coordinateScale: CGFloat = 80.0
    var padding: CGFloat = 50.0
    var mapOriginX: CGFloat = 0
    var mapOriginY: CGFloat = 0
    var coloredRectangleSize: CGSize = .zero // Для линий и потенциально для hit-test
    var sceneElementSize: CGSize = .zero // Для линий и потенциально для hit-test


    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear // Фон должен быть прозрачным
        // Линии будут добавлены как subview позже
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Основной метод отрисовки
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        // print("[MarkerView] Frame: \(self.frame), Bounds: \(self.bounds)")
        guard let context = UIGraphicsGetCurrentContext() else { return }

        for data in markerDrawDataList {
            let markerFrame = data.frame
            if !markerFrame.intersects(rect) { continue }
            context.saveGState()
            context.translateBy(x: data.frame.origin.x, y: data.frame.origin.y)
            // --- Draw main colored rectangle (always opaque) ---
            let backgroundColor = data.baseBackgroundColor // Already opaque
            if data.isCurrent {
                context.saveGState()
                context.setShadow(offset: .zero, blur: 8.0, color: UIColor.yellow.cgColor)
                backgroundColor.setFill()
                let shadowCastingPath = UIBezierPath(roundedRect: data.coloredRectangleFrame, cornerRadius: 8)
                shadowCastingPath.fill()
                context.restoreGState()
            } else {
                backgroundColor.setFill()
                let backgroundPath = UIBezierPath(roundedRect: data.coloredRectangleFrame, cornerRadius: 8)
                backgroundPath.fill()
            }
            // Draw border
            UIColor.black.setStroke()
            let borderDrawingPath = UIBezierPath(roundedRect: data.coloredRectangleFrame, cornerRadius: 8)
            borderDrawingPath.lineWidth = 0.5
            borderDrawingPath.stroke()
            // --- Draw icon, name, and type inside colored rectangle ---
            let iconFrame = data.iconFrame
            if data.isLocked {
                let lockIconSFName = "lock.fill"
                let lockIconColor = UIColor(white: 0.85, alpha: 1.0)
                let spacingBetweenIcons: CGFloat = 2.0
                let maxWidthPerIcon = (iconFrame.width - spacingBetweenIcons) / 2.0
                let maxHeightPerIcon = iconFrame.height
                let iconSideLength = max(1.0, min(maxWidthPerIcon, maxHeightPerIcon))
                let totalOccupiedWidth = iconSideLength * 2 + spacingBetweenIcons
                let startX = iconFrame.origin.x + (iconFrame.width - totalOccupiedWidth) / 2.0
                let startY = iconFrame.origin.y + (iconFrame.height - iconSideLength) / 2.0
                let typeIconActualRect = CGRect(x: startX, y: startY, width: iconSideLength, height: iconSideLength)
                let lockIconActualRect = CGRect(x: typeIconActualRect.maxX + spacingBetweenIcons, y: startY, width: iconSideLength, height: iconSideLength)
                if let typeIconImage = UIImage(systemName: data.iconImageName) {
                    typeIconImage.withTintColor(data.iconTintColor).draw(in: typeIconActualRect)
                }
                if let lockImage = UIImage(systemName: lockIconSFName) {
                    lockImage.withTintColor(lockIconColor).draw(in: lockIconActualRect)
                }
            } else {
                let iconSideLength = min(iconFrame.width, iconFrame.height)
                let centeredIconX = iconFrame.origin.x + (iconFrame.width - iconSideLength) / 2.0
                let centeredIconY = iconFrame.origin.y + (iconFrame.height - iconSideLength) / 2.0
                let centeredSquareFrame = CGRect(x: centeredIconX, y: centeredIconY, width: iconSideLength, height: iconSideLength)
                if let icon = UIImage(systemName: data.iconImageName) {
                    icon.withTintColor(data.iconTintColor).draw(in: centeredSquareFrame)
                }
            }
            // Draw name (centered)
            let nameParagraphStyle = NSMutableParagraphStyle()
            nameParagraphStyle.alignment = .center
            nameParagraphStyle.lineBreakMode = .byTruncatingTail
            let nameShadow = NSShadow()
            nameShadow.shadowColor = UIColor.black.withAlphaComponent(0.5)
            nameShadow.shadowOffset = CGSize(width: 0.7, height: 0.7)
            nameShadow.shadowBlurRadius = 1.0
            let nameFont: UIFont = UIFont(name: "Optima-Bold", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .bold)
            let nameAttribs: [NSAttributedString.Key: Any] = [
                .font: nameFont,
                .foregroundColor: data.nameLabelColor,
                .paragraphStyle: nameParagraphStyle,
                .shadow: nameShadow
            ]
            (data.nameText as NSString).draw(with: data.nameLabelFrame, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], attributes: nameAttribs, context: nil)
            // Draw type (centered, below name)
            let typeParagraphStyle = NSMutableParagraphStyle()
            typeParagraphStyle.alignment = .center
            typeParagraphStyle.lineBreakMode = .byTruncatingTail
            let typeShadow = NSShadow()
            typeShadow.shadowColor = UIColor.black.withAlphaComponent(0.5)
            typeShadow.shadowOffset = CGSize(width: 0.7, height: 0.7)
            typeShadow.shadowBlurRadius = 1.0
            let typeFont = UIFont(name: "Optima-Regular", size: 11) ?? UIFont.systemFont(ofSize: 11)
            let typeAttribs: [NSAttributedString.Key: Any] = [
                .font: typeFont,
                .foregroundColor: data.typeLabelColor,
                .paragraphStyle: typeParagraphStyle,
                .shadow: typeShadow
            ]
            (data.typeText as NSString).draw(with: data.typeLabelFrame, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], attributes: typeAttribs, context: nil)
            context.restoreGState()
        }
    }
    
    // Метод для обновления ID текущей сцены и запроса перерисовки
    func setCurrentSceneId(_ id: Int?) {
        var oldSceneId: Int? = nil
        if let currentIndex = markerDrawDataList.firstIndex(where: { $0.isCurrent }) {
            if markerDrawDataList[currentIndex].scene.id != id { 
                oldSceneId = markerDrawDataList[currentIndex].scene.id
                markerDrawDataList[currentIndex].isCurrent = false
            }
        }

        if let newId = id, let newCurrentIndex = markerDrawDataList.firstIndex(where: { $0.scene.id == newId }) {
            // Ensure isCurrent is setModeling to true only if it was previously false,
            // or if it's a different scene becoming current.
            // This prevents unnecessary redraws if the same current scene is set again.
            if !markerDrawDataList[newCurrentIndex].isCurrent || markerDrawDataList[newCurrentIndex].scene.id != oldSceneId {
                 markerDrawDataList[newCurrentIndex].isCurrent = true
            }
        }
        
        var needsRedrawOldRect: CGRect?
        var needsRedrawNewRect: CGRect?

        // Эта логика теперь корректно определяет, какие области нужно перерисовать
        // на основе изменений флага isCurrent, сделанных выше.
        for data in markerDrawDataList {
            if data.scene.id == oldSceneId && !data.isCurrent { // Старый, который перестал быть текущим
                 needsRedrawOldRect = data.frame.insetBy(dx: -10, dy: -10)
            }
            if data.scene.id == id && data.isCurrent { // Новый, который стал текущим
                 needsRedrawNewRect = data.frame.insetBy(dx: -10, dy: -10)
            }
        }

        if let oldRect = needsRedrawOldRect {
            setNeedsDisplay(oldRect) 
        }
        if let newRect = needsRedrawNewRect {
            setNeedsDisplay(newRect)
        } else if id != nil, let currentData = markerDrawDataList.first(where: {$0.scene.id == id}), currentData.isCurrent {
            // Если newRect не установлен (т.е. маркер уже БЫЛ текущим и остался им),
            // но ID пришел, все равно перерисуем его область для надежности (например, первая загрузка).
            setNeedsDisplay(currentData.frame.insetBy(dx: -10, dy: -10))
        }
        // print("[MarkerView] setCurrentSceneId - Old: \(oldSceneId ?? -1), New: \(id ?? -1)") // КОММЕНТИРУЕМ ИЛИ УДАЛЯЕМ
    }
}

class WorldMapViewController: UIViewController, UIScrollViewDelegate {

    private var scrollView: UIScrollView!
    private var markerRenderingView: MarkerView! 
    private var linesView: MapLinesView! 
    private var zoomableViewContainer: UIView! // <<< НОВЫЙ КОНТЕЙНЕР ДЛЯ ЗУМА
    
    private var allScenes: [Scene] = []
    // private var currentPlayerMarker: UIView? // Больше не используется, свечение рисуется
    private var markerDrawDataList: [MarkerDrawingData] = [] 
    // private var currentSceneIdForGlow: Int? // Заменено на передачу в markerRenderingView.setCurrentSceneId
    private var pendingScenePointCache: [Int: CGPoint]? // <<< НОВОЕ СВОЙСТВО для временного хранения

    // Размеры элементов маркера
    private let coloredRectangleSize = CGSize(width: 120, height: 50) // Размер цветного блока
    private let spacingBelowRectangle: CGFloat = 5 // Пространство под цветным блоком
    private let infoAreaHeight: CGFloat = 50 // Высота для иконки, названия и типа под блоком
    
    // Общий размер элемента сцены на карте (вычисляемый)
    private var sceneElementSize: CGSize {
        return CGSize(width: coloredRectangleSize.width, 
                      height: coloredRectangleSize.height + spacingBelowRectangle + infoAreaHeight)
    }
    
    private let coordinateScale: CGFloat = 80.0 // Масштаб для координат (1_point на карте = 80_pt на экране)
    private let padding: CGFloat = 50.0 // Отступы вокруг контента карты
    private var minMapX: CGFloat = 0 // Store min X coordinate of the map content
    private var minMapY: CGFloat = 0 // Store min Y coordinate of the map content

    private let mainViewModel: MainSceneViewModel // <<< Store the viewModel
    private var topWidgetHostingController: UIHostingController<TopWidgetView>? // <<< For TopWidgetView
    private var dustEffectHostingController: UIHostingController<DustEmitterView>? // <<< For DustEmitterView
    private let backgroundImageView = UIImageView() // <<< For Background Image

    // Labels for current location info
    private let currentLocationNameLabel = UILabel()
    private let currentLocationTypeLabel = UILabel()
    private let currentLocationTypeIconImageView = UIImageView() // <<< Новая UIImageView для иконки типа

    private var backButton: UIButton! // <<< New back button

    // Флаг для предотвращения повторной инициализации zoom/позиции
    private var isInitialMapSetupDone: Bool = false
    private var didCenterOnInitialScene = false

    private var glowView: UIView? // Для свечения текущего маркера

    // Initializer to accept MainSceneViewModel
    init(mainViewModel: MainSceneViewModel) {
        self.mainViewModel = mainViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented for WorldMapViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black // Main background for the entire view controller

        // 1. Синхронная настройка основного UI, который не зависит от данных карты
        setupBackgroundImage() 
        setupDustEffect()     
        setupScrollView() // Инициализирует self.scrollView, но без contentSize и subviews карты

        setupTopWidget()
        setupLocationInfoLabels()
        setupBackButton()
        
        // 2. Асинхронная загрузка данных и настройка зависимых от данных View
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // --- Начало фоновых операций ---
            self.loadSceneData() // Загружает self.allScenes

            guard !self.allScenes.isEmpty else {
                DispatchQueue.main.async {
                    // activityIndicator.stopAnimating() // Индикатора больше нет
                    print("[WorldMapView] No scenes loaded. Map will be empty.")
                    // Настроим базовый зум для пустого состояния, если scrollView уже есть
                    if self.scrollView != nil {
                         self.scrollView.minimumZoomScale = 1.0
                         self.scrollView.zoomScale = 1.0
                    }
                }
                return
            }

            // Вычисляем minMapX/Y после загрузки allScenes
            self.minMapX = self.allScenes.map { CGFloat($0.x) * self.coordinateScale }.min() ?? 0
            self.minMapY = self.allScenes.map { CGFloat($0.y) * self.coordinateScale }.min() ?? 0

            // Рассчитываем общий размер контента (contentFrame)
            let actualMinX = self.allScenes.map { CGFloat($0.x) * self.coordinateScale }.min() ?? 0 // Повторно, но self.minMapX уже установлен
            let actualMaxX = self.allScenes.map { CGFloat($0.x) * self.coordinateScale }.max() ?? 0
            let actualMinY = self.allScenes.map { CGFloat($0.y) * self.coordinateScale }.min() ?? 0 // Повторно, но self.minMapY уже установлен
            let actualMaxY = self.allScenes.map { CGFloat($0.y) * self.coordinateScale }.max() ?? 0
            
            let contentWidth = (actualMaxX - actualMinX) + self.sceneElementSize.width + 2 * self.padding
            let contentHeight = (actualMaxY - actualMinY) + self.sceneElementSize.height + 2 * self.padding
            let calculatedContentFrame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)

            // Готовим данные для отрисовки в одном методе
            // self.prepareMarkerDrawData() // УДАЛЕНО
            // self.prepareLinePoints()     // УДАЛЕНО
            self.initializeMarkerDrawDataIfNeeded()
            // --- Конец фоновых операций ---

            DispatchQueue.main.async {
                // --- Начало операций в главном потоке ---
                // activityIndicator.stopAnimating() // Индикатора больше нет

                self.scrollView.contentSize = calculatedContentFrame.size
                print("[VIEW_DID_LOAD_DEBUG] scrollView.contentSize SET TO: \(self.scrollView.contentSize) (calculatedContentFrame.size: \(calculatedContentFrame.size))") // <<< НОВЫЙ ЛОГ

                // Создаем и настраиваем zoomableViewContainer
                self.zoomableViewContainer = UIView(frame: calculatedContentFrame)
                self.scrollView.addSubview(self.zoomableViewContainer)
                print("[VIEW_DID_LOAD_DEBUG] zoomableViewContainer.frame SET TO: \(self.zoomableViewContainer.frame) (calculatedContentFrame: \(calculatedContentFrame))") // <<< НОВЫЙ ЛОГ

                // Конфигурируем linesView, добавляем его в zoomableViewContainer
                self.configureLinesView(boundsForLinesView: self.zoomableViewContainer.bounds) 
                self.zoomableViewContainer.addSubview(self.linesView)

                // Конфигурируем markerRenderingView, добавляем его в zoomableViewContainer (поверх linesView)
                self.configureMarkerView(boundsForMarkerView: self.zoomableViewContainer.bounds)
                self.zoomableViewContainer.addSubview(self.markerRenderingView)
                // Явно выставляем frame после добавления
                self.markerRenderingView.frame = self.zoomableViewContainer.bounds
                print("[DEBUG] markerRenderingView.frame = \(self.markerRenderingView.frame), bounds = \(self.markerRenderingView.bounds)")
                self.markerRenderingView.alpha = 1.0

                // Передаем данные и параметры в markerRenderingView
                self.markerRenderingView.markerDrawDataList = self.markerDrawDataList
                self.markerRenderingView.coordinateScale = self.coordinateScale
                self.markerRenderingView.padding = self.padding
                self.markerRenderingView.mapOriginX = self.minMapX
                self.markerRenderingView.mapOriginY = self.minMapY
                self.markerRenderingView.coloredRectangleSize = self.coloredRectangleSize 
                self.markerRenderingView.sceneElementSize = self.sceneElementSize
                self.markerRenderingView.setNeedsDisplay() // Запрос на перерисовку маркеров

                // Передаем данные в linesView 
                self.linesView.scenes = self.allScenes 
                // self.linesView.scenePointCache должен быть уже заполнен через prepareLinePoints()
                if let points = self.pendingScenePointCache { // <<< ИСПОЛЬЗУЕМ ВРЕМЕННОЕ ХРАНИЛИЩЕ
                    self.linesView.scenePointCache = points
                    self.pendingScenePointCache = nil // Очищаем временное хранилище после использования
                }
                self.linesView.currentSceneId = GameStateService.shared.currentScene?.id 
                self.linesView.setNeedsDisplay() // Запрос на перерисовку линий

                // --- ДОБАВЛЯЕМ ЯВНУЮ УСТАНОВКУ contentSize ПОСЛЕ ВСЕХ ДОБАВЛЕНИЙ ---
                self.scrollView.contentSize = self.zoomableViewContainer.bounds.size
                print("[FINAL] scrollView.contentSize = \(self.scrollView.contentSize), zoomableViewContainer.bounds = \(self.zoomableViewContainer.bounds)")
                // --- КОНЕЦ ДОБАВЛЕНИЯ ---

                // ВОССТАНАВЛИВАЕМ ИНИЦИАЛЬНУЮ УСТАНОВКУ ПОДСВЕТКИ И ИНФОРМАЦИИ О ТЕКУЩЕЙ СЦЕНЕ
                let initialSceneId = GameStateService.shared.currentScene?.id
                self.markerRenderingView.setCurrentSceneId(initialSceneId) // Для подсветки маркера
                // self.linesView.currentSceneId уже установлен выше, но на всякий случай можно и здесь, если порядок важен.
                // self.linesView.setNeedsDisplay() // Уже вызван выше, но setCurrentSceneId для маркеров сам вызывает setNeedsDisplay для себя.
                                                 // Для linesView может потребоваться явный вызов, если currentSceneId влияет на его отрисовку.

                if let sceneId = initialSceneId,
                   let currentSceneData = self.allScenes.first(where: { $0.id == sceneId }) {
                    self.currentLocationNameLabel.text = currentSceneData.name
                    self.currentLocationTypeLabel.text = currentSceneData.sceneType.displayName
                    self.currentLocationTypeIconImageView.image = UIImage(systemName: currentSceneData.sceneType.iconName)
                } else {
                    self.currentLocationNameLabel.text = "N/A"
                    self.currentLocationTypeLabel.text = ""
                    self.currentLocationTypeIconImageView.image = nil
                }
                // КОНЕЦ БЛОКА ВОССТАНОВЛЕНИЯ

                // Установка zoomScale (эта логика была в конце viewDidLoad)
                if !self.isInitialMapSetupDone {
                    if self.scrollView.contentSize.width > 0 && self.scrollView.contentSize.height > 0 {
                        let sBounds = self.scrollView.bounds
                        let cSize = self.scrollView.contentSize
                        let scaleWidth = sBounds.width / cSize.width
                        let scaleHeight = sBounds.height / cSize.height
                        var minScaleToFitContent = min(scaleWidth, scaleHeight)
                        minScaleToFitContent = max(minScaleToFitContent, 0.2)

                        self.scrollView.minimumZoomScale = minScaleToFitContent * 0.5
                        let baseInitialZoom = max(minScaleToFitContent, self.scrollView.minimumZoomScale)
                        var desiredInitialZoom = baseInitialZoom * 2 // Используем значение пользователя
                        desiredInitialZoom = min(desiredInitialZoom, self.scrollView.maximumZoomScale)
                        desiredInitialZoom = max(desiredInitialZoom, self.scrollView.minimumZoomScale)
                        self.scrollView.zoomScale = desiredInitialZoom
                    } else {
                        print("[WorldMapView] viewDidLoad (async completion): scrollView.contentSize is zero, cannot set zoom scale.")
                    }
                    self.isInitialMapSetupDone = true
                }
                
                // Анимация плавного появления контента
                UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveEaseOut, animations: {
                    self.linesView.alpha = 1.0
                    self.markerRenderingView.alpha = 1.0
                }, completion: nil)
                // --- Конец операций в главном потоке ---

                // Центрируем карту на текущей сцене при первом открытии
                if let initialSceneId = GameStateService.shared.currentScene?.id {
                    DispatchQueue.main.async {
                        self.centerCameraOnScene(withId: initialSceneId, animated: false)
                        self.updateGlowView(for: initialSceneId)
                    }
                }
            }
        }
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

        // Убедимся, что dustEffectView над фоном, но под остальными элементами
        if let dustView = dustEffectHostingController?.view {
            view.insertSubview(dustView, aboveSubview: backgroundImageView)
        }
        // scrollView и topWidget уже находятся выше благодаря порядку добавления в viewDidLoad 
        // и sendSubviewToBack для dustView в его setup методе.
        // Однако, чтобы быть абсолютно уверенным в иерархии после sendSubviewToBack(backgroundImageView):
        // 1. backgroundImageView (самый нижний)
        // 2. dustEffectView (над backgroundImageView)
        // 3. scrollView (над dustEffectView - добавляется позже в viewDidLoad)
        // 4. topWidget (над scrollView - добавляется еще позже в viewDidLoad)

        if !didCenterOnInitialScene,
           markerRenderingView != nil,
           zoomableViewContainer != nil,
           let initialSceneId = GameStateService.shared.currentScene?.id {
            centerCameraOnScene(withId: initialSceneId, animated: false)
            didCenterOnInitialScene = true
        }
    }

    private func setupBackgroundImage() {
        // Используйте "worldMapBackground" или актуальное имя вашего ресурса
        backgroundImageView.image = UIImage(named: "worldMapBackground") ?? UIImage(named: "MainSceneBackground") // Fallback
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = false // Для "растягивания" за пределы
        view.addSubview(backgroundImageView)
        // Отправка на задний план будет в viewDidLayoutSubviews для корректного порядка
    }

    private func setupDustEffect() {
        let dustView = DustEmitterView()
        let hostingController = UIHostingController(rootView: dustView)

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        view.sendSubviewToBack(hostingController.view) // <<< Explicitly send to back

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        hostingController.view.isUserInteractionEnabled = false // Ensure it doesn't block gestures

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        self.dustEffectHostingController = hostingController
    }

    private func setupTopWidget() {
        let topWidgetView = TopWidgetView(viewModel: mainViewModel)
        let hostingController = UIHostingController(rootView: topWidgetView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear // Make hosting controller's view background clear
        
        // Constraints for TopWidgetView
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            hostingController.view.heightAnchor.constraint(equalToConstant: 35)
        ])
        
        self.topWidgetHostingController = hostingController
    }

    private func setupLocationInfoLabels() {
        // Name Label
        currentLocationNameLabel.font = UIFont(name: "Optima-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium)
        currentLocationNameLabel.textColor = .white // Или ваш Theme.textColor
        currentLocationNameLabel.textAlignment = .center
        currentLocationNameLabel.shadowColor = UIColor.black.withAlphaComponent(0.5) // <<< Тень
        currentLocationNameLabel.shadowOffset = CGSize(width: 1, height: 1)       // <<< Тень
        currentLocationNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(currentLocationNameLabel)

        // Type Icon ImageView
        currentLocationTypeIconImageView.tintColor = .systemGreen // Цвет иконки как у текста типа
        currentLocationTypeIconImageView.contentMode = .scaleAspectFit
        currentLocationTypeIconImageView.translatesAutoresizingMaskIntoConstraints = false
        // view.addSubview(currentLocationTypeIconImageView) // Будет добавлена в StackView

        // Type Label
        currentLocationTypeLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        currentLocationTypeLabel.textColor = .systemGreen // Или ваш Theme.secondaryTextColor
        currentLocationTypeLabel.textAlignment = .left // Изменим на left для StackView
        currentLocationTypeLabel.shadowColor = UIColor.black.withAlphaComponent(0.5) // <<< Тень
        currentLocationTypeLabel.shadowOffset = CGSize(width: 1, height: 1)       // <<< Тень
        currentLocationTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        // view.addSubview(currentLocationTypeLabel) // Будет добавлена в StackView

        // StackView for Type Icon and Type Label
        let typeInfoStackView = UIStackView(arrangedSubviews: [currentLocationTypeIconImageView, currentLocationTypeLabel])
        typeInfoStackView.axis = .horizontal
        typeInfoStackView.spacing = 5 // Расстояние между иконкой и текстом
        typeInfoStackView.alignment = .center
        typeInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(typeInfoStackView)
        
        // Constraints
        guard let topWidgetActualView = topWidgetHostingController?.view else {
            print("[WorldMapView] Error: topWidgetHostingController.view is nil, cannot constrain location labels properly.")
            // Fallback constraints
            NSLayoutConstraint.activate([
                currentLocationNameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 45),
                currentLocationNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                currentLocationNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
                currentLocationNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

                typeInfoStackView.topAnchor.constraint(equalTo: currentLocationNameLabel.bottomAnchor, constant: 4),
                typeInfoStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                currentLocationTypeIconImageView.widthAnchor.constraint(equalToConstant: 16), // Размер иконки
                currentLocationTypeIconImageView.heightAnchor.constraint(equalToConstant: 16) // Размер иконки
            ])
            return
        }

        NSLayoutConstraint.activate([
            currentLocationNameLabel.topAnchor.constraint(equalTo: topWidgetActualView.bottomAnchor, constant: 8),
            currentLocationNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            currentLocationNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            currentLocationNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            typeInfoStackView.topAnchor.constraint(equalTo: currentLocationNameLabel.bottomAnchor, constant: 4),
            typeInfoStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            // Ограничения для StackView, чтобы он мог сжиматься, если имя очень длинное, но при этом центрировался.
            // Можно также задать explicit width/height для иконки, если она имеет фиксированный размер.
            currentLocationTypeIconImageView.widthAnchor.constraint(equalToConstant: 16), // Примерный размер иконки
            currentLocationTypeIconImageView.heightAnchor.constraint(equalToConstant: 16) // Примерный размер иконки
        ])
    }

    private func setupBackButton() {
        backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "arrow.uturn.backward.circle.fill"), for: .normal)
        backButton.tintColor = .white // Or your desired color
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)

        guard let topWidgetView = topWidgetHostingController?.view else {
            print("[WorldMapView] Error: topWidgetHostingController.view is nil, cannot constrain back button properly.")
            // Fallback constraints if topWidgetView is not available
            NSLayoutConstraint.activate([
                backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
                backButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                backButton.widthAnchor.constraint(equalToConstant: 44),
                backButton.heightAnchor.constraint(equalToConstant: 44)
            ])
            return
        }

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: topWidgetView.bottomAnchor, constant: 10), // Below TopWidget
            backButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),   // Right side with padding
            backButton.widthAnchor.constraint(equalToConstant: 44), // Standard tap size
            backButton.heightAnchor.constraint(equalToConstant: 44)  // Standard tap size
        ])
    }

    @objc private func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }

    private func loadSceneData() {
        allScenes = LocationReader.getLocations()
        // TODO: Логирование, если сцены не загрузились
    }

    private func setupScrollView() {
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 3 // Ограничиваем максимальный зум до 90%
        scrollView.backgroundColor = .clear // <<< Make ScrollView background clear
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.bouncesZoom = false // Отключаем bounce эффект для зума
        view.addSubview(scrollView)
    }

    // Замена setupContentView
    private func setupMarkerViewLayout() {
        var minX = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude

        if allScenes.isEmpty {
            minX = 0; maxX = 300; minY = 0; maxY = 300; // Default size if no scenes
        } else {
        for scene in allScenes {
            let sceneX = CGFloat(scene.x) * coordinateScale
            let sceneY = CGFloat(scene.y) * coordinateScale
            minX = min(minX, sceneX)
            maxX = max(maxX, sceneX)
            minY = min(minY, sceneY)
            maxY = max(maxY, sceneY)
        }
        }
        
        // Используем sceneElementSize для расчета размеров
        let contentWidth = (maxX - minX) + sceneElementSize.width + 2 * padding
        let contentHeight = (maxY - minY) + sceneElementSize.height + 2 * padding
        
        markerRenderingView = MarkerView(frame: CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight))
        scrollView.addSubview(markerRenderingView)
        scrollView.contentSize = markerRenderingView.bounds.size

        // Добавляем обработчик нажатий к markerRenderingView
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(markerTapped(_:)))
        markerRenderingView.addGestureRecognizer(tapGesture)
    }

    // Новый метод для инициализации координат маркеров и scenePointCache только один раз
    private func initializeMarkerDrawDataIfNeeded() {
        print("[WorldMap] initializeMarkerDrawDataIfNeeded called. allScenes.count = \(allScenes.count)")
        markerDrawDataList.removeAll() // Убираем guard, всегда пересоздаем
        guard !allScenes.isEmpty else {
            print("[WorldMap] allScenes is empty, nothing to draw.")
            return
        }
        var newMarkerDataList: [MarkerDrawingData] = []
        newMarkerDataList.reserveCapacity(allScenes.count)
        var newCalculatedPoints: [Int: CGPoint] = [:]
        newCalculatedPoints.reserveCapacity(allScenes.count)
        var minX: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude
        for scene in allScenes {
            let sceneX = CGFloat(scene.x) * coordinateScale
            let sceneY = CGFloat(scene.y) * coordinateScale
            minX = min(minX, sceneX)
            maxX = max(maxX, sceneX)
            minY = min(minY, sceneY)
            maxY = max(maxY, sceneY)
            let elementOriginX = (sceneX - minMapX) + padding
            let elementOriginY = (sceneY - minMapY) + padding
            let sceneElementFrame = CGRect(origin: CGPoint(x: elementOriginX, y: elementOriginY), size: coloredRectangleSize)
            let coloredRectFrame = CGRect(origin: .zero, size: coloredRectangleSize)
            // --- Новая разметка для Optima иконки и типа ---
            let iconSize = CGSize(width: 18, height: 18)
            let nameLabelHeight: CGFloat = 14
            let typeLabelHeight: CGFloat = 12
            let spacing1: CGFloat = 2 // между иконкой и названием
            let spacing2: CGFloat = 0 // между названием и типом
            let totalContentHeight = iconSize.height + spacing1 + nameLabelHeight + spacing2 + typeLabelHeight
            let startY = (coloredRectangleSize.height - totalContentHeight) / 2
            let iconFrame = CGRect(x: (coloredRectangleSize.width - iconSize.width) / 2, y: startY, width: iconSize.width, height: iconSize.height)
            let nameLabelFrame = CGRect(x: 4, y: iconFrame.maxY + spacing1, width: coloredRectangleSize.width - 8, height: nameLabelHeight)
            let typeLabelFrame = CGRect(x: 4, y: nameLabelFrame.maxY + spacing2, width: coloredRectangleSize.width - 8, height: typeLabelHeight)
            // --- Цвет фона по npcActivityType ---
            let baseColorForType: UIColor = SceneTypeColorProvider.color(for: scene.sceneType)
            // --- Цвет иконки: белый если фон тёмный, иначе чёрный ---
            let iconTintColor: UIColor = baseColorForType.isDarkColor ? .white : .black
            let markerData = MarkerDrawingData(
                scene: scene,
                frame: sceneElementFrame,
                coloredRectangleFrame: coloredRectFrame,
                iconFrame: iconFrame,
                nameLabelFrame: nameLabelFrame,
                typeLabelFrame: typeLabelFrame,
                nameText: scene.name,
                typeText: scene.sceneType.displayName,
                iconImageName: scene.sceneType.iconName,
                baseBackgroundColor: baseColorForType,
                nameLabelColor: .white,
                typeLabelColor: .systemGreen,
                iconTintColor: iconTintColor,
                isLocked: scene.isLocked,
                isCurrent: false
            )
            newMarkerDataList.append(markerData)
            let pointX = markerData.frame.origin.x + markerData.coloredRectangleFrame.midX
            let pointY = markerData.frame.origin.y + markerData.coloredRectangleFrame.midY
            newCalculatedPoints[scene.id] = CGPoint(x: pointX, y: pointY)
            print("[WorldMap] Scene id=\(scene.id) name=\(scene.name) x=\(scene.x) y=\(scene.y) -> frame=\(sceneElementFrame)")
        }
        print("[WorldMap] minX=\(minX) maxX=\(maxX) minY=\(minY) maxY=\(maxY)")
        print("[WorldMap] markerDrawDataList.count = \(newMarkerDataList.count)")
        markerDrawDataList = newMarkerDataList
        pendingScenePointCache = newCalculatedPoints
        markerRenderingView?.setNeedsDisplay()
        print("[WorldMap] markerRenderingView.setNeedsDisplay() called")
    }

    // Замена setupMarkersAndLines - теперь это в основном про linesView
    private func setupLinesView() {
        guard !allScenes.isEmpty else { return }
        
        linesView = MapLinesView(frame: markerRenderingView.bounds) // linesView занимает все пространство markerRenderingView
        linesView.backgroundColor = .clear
        linesView.scenes = allScenes // MapLinesView все еще может использовать allScenes для получения связей
        linesView.currentSceneId = nil // <<< ПЕРЕДАЕМ ID В LINESVIEW
        
        markerRenderingView.addSubview(linesView) // Добавляем linesView в markerRenderingView
    }

    // MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomableViewContainer // <<< ВОЗВРАЩАЕМ ОБЩИЙ КОНТЕЙНЕР
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // print("[WorldMapView] scrollViewDidZoom - body commented out for diagnostics. Zoom: \(scrollView.zoomScale)")
    }

    // MARK: - Gesture Recognizer Handler
    @objc private func markerTapped(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: markerRenderingView)
        for data in markerDrawDataList {
            let liveSceneFromAllScenes = self.allScenes.first(where: { $0.id == data.scene.id })
            let isActuallyLocked = liveSceneFromAllScenes?.isLocked ?? true
            if !isActuallyLocked && data.frame.contains(tapLocation) {
                guard let tappedSceneObjectForLogic = liveSceneFromAllScenes else {
                    print("[WorldMapView] Error: Tapped scene (ID: \(data.scene.id)) not found in self.allScenes despite being tappable. Skipping.")
                    continue
                }
                if GameStateService.shared.currentScene?.id == tappedSceneObjectForLogic.id {
                    return
                }
                guard let currentScene = GameStateService.shared.currentScene else {
                    print("[WorldMapView] Error: Current scene is not set in GameStateService. Cannot determine valid moves.")
                    return
                }
                let isConnected = currentScene.connections.contains { connection in
                    connection.connectedSceneId == tappedSceneObjectForLogic.id
                }
                if isConnected {
                    let sceneIdToMoveTo = tappedSceneObjectForLogic.id
                    // --- LOG: время до смены локации ---
                    let perfStart = Date()
                    try? GameStateService.shared.changeLocation(to: sceneIdToMoveTo)
                    let perfAfterChange = Date()
                    print("[PERF] changeLocation duration: \((perfAfterChange.timeIntervalSince(perfStart) * 1000).rounded()) ms")
                    // --- обновляем только статусы и собираем изменённые фреймы ---
                    var changedRects: [CGRect] = []
                    for i in 0..<markerDrawDataList.count {
                        let sceneId = markerDrawDataList[i].scene.id
                        if let updatedScene = allScenes.first(where: { $0.id == sceneId }) {
                            let oldIsLocked = markerDrawDataList[i].isLocked
                            let oldIsCurrent = markerDrawDataList[i].isCurrent
                            let newIsLocked = updatedScene.isLocked
                            let newIsCurrent = (sceneId == sceneIdToMoveTo)
                            if oldIsLocked != newIsLocked || oldIsCurrent != newIsCurrent {
                                changedRects.append(markerDrawDataList[i].frame.insetBy(dx: -10, dy: -10))
                            }
                            markerDrawDataList[i].isLocked = newIsLocked
                            markerDrawDataList[i].isCurrent = newIsCurrent
                        }
                    }
                    let perfBeforeUI = Date()
                    // setNeedsDisplay только для изменённых маркеров, которые видимы на экране (lazy rendering)
                    let visibleRect = scrollView.convert(scrollView.bounds, to: markerRenderingView)
                    for rect in changedRects {
                        if rect.intersects(visibleRect) {
                            markerRenderingView.setNeedsDisplay(rect)
                        }
                    }
                    markerRenderingView.setCurrentSceneId(sceneIdToMoveTo)
                    linesView.currentSceneId = sceneIdToMoveTo
                    linesView.setNeedsDisplay()
                    if let newCurrentSceneData = allScenes.first(where: { $0.id == sceneIdToMoveTo }) {
                        currentLocationNameLabel.text = newCurrentSceneData.name
                        currentLocationTypeLabel.text = newCurrentSceneData.sceneType.displayName
                        currentLocationTypeIconImageView.image = UIImage(systemName: newCurrentSceneData.sceneType.iconName)
                    } else {
                        currentLocationNameLabel.text = "N/A"
                        currentLocationTypeLabel.text = ""
                        currentLocationTypeIconImageView.image = nil
                    }
                    DispatchQueue.main.async {
                        self.centerCameraOnScene(withId: sceneIdToMoveTo, animated: true)
                    }
                    let perfAfterUI = Date()
                    print("[PERF] UI update duration: \((perfAfterUI.timeIntervalSince(perfBeforeUI) * 1000).rounded()) ms")
                    self.updateGlowView(for: sceneIdToMoveTo)
                    return
                } else {
                    print("[WorldMapView] Cannot move to scene '\(tappedSceneObjectForLogic.name)' (ID: \(tappedSceneObjectForLogic.id)). It is not directly connected to the current scene '\(currentScene.name)' (ID: \(currentScene.id)).")
                    return
                }
            }
        }
    }

    // Замена setupContentView -> configureMarkerView
    private func configureMarkerView(boundsForMarkerView: CGRect) { // Изменен параметр
        markerRenderingView = MarkerView(frame: boundsForMarkerView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(markerTapped(_:)))
        markerRenderingView.addGestureRecognizer(tapGesture)
        // markerRenderingView.linesView больше не нужен, так как они на одном уровне в zoomableViewContainer
    }

    // Замена setupLinesView -> configureLinesView
    private func configureLinesView(boundsForLinesView: CGRect) {
        linesView = MapLinesView(frame: boundsForLinesView) 
        linesView.backgroundColor = .clear
        
        // Удаляем связь с MarkerView, так как они теперь соседи
        // guard let mrView = markerRenderingView else { return } 
        // mrView.addSubview(linesView)
        // mrView.sendSubviewToBack(linesView)
        // mrView.linesView = linesView 
    }

    // MARK: - Центрирование камеры на сцене
    private func centerCameraOnScene(withId sceneId: Int, animated: Bool = true) {
        guard let markerRenderingView = markerRenderingView,
              let zoomableViewContainer = zoomableViewContainer,
              let markerData = markerDrawDataList.first(where: { $0.scene.id == sceneId }) else { return }
        let markerRectInContainer = markerRenderingView.convert(markerData.frame, to: zoomableViewContainer)
        let markerCenter = CGPoint(x: markerRectInContainer.midX, y: markerRectInContainer.midY)
        let zoom = scrollView.zoomScale
        let visibleSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize

        var targetOffset = CGPoint(
            x: markerCenter.x * zoom - visibleSize.width / 2,
            y: markerCenter.y * zoom - visibleSize.height / 2
        )
        let maxOffsetX = contentSize.width - visibleSize.width
        let maxOffsetY = contentSize.height - visibleSize.height
        targetOffset.x = max(0, min(targetOffset.x, maxOffsetX))
        targetOffset.y = max(0, min(targetOffset.y, maxOffsetY))

        print("[DEBUG] Centering on scene \(sceneId): markerCenter=\(markerCenter), zoom=\(zoom), visibleSize=\(visibleSize), targetOffset=\(targetOffset), contentSize=\(contentSize)")
        scrollView.setContentOffset(targetOffset, animated: animated)
    }

    private func updateGlowView(for sceneId: Int) {
        guard let markerData = markerDrawDataList.first(where: { $0.scene.id == sceneId }) else {
            glowView?.removeFromSuperview()
            glowView = nil
            return
        }
        let markerFrame = markerRenderingView.convert(markerData.frame, to: markerRenderingView)
        let coloredRect = markerData.coloredRectangleFrame
        let coloredRectInView = CGRect(x: markerFrame.origin.x + coloredRect.origin.x, y: markerFrame.origin.y + coloredRect.origin.y, width: coloredRect.width, height: coloredRect.height)
        let glow: UIView
        if let existing = glowView {
            glow = existing
        } else {
            glow = UIView()
            glow.isUserInteractionEnabled = false
            markerRenderingView.addSubview(glow)
            glowView = glow
        }
        glow.frame = coloredRectInView.insetBy(dx: -4, dy: -4)
        glow.backgroundColor = .clear
        glow.layer.shadowColor = UIColor.yellow.cgColor
        glow.layer.shadowOpacity = 0.8
        glow.layer.shadowRadius = 8.0
        glow.layer.shadowOffset = .zero
        glow.layer.cornerRadius = 10
        glow.layer.masksToBounds = false
        glow.layer.borderColor = UIColor.clear.cgColor
        // Можно добавить анимацию появления/исчезновения при желании
    }
}

class MapLinesView: UIView {
    var scenes: [Scene] = []
    var scenePointCache: [Int: CGPoint] = [:] // Будет заполняться извне
    var currentSceneId: Int? 

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        // print("[MapLinesView] Frame: \(self.frame), Bounds: \(self.bounds)") // ОТЛАДКА - РАСКОММЕНТИРОВАНО
        guard let context = UIGraphicsGetCurrentContext() else { return }
        guard !scenePointCache.isEmpty else { 
            // print("[MapLinesView] scenePointCache is empty, not drawing lines.")
            return
        }
        guard !scenes.isEmpty else { // Добавим проверку, что массив scenes не пуст
            // print("[MapLinesView] scenes array is empty, cannot determine locked status for connections.")
            return
        }

        // Создаем словарь для быстрого доступа к сценам по ID
        let scenesById = Dictionary(uniqueKeysWithValues: self.scenes.map { ($0.id, $0) })

        let defaultLineColor = UIColor.lightGray.cgColor
        let currentSceneLineColor = UIColor.systemGreen.cgColor
        let defaultLineWidth: CGFloat = 0.7
        let currentLineWidth: CGFloat = 2.0 // <<< Увеличено с 1.4

        var drawnConnections = Set<String>() 

        // --- ОТЛАДКА: Рисуем точки из scenePointCache --- (перед линиями)
        /*
        let debugLineDotColor = UIColor.cyan
        let debugLineDotSize: CGFloat = 3.0 // Чуть меньше, чтобы видеть перекрытие
        context.setFillColor(debugLineDotColor.cgColor)
        for (_, point) in self.scenePointCache {
            let dotRect = CGRect(x: point.x - debugLineDotSize / 2.0, 
                                 y: point.y - debugLineDotSize / 2.0, 
                                 width: debugLineDotSize, 
                                 height: debugLineDotSize)
            context.fillEllipse(in: dotRect)
        }
        */
        // --- КОНЕЦ ОТЛАДКИ ---

        for scene in scenes { // Это sourceScene
            guard let startPoint = scenePointCache[scene.id] else { continue }
            
            for connection in scene.connections {
                let targetSceneId = connection.connectedSceneId
                guard let endPoint = scenePointCache[targetSceneId] else { continue }
                
                let minId = min(scene.id, targetSceneId)
                let maxId = max(scene.id, targetSceneId)
                let connectionKey = "\(minId)-\(maxId)"

                if drawnConnections.contains(connectionKey) {
                    continue 
                }
                
                var drawAsCurrentConnection = false
                if let currentId = self.currentSceneId {
                    if scene.id == currentId { // Текущая сцена - это source (scene)
                        // Проверяем, что targetSceneId не заблокирована
                        if let targetScene = scenesById[targetSceneId], !targetScene.isLocked {
                            drawAsCurrentConnection = true
                        }
                    } else if targetSceneId == currentId { // Текущая сцена - это target
                        // Проверяем, что sourceScene (scene) не заблокирована
                        if !scene.isLocked {
                            drawAsCurrentConnection = true
                        }
                    }
                }
                
                context.beginPath()
                context.move(to: startPoint)
                context.addLine(to: endPoint)

                if drawAsCurrentConnection {
                    context.saveGState() // Сохраняем состояние перед применением спецэффектов
                    
                    context.setStrokeColor(currentSceneLineColor)
                    context.setLineWidth(currentLineWidth)
                    // Добавляем свечение
                    context.setShadow(offset: .zero, blur: 6.0, color: UIColor.systemGreen.withAlphaComponent(0.8).cgColor) // <<< blur увеличен с 4.0, alpha с 0.6
                    
                    context.strokePath()
                    
                    context.restoreGState() // Восстанавливаем состояние (убираем тень и др.)
                } else {
                    // Убедимся, что для обычных линий тень не применяется (хотя restoreGState должен это делать)
                    // context.setShadow(offset: .zero, blur: 0, color: nil) // Можно раскомментировать для явного сброса тени
                    context.setStrokeColor(defaultLineColor)
                    context.setLineWidth(defaultLineWidth)
                context.strokePath()
                }
                
                drawnConnections.insert(connectionKey) 
            }
        }
    }
}

// --- ВСПОМОГАТЕЛЬНЫЙ КЛАСС ДЛЯ ЦВЕТА ---
extension UIColor {
    var isDarkColor: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        // Простая формула яркости
        let brightness = (r * 299 + g * 587 + b * 114) / 1000
        return brightness < 0.5
    }
}

class SceneTypeColorProvider {
    static func color(for type: SceneType) -> UIColor {
        switch type {
        case .tavern: return UIColor(red: 0.7, green: 0.4, blue: 0.1, alpha: 1)
        case .square: return UIColor.systemGreen
        case .blacksmith: return UIColor.darkGray
        case .house: return UIColor.systemBlue
        case .road: return UIColor.lightGray
        case .temple: return UIColor.systemPurple
        case .shop: return UIColor.systemOrange
        case .cathedral: return UIColor.systemIndigo
        case .castle: return UIColor.systemGray
        case .crypt: return UIColor.darkGray
        case .mine: return UIColor.brown
        case .forest: return UIColor.systemGreen
        case .cave: return UIColor.brown
        case .ruins: return UIColor.systemGray2
        case .brothel: return UIColor.systemPink
        case .bathhouse: return UIColor.systemTeal
        case .docks: return UIColor.systemTeal
        case .manor: return UIColor.systemYellow
        case .military: return UIColor.systemRed
        case .warehouse: return UIColor.systemGray3
        case .bookstore: return UIColor.systemTeal
        case .alchemistShop: return UIColor.systemPurple
        case .district: return UIColor.systemGray4
        case .town: return UIColor.systemGray5
        case .cloister: return UIColor.systemGray6
        case .cemetery: return UIColor.systemGray
        case .dungeon: return UIColor.black
        default: return UIColor.systemGray
        }
    }
}

// --- ПРОТОТИП: Виртуализированная карта для 10 000+ сцен ---

import UIKit

class VirtualWorldMapViewController: UIViewController, UIScrollViewDelegate {
    private let coordinateScale: CGFloat = 80.0 // Оставим как в редакторе, чтобы совпадало позиционирование
    private let markerSize = CGSize(width: 120, height: 60) // Было 50, теперь 60
    private let padding: CGFloat = 50.0
    private var allScenes: [Scene] = []
    private var currentSceneId: Int? { GameStateService.shared.currentScene?.id }
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var markerViews: [Int: UIButton] = [:] // sceneId -> marker
    private var linesLayer: CAShapeLayer!
    private var visibleSceneIds: Set<Int> = []
    private var minMapX: CGFloat = 0
    private var minMapY: CGFloat = 0
    private var contentSize: CGSize = .zero
    private var greenLinesLayer: CAShapeLayer! // Новый слой для зелёных линий
    private var currentLocationInfoView: UIView! // Новый view для названия и типа текущей локации
    private var currentLocationNameLabel: UILabel!
    private var currentLocationTypeLabel: UILabel!
    private var markerImageCache = NSCache<NSNumber, UIImage>() // Кэш для ассетов маркеров
    private var didAnimateContentAppearance = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        loadSceneData()
        guard !allScenes.isEmpty else { return }
        calculateContentBounds()
        setupScrollView()
        setupContentView()
        scrollView.alpha = 0 // Скрываем scrollView перед анимацией
        setupLinesLayer()
        setupCurrentLocationInfoView()
        currentLocationInfoView.alpha = 0 // Скрываем инфо о локации перед анимацией
        updateVisibleMarkersAndLines()
        centerOnCurrentScene(animated: false)
        updateCurrentLocationInfo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didAnimateContentAppearance {
            didAnimateContentAppearance = true
            print("[DEBUG] scrollView.alpha before animation: \(self.scrollView.alpha), currentLocationInfoView.alpha: \(self.currentLocationInfoView.alpha)")
            UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveEaseOut, animations: {
                self.scrollView.alpha = 1.0
                self.currentLocationInfoView.alpha = 1.0
            }, completion: nil)
        }
    }
    
    private func loadSceneData() {
        allScenes = LocationReader.getLocations()
    }
    
    private func calculateContentBounds() {
        let xs = allScenes.map { CGFloat($0.x) * coordinateScale }
        let ys = allScenes.map { CGFloat($0.y) * coordinateScale }
        minMapX = xs.min() ?? 0
        minMapY = ys.min() ?? 0
        let maxMapX = xs.max() ?? 0
        let maxMapY = ys.max() ?? 0
        contentSize = CGSize(
            width: (maxMapX - minMapX) + markerSize.width + 2 * padding,
            height: (maxMapY - minMapY) + markerSize.height + 2 * padding
        )
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.backgroundColor = .black
        scrollView.minimumZoomScale = 0.3
        scrollView.maximumZoomScale = 2.0
        scrollView.contentSize = contentSize
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.bouncesZoom = false // Отключаем bounce эффект для зума
        view.addSubview(scrollView)
    }
    
    private func setupContentView() {
        contentView = UIView(frame: CGRect(origin: .zero, size: contentSize))
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)
    }
    
    private func setupLinesLayer() {
        linesLayer = CAShapeLayer()
        linesLayer.frame = contentView.bounds
        linesLayer.strokeColor = UIColor.gray.cgColor
        linesLayer.lineWidth = 1.0
        linesLayer.fillColor = nil
        contentView.layer.addSublayer(linesLayer)

        greenLinesLayer = CAShapeLayer()
        greenLinesLayer.frame = contentView.bounds
        greenLinesLayer.strokeColor = UIColor.systemGreen.cgColor
        greenLinesLayer.lineWidth = 2.0
        greenLinesLayer.fillColor = nil
        contentView.layer.addSublayer(greenLinesLayer)
    }
    
    private func setupCurrentLocationInfoView() {
        let infoView = UIView()
        infoView.backgroundColor = .clear
        infoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoView)
        // Название
        let nameLabel = UILabel()
        nameLabel.font = UIFont(name: "Optima-Bold", size: 26) ?? UIFont.systemFont(ofSize: 26, weight: .bold)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        nameLabel.layer.shadowColor = UIColor.black.cgColor
        nameLabel.layer.shadowRadius = 3
        nameLabel.layer.shadowOpacity = 0.7
        nameLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        infoView.addSubview(nameLabel)
        // Тип
        let typeLabel = UILabel()
        typeLabel.font = UIFont(name: "Optima-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18)
        typeLabel.textColor = .systemYellow
        typeLabel.textAlignment = .center
        typeLabel.numberOfLines = 2
        typeLabel.adjustsFontSizeToFitWidth = true
        typeLabel.minimumScaleFactor = 0.5
        typeLabel.lineBreakMode = .byTruncatingTail
        typeLabel.layer.shadowColor = UIColor.black.cgColor
        typeLabel.layer.shadowRadius = 2
        typeLabel.layer.shadowOpacity = 0.7
        typeLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        infoView.addSubview(typeLabel)
        // Constraints
        NSLayoutConstraint.activate([
            infoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            infoView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.9),
            nameLabel.topAnchor.constraint(equalTo: infoView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor),
            typeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            typeLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor),
            typeLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor),
            typeLabel.bottomAnchor.constraint(equalTo: infoView.bottomAnchor)
        ])
        self.currentLocationInfoView = infoView
        self.currentLocationNameLabel = nameLabel
        self.currentLocationTypeLabel = typeLabel
    }

    private func updateCurrentLocationInfo() {
        guard let scene = allScenes.first(where: { $0.id == currentSceneId }) else { return }
        currentLocationNameLabel.text = scene.name
        currentLocationTypeLabel.text = scene.sceneType.displayName
    }

    private func updateVisibleMarkersAndLines() {
        let visibleRect = scrollView.convert(scrollView.bounds, to: contentView)
        let margin: CGFloat = 200 // чуть больше, чтобы не мигали на границе
        let extendedRect = visibleRect.insetBy(dx: -margin, dy: -margin)
        var newVisibleIds: Set<Int> = []
        let zoom = scrollView.zoomScale
        let assetAlpha = assetAlphaForZoom(zoom)
        for scene in allScenes {
            let pos = scenePosition(scene)
            let markerFrame = CGRect(origin: pos, size: markerSize)
            if markerFrame.intersects(extendedRect) {
                newVisibleIds.insert(scene.id)
                if markerViews[scene.id] == nil {
                    let marker = UIButton(type: .custom)
                    marker.frame = markerFrame
                    var imageView: UIImageView? = nil
                    // --- Картинка ассета, если есть ---
                    var bgColor = SceneTypeColorProvider.color(for: scene.sceneType)
                    if let img = markerImageCache.object(forKey: NSNumber(value: scene.id)) {
                        imageView = UIImageView(frame: marker.bounds)
                        imageView!.image = img
                        imageView!.contentMode = .scaleAspectFill
                        imageView!.clipsToBounds = true
                        imageView!.layer.cornerRadius = 8
                        imageView!.alpha = assetAlpha
                        marker.addSubview(imageView!)
                        // Цветной фон не нужен, если ассет есть (будет проявляться через alpha)
                        marker.backgroundColor = bgColor
                    } else if let img = UIImage(named: "location\(scene.id)") {
                        markerImageCache.setObject(img, forKey: NSNumber(value: scene.id))
                        imageView = UIImageView(frame: marker.bounds)
                        imageView!.image = img
                        imageView!.contentMode = .scaleAspectFill
                        imageView!.clipsToBounds = true
                        imageView!.layer.cornerRadius = 8
                        imageView!.alpha = assetAlpha
                        marker.addSubview(imageView!)
                        marker.backgroundColor = bgColor
                    } else {
                        marker.backgroundColor = bgColor
                    }
                    // Если ассет есть и alpha=0, скрыть imageView
                    if let iv = imageView, assetAlpha <= 0.01 { iv.isHidden = true } else { imageView?.isHidden = false }
                    // Цвет иконки по фону
                    let iconTint: UIColor = bgColor.isDarkColor ? .white : .black
                    let iconImageView = UIImageView(frame: CGRect(x: (markerSize.width-18)/2, y: 4, width: 18, height: 18))
                    iconImageView.contentMode = .scaleAspectFit
                    iconImageView.image = UIImage(systemName: scene.sceneType.iconName)
                    iconImageView.tintColor = iconTint
                    marker.addSubview(iconImageView)
                    let nameLabel = UILabel(frame: CGRect(x: 4, y: 24, width: markerSize.width-8, height: 16))
                    nameLabel.text = scene.name
                    nameLabel.font = UIFont(name: "Optima-Bold", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .bold)
                    nameLabel.textColor = .white
                    nameLabel.textAlignment = .center
                    nameLabel.adjustsFontSizeToFitWidth = true
                    nameLabel.minimumScaleFactor = 0.7
                    nameLabel.lineBreakMode = .byTruncatingTail
                    nameLabel.layer.zPosition = 10
                    marker.addSubview(nameLabel)
                    let typeLabel = UILabel(frame: CGRect(x: 4, y: 40, width: markerSize.width-8, height: 18))
                    typeLabel.text = scene.sceneType.displayName
                    typeLabel.font = UIFont(name: "Optima-Regular", size: 11) ?? UIFont.systemFont(ofSize: 11)
                    typeLabel.textColor = .white
                    typeLabel.textAlignment = .center
                    typeLabel.numberOfLines = 2
                    typeLabel.adjustsFontSizeToFitWidth = true
                    typeLabel.minimumScaleFactor = 0.5
                    typeLabel.lineBreakMode = .byTruncatingTail
                    typeLabel.layer.shadowColor = UIColor.black.cgColor
                    typeLabel.layer.shadowRadius = 1.5
                    typeLabel.layer.shadowOpacity = 0.7
                    typeLabel.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
                    typeLabel.layer.zPosition = 10
                    marker.addSubview(typeLabel)
                    marker.layer.cornerRadius = 8
                    marker.layer.borderWidth = 1.0
                    marker.layer.borderColor = (scene.id == currentSceneId) ? UIColor.yellow.cgColor : UIColor.black.cgColor
                    marker.tag = scene.id
                    marker.addTarget(self, action: #selector(markerTapped(_:)), for: .touchUpInside)
                    contentView.addSubview(marker)
                    markerViews[scene.id] = marker
                } else {
                    let marker = markerViews[scene.id]!
                    marker.layer.borderColor = (scene.id == currentSceneId) ? UIColor.yellow.cgColor : UIColor.black.cgColor
                    // Обновить alpha ассета при изменении зума
                    if let imageView = marker.subviews.compactMap({ $0 as? UIImageView }).first {
                        let assetAlpha = assetAlphaForZoom(scrollView.zoomScale)
                        imageView.alpha = assetAlpha
                        imageView.isHidden = assetAlpha <= 0.01
                    }
                }
            }
        }
        for (sceneId, marker) in markerViews where !newVisibleIds.contains(sceneId) {
            marker.removeFromSuperview()
        }
        markerViews = markerViews.filter { newVisibleIds.contains($0.key) }
        visibleSceneIds = newVisibleIds
        drawLines()
    }
    
    private func scenePosition(_ scene: Scene) -> CGPoint {
        let x = (CGFloat(scene.x) * coordinateScale - minMapX) + padding
        let y = (CGFloat(scene.y) * coordinateScale - minMapY) + padding
        return CGPoint(x: x, y: y)
    }
    
    private func drawLines() {
        let grayPath = UIBezierPath()
        let greenPath = UIBezierPath()
        for scene in allScenes {
            let start = scenePosition(scene)
            for conn in scene.connections {
                guard let target = allScenes.first(where: { $0.id == conn.connectedSceneId }) else { continue }
                // Рисуем, если хотя бы один маркер видим
                if !visibleSceneIds.contains(scene.id) && !visibleSceneIds.contains(target.id) { continue }
                let end = scenePosition(target)
                let line = UIBezierPath()
                line.move(to: CGPoint(x: start.x + markerSize.width/2, y: start.y + markerSize.height/2))
                line.addLine(to: CGPoint(x: end.x + markerSize.width/2, y: end.y + markerSize.height/2))
                // Только для connections текущей сцены и если target доступен — зелёная линия
                if scene.id == currentSceneId && !target.isLocked {
                    greenPath.append(line)
                } else {
                    grayPath.append(line)
                }
            }
        }
        linesLayer.path = grayPath.cgPath
        greenLinesLayer.path = greenPath.cgPath
    }
    
    @objc private func markerTapped(_ sender: UIButton) {
        let sceneId = sender.tag
        if let scene = allScenes.first(where: { $0.id == sceneId }) {
            try? GameStateService.shared.changeLocation(to: sceneId)
            currentSceneChanged(to: sceneId)
        }
    }
    
    private func currentSceneChanged(to sceneId: Int) {
        // Обновить выделение
        for (id, marker) in markerViews {
            marker.layer.borderColor = (id == sceneId) ? UIColor.yellow.cgColor : UIColor.black.cgColor
        }
        centerOnCurrentScene(animated: true)
        updateVisibleMarkersAndLines()
        updateCurrentLocationInfo()
    }
    
    private func centerOnCurrentScene(animated: Bool) {
        guard let sceneId = currentSceneId, let scene = allScenes.first(where: { $0.id == sceneId }) else { return }
        let pos = scenePosition(scene)
        let center = CGPoint(x: pos.x + markerSize.width/2, y: pos.y + markerSize.height/2)
        let visibleSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize
        // Проверяем, что размеры актуальны
        guard contentSize.width > 0, contentSize.height > 0, visibleSize.width > 0, visibleSize.height > 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.centerOnCurrentScene(animated: animated)
            }
            return
        }
        var offset = CGPoint(
            x: max(0, min(center.x - visibleSize.width/2, contentSize.width - visibleSize.width)),
            y: max(0, min(center.y - visibleSize.height/2, contentSize.height - visibleSize.height))
        )
        // Если карта меньше экрана — offset = 0
        if contentSize.width <= visibleSize.width { offset.x = 0 }
        if contentSize.height <= visibleSize.height { offset.y = 0 }
        DispatchQueue.main.async {
            self.scrollView.setContentOffset(offset, animated: animated)
        }
    }
    
    // UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateVisibleMarkersAndLines()
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateVisibleMarkersAndLines()
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    // Функция для вычисления прозрачности ассета в зависимости от зума
    private func assetAlphaForZoom(_ zoom: CGFloat) -> CGFloat {
        // Примерная логика: zoom >= 0.7 — ассет полностью видим, zoom <= 0.3 — полностью прозрачен
        if zoom >= 0.7 { return 1.0 }
        if zoom <= 0.3 { return 0.0 }
        // Линейная интерполяция
        return (zoom - 0.3) / (0.7 - 0.3)
    }
} 
