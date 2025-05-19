import UIKit
import SwiftUI // <<< Added for UIHostingController

// Структура для хранения данных, необходимых для отрисовки одного маркера
struct MarkerDrawingData {
    let scene: Scene // Оригинальные данные сцены
    let frame: CGRect // Общий прямоугольник для всего элемента маркера
    let coloredRectangleFrame: CGRect // Прямоугольник для цветной/изображенческой части
    let iconFrame: CGRect
    let nameLabelFrame: CGRect
    let typeLabelFrame: CGRect
    
    let nameText: String
    let typeText: String
    let iconImageName: String // SF Symbol для иконки типа
    
    let baseBackgroundColor: UIColor // Базовый цвет фона (по типу сцены)
    let nameLabelColor: UIColor
    let typeLabelColor: UIColor
    let iconTintColor: UIColor
    
    // let sceneImage: UIImage? // УДАЛЕНО: Предзагруженное изображение, если есть
    let sceneImageNameSuffix: String // Суффикс для имени изображения ("location<ID>")
    
    var isLocked: Bool // Будет обновляться
    var isCurrent: Bool // Будет обновляться
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
            let intersectsDrawRect = markerFrame.intersects(rect)
            
            if !intersectsDrawRect { continue } 

            context.saveGState()
            context.translateBy(x: data.frame.origin.x, y: data.frame.origin.y)

            // Пытаемся загрузить изображение сцены
            var sceneImageToDraw: UIImage? = nil
            if !data.sceneImageNameSuffix.isEmpty { // Убедимся, что имя не пустое
                // >>> ОТЛАДКА (Закомментировано)
                /*
                print("[MarkerView] Attempting to load image: '\(data.sceneImageNameSuffix)' for scene ID: \(data.scene.id)")
                sceneImageToDraw = UIImage(named: data.sceneImageNameSuffix)
                if sceneImageToDraw == nil {
                    print("[MarkerView] Image '\(data.sceneImageNameSuffix)' NOT FOUND for scene ID: \(data.scene.id).")
                } else {
                    print("[MarkerView] Image '\(data.sceneImageNameSuffix)' LOADED SUCCESSFULLY for scene ID: \(data.scene.id).")
                }
                */
                // <<< КОНЕЦ ОТЛАДКИ
                sceneImageToDraw = UIImage(named: data.sceneImageNameSuffix) // Оставляем только загрузку
            }
            
            let hasImage = (sceneImageToDraw != nil)
            let actualBackgroundColor = hasImage ? .clear : data.baseBackgroundColor

            // --- Отрисовка основного цветного/изображенческого прямоугольника ---
            if data.isCurrent {
                if hasImage { // Свечение для маркеров с изображением
                    context.saveGState()
                    UIColor.yellow.withAlphaComponent(0.6).setFill()
                    context.setShadow(offset: .zero, blur: 8.0, color: UIColor.yellow.withAlphaComponent(0.8).cgColor)
                    let glowRect = data.coloredRectangleFrame.insetBy(dx: -4, dy: -4)
                    let glowPath = UIBezierPath(roundedRect: glowRect, cornerRadius: 10)
                    glowPath.fill()
                    context.restoreGState()

                    actualBackgroundColor.setFill() // Должен быть .clear
                    let backgroundPath = UIBezierPath(roundedRect: data.coloredRectangleFrame, cornerRadius: 8)
                    backgroundPath.fill()
                } else { // Свечение для маркеров без изображения (только цветной фон)
                    context.saveGState() 
                    context.setShadow(offset: .zero, blur: 8.0, color: UIColor.yellow.cgColor)
                    
                    actualBackgroundColor.setFill() // Это будет data.baseBackgroundColor
                    let shadowCastingPath = UIBezierPath(roundedRect: data.coloredRectangleFrame, cornerRadius: 8)
                    shadowCastingPath.fill()
                    context.restoreGState() 
                }
            } else { // Не текущий, просто рисуем фон
                actualBackgroundColor.setFill()
                let backgroundPath = UIBezierPath(roundedRect: data.coloredRectangleFrame, cornerRadius: 8)
                backgroundPath.fill()
            }

            // Рисуем изображение поверх фона, если оно есть
            if let image = sceneImageToDraw { // Используем загруженное изображение
                context.saveGState()
                let imagePath = UIBezierPath(roundedRect: data.coloredRectangleFrame, cornerRadius: 8)
                imagePath.addClip()
                image.draw(in: data.coloredRectangleFrame)
                context.restoreGState()
            }
            
