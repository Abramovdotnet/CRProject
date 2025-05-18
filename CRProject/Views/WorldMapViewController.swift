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
    let iconImageName: String
    
    let backgroundColor: UIColor
    let nameLabelColor: UIColor
    let typeLabelColor: UIColor
    let iconTintColor: UIColor
    
    let sceneImage: UIImage? // Предзагруженное изображение, если есть
    
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
        // print("[MarkerView] Frame: \(self.frame), Bounds: \(self.bounds)") // ОТЛАДКА - РАСКОММЕНТИРОВАНО
        guard let context = UIGraphicsGetCurrentContext() else { return }
        // print("[MarkerView] DRAW CALLED with rect: \(rect)") // КОММЕНТИРУЕМ ИЛИ УДАЛЯЕМ

        for data in markerDrawDataList {
            let markerFrame = data.frame // Полный frame элемента маркера
            let intersectsDrawRect = markerFrame.intersects(rect)
            
            // print("[MarkerView] Drawing Loop: ID=\(data.scene.id), Name=\(data.scene.name), isCurrent=\(data.isCurrent), Frame=\(markerFrame), DrawRect=\(rect), Intersects=\(intersectsDrawRect)") // КОММЕНТИРУЕМ ИЛИ УДАЛЯЕМ

            if !intersectsDrawRect { continue } 

            context.saveGState() // Сохраняем состояние для трансформаций и альфы этого маркера

            // Смещаем систему координат к началу текущего маркера
            context.translateBy(x: data.frame.origin.x, y: data.frame.origin.y)

            // --- Отрисовка основного цветного/изображенческого прямоугольника ---
            if data.isCurrent {
                // print("[MarkerView] Drawing glow for current scene ID: \(data.scene.id)") // КОММЕНТИРУЕМ ИЛИ УДАЛЯЕМ
                if data.sceneImage != nil {
                    // Свечение для МАРКЕРОВ С ИЗОБРАЖЕНИЕМ: рисуем подложку с тенью
                    context.saveGState()
                    // Цвет подложки свечения (может быть просто желтым, тень сделает размытие)
                    UIColor.yellow.withAlphaComponent(0.6).setFill() // Полупрозрачный желтый для тела свечения
                    context.setShadow(offset: .zero, blur: 8.0, color: UIColor.yellow.withAlphaComponent(0.8).cgColor)
                    // Немного больший прямоугольник для свечения, чтобы оно выступало
                    let glowRect = data.coloredRectangleFrame.insetBy(dx: -4, dy: -4)
                    let glowPath = UIBezierPath(roundedRect: glowRect, cornerRadius: 10) // Чуть больший радиус скругления для мягкости
                    glowPath.fill() // Это нарисует желтый прямоугольник с тенью (размытыми краями)
                    context.restoreGState()

                    // Далее будет нарисован сам маркер (фон .clear, изображение, рамка) поверх этого свечения
                    data.backgroundColor.setFill() // Должен быть .clear для маркеров с изображением
                    let backgroundPath = UIBezierPath(roundedRect: data.coloredRectangleFrame, cornerRadius: 8)
                    backgroundPath.fill()

                } else {
                    // Свечение для МАРКЕРОВ БЕЗ ИЗОБРАЖЕНИЯ (только цветной фон)
                    context.saveGState() 
                    context.setShadow(offset: .zero, blur: 8.0, color: UIColor.yellow.cgColor)
                    
                    data.backgroundColor.setFill()
                    let shadowCastingPath = UIBezierPath(roundedRect: data.coloredRectangleFrame, cornerRadius: 8)
                    shadowCastingPath.fill()
                    
                    context.restoreGState() 
                }
            } else {
                // Если не текущий, просто рисуем фон
                data.backgroundColor.setFill()
                let backgroundPath = UIBezierPath(roundedRect: data.coloredRectangleFrame, cornerRadius: 8)
                backgroundPath.fill()
            }

            // Рисуем изображение поверх фона (уже без тени от setShadow, но поверх "тела" свечения, если оно было)
            if let image = data.sceneImage {
                context.saveGState() // Сохраняем для обрезки изображения
                let imagePath = UIBezierPath(roundedRect: data.coloredRectangleFrame, cornerRadius: 8)
                imagePath.addClip() // Обрезаем по скругленному пути
                image.draw(in: data.coloredRectangleFrame)
                context.restoreGState() // Восстанавливаем после обрезки изображения
            }
            
            // Рисуем рамку для цветного прямоугольника (без тени)
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
                
                // Each icon should be square. Determine max possible side length.
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

                // Отрисовка иконки типа (оригинальной)
                if let typeIconImage = UIImage(systemName: data.iconImageName) {
                    typeIconImage.withTintColor(data.iconTintColor).draw(in: typeIconActualRect)
                }

                // Отрисовка иконки замка
                if let lockImage = UIImage(systemName: lockIconSFName) {
                    lockImage.withTintColor(lockIconColor).draw(in: lockIconActualRect)
                }

            } else {
                // Если не заблокировано, рисуем оригинальную иконку как обычно, centered and square
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
                    // Если не удалось сделать жирным, используем Optima-Regular
                    nameFont = optimaRegularFont
                }
            } else {
                // Если Optima вообще нет, используем системный жирный шрифт
                nameFont = UIFont.systemFont(ofSize: 12, weight: .bold)
            }

            let nameAttribs: [NSAttributedString.Key: Any] = [
                .font: nameFont, // <<< Шрифт Optima-Bold
                .foregroundColor: data.nameLabelColor,
                .paragraphStyle: nameParagraphStyle,
                .shadow: nameShadow // <<< Тень
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
                .font: typeFont, // <<< Шрифт Optima-Regular
                .foregroundColor: data.typeLabelColor,
                .paragraphStyle: typeParagraphStyle,
                .shadow: typeShadow // <<< Тень
            ]
            (data.typeText as NSString).draw(with: data.typeLabelFrame, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], attributes: typeAttribs, context: nil)

            context.restoreGState() // Восстанавливаем от трансформаций и альфы этого маркера
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

        setupBackgroundImage() 
        setupDustEffect()     
        loadSceneData()
        setupScrollView()     
        
        if !allScenes.isEmpty {
            minMapX = allScenes.map { CGFloat($0.x) * coordinateScale }.min() ?? 0
            minMapY = allScenes.map { CGFloat($0.y) * coordinateScale }.min() ?? 0
        } else {
            minMapX = 0
            minMapY = 0
        }

        // Рассчитываем общий размер контента
        let contentWidth: CGFloat
        let contentHeight: CGFloat
        if allScenes.isEmpty {
            let defaultSize: CGFloat = 300 // Default size if no scenes
            contentWidth = defaultSize + sceneElementSize.width + 2 * padding
            contentHeight = defaultSize + sceneElementSize.height + 2 * padding
        } else {
            let actualMinX = allScenes.map { CGFloat($0.x) * coordinateScale }.min() ?? 0
            let actualMaxX = allScenes.map { CGFloat($0.x) * coordinateScale }.max() ?? 0
            let actualMinY = allScenes.map { CGFloat($0.y) * coordinateScale }.min() ?? 0
            let actualMaxY = allScenes.map { CGFloat($0.y) * coordinateScale }.max() ?? 0
            contentWidth = (actualMaxX - actualMinX) + sceneElementSize.width + 2 * padding
            contentHeight = (actualMaxY - actualMinY) + sceneElementSize.height + 2 * padding
        }
        let contentFrame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        scrollView.contentSize = contentFrame.size

        // Создаем контейнер для зумируемых элементов
        zoomableViewContainer = UIView(frame: contentFrame)
        scrollView.addSubview(zoomableViewContainer)

        // Конфигурируем linesView и добавляем его в zoomableViewContainer
        configureLinesView(boundsForLinesView: zoomableViewContainer.bounds) 
        zoomableViewContainer.addSubview(linesView)

        // Конфигурируем markerRenderingView и добавляем его в zoomableViewContainer (поверх linesView)
        configureMarkerView(boundsForMarkerView: zoomableViewContainer.bounds)
        zoomableViewContainer.addSubview(markerRenderingView)
        
        prepareMarkerDrawData() 
        prepareLinePoints() // Готовим точки для линий (использует markerDrawDataList)
        
        markerRenderingView.markerDrawDataList = self.markerDrawDataList
        markerRenderingView.coordinateScale = self.coordinateScale
        markerRenderingView.padding = self.padding
        markerRenderingView.mapOriginX = self.minMapX
        markerRenderingView.mapOriginY = self.minMapY
        markerRenderingView.coloredRectangleSize = self.coloredRectangleSize 
        markerRenderingView.sceneElementSize = self.sceneElementSize

        // Передаем данные в linesView 
        linesView.scenes = allScenes 
        linesView.scenePointCache = self.linesView.scenePointCache // Передаем рассчитанные точки
        linesView.currentSceneId = GameStateService.shared.currentScene?.id 

        setupTopWidget()
        setupLocationInfoLabels() // <<< Call setup for location labels
        setupBackButton() // <<< Call setup for back button
        setupInitialZoomAndPosition()

        // if let window = view.window { // КОММЕНТИРУЕМ ИЛИ УДАЛЯЕМ
        //     let frameInWindow = markerRenderingView.convert(markerRenderingView.bounds, to: window)
        //     print("[WorldMapView] viewDidLoad END: markerRenderingView - isHidden: \(markerRenderingView.isHidden), alpha: \(markerRenderingView.alpha), frameInWindow: \(frameInWindow), bounds: \(markerRenderingView.bounds)")
        // } else {
        //     print("[WorldMapView] viewDidLoad END: markerRenderingView - view.window is nil. isHidden: \(markerRenderingView.isHidden), alpha: \(markerRenderingView.alpha), bounds: \(markerRenderingView.bounds)")
        // }

        // Устанавливаем zoomScale один раз после того, как contentSize известен
        // и centerMapOn (через setupInitialZoomAndPosition) мог его инициализировать, если он был 1.0
        // Но лучше сделать это более явно здесь.
        if scrollView.contentSize.width > 0 && scrollView.contentSize.height > 0 {
            let sBounds = scrollView.bounds
            let cSize = scrollView.contentSize
            let scaleWidth = sBounds.width / cSize.width
            let scaleHeight = sBounds.height / cSize.height
            var minScaleToFitContent = min(scaleWidth, scaleHeight)
            minScaleToFitContent = max(minScaleToFitContent, 0.2) // Убедимся, что масштаб не слишком мал

            scrollView.minimumZoomScale = minScaleToFitContent * 0.5 
            
            // Базовый начальный зум - это масштаб, чтобы все поместилось, или минимальный зум
            let baseInitialZoom = max(minScaleToFitContent, scrollView.minimumZoomScale)
            
            // Увеличиваем на 30%
            var desiredInitialZoom = baseInitialZoom * 2
            
            // Ограничиваем сверху максимальным зумом и снизу минимальным (на всякий случай)
            desiredInitialZoom = min(desiredInitialZoom, scrollView.maximumZoomScale)
            desiredInitialZoom = max(desiredInitialZoom, scrollView.minimumZoomScale)

            scrollView.zoomScale = desiredInitialZoom 
            // print("[WorldMapView] viewDidLoad: Initial zoom scale set to \(scrollView.zoomScale) (30% increased)")
        } else {
            print("[WorldMapView] viewDidLoad: scrollView.contentSize is zero, cannot set zoom scale.") 
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
                typeInfoStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
                typeInfoStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
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

    // Новый метод для подготовки данных для отрисовки
    private func prepareMarkerDrawData() {
        guard !allScenes.isEmpty else { return }
        markerDrawDataList.removeAll()

        for scene in allScenes {
            let sceneX = CGFloat(scene.x) * coordinateScale
            let sceneY = CGFloat(scene.y) * coordinateScale
            
            let elementOriginX = (sceneX - minMapX) + padding
            let elementOriginY = (sceneY - minMapY) + padding
            let sceneElementFrame = CGRect(origin: CGPoint(x: elementOriginX, y: elementOriginY), size: sceneElementSize)

            // Расчет CGRect для каждого элемента внутри маркера
            let coloredRectFrame = CGRect(origin: .zero, size: coloredRectangleSize) // Относительно sceneElementFrame

            let infoOriginY = coloredRectangleSize.height + spacingBelowRectangle
            let infoContentPadding: CGFloat = 5
            let iconSize = CGSize(width: 20, height: 20)
            let textStartX: CGFloat = iconSize.width + infoContentPadding * 2
            let labelWidth = sceneElementSize.width - textStartX - infoContentPadding
            let nameLabelHeight: CGFloat = 22
            let typeLabelHeight: CGFloat = 20

            let iconFrame = CGRect(x: infoContentPadding, 
                                   y: infoOriginY + infoContentPadding, 
                                   width: iconSize.width, 
                                   height: iconSize.height) // Относительно sceneElementFrame

            let nameLabelFrame = CGRect(x: textStartX, 
                                       y: infoOriginY + infoContentPadding, 
                                       width: labelWidth, 
                                       height: nameLabelHeight) // Относительно sceneElementFrame
            
            let typeLabelFrame = CGRect(x: textStartX, 
                                       y: nameLabelFrame.maxY - 4, 
                                       width: labelWidth, 
                                       height: typeLabelHeight) // Относительно sceneElementFrame
            
            // Цвета и изображение
            var currentRectangleColor: UIColor = UIColor.white.withAlphaComponent(0.7)
            var sceneImage: UIImage? = nil
            let imageName = "location\(scene.id)" // <<< ВОЗВРАЩЕНО: Формат имени БЕЗ фигурных скобок
            if let loadedImage = UIImage(named: imageName) {
                sceneImage = loadedImage
                currentRectangleColor = .clear // Фон делаем прозрачным, если есть картинка
            } else {
                // Логика для цветов по умолчанию, если изображение не найдено
                switch scene.sceneType {
                case .tavern: currentRectangleColor = UIColor.brown.withAlphaComponent(0.7)
                case .square: currentRectangleColor = UIColor.systemGreen.withAlphaComponent(0.7)
                // ... (остальные case как были) ...
                 case .blacksmith: currentRectangleColor = UIColor.darkGray.withAlphaComponent(0.7)
                case .house: currentRectangleColor = UIColor.systemBlue.withAlphaComponent(0.7)
                case .road: currentRectangleColor = UIColor.lightGray.withAlphaComponent(0.7)
                case .temple: currentRectangleColor = UIColor.systemPurple.withAlphaComponent(0.7)
                case .shop: currentRectangleColor = UIColor.systemOrange.withAlphaComponent(0.7)
                case .cathedral: currentRectangleColor = UIColor.systemIndigo.withAlphaComponent(0.7)
                case .castle: currentRectangleColor = UIColor.systemGray.withAlphaComponent(0.8)
                case .crypt: currentRectangleColor = UIColor.darkGray.withAlphaComponent(0.8)
                case .mine: currentRectangleColor = UIColor.brown.withAlphaComponent(0.6)
                case .forest: currentRectangleColor = UIColor.systemGreen.withAlphaComponent(0.6)
                case .cave: currentRectangleColor = UIColor.systemBrown.withAlphaComponent(0.7)
                case .ruins: currentRectangleColor = UIColor.systemGray2.withAlphaComponent(0.7)
                default: break
                }
            }

            let data = MarkerDrawingData(
                scene: scene,
                frame: sceneElementFrame, // Это frame всего элемента маркера в координатах markerRenderingView
                coloredRectangleFrame: coloredRectFrame, // Это frame цветной части ОТНОСИТЕЛЬНО НАЧАЛА sceneElementFrame
                iconFrame: iconFrame,       // ОТНОСИТЕЛЬНО НАЧАЛА sceneElementFrame
                nameLabelFrame: nameLabelFrame, // ОТНОСИТЕЛЬНО НАЧАЛА sceneElementFrame
                typeLabelFrame: typeLabelFrame, // ОТНОСИТЕЛЬНО НАЧАЛА sceneElementFrame
                nameText: scene.name,
                typeText: scene.sceneType.displayName,
                iconImageName: scene.sceneType.iconName,
                backgroundColor: currentRectangleColor,
                nameLabelColor: .white,
                typeLabelColor: .systemGreen,
                iconTintColor: .black, // Раньше было .black
                sceneImage: sceneImage,
                isLocked: scene.isLocked,
                isCurrent: false // Изначально ни один не текущий
            )
            markerDrawDataList.append(data)
        }
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

    // Старый setupMarkersAndLines больше не нужен в таком виде, его логика распределена
    // между prepareMarkerDrawData и setupLinesView
    
    private func setupInitialZoomAndPosition() {
        // Initial call to centering logic
        centerMapOn(sceneId: GameStateService.shared.currentScene?.id, animated: false)
    }

    // Public method to be called to center the map on a specific scene
    func centerMapOn(sceneId: Int?, animated: Bool) {
        // print("[WorldMapView] centerMapOn BEGIN: sceneId=\(sceneId ?? -1), animated=\(animated), allScenes.count = \(allScenes.count), scrollView.contentSize = \(scrollView.contentSize)")
        markerRenderingView.setCurrentSceneId(sceneId) 
        linesView.currentSceneId = sceneId // <<< ПЕРЕДАЕМ ID В LINESVIEW
        linesView.setNeedsDisplay() // <<< ЗАПРАШИВАЕМ ПЕРЕРИСОВКУ ЛИНИЙ

        // Update isLocked status from live scene data
        // This is important if isLocked can change dynamically (e.g., due to in-game time)
        let liveScenesById = Dictionary(uniqueKeysWithValues: allScenes.map { ($0.id, $0) })
        var redrawFrames: [CGRect] = []

        for i in 0..<markerRenderingView.markerDrawDataList.count {
            let originalDrawData = markerRenderingView.markerDrawDataList[i]
            if let liveScene = liveScenesById[originalDrawData.scene.id] {
                if originalDrawData.isLocked != liveScene.isLocked {
                    var updatedDrawData = originalDrawData // Create a mutable copy as MarkerDrawingData is a struct
                    updatedDrawData.isLocked = liveScene.isLocked // Modify the copy
                    markerRenderingView.markerDrawDataList[i] = updatedDrawData // Replace the original in the array
                    
                    // Add the frame to be redrawn. Expand slightly to include potential glow.
                    redrawFrames.append(updatedDrawData.frame.insetBy(dx: -10, dy: -10)) 
                    // print("[WorldMapView] Updated isLocked for scene \(liveScene.id) to \(liveScene.isLocked). Requesting redraw.")
                }
            }
        }
        for frameToRedraw in redrawFrames {
            markerRenderingView.setNeedsDisplay(frameToRedraw)
        }

        // DispatchQueue.main.async { // КОММЕНТИРУЕМ ИЛИ УДАЛЯЕМ
        //     if let window = self.view.window {
        //         let frameInWindow = self.markerRenderingView.convert(self.markerRenderingView.bounds, to: window)
        //         print("[WorldMapView] centerMapOn AFTER setCurrentSceneId: markerRenderingView - isHidden: \(self.markerRenderingView.isHidden), alpha: \(self.markerRenderingView.alpha), frameInWindow: \(frameInWindow), bounds: \(self.markerRenderingView.bounds)")
        //     } else {
        //         print("[WorldMapView] centerMapOn AFTER setCurrentSceneId: markerRenderingView - view.window is nil. isHidden: \(self.markerRenderingView.isHidden), alpha: \(self.markerRenderingView.alpha), bounds: \(self.markerRenderingView.bounds)")
        //     }
        // }

        guard !allScenes.isEmpty else {
            print("[WorldMapView] centerMapOn: allScenes is empty, cannot center.")
            return
        }
        guard scrollView.contentSize.width > 0, scrollView.contentSize.height > 0 else {
            print("[WorldMapView] centerMapOn: scrollView contentSize is zero, cannot center.")
            return
        }

        let sBounds = scrollView.bounds
        let cSize = scrollView.contentSize // Этот cSize должен быть стабильным (860, 630)
        let currentZoom = scrollView.zoomScale // Этот zoomScale должен быть стабильным после viewDidLoad
        // print("[WorldMapView] centerMapOn: Using sBounds=\(sBounds), cSize=\(cSize), currentZoom=\(currentZoom)")

        if let currentSceneId = sceneId {
            if let currentScene = allScenes.first(where: { $0.id == currentSceneId }) {
                // print("[WorldMapView] Found scene for centering: \(currentScene.name) at (\(currentScene.x), \(currentScene.y))")
                
                self.currentLocationNameLabel.text = currentScene.name
                self.currentLocationTypeLabel.text = currentScene.sceneType.displayName
                self.currentLocationTypeIconImageView.image = UIImage(systemName: currentScene.sceneType.iconName) // <<< Обновление иконки

                let zoomedMarkerX = (CGFloat(currentScene.x) * coordinateScale - minMapX + padding + sceneElementSize.width / 2) * currentZoom
                let zoomedMarkerY = (CGFloat(currentScene.y) * coordinateScale - minMapY + padding + sceneElementSize.height / 2) * currentZoom
                // print("[WorldMapView] Marker center in zoomed content: (\(zoomedMarkerX), \(zoomedMarkerY))")

                let zoomedContentWidth = cSize.width * currentZoom
                let zoomedContentHeight = cSize.height * currentZoom

                var finalTargetOffsetX: CGFloat
                var finalTargetOffsetY: CGFloat
                var calculatedContentInset: UIEdgeInsets

                if zoomedContentWidth <= sBounds.width && zoomedContentHeight <= sBounds.height {
                    // print("[WorldMapView] Content is smaller. Centering point with offset, block centered with inset.")
                    let blockCenteringInsetX = max(0, (sBounds.width - zoomedContentWidth) / 2)
                    let blockCenteringInsetY = max(0, (sBounds.height - zoomedContentHeight) / 2)
                    calculatedContentInset = UIEdgeInsets(top: blockCenteringInsetY, left: blockCenteringInsetX, bottom: blockCenteringInsetY, right: blockCenteringInsetX)

                    finalTargetOffsetX = zoomedMarkerX - sBounds.width / 2
                    finalTargetOffsetY = zoomedMarkerY - sBounds.height / 2
                    // print("[WorldMapView] Small Content: Calculated targetContentOffset: (\(finalTargetOffsetX), \(finalTargetOffsetY))")
                } else {
                    // print("[WorldMapView] Content is larger. Centering point with offset, edge insets if part is smaller.")
                    let blockCenterXInset = max(0, (sBounds.width - zoomedContentWidth) / 2) 
                    let blockCenterYInset = max(0, (sBounds.height - zoomedContentHeight) / 2) 
                    calculatedContentInset = UIEdgeInsets(
                        top: zoomedContentHeight <= sBounds.height ? blockCenterYInset : 0,
                        left: zoomedContentWidth <= sBounds.width ? blockCenterXInset : 0,
                        bottom: zoomedContentHeight <= sBounds.height ? blockCenterYInset : 0,
                        right: zoomedContentWidth <= sBounds.width ? blockCenterXInset : 0
                    )

                    finalTargetOffsetX = zoomedMarkerX - sBounds.width / 2
                    finalTargetOffsetY = zoomedMarkerY - sBounds.height / 2
                    
                    let minScrollOffsetX = -calculatedContentInset.left
                    let maxScrollOffsetX = zoomedContentWidth - sBounds.width + calculatedContentInset.right
                    let minScrollOffsetY = -calculatedContentInset.top
                    let maxScrollOffsetY = zoomedContentHeight - sBounds.height + calculatedContentInset.bottom

                    finalTargetOffsetX = max(minScrollOffsetX, min(finalTargetOffsetX, maxScrollOffsetX))
                    finalTargetOffsetY = max(minScrollOffsetY, min(finalTargetOffsetY, maxScrollOffsetY))
                    // print("[WorldMapView] Large Content: Clamped targetContentOffset: (\(finalTargetOffsetX), \(finalTargetOffsetY))")
                }
                
                let finalOffset = CGPoint(x: finalTargetOffsetX, y: finalTargetOffsetY)
                // print("[WorldMapView] Final calculated offset: \(finalOffset), final inset: \(calculatedContentInset)")

                if animated {
                    // print("[WorldMapView] Applying changes with animation.")
                    UIView.animate(withDuration: 0.35, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                        self.scrollView.contentInset = calculatedContentInset
                        self.scrollView.contentOffset = finalOffset
                    }, completion: { completed in
                        // print("[WorldMapView] Animation completed: \(completed)")
                    })
                } else {
                    // print("[WorldMapView] Applying changes without animation.")
                    self.scrollView.contentInset = calculatedContentInset
                    self.scrollView.contentOffset = finalOffset
                }
                // print("[WorldMapView] Centering complete for \(currentScene.name).")
            } else {
                print("[WorldMapView] Error: Scene ID \(currentSceneId) not found in allScenes array.")
            }
        } else {
             print("[WorldMapView] No scene ID provided for centering.")
        }
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

        // Проходим по всем данным маркеров для определения, на какой из них нажали
        for data in markerDrawDataList {
            if !data.isLocked && data.frame.contains(tapLocation) {
                let tappedScene = data.scene // Сцена, на которую нажал пользователь
                
                // Если текущая локация уже эта, не делаем ничего
                if GameStateService.shared.currentScene?.id == tappedScene.id {
                    // print("Tapped on the current scene, no change needed.")
                    return
                }

                // Проверяем, связана ли tappedScene с текущей локацией
                guard let currentScene = GameStateService.shared.currentScene else {
                    print("[WorldMapView] Error: Current scene is not set in GameStateService. Cannot determine valid moves.")
                    return // Не можем определить текущую сцену, прерываем
                }

                let isConnected = currentScene.connections.contains { connection in
                    connection.connectedSceneId == tappedScene.id
                }

                if isConnected {
                    // print("Moving to connected scene: \(tappedScene.name)")
                    try? GameStateService.shared.changeLocation(to: tappedScene.id)
                    // centerMapOn будет вызван автоматически через Notification или другой механизм обновления UI,
                    // который в свою очередь вызовет markerRenderingView.setCurrentSceneId()
                } else {
                    // Локация не связана напрямую, перемещение не выполняем
                    print("[WorldMapView] Cannot move to scene '\(tappedScene.name)' (ID: \(tappedScene.id)). It is not directly connected to the current scene '\(currentScene.name)' (ID: \(currentScene.id)).")
                }
                return // Выходим после обработки первого же найденного маркера (связанного или нет)
            }
        }
        // print("Tap did not hit any unlocked marker.")
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

    private func prepareLinePoints() {
        guard !markerDrawDataList.isEmpty else {
            linesView.scenePointCache = [:]
            return
        }
        
        var calculatedPoints: [Int: CGPoint] = [:]
        for data in markerDrawDataList {
            let sceneId = data.scene.id
            // data.frame.origin это уже абсолютные координаты верхнего левого угла всего элемента маркера
            // data.coloredRectangleFrame.origin это (0,0) относительно data.frame.origin
            // Нам нужен центр coloredRectangleFrame в абсолютных координатах contentFrame
            let pointX = data.frame.origin.x + data.coloredRectangleFrame.midX // midX прямоугольника, который начинается в 0
            let pointY = data.frame.origin.y + data.coloredRectangleFrame.midY // midY прямоугольника, который начинается в 0
            
            calculatedPoints[sceneId] = CGPoint(x: pointX, y: pointY)
        }
        self.linesView.scenePointCache = calculatedPoints 
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
