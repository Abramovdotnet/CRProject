import UIKit

class WorldMapViewController: UIViewController, UIScrollViewDelegate {

    private var scrollView: UIScrollView!
    private var contentView: UIView! // Для размещения маркеров локаций
    private var linesView: MapLinesView! // Для отрисовки связей
    
    private var allScenes: [Scene] = []
    private let markerSize = CGSize(width: 120, height: 50) // Увеличенный размер маркера
    private let coordinateScale: CGFloat = 80.0 // Масштаб для координат (1_point на карте = 80_pt на экране)
    private let padding: CGFloat = 50.0 // Отступы вокруг контента карты

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        loadSceneData()
        setupScrollView()
        setupContentView()
        setupMarkersAndLines()
        setupInitialZoomAndPosition()
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
        scrollView.backgroundColor = .darkGray // Для отладки, чтобы видеть границы
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)
    }

    private func setupContentView() {
        // Рассчитываем размер contentView на основе координат сцен
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
        
        // Если сцен нет, устанавливаем дефолтный размер
        if allScenes.isEmpty {
            minX = 0; maxX = 300; minY = 0; maxY = 300;
        }

        let contentWidth = (maxX - minX) + markerSize.width + 2 * padding
        let contentHeight = (maxY - minY) + markerSize.height + 2 * padding
        
        contentView = UIView(frame: CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight))
        // contentView.backgroundColor = .lightGray // Для отладки
        scrollView.addSubview(contentView)
        scrollView.contentSize = contentView.bounds.size
    }

    private func setupMarkersAndLines() {
        guard !allScenes.isEmpty else { return }
        
        // View для линий
        linesView = MapLinesView(frame: contentView.bounds)
        linesView.backgroundColor = .clear
        linesView.scenes = allScenes
        linesView.coordinateScale = coordinateScale
        linesView.markerSize = markerSize
        linesView.padding = padding
        // Нормализация координат относительно minX, minY из setupContentView
        // Рассчитываем смещения один раз
        let minMapX = allScenes.map { CGFloat($0.x) * coordinateScale }.min() ?? 0
        let minMapY = allScenes.map { CGFloat($0.y) * coordinateScale }.min() ?? 0
        
        // Передаем minMapX и minMapY напрямую в MapLinesView
        linesView.mapOriginX = minMapX
        linesView.mapOriginY = minMapY
        contentView.addSubview(linesView)

        // Маркеры локаций
        for scene in allScenes {
            let sceneX = CGFloat(scene.x) * coordinateScale
            let sceneY = CGFloat(scene.y) * coordinateScale
            
            let markerOriginX = (sceneX - minMapX) + padding
            let markerOriginY = (sceneY - minMapY) + padding

            let marker = UIView(frame: CGRect(origin: CGPoint(x: markerOriginX, y: markerOriginY), size: markerSize))
            
            // Установка цвета фона маркера на основе SceneType
            // Поскольку в SceneType нет свойства color, используем стандартные цвета или можно будет добавить
            switch scene.sceneType {
            case .tavern: marker.backgroundColor = UIColor.brown.withAlphaComponent(0.7)
            case .square: marker.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.7)
            case .blacksmith: marker.backgroundColor = UIColor.darkGray.withAlphaComponent(0.7)
            case .house: marker.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.7)
            case .road: marker.backgroundColor = UIColor.lightGray.withAlphaComponent(0.7)
            case .temple: marker.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.7)
            case .shop: marker.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.7)
            case .cathedral: marker.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.7)
            // Новые типы
            case .castle: marker.backgroundColor = UIColor.systemGray.withAlphaComponent(0.8) // Замок - серый, как камень
            case .crypt: marker.backgroundColor = UIColor.darkGray.withAlphaComponent(0.8)    // Крипта - темно-серая
            case .mine: marker.backgroundColor = UIColor.brown.withAlphaComponent(0.6)       // Шахта - коричневая
            case .forest: marker.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.6) // Лес - зеленый
            case .cave: marker.backgroundColor = UIColor.systemBrown.withAlphaComponent(0.7)   // Пещера - землисто-коричневая
            case .ruins: marker.backgroundColor = UIColor.systemGray2.withAlphaComponent(0.7) // Руины - светло-серые
            // Добавьте другие типы по мере необходимости
            default: marker.backgroundColor = UIColor.white.withAlphaComponent(0.7)
            }
            marker.layer.cornerRadius = 8 // Немного скруглим углы
            marker.layer.borderColor = UIColor.black.cgColor
            marker.layer.borderWidth = 0.5
            
            // Иконка типа локации
            let iconImageView = UIImageView(frame: CGRect(x: 5, y: 5, width: 20, height: 20))
            iconImageView.image = UIImage(systemName: scene.sceneType.iconName)
            iconImageView.tintColor = .black // Цвет иконки
            iconImageView.contentMode = .scaleAspectFit
            marker.addSubview(iconImageView)
            
            // Название локации
            let nameLabel = UILabel(frame: CGRect(x: 30, y: 5, width: markerSize.width - 35, height: 20))
            nameLabel.text = scene.name
            nameLabel.font = .systemFont(ofSize: 10, weight: .bold)
            nameLabel.textColor = .black
            nameLabel.adjustsFontSizeToFitWidth = true
            nameLabel.minimumScaleFactor = 0.7
            marker.addSubview(nameLabel)
            
            // Тип локации
            let typeLabel = UILabel(frame: CGRect(x: 30, y: 25, width: markerSize.width - 35, height: 20))
            typeLabel.text = scene.sceneType.displayName
            typeLabel.font = .systemFont(ofSize: 9)
            typeLabel.textColor = .darkGray
            typeLabel.adjustsFontSizeToFitWidth = true
            typeLabel.minimumScaleFactor = 0.7
            marker.addSubview(typeLabel)
            
            contentView.addSubview(marker)
        }
    }
    
    private func setupInitialZoomAndPosition() {
        guard !allScenes.isEmpty else { return }
        
        let contentWidth = scrollView.contentSize.width
        let contentHeight = scrollView.contentSize.height
        
        guard contentWidth > 0, contentHeight > 0 else { return }

        let scaleWidth = scrollView.bounds.width / contentWidth
        let scaleHeight = scrollView.bounds.height / contentHeight
        let minScale = min(scaleWidth, scaleHeight)
        
        scrollView.minimumZoomScale = minScale * 0.5 
        scrollView.zoomScale = max(minScale, scrollView.minimumZoomScale)

        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width * scrollView.zoomScale) / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height * scrollView.zoomScale) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }

    // MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width * scrollView.zoomScale) / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height * scrollView.zoomScale) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}

class MapLinesView: UIView {
    var scenes: [Scene] = []
    var scenePointCache: [Int: CGPoint] = [:]
    var coordinateScale: CGFloat = 1.0
    var markerSize: CGSize = .zero
    var padding: CGFloat = 0.0
    var mapOriginX: CGFloat = 0.0 // Новый параметр для минимального X карты (без padding)
    var mapOriginY: CGFloat = 0.0 // Новый параметр для минимального Y карты (без padding)

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }

        if scenePointCache.isEmpty {
            for scene in scenes {
                let sceneScaledX = CGFloat(scene.x) * coordinateScale
                let sceneScaledY = CGFloat(scene.y) * coordinateScale
                // Координаты центра маркера относительно contentView
                // (sceneScaledX - mapOriginX) дает позицию относительно левого верхнего угла карты (без padding)
                // + padding сдвигает внутрь contentView
                // + markerSize.width / 2 для получения центра маркера
                let pointX = (sceneScaledX - mapOriginX) + padding + markerSize.width / 2
                let pointY = (sceneScaledY - mapOriginY) + padding + markerSize.height / 2
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