import UIKit
import SwiftUI // <<< Added for UIHostingController

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
    private let mainViewModel: MainSceneViewModel
    private let coordinateScale: CGFloat = 80.0 // Оставим как в редакторе, чтобы совпадало позиционирование
    private let markerSize = CGSize(width: 120, height: 60) // Было 50, теперь 60
    private let padding: CGFloat = 50.0
    private let backgroundImageView = UIImageView()
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
    private let topWidgetContainerView = UIView()
    private var topWidgetViewController: TopWidgetUIViewController?
    
    init(mainViewModel: MainSceneViewModel) {
        self.mainViewModel = mainViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundImage()
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
        if let scene = allScenes.first(where: { $0.id == currentSceneId }) {
            centerOnScene(scene, animated: false)
        }
        updateCurrentLocationInfo()
        setupTopWidget()
        view.bringSubviewToFront(topWidgetContainerView)
        // --- Добавляю кнопку обратной навигации ---
        setupBackButton()
        // --- конец кнопки ---
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
    
    private func setupTopWidget() {
        topWidgetContainerView.translatesAutoresizingMaskIntoConstraints = false
        topWidgetContainerView.backgroundColor = .clear
        view.addSubview(topWidgetContainerView)
        let widgetVC = TopWidgetUIViewController(viewModel: mainViewModel)
        addChild(widgetVC)
        topWidgetContainerView.addSubview(widgetVC.view)
        widgetVC.view.translatesAutoresizingMaskIntoConstraints = false
        widgetVC.didMove(toParent: self)
        self.topWidgetViewController = widgetVC
        NSLayoutConstraint.activate([
            topWidgetContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 2),
            topWidgetContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            topWidgetContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            topWidgetContainerView.heightAnchor.constraint(equalToConstant: 35)
        ])
        NSLayoutConstraint.activate([
            widgetVC.view.topAnchor.constraint(equalTo: topWidgetContainerView.topAnchor, constant: 2),
            widgetVC.view.leadingAnchor.constraint(equalTo: topWidgetContainerView.leadingAnchor, constant: 2),
            widgetVC.view.trailingAnchor.constraint(equalTo: topWidgetContainerView.trailingAnchor, constant: -2),
            widgetVC.view.bottomAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: -2)
        ])
    }
    
    private func setupBackgroundImage() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.image = UIImage(named: "mapBackgroundAlt")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = false
        view.addSubview(backgroundImageView)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
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
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.backgroundColor = .clear
        scrollView.minimumZoomScale = 0.3
        scrollView.maximumZoomScale = 2.0
        scrollView.contentSize = contentSize
        scrollView.bouncesZoom = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupContentView() {
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalToConstant: contentSize.width),
            contentView.heightAnchor.constraint(equalToConstant: contentSize.height)
        ])
    }
    
    private func setupLinesLayer() {
        linesLayer = CAShapeLayer()
        linesLayer.frame = contentView.bounds
        linesLayer.strokeColor = UIColor.darkGray.cgColor
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
        nameLabel.layer.shadowRadius = 2
        nameLabel.layer.shadowOpacity = 0.5
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
            infoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 35),
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
        // --- Для замков ---
        let currentScene = allScenes.first(where: { $0.id == currentSceneId })
        let lockedNeighborIds: Set<Int> = {
            guard let currentScene = currentScene else { return [] }
            return Set(currentScene.connections.compactMap { conn in
                if let target = allScenes.first(where: { $0.id == conn.connectedSceneId }), target.isLocked {
                    return target.id
                }
                return nil
            })
        }()
        // --- конец для замков ---
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
                        imageView!.tag = 1111 // tag для ассета
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
                        imageView!.tag = 1111 // tag для ассета
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
                    // --- Тень для иконки ---
                    iconImageView.layer.shadowColor = UIColor.black.cgColor
                    iconImageView.layer.shadowRadius = 1
                    iconImageView.layer.shadowOpacity = 0.7
                    iconImageView.layer.shadowOffset = CGSize(width: 0, height: 1)
                    // --- конец тени ---
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
                    // --- Тень для текста ---
                    nameLabel.layer.shadowColor = UIColor.black.cgColor
                    nameLabel.layer.shadowRadius = 0.5
                    nameLabel.layer.shadowOpacity = 0.7
                    nameLabel.layer.shadowOffset = CGSize(width: 0, height: 0.5)
                    // --- конец тени ---
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
                    // --- Тень для текста ---
                    typeLabel.layer.shadowColor = UIColor.black.cgColor
                    typeLabel.layer.shadowRadius = 1
                    typeLabel.layer.shadowOpacity = 0.8
                    typeLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
                    // --- конец тени ---
                    typeLabel.layer.zPosition = 10
                    marker.addSubview(typeLabel)
                    marker.layer.cornerRadius = 8
                    marker.layer.borderWidth = 1.0
                    // --- Обновляю цвет обводки ---
                    if scene.id == currentSceneId {
                        marker.layer.borderColor = UIColor.yellow.cgColor
                    } else if let currentScene = currentScene, currentScene.connections.contains(where: { $0.connectedSceneId == scene.id }), !scene.isLocked {
                        marker.layer.borderColor = UIColor.systemGreen.cgColor
                    } else {
                        marker.layer.borderColor = UIColor.black.cgColor
                    }
                    // --- конец цвета обводки ---
                    // --- Добавляем тень для маркера ---
                    marker.layer.shadowColor = UIColor.black.cgColor
                    marker.layer.shadowOpacity = 0.4
                    marker.layer.shadowRadius = 3
                    marker.layer.shadowOffset = CGSize(width: 0, height: 3)
                    // --- конец тени ---
                    marker.tag = scene.id
                    marker.addTarget(self, action: #selector(markerTapped(_:)), for: .touchUpInside)
                    // --- Добавляем иконку замка, если нужно ---
                    if lockedNeighborIds.contains(scene.id) {
                        let lockSize: CGFloat = 22
                        let lockTag = 9999
                        let lockImageView = UIImageView(frame: CGRect(
                            x: -lockSize - 7, // одинаковое значение для всех случаев
                            y: (markerSize.height - lockSize) / 2,
                            width: lockSize,
                            height: lockSize
                        ))
                        lockImageView.contentMode = .scaleAspectFit
                        lockImageView.image = UIImage(systemName: "lock.fill")
                        lockImageView.tintColor = .systemGray2
                        lockImageView.layer.shadowColor = UIColor.black.cgColor
                        lockImageView.layer.shadowRadius = 2
                        lockImageView.layer.shadowOpacity = 0.7
                        lockImageView.layer.shadowOffset = CGSize(width: 1, height: 1)
                        lockImageView.tag = lockTag
                        marker.addSubview(lockImageView)
                    }
                    // --- Добавляем иконку компаса для текущей локации ---
                    if scene.id == currentSceneId {
                        let compassSize: CGFloat = 72
                        let compassTag = 9998
                        let compassImageView = UIImageView(frame: CGRect(
                            x: markerSize.width - 6, // чуть правее маркера
                            y: (markerSize.height - compassSize) / 2,
                            width: compassSize,
                            height: compassSize
                        ))
                        compassImageView.contentMode = .scaleAspectFit
                        compassImageView.image = UIImage(named: "vampireSigil")
                        compassImageView.layer.shadowColor = UIColor.black.cgColor
                        compassImageView.layer.shadowRadius = 1
                        compassImageView.layer.shadowOpacity = 0.5
                        compassImageView.layer.shadowOffset = CGSize(width: 1, height: 1)
                        compassImageView.tag = compassTag
                        marker.addSubview(compassImageView)
                    }
                    // --- конец компаса ---
                    contentView.addSubview(marker)
                    markerViews[scene.id] = marker
                    // --- Анимация мерцания для текущей локации ---
                    if scene.id == currentSceneId {
                        marker.layer.removeAllAnimations()
                        marker.alpha = 1.0
                        UIView.animate(withDuration: 1.0, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction], animations: {
                            marker.alpha = 0.7
                        }, completion: nil)
                    } else {
                        marker.layer.removeAllAnimations()
                        marker.alpha = 1.0
                    }
                    // --- конец анимации ---
                } else {
                    let marker = markerViews[scene.id]!
                    // --- Обновляю цвет обводки при обновлении ---
                    if scene.id == currentSceneId {
                        marker.layer.borderColor = UIColor.yellow.cgColor
                    } else if let currentScene = currentScene, currentScene.connections.contains(where: { $0.connectedSceneId == scene.id }), !scene.isLocked {
                        marker.layer.borderColor = UIColor.systemGreen.cgColor
                    } else {
                        marker.layer.borderColor = UIColor.black.cgColor
                    }
                    // --- конец цвета обводки ---
                    // Обновить alpha ассета при изменении зума
                    if let assetImageView = marker.subviews.first(where: { $0 is UIImageView && $0.tag == 1111 }) as? UIImageView {
                        let assetAlpha = assetAlphaForZoom(scrollView.zoomScale)
                        assetImageView.alpha = assetAlpha
                        assetImageView.isHidden = assetAlpha <= 0.01
                    }
                    // --- Добавляем/убираем иконку замка при обновлении ---
                    let lockTag = 9999
                    if lockedNeighborIds.contains(scene.id) {
                        if marker.subviews.first(where: { $0.tag == lockTag }) == nil {
                            let lockSize: CGFloat = 22
                            let lockImageView = UIImageView(frame: CGRect(
                                x: -lockSize - 7,
                                y: (markerSize.height - lockSize) / 2,
                                width: lockSize,
                                height: lockSize
                            ))
                            lockImageView.contentMode = .scaleAspectFit
                            lockImageView.image = UIImage(systemName: "lock.fill")
                            lockImageView.tintColor = .systemGray2
                            lockImageView.layer.shadowColor = UIColor.black.cgColor
                            lockImageView.layer.shadowRadius = 2
                            lockImageView.layer.shadowOpacity = 0.7
                            lockImageView.layer.shadowOffset = CGSize(width: 1, height: 1)
                            lockImageView.tag = lockTag
                            marker.addSubview(lockImageView)
                        }
                    } else {
                        // Удаляем замок, если он был
                        marker.subviews.filter { $0.tag == lockTag }.forEach { $0.removeFromSuperview() }
                    }
                    // --- конец обновления замка ---
                    // --- Добавляем/убираем иконку компаса при обновлении ---
                    let compassTag = 9998
                    if scene.id == currentSceneId {
                        if marker.subviews.first(where: { $0.tag == compassTag }) == nil {
                            let compassSize: CGFloat = 72
                            let compassImageView = UIImageView(frame: CGRect(
                                x: markerSize.width - 6,
                                y: (markerSize.height - compassSize) / 2,
                                width: compassSize,
                                height: compassSize
                            ))
                            compassImageView.contentMode = .scaleAspectFit
                            compassImageView.image = UIImage(named: "vampireSigil")
                            compassImageView.layer.shadowColor = UIColor.black.cgColor
                            compassImageView.layer.shadowRadius = 1
                            compassImageView.layer.shadowOpacity = 0.5
                            compassImageView.layer.shadowOffset = CGSize(width: 1, height: 1)
                            compassImageView.tag = compassTag
                            marker.addSubview(compassImageView)
                        }
                    } else {
                        marker.subviews.filter { $0.tag == compassTag }.forEach { $0.removeFromSuperview() }
                    }
                    // --- конец обновления компаса ---
                    // --- Анимация мерцания для текущей локации при обновлении ---
                    if scene.id == currentSceneId {
                        marker.layer.removeAllAnimations()
                        marker.alpha = 1.0
                        UIView.animate(withDuration: 1.0, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction], animations: {
                            marker.alpha = 0.7
                        }, completion: nil)
                    } else {
                        marker.layer.removeAllAnimations()
                        marker.alpha = 1.0
                    }
                    // --- конец анимации ---
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
        if let scene = allScenes.first(where: { $0.id == sceneId }) {
            centerOnScene(scene, animated: true)
        }
        updateVisibleMarkersAndLines()
        updateCurrentLocationInfo()
    }
    
    // Новая функция центрирования на сцене
    private func centerOnScene(_ scene: Scene, animated: Bool) {
        // 1. Координаты центра маркера в contentView
        let markerCenter = CGPoint(
            x: (CGFloat(scene.x) * coordinateScale - minMapX) + padding + markerSize.width / 2,
            y: (CGFloat(scene.y) * coordinateScale - minMapY) + padding + markerSize.height / 2
        )
        // 2. Размеры видимой области (scrollView.bounds)
        let visibleSize = scrollView.bounds.size
        // 3. Вычисляем offset так, чтобы markerCenter оказался по центру экрана
        var offset = CGPoint(
            x: markerCenter.x * scrollView.zoomScale - visibleSize.width / 2,
            y: markerCenter.y * scrollView.zoomScale - visibleSize.height / 2
        )
        // 4. Ограничиваем offset, чтобы не выйти за пределы contentSize
        let maxOffsetX = scrollView.contentSize.width - visibleSize.width
        let maxOffsetY = scrollView.contentSize.height - visibleSize.height
        offset.x = max(0, min(offset.x, maxOffsetX))
        offset.y = max(0, min(offset.y, maxOffsetY))
        // 5. Применяем offset
        scrollView.setContentOffset(offset, animated: animated)
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
    
    // --- Кнопка обратной навигации ---
    private func setupBackButton() {
        let buttonSize: CGFloat = 40
        let backButton = UIButton(type: .custom)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        let icon = UIImage(systemName: "arrow.uturn.left", withConfiguration: config)?.withRenderingMode(.alwaysTemplate)
        backButton.setImage(icon, for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = UIColor(white: 0.08, alpha: 0.98)
        backButton.layer.cornerRadius = buttonSize / 2
        backButton.layer.masksToBounds = false
        // Outer glow (CALayer)
        let glowLayer = CALayer()
        glowLayer.frame = CGRect(x: -1, y: -1, width: buttonSize + 2, height: buttonSize + 2)
        glowLayer.cornerRadius = (buttonSize + 2) / 2
        glowLayer.backgroundColor = UIColor.white.withAlphaComponent(0.9).cgColor
        glowLayer.shadowColor = UIColor.black.cgColor
        glowLayer.shadowRadius = 8
        glowLayer.shadowOpacity = 1.0
        glowLayer.shadowOffset = CGSize(width: 0, height: 0)
        glowLayer.opacity = 0.7
        backButton.layer.insertSublayer(glowLayer, at: 0)
        // Анимация нажатия
        backButton.addTarget(self, action: #selector(backButtonTouchDown), for: .touchDown)
        backButton.addTarget(self, action: #selector(backButtonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: topWidgetContainerView.bottomAnchor, constant: 12),
            backButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            backButton.widthAnchor.constraint(equalToConstant: buttonSize),
            backButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
        view.bringSubviewToFront(backButton)
    }
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    @objc private func backButtonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.08) {
            sender.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
            sender.alpha = 0.8
        }
    }
    @objc private func backButtonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12) {
            sender.transform = .identity
            sender.alpha = 1.0
        }
    }
    // --- конец кнопки ---
} 
