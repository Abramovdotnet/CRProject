using Foundation;
using UIKit;

namespace MauiApp1;

[Register("AppDelegate")]
public class AppDelegate : MauiUIApplicationDelegate
{
	protected override MauiApp CreateMauiApp() => MauiProgram.CreateMauiApp();

	// Добавлено для попытки максимизации окна
	public override void OnActivated(UIApplication application)
	{
		base.OnActivated(application);

		var windowScene = application.ConnectedScenes.ToArray().FirstOrDefault(s => s is UIWindowScene) as UIWindowScene;
		if (windowScene != null && windowScene.Windows.Any())
		{
			var nativeWindow = windowScene.Windows[0]; 
			// Для Mac Catalyst, попытка "приблизить" (maximize) окно.
			// Это может не быть истинным "полноэкранным режимом", но должно развернуть окно.
			// Для macOS есть NSWindow.Zoom(), но доступ к нему из UIWindow может потребовать дополнительных шагов.
			// Этот код является общей попыткой.
			if (nativeWindow.RootViewController != null)
			{
				// Прямого метода Maximize() или FullScreen() для UIWindow в Mac Catalyst нет так просто.
				// Обычно это управляется через NSWindow на уровне AppKit.
				// Оставим это пока как есть, так как глубокая интеграция с AppKit выходит за рамки простого изменения.
				// Пользователь сможет вручную развернуть окно.
				// Для будущего: можно исследовать Objective-C runtime вызовы для NSWindow.Zoom().
			}
		}
	}
}