            // Рисуем рамку для цветного прямоугольника
            UIColor.black.setStroke()
            let borderDrawingPath = UIBezierPath(roundedRect: data.coloredRectangleFrame, cornerRadius: 8)
            borderDrawingPath.lineWidth = 0.5
            borderDrawingPath.stroke()

            // --- ОТЛАДКА: Рисуем точку в центре цветного прямоугольника ---
            /*
            let debugMarkerDotColor = UIColor.magenta
            let debugMarkerDotSize: CGFloat = 4.0
            let dotX_relative = data.coloredRectangleFrame.midX - debugMarkerDotSize / 2.0
            let dotY_relative = data.coloredRectangleFrame.midY - debugMarkerDotSize / 2.0
            let debugDotRect = CGRect(x: dotX_relative, y: dotY_relative, width: debugMarkerDotSize, height: debugMarkerDotSize)
            context.setFillColor(debugMarkerDotColor.cgColor)
            context.fillEllipse(in: debugDotRect)
            */
            // --- КОНЕЦ ОТЛАДКИ ---

            // --- Отрисовка иконки ---
            let baseIconFrame = data.iconFrame 

            if data.isLocked {
                let lockIconSFName = "lock.fill"
                let lockIconColor = UIColor(white: 0.85, alpha: 1.0)
                
                let spacingBetweenIcons: CGFloat = 2.0
                
                let maxWidthPerIcon = (baseIconFrame.width - spacingBetweenIcons) / 2.0
                let maxHeightPerIcon = baseIconFrame.height
                let iconSideLength = max(1.0, min(maxWidthPerIcon, maxHeightPerIcon))
                
                let totalOccupiedWidth = iconSideLength * 2 + spacingBetweenIcons
                
                let startX = baseIconFrame.origin.x + (baseIconFrame.width - totalOccupiedWidth) / 2.0
                let startY = baseIconFrame.origin.y + (baseIconFrame.height - iconSideLength) / 2.0

                let typeIconActualRect = CGRect(
                    x: startX,
                    y: startY,
                    width: iconSideLength,
                    height: iconSideLength
                )
                
                let lockIconActualRect = CGRect(
                    x: typeIconActualRect.maxX + spacingBetweenIcons,
                    y: startY,
                    width: iconSideLength,
                    height: iconSideLength
                )

                if let typeIconImage = UIImage(systemName: data.iconImageName) {
                    typeIconImage.withTintColor(data.iconTintColor).draw(in: typeIconActualRect)
                }

                if let lockImage = UIImage(systemName: lockIconSFName) {
                    lockImage.withTintColor(lockIconColor).draw(in: lockIconActualRect)
                }

            } else {
                let iconSideLength = min(baseIconFrame.width, baseIconFrame.height)
                let centeredIconX = baseIconFrame.origin.x + (baseIconFrame.width - iconSideLength) / 2.0
                let centeredIconY = baseIconFrame.origin.y + (baseIconFrame.height - iconSideLength) / 2.0
                let centeredSquareFrame = CGRect(x: centeredIconX, y: centeredIconY, width: iconSideLength, height: iconSideLength)

                if let icon = UIImage(systemName: data.iconImageName) {
                    icon.withTintColor(data.iconTintColor).draw(in: centeredSquareFrame) 
                }
            }

            // --- Отрисовка названия локации ---
            let nameParagraphStyle = NSMutableParagraphStyle()
            nameParagraphStyle.alignment = .center
            nameParagraphStyle.lineBreakMode = .byTruncatingTail
            
            let nameShadow = NSShadow()
            nameShadow.shadowColor = UIColor.black.withAlphaComponent(0.5)
            nameShadow.shadowOffset = CGSize(width: 0.7, height: 0.7)
            nameShadow.shadowBlurRadius = 1.0
            
