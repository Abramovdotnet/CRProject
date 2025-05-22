# Cursor Rules for CRProject

## 1. Основные классы и их расположение

- Класс игрока:
  `/Users/abramovanatoliy/Documents/CRProject/CRProject/Models/Characters/Player.swift`
- Класс NPC (нпс) и профессии:
  `/Users/abramovanatoliy/Documents/CRProject/CRProject/Models/Characters/NPC.swift`
- Активности NPC:
  `/Users/abramovanatoliy/Documents/CRProject/CRProject/Models/Characters/NPCBehavior/NPCActivityType.swift`
- Класс сцены:
  `/Users/abramovanatoliy/Documents/CRProject/CRProject/Models/Environment/Scene.swift`
- Типы сцен:
  `/Users/abramovanatoliy/Documents/CRProject/CRProject/Models/Environment/SceneType.swift`

## 2. Сервисы

- Все сервисы находятся в:
  `/Users/abramovanatoliy/Documents/CRProject/CRProject/Services`
- Ключевые сервисы:
  - GameStateService (управление перемещением по локациям, игрок, нпс на локации, awareness):
    `/Users/abramovanatoliy/Documents/CRProject/CRProject/Services/GameStateService.swift`
  - NPCBehaviorService (перемещение нпс по карте):
    `/Users/abramovanatoliy/Documents/CRProject/CRProject/Services/NPCBehaviorService.swift`
  - NPCInteractionService (взаимодействие нпс друг с другом):
    `/Users/abramovanatoliy/Documents/CRProject/CRProject/Services/NPCInteractionService.swift`
- Все сервисы реализованы как singleton через статическое свойство shared.

## 3. Данные

- Список NPC:
  `/Users/abramovanatoliy/Documents/CRProject/CRProject/Data/NPCs.json`
- Список сцен:
  `/Users/abramovanatoliy/Documents/CRProject/CRProject/Data/Duskvale/Duskvale.json`

## 4. Чтение данных

- Для получения списка сцен используйте:
  `/Users/abramovanatoliy/Documents/CRProject/CRProject/Supportive/LocationReader.swift`
  - Получить все локации: `LocationReader.getLocations()`
  - Получить сцену по id: `LocationReader.getRuntimeLocation(id)` (может бросать throw)
- Для получения списка NPC используйте:
  `/Users/abramovanatoliy/Documents/CRProject/CRProject/Supportive/NPCReader.swift`
  - Получить всех NPC: `NPCReader.getNPCs()`
  - Получить NPC по id: `NPCReader.getRuntimeNPC(id)` (может вернуть nil)

## 5. Вью и ViewModel

- Главная игровая сцена (основная view):
  `/Users/abramovanatoliy/Documents/CRProject/CRProject/Views/MainSceneView.swift` (SwiftUI)
  - ViewModel:
    `/Users/abramovanatoliy/Documents/CRProject/CRProject/ViewModels/MainSceneViewModel.swift`
- UIKit-вью и их SwiftUI-врапперы:
  - Журнал квестов:
    UIKit: `/Users/abramovanatoliy/Documents/CRProject/CRProject/Views/QuestJournalViewController.swift`
    SwiftUI-враппер: `/Users/abramovanatoliy/Documents/CRProject/CRProject/Views/QuestJournalView.swift`
  - Карта мира:
    UIKit: `/Users/abramovanatoliy/Documents/CRProject/CRProject/Views/VirtualWorldMapViewController.swift`
    SwiftUI-враппер: `/Users/abramovanatoliy/Documents/CRProject/CRProject/Views/WorldMapView.swift`
  - Сетка NPC:
    SwiftUI: `/Users/abramovanatoliy/Documents/CRProject/CRProject/Views/MainSceneViews/NPCSGridView.swift` (враппер внутри файла)
  - Топ виджет:
    SwiftUI: `/Users/abramovanatoliy/Documents/CRProject/CRProject/Views/MainSceneViews/TopWidgetView.swift` 
## 6. Согласованность моделей и парсеров

- При изменении классов NPC, Scene, Player, Profession или SceneType:
  - Обязательно обновляйте соответствующие парсеры:
    - Для NPC: `/Users/abramovanatoliy/Documents/CRProject/CRProject/Supportive/NPCReader.swift`
    - Для сцен: `/Users/abramovanatoliy/Documents/CRProject/CRProject/Supportive/LocationReader.swift`
  - Проверьте, что новые/удалённые свойства корректно сериализуются/десериализуются из/в JSON.

## 7. Навигация и взаимодействие

- Основная навигация между сценами и вью осуществляется через SwiftUI-вью и их врапперы для UIKit.
- Для доступа к текущему игроку, сцене, NPC используйте singleton-сервисы, например:
  `GameStateService.shared.player`

---

## Примерные правила для Cursor

1. **Изменяя модель (NPC, Scene, Player, Profession, SceneType), всегда проверяй и обновляй соответствующий Reader (NPCReader, LocationReader) для поддержки новых свойств.**
2. **Все пути к файлам и папкам указывай максимально точно, как в этом документе.**
3. **Для получения или обновления данных NPC и сцен всегда используй методы из NPCReader и LocationReader.**
4. **Для доступа к состоянию игры, игроку, текущей сцене и NPC на сцене используй GameStateService.shared.**
5. **Для управления перемещением NPC по карте используй NPCBehaviorService.shared.**
6. **Для взаимодействия NPC между собой используй NPCInteractionService.shared.**
7. **Все новые View и ViewModel размещай в соответствующих папках Views и ViewModels, с точным указанием пути.**
8. **Если добавляешь новую профессию, активность или тип сцены, обязательно обновляй соответствующие enum/struct в файлах:**
   - Профессии: `/Users/abramovanatoliy/Documents/CRProject/CRProject/Models/Characters/NPC.swift`
   - Активности: `/Users/abramovanatoliy/Documents/CRProject/CRProject/Models/Characters/NPCBehavior/NPCActivityType.swift`
   - Типы сцен: `/Users/abramovanatoliy/Documents/CRProject/CRProject/Models/Environment/SceneType.swift`
9. **Для любых изменений, влияющих на сериализацию/десериализацию, не забывай обновлять JSON-файлы и их парсеры.**
10. **Для сложных UI используйте UIKit-вью с врапперами для SwiftUI, как в примерах выше.** 