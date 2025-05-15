// No using for CommunityToolkit.Maui.Views needed here anymore for SegmentedControl
// using System.Collections.Generic; // Not needed if children are defined in XAML
// using Plugin.Maui.SegmentedControl; // Removed as it's not used
using System.Diagnostics;

namespace MauiApp1.Views;

public partial class MainTabViewPage : ContentPage
{
	// We can go back to pre-initializing them if they are light-weight
	// or create them on demand. For now, let's keep creating on demand.

	public MainTabViewPage()
	{
		InitializeComponent();
		Debug.WriteLine("[MainTabViewPage] Initializing. Setting content to a new WorldView instance.");
		var initialView = new WorldView();
		CurrentViewContent.Content = initialView;
		LogContentViewDetails(initialView, "Initial WorldView");
		// Set the initial button style using VisualStateManager
		VisualStateManager.GoToState(WorldTabButton, "Selected");
		VisualStateManager.GoToState(NPCsTabButton, "Unselected");
		VisualStateManager.GoToState(QuestsTabButton, "Unselected");
		VisualStateManager.GoToState(DialoguesTabButton, "Unselected");
	}

	void OnTabButtonClicked(object? sender, EventArgs e)
	{
		Debug.WriteLine($"[MainTabViewPage] OnTabButtonClicked Fired!");
		View? newView = null;
		string viewName = "UnknownView";
		Button? clickedButton = sender as Button;

		if (clickedButton == null)
		{
			Debug.WriteLine("[MainTabViewPage] Sender is not a Button.");
			return;
		}

		UpdateTabButtonVisualStates(clickedButton);

		if (clickedButton == WorldTabButton)
		{
			Debug.WriteLine("[MainTabViewPage] Creating and switching to WorldView instance");
			newView = new WorldView();
			viewName = "WorldView";
		}
		else if (clickedButton == NPCsTabButton)
		{
			Debug.WriteLine("[MainTabViewPage] Creating and switching to NPCsView instance");
			newView = new NPCsView();
			viewName = "NPCsView";
		}
		else if (clickedButton == QuestsTabButton)
		{
			Debug.WriteLine("[MainTabViewPage] Creating and switching to QuestsView instance");
			newView = new QuestsView();
			viewName = "QuestsView";
		}
		else if (clickedButton == DialoguesTabButton)
		{
			Debug.WriteLine("[MainTabViewPage] Creating and switching to DialoguesView instance");
			newView = new DialoguesView();
			viewName = "DialoguesView";
		}
		else
		{
			Debug.WriteLine("[MainTabViewPage] Unknown button clicked in OnTabButtonClicked");
		}
		
		if (newView != null)
		{
			LogContentViewDetails(newView, viewName);
		}
		CurrentViewContent.Content = newView;
	}

	void UpdateTabButtonVisualStates(Button selectedButton)
	{
		Button[] tabButtons = { WorldTabButton, NPCsTabButton, QuestsTabButton, DialoguesTabButton };
		foreach (var button in tabButtons)
		{
			if (button == selectedButton)
			{
				VisualStateManager.GoToState(button, "Selected");
			}
			else
			{
				VisualStateManager.GoToState(button, "Unselected");
			}
		}
	}

	private void LogContentViewDetails(View? view, string viewNameForLog)
	{
		if (view == null)
		{
			Debug.WriteLine($"[MainTabViewPage] LogContentViewDetails: {viewNameForLog} is null.");
			return;
		}

		Debug.WriteLine($"[MainTabViewPage] LogContentViewDetails: Assigning {viewNameForLog} of type {view.GetType().FullName}.");
		
		if (view is ContentView cvv)
		{
			if (cvv.Content == null)
			{
				Debug.WriteLine($"[MainTabViewPage] LogContentViewDetails: {viewNameForLog}.Content (as ContentView.Content) is null.");
			}
			else
			{
				Debug.WriteLine($"[MainTabViewPage] LogContentViewDetails: {viewNameForLog}.Content (as ContentView.Content) is of type {cvv.Content.GetType().FullName}.");
				if (cvv.Content is Layout layout)
				{
					Debug.WriteLine($"[MainTabViewPage] LogContentViewDetails: {viewNameForLog}.Content has {layout.Count} children.");
				}
			}
		}
		else if (view is Layout layoutRoot)
		{
			 Debug.WriteLine($"[MainTabViewPage] LogContentViewDetails: {viewNameForLog} (as Layout) has {layoutRoot.Count} children.");
		}
		else 
		{
			Debug.WriteLine($"[MainTabViewPage] LogContentViewDetails: {viewNameForLog} is not a ContentView or Layout.");
		}
	}
} 