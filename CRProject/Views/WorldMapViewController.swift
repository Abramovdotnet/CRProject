import UIKit
import SwiftUI // <<< Added for UIHostingController

class WorldMapViewController: UIViewController, UIScrollViewDelegate {

    private var scrollView: UIScrollView!
    private var contentView: UIView! // Для размещения маркеров локаций
    private var linesView: MapLinesView! // Для отрисовки связей
    
    private var allScenes: [Scene] = []
    private var currentPlayerMarker: UIView? // Ссылка на маркер текущего игрока
    
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

        setupBackgroundImage() // <<< Add background image first
        setupDustEffect()     // Add dust effect
        loadSceneData()
        setupScrollView()     // Add scroll view (will be made transparent)
        setupContentView()
        setupMarkersAndLines()
        setupTopWidget()
        setupLocationInfoLabels() // <<< Call setup for location labels
        setupBackButton() // <<< Call setup for back button
        setupInitialZoomAndPosition()

        // Устанавливаем zoomScale один раз после того, как contentSize известен
        // и centerMapOn (через setupInitialZoomAndPosition) мог его инициализировать, если он был 1.0
        // Но лучше сделать это более явно здесь.
        if scrollView.contentSize.width > 0 && scrollView.contentSize.height > 0 {
            let sBounds = scrollView.bounds
            let cSize = scrollView.contentSize
            let scaleWidth = sBounds.width / cSize.width
            let scaleHeight = sBounds.height / cSize.height
            var minScale = min(scaleWidth, scaleHeight)
            minScale = max(minScale, 0.2) // Ensure minScale is not excessively small

            scrollView.minimumZoomScale = minScale * 0.5 
            scrollView.zoomScale = max(minScale, scrollView.minimumZoomScale) 
            print("[WorldMapView] viewDidLoad: Initial zoom scale definitively set to \(scrollView.zoomScale)")
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
        currentLocationNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(currentLocationNameLabel)

        // Type Label
        currentLocationTypeLabel.font = UIFont(name: "Optima-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        currentLocationTypeLabel.textColor = .systemGreen // Или ваш Theme.secondaryTextColor
        currentLocationTypeLabel.textAlignment = .center
        currentLocationTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(currentLocationTypeLabel)

        // Constraints
        guard let topWidgetActualView = topWidgetHostingController?.view else {
            print("[WorldMapView] Error: topWidgetHostingController.view is nil, cannot constrain location labels properly.")
            // Fallback constraints to view.safeAreaLayoutGuide.topAnchor if topWidget is missing
            // This might not be ideal visually but prevents a crash or unconstrained labels.
            NSLayoutConstraint.activate([
                currentLocationNameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 45), // Approximate position
                currentLocationNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                currentLocationNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
                currentLocationNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

                currentLocationTypeLabel.topAnchor.constraint(equalTo: currentLocationNameLabel.bottomAnchor, constant: 4),
                currentLocationTypeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                currentLocationTypeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
                currentLocationTypeLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            ])
            return
        }

        NSLayoutConstraint.activate([
            currentLocationNameLabel.topAnchor.constraint(equalTo: topWidgetActualView.bottomAnchor, constant: 8), // 8 points below top widget
            currentLocationNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            currentLocationNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20), // Allow shrinking if needed
            currentLocationNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20), // Allow shrinking if needed

            currentLocationTypeLabel.topAnchor.constraint(equalTo: currentLocationNameLabel.bottomAnchor, constant: 4), // 4 points below name label
            currentLocationTypeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            currentLocationTypeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            currentLocationTypeLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
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

    private func setupContentView() {
        var minX = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude

        for scene in allScenes {
            let sceneX = CGFloat(scene.x) * coordinateScale
            let sceneY = CGFloat(scene.y) * coordinateScale
            minX = min(minX, sceneX)
            maxX = max(maxX, sceneX)
            minY = min(minY, sceneY)
            maxY = max(maxY, sceneY)
        }
        
        if allScenes.isEmpty {
            minX = 0; maxX = 300; minY = 0; maxY = 300;
        }

        // Используем sceneElementSize для расчета размеров contentView
        let contentWidth = (maxX - minX) + sceneElementSize.width + 2 * padding
        let contentHeight = (maxY - minY) + sceneElementSize.height + 2 * padding
        
        contentView = UIView(frame: CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight))
        scrollView.addSubview(contentView)
        scrollView.contentSize = contentView.bounds.size
    }