            let nameFont: UIFont
            if let optimaBoldFont = UIFont(name: "Optima-Bold", size: 12) {
                nameFont = optimaBoldFont
            } else if let optimaRegularFont = UIFont(name: "Optima-Regular", size: 12) {
                if let boldDescriptor = optimaRegularFont.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits.traitBold) {
                    nameFont = UIFont(descriptor: boldDescriptor, size: 12)
                } else {
                    nameFont = optimaRegularFont
                }
            } else {
                nameFont = UIFont.systemFont(ofSize: 12, weight: .bold)
            }

            let nameAttribs: [NSAttributedString.Key: Any] = [
                .font: nameFont,
                .foregroundColor: data.nameLabelColor,
                .paragraphStyle: nameParagraphStyle,
                .shadow: nameShadow
            ]
            (data.nameText as NSString).draw(with: data.nameLabelFrame, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], attributes: nameAttribs, context: nil)

            // --- Отрисовка типа локации ---
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
                
                // Устанавливаем начальную прозрачность перед анимацией
                self.linesView.alpha = 0.0
                self.markerRenderingView.alpha = 0.0

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
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 5.0
        scrollView.backgroundColor = .clear // <<< Make ScrollView background clear
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
        guard markerDrawDataList.isEmpty else { return }
        guard !allScenes.isEmpty else { return }
        var newMarkerDataList: [MarkerDrawingData] = []
        newMarkerDataList.reserveCapacity(allScenes.count)
        var newCalculatedPoints: [Int: CGPoint] = [:]
        newCalculatedPoints.reserveCapacity(allScenes.count)
        for scene in allScenes {
            let sceneX = CGFloat(scene.x) * coordinateScale
            let sceneY = CGFloat(scene.y) * coordinateScale
            let elementOriginX = (sceneX - minMapX) + padding
            let elementOriginY = (sceneY - minMapY) + padding
            let sceneElementFrame = CGRect(origin: CGPoint(x: elementOriginX, y: elementOriginY), size: sceneElementSize)
            let coloredRectFrame = CGRect(origin: .zero, size: coloredRectangleSize)
            let infoOriginY = coloredRectangleSize.height + spacingBelowRectangle
            let infoContentPadding: CGFloat = 5
            let iconSize = CGSize(width: 20, height: 20)
            let textStartX: CGFloat = iconSize.width + infoContentPadding * 2
            let labelWidth = sceneElementSize.width - textStartX - infoContentPadding
            let nameLabelHeight: CGFloat = 22
            let typeLabelHeight: CGFloat = 20
            let iconFrame = CGRect(x: infoContentPadding, y: infoOriginY + infoContentPadding, width: iconSize.width, height: iconSize.height)
            let nameLabelFrame = CGRect(x: textStartX, y: infoOriginY + infoContentPadding, width: labelWidth, height: nameLabelHeight)
            let typeLabelFrame = CGRect(x: textStartX, y: nameLabelFrame.maxY - 4, width: labelWidth, height: typeLabelHeight)
            var baseColorForType: UIColor = UIColor.white.withAlphaComponent(0.7)
            switch scene.sceneType {
                case .tavern: baseColorForType = UIColor.brown.withAlphaComponent(0.7)
                case .square: baseColorForType = UIColor.systemGreen.withAlphaComponent(0.7)
                case .blacksmith: baseColorForType = UIColor.darkGray.withAlphaComponent(0.7)
                case .house: baseColorForType = UIColor.systemBlue.withAlphaComponent(0.7)
                case .road: baseColorForType = UIColor.lightGray.withAlphaComponent(0.7)
                case .temple: baseColorForType = UIColor.systemPurple.withAlphaComponent(0.7)
                case .shop: baseColorForType = UIColor.systemOrange.withAlphaComponent(0.7)
                case .cathedral: baseColorForType = UIColor.systemIndigo.withAlphaComponent(0.7)
                case .castle: baseColorForType = UIColor.systemGray.withAlphaComponent(0.8)
                case .crypt: baseColorForType = UIColor.darkGray.withAlphaComponent(0.8)
                case .mine: baseColorForType = UIColor.brown.withAlphaComponent(0.6)
                case .forest: baseColorForType = UIColor.systemGreen.withAlphaComponent(0.6)
                case .cave: baseColorForType = UIColor.systemBrown.withAlphaComponent(0.7)
                case .ruins: baseColorForType = UIColor.systemGray2.withAlphaComponent(0.7)
                default: break
            }
            let imageNameSuffixForScene = "location\(scene.id)"
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
                iconTintColor: .black,
                sceneImageNameSuffix: imageNameSuffixForScene,
                isLocked: scene.isLocked,
                isCurrent: false
            )
            newMarkerDataList.append(markerData)
            let pointX = markerData.frame.origin.x + markerData.coloredRectangleFrame.midX
            let pointY = markerData.frame.origin.y + markerData.coloredRectangleFrame.midY
            newCalculatedPoints[scene.id] = CGPoint(x: pointX, y: pointY)
        }
        markerDrawDataList = newMarkerDataList
        pendingScenePointCache = newCalculatedPoints
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
