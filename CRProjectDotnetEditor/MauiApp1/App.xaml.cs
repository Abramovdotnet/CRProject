namespace MauiApp1;

using MauiApp1.Views;

public partial class App : Application
{
	public App()
	{
		InitializeComponent();

		MainPage = new NavigationPage(new MainTabViewPage());
	}
}