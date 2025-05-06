import SwiftUI
import UIKit

struct QuestJournalView: UIViewControllerRepresentable {
    // Добавляем свойство для передачи MainSceneViewModel
    var mainSceneViewModel: MainSceneViewModel

    // Сюда можно передать данные, если нужно, например, player или npc,
    // но QuestJournalViewController сам получает доступ к QuestService.shared

    func makeUIViewController(context: Context) -> QuestJournalViewController {
        // Передаем viewModel при создании QuestJournalViewController
        return QuestJournalViewController(mainViewModel: mainSceneViewModel)
    }

    func updateUIViewController(_ uiViewController: QuestJournalViewController, context: Context) {
        // Здесь можно обновлять QuestJournalViewController, если нужно, 
        // когда изменяются значения в SwiftUI
    }
}

#if DEBUG
struct QuestJournalView_Previews: PreviewProvider {
    static var previews: some View {
        // Для превью можно создать моковый QuestService с данными или убедиться,
        // что QuestService.shared и QuestService.shared.player инициализированы
        // если ваш QuestService и Player это ObservableObject, их можно передать в Environment
        
        // Простейший вариант (может не показать данные без инициализированного QuestService):
        QuestJournalView(mainSceneViewModel: MainSceneViewModel())
            .background(Color.black.opacity(0.7))
            .edgesIgnoringSafeArea(.all)
    }
}
#endif 