    private func setupMarkersAndLines() {
        guard !allScenes.isEmpty else { return }
        
        linesView = MapLinesView(frame: contentView.bounds)
        linesView.backgroundColor = .clear
        linesView.scenes = allScenes
        linesView.coordinateScale = coordinateScale
        linesView.markerSize = self.sceneElementSize         // Общий размер элемента
        linesView.lineTargetRectSize = self.coloredRectangleSize // Размер для таргетинга линий
        linesView.padding = padding
        minMapX = allScenes.map { CGFloat($0.x) * coordinateScale }.min() ?? 0
        minMapY = allScenes.map { CGFloat($0.y) * coordinateScale }.min() ?? 0
        linesView.mapOriginX = minMapX
        linesView.mapOriginY = minMapY
        contentView.addSubview(linesView)

        for scene in allScenes {
            let sceneX = CGFloat(scene.x) * coordinateScale
            let sceneY = CGFloat(scene.y) * coordinateScale
            
            let elementOriginX = (sceneX - minMapX) + padding
            let elementOriginY = (sceneY - minMapY) + padding

            // Главный контейнер для элемента сцены
            let sceneElementView = UIView(frame: CGRect(origin: CGPoint(x: elementOriginX, y: elementOriginY), size: sceneElementSize))
            // sceneElementView.backgroundColor = UIColor.purple.withAlphaComponent(0.3) // для отладки

            // Цветной прямоугольник (верхняя часть)
            let coloredRectangleView = UIView(frame: CGRect(origin: .zero, size: coloredRectangleSize))
            coloredRectangleView.layer.cornerRadius = 8
            coloredRectangleView.layer.borderColor = UIColor.black.cgColor
            coloredRectangleView.layer.borderWidth = 0.5
            coloredRectangleView.clipsToBounds = true // Важно для UIImageView внутри

            let imageName = "location\(scene.id)"
            if let sceneImage = UIImage(named: imageName) {
                let imageView = UIImageView(image: sceneImage)
                imageView.frame = coloredRectangleView.bounds
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true // Хотя родитель уже clipsToBounds, для UIImageView это тоже хорошо
                imageView.layer.cornerRadius = coloredRectangleView.layer.cornerRadius // <<< Ensure image view also has corner radius
                coloredRectangleView.addSubview(imageView)
                coloredRectangleView.backgroundColor = .clear // Фон делаем прозрачным, если есть картинка
            } else {
                // Если картинки нет, используем цвет по типу сцены
                var currentRectangleColor: UIColor = UIColor.white.withAlphaComponent(0.7)
                switch scene.sceneType {
                case .tavern: currentRectangleColor = UIColor.brown.withAlphaComponent(0.7)
                case .square: currentRectangleColor = UIColor.systemGreen.withAlphaComponent(0.7)
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
                coloredRectangleView.backgroundColor = currentRectangleColor
            }
            sceneElementView.addSubview(coloredRectangleView)
            
            // Элементы в информационной области (под цветным прямоугольником)
            let infoOriginY = coloredRectangleSize.height + spacingBelowRectangle
            let infoContentPadding: CGFloat = 5 // Внутренний отступ для контента в infoArea
            let iconSize = CGSize(width: 20, height: 20)
            let textStartX: CGFloat = iconSize.width + infoContentPadding * 2 // X для текста, справа от иконки
            let labelWidth = sceneElementSize.width - textStartX - infoContentPadding
            
            // Иконка типа локации
            let iconImageView = UIImageView(frame: CGRect(x: infoContentPadding, 
                                                          y: infoOriginY + infoContentPadding, 
                                                          width: iconSize.width, 
                                                          height: iconSize.height))
            iconImageView.image = UIImage(systemName: scene.sceneType.iconName)
            iconImageView.tintColor = .black 
            iconImageView.contentMode = .scaleAspectFit
            sceneElementView.addSubview(iconImageView)
            
            // Название локации
            let nameLabelHeight: CGFloat = 22 // Немного увеличим высоту для нового шрифта
            let nameLabel = UILabel(frame: CGRect(x: textStartX, 
                                                  y: infoOriginY + infoContentPadding, 
                                                  width: labelWidth, 
                                                  height: nameLabelHeight))
            nameLabel.text = scene.name
            nameLabel.font = .systemFont(ofSize: 12, weight: .bold) // << Увеличен шрифт
            nameLabel.textColor = .white // << Изменено на белый
            nameLabel.adjustsFontSizeToFitWidth = true
            nameLabel.minimumScaleFactor = 0.7
            sceneElementView.addSubview(nameLabel)
            
            // Тип локации
            let typeLabelHeight: CGFloat = 20 // Немного увеличим высоту для нового шрифта
            let typeLabel = UILabel(frame: CGRect(x: textStartX, 
                                                  y: nameLabel.frame.maxY - 4, // << Еще ближе к названию
                                                  width: labelWidth, 
                                                  height: typeLabelHeight))
            typeLabel.text = scene.sceneType.displayName
            typeLabel.font = .systemFont(ofSize: 11) // << Увеличен шрифт
            typeLabel.textColor = UIColor.systemGreen // << Цвет типа локации всегда зеленый
            typeLabel.adjustsFontSizeToFitWidth = true
            typeLabel.minimumScaleFactor = 0.7
            sceneElementView.addSubview(typeLabel)

            // Обработка состояния блокировки
            if scene.isLocked {
                sceneElementView.alpha = 0.4
                sceneElementView.isUserInteractionEnabled = false
            } else {
                sceneElementView.alpha = 1.0
                sceneElementView.isUserInteractionEnabled = true
                sceneElementView.tag = scene.id
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(markerTapped(_:)))
                sceneElementView.addGestureRecognizer(tapGesture)
                // Accessibility ID для цветного прямоугольника (для свечения)
                coloredRectangleView.accessibilityIdentifier = "marker_\(scene.id)"
            }
            
            contentView.addSubview(sceneElementView)
        }
    }
    
    private func setupInitialZoomAndPosition() {
        // Initial call to centering logic
        centerMapOn(sceneId: GameStateService.shared.currentScene?.id, animated: false)
    }

    // Public method to be called to center the map on a specific scene
    func centerMapOn(sceneId: Int?, animated: Bool) {
        print("[WorldMapView] centerMapOn BEGIN: sceneId=\(sceneId ?? -1), animated=\(animated), allScenes.count = \(allScenes.count), scrollView.contentSize = \(scrollView.contentSize)")
        print("[WorldMapView] centerMapOn: minMapX = \(minMapX), minMapY = \(minMapY)")

        guard !allScenes.isEmpty else {
            print("[WorldMapView] centerMapOn: allScenes is empty, cannot center.")
            return
        }
        // Используем guard для contentSize, чтобы избежать деления на ноль если что-то пошло не так
        guard scrollView.contentSize.width > 0, scrollView.contentSize.height > 0 else {
            print("[WorldMapView] centerMapOn: scrollView contentSize is zero, cannot center.")
            return
        }

        let sBounds = scrollView.bounds
        let cSize = scrollView.contentSize // Этот cSize должен быть стабильным (860, 630)
        let currentZoom = scrollView.zoomScale // Этот zoomScale должен быть стабильным после viewDidLoad
        print("[WorldMapView] centerMapOn: Using sBounds=\(sBounds), cSize=\(cSize), currentZoom=\(currentZoom)")

        // Удаляем блок установки zoomScale отсюда

        // Убираем свечение со старого маркера
        if let previousMarker = currentPlayerMarker {
            previousMarker.layer.shadowColor = UIColor.clear.cgColor
            previousMarker.layer.shadowRadius = 0
            previousMarker.layer.shadowOpacity = 0
            self.currentPlayerMarker = nil
        }

        print("[WorldMapView] centerMapOn: Attempting to center on scene ID: \(sceneId ?? -1)")
        if let currentSceneId = sceneId {
            if let currentScene = allScenes.first(where: { $0.id == currentSceneId }) {
                print("[WorldMapView] Found scene for centering: \(currentScene.name) at (\(currentScene.x), \(currentScene.y))")
                
                // Update location info labels
                self.currentLocationNameLabel.text = currentScene.name
                self.currentLocationTypeLabel.text = currentScene.sceneType.displayName

                // Находим маркер (coloredRectangleView) для свечения
                if let markerToGlow = contentView.subviews.compactMap({ $0.subviews.first(where: { $0.accessibilityIdentifier == "marker_\(currentSceneId)" }) }).first {
                    markerToGlow.layer.shadowColor = UIColor.yellow.cgColor
                    markerToGlow.layer.shadowRadius = 8.0
                    markerToGlow.layer.shadowOpacity = 0.95
                    markerToGlow.layer.shadowOffset = CGSize.zero
                    markerToGlow.layer.masksToBounds = false // Для тени важно
                    self.currentPlayerMarker = markerToGlow
                    print("[WorldMapView] Applied glow to marker for scene \(currentSceneId)")
                } else {
                    print("[WorldMapView] ERROR: Could not find marker view for scene ID \(currentSceneId) to apply glow.")
                }

                // Используем sceneElementSize для расчета центра
                let zoomedMarkerX = (CGFloat(currentScene.x) * coordinateScale - minMapX + padding + sceneElementSize.width / 2) * currentZoom
                let zoomedMarkerY = (CGFloat(currentScene.y) * coordinateScale - minMapY + padding + sceneElementSize.height / 2) * currentZoom
                print("[WorldMapView] Marker center in zoomed content: (\(zoomedMarkerX), \(zoomedMarkerY))")

                let zoomedContentWidth = cSize.width * currentZoom
                let zoomedContentHeight = cSize.height * currentZoom
                // print("[WorldMapView] Zoomed Content Size: (\(zoomedContentWidth), \(zoomedContentHeight))") // Дублирует информацию из cSize * currentZoom

                var finalTargetOffsetX: CGFloat
                var finalTargetOffsetY: CGFloat
                var calculatedContentInset: UIEdgeInsets

                if zoomedContentWidth <= sBounds.width && zoomedContentHeight <= sBounds.height {
                    print("[WorldMapView] Content is smaller. Centering point with offset, block centered with inset.")
                    let blockCenteringInsetX = max(0, (sBounds.width - zoomedContentWidth) / 2)
                    let blockCenteringInsetY = max(0, (sBounds.height - zoomedContentHeight) / 2)
                    calculatedContentInset = UIEdgeInsets(top: blockCenteringInsetY, left: blockCenteringInsetX, bottom: blockCenteringInsetY, right: blockCenteringInsetX)

                    finalTargetOffsetX = zoomedMarkerX - sBounds.width / 2
                    finalTargetOffsetY = zoomedMarkerY - sBounds.height / 2
                    print("[WorldMapView] Small Content: Calculated targetContentOffset: (\(finalTargetOffsetX), \(finalTargetOffsetY))")
                } else {
                    print("[WorldMapView] Content is larger. Centering point with offset, edge insets if part is smaller.")
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
                    
                    // Ограничения для большого контента
                    let minScrollOffsetX = -calculatedContentInset.left
                    let maxScrollOffsetX = zoomedContentWidth - sBounds.width + calculatedContentInset.right
                    let minScrollOffsetY = -calculatedContentInset.top
                    let maxScrollOffsetY = zoomedContentHeight - sBounds.height + calculatedContentInset.bottom

                    finalTargetOffsetX = max(minScrollOffsetX, min(finalTargetOffsetX, maxScrollOffsetX))
                    finalTargetOffsetY = max(minScrollOffsetY, min(finalTargetOffsetY, maxScrollOffsetY))
                    print("[WorldMapView] Large Content: Clamped targetContentOffset: (\(finalTargetOffsetX), \(finalTargetOffsetY))")
                }
                
                let finalOffset = CGPoint(x: finalTargetOffsetX, y: finalTargetOffsetY)
                print("[WorldMapView] Final calculated offset: \(finalOffset), final inset: \(calculatedContentInset)")

                if animated {
                    print("[WorldMapView] Applying changes with animation.")
                    UIView.animate(withDuration: 0.35, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                        self.scrollView.contentInset = calculatedContentInset
                        self.scrollView.contentOffset = finalOffset
                    }, completion: { completed in
                        print("[WorldMapView] Animation completed: \(completed)")
                    })
                } else {
                    print("[WorldMapView] Applying changes without animation.")
                    self.scrollView.contentInset = calculatedContentInset
                    self.scrollView.contentOffset = finalOffset
                }

                print("[WorldMapView] Centering complete for \(currentScene.name).")
            } else {
                print("[WorldMapView] Error: Scene ID \(currentSceneId) not found in allScenes array.")
            }
        } else {
             print("[WorldMapView] No scene ID provided for centering.")
        }
    }

    // MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // ЗАКОММЕНТИРОВАНО ДЛЯ ДИАГНОСТИКИ КОНФЛИКТА С centerMapOn
        /*
        let sBounds = scrollView.bounds
        let zoomedContentWidth = scrollView.contentSize.width * scrollView.zoomScale
        let zoomedContentHeight = scrollView.contentSize.height * scrollView.zoomScale

        let offsetX = max((sBounds.width - zoomedContentWidth) / 2, 0)
        let offsetY = max((sBounds.height - zoomedContentHeight) / 2, 0)

        // scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0) // Старая версия
        // scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetY) // Предлагаемая симметричная версия
        print("[WorldMapView] scrollViewDidZoom - body commented out for diagnostics. Zoom: \(scrollView.zoomScale)")
        */
    }

    // MARK: - Gesture Recognizer Handler
    @objc private func markerTapped(_ sender: UITapGestureRecognizer) {
        guard let sceneId = sender.view?.tag else {
            print("Error: Scene ID not found in marker tag.")
            return
        }
        print("Marker tapped for scene ID: \(sceneId)")
        try? GameStateService.shared.changeLocation(to: sceneId)
        // Potentially dismiss the map view or navigate elsewhere after changing location
        // For example, if this view controller is presented modally:
        // self.dismiss(animated: true, completion: nil)
    }
}

class MapLinesView: UIView {
    var scenes: [Scene] = []
    var scenePointCache: [Int: CGPoint] = [:]
    var coordinateScale: CGFloat = 1.0
    var markerSize: CGSize = .zero // Это получит sceneElementSize
    var lineTargetRectSize: CGSize = .zero // <<< НОВОЕ свойство для размера цели линии
    var padding: CGFloat = 0.0
    var mapOriginX: CGFloat = 0.0 // Новый параметр для минимального X карты (без padding)
    var mapOriginY: CGFloat = 0.0 // Новый параметр для минимального Y карты (без padding)

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let targetHeightForLine = (lineTargetRectSize.height > 0) ? lineTargetRectSize.height : markerSize.height

        if scenePointCache.isEmpty {
            for scene in scenes {
                let sceneScaledX = CGFloat(scene.x) * coordinateScale
                let sceneScaledY = CGFloat(scene.y) * coordinateScale
                let pointX = (sceneScaledX - mapOriginX) + padding + markerSize.width / 2
                // Используем targetHeightForLine для Y-координаты центра линии
                let pointY = (sceneScaledY - mapOriginY) + padding + targetHeightForLine / 2 
                scenePointCache[scene.id] = CGPoint(x: pointX, y: pointY)
            }
        }
        
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(0.5)

        for scene in scenes {
            guard let startPoint = scenePointCache[scene.id] else { continue }
            
            for connection in scene.connections {
                guard let endPoint = scenePointCache[connection.connectedSceneId] else { continue }
                
                context.beginPath()
                context.move(to: startPoint)
                context.addLine(to: endPoint)
                context.strokePath()
            }
        }
    }
} 
