# Chat System Migration: SwiftUI to UIKit

## Overview
The chat system has been completely migrated from SwiftUI to UIKit for better performance and control.

## Architecture

### Core Components

1. **ChatViewModel.swift** - View model containing all chat business logic
   - Manages message subscription from GameEventsBusService
   - Handles message formatting and attribute string building
   - Provides helper methods for different message types

2. **ChatViewController.swift** - Main UIKit controller for chat display
   - Uses UITableView for message display
   - **Combat log styling**: Semi-transparent black background with rounded corners, border, and shadow
   - Auto-scrolling functionality
   - Smooth animations for new messages

3. **ChatMessageTableViewCell.swift** - Custom table view cell for messages
   - Displays attributed text messages
   - Handles appearance animations
   - Proper cell reuse handling

4. **ChatViewControllerWrapper.swift** - SwiftUI bridge for UIKit controller
   - Allows using UIKit chat in SwiftUI views
   - Backward compatibility with existing eventsBus parameter

## Visual Design

### Combat Log Styling
The chat window now uses the same visual style as the combat log:
- **Background**: Semi-transparent black (`UIColor.black.withAlphaComponent(0.5)`)
- **Border**: Thin black border (`borderWidth: 0.5`, `borderColor: UIColor.black`)
- **Corners**: Rounded corners (`cornerRadius: 12`)
- **Shadow**: Soft shadow around the container (`shadowOpacity: 0.8`, `shadowRadius: 8`)
- **Typography**: Optima-Regular 12pt font for enhanced readability

This provides visual consistency with other game UI elements and improves readability.

## Data Models (Unchanged)
- **ChatMessage.swift** - Message data structure
- **MessageType.swift** - Message type enumeration

## Service Integration
The chat system integrates with:
- **GameEventsBusService** - Main event bus for game messages
- **NPCInteractionEventsService** - NPC interaction event handling
- **GameTimeService** - Time stamps for messages

## Integration Points

### SceneView.swift Integration
The chat has been integrated into `SceneView.swift` in the following way:

**Layout Structure:**
```
Top Widget (35px height)
↓ (10px gap)
Chat Container (120px height) - spans between button stacks
↓ (10px gap)  
NPCs Grid - spans between button stacks to bottom
```

**Components Added:**
- `chatContainerView: UIView` - Container for chat
- `chatViewController: ChatViewController?` - Chat controller instance
- `setupChat()` - Setup method called in viewDidLoad
- Updated `setupLayout()` - Positioning chat between top widget and NPCs grid

**Layout Constraints:**
- Chat positioned between left and right button stacks
- Fixed height of 120px for optimal visibility
- 10px margins from top widget and NPCs grid

### MainSceneView.swift Integration
- Updated to use `ChatViewControllerWrapper` instead of `ChatHistoryView`
- Maintains backward compatibility with existing SwiftUI structure

## Key Features
- Attributed text with colors and formatting
- **Optima-Regular 14pt font** for enhanced readability
- Auto-scroll to new messages
- Smooth appearance animations
- Support for interaction icons and complex message structures
- Discussion/rumor message formatting
- Success/failure indicators

## Typography
The chat system uses **Optima-Regular** font at 12pt size for all text elements:
- Timestamps
- Message content
- Character names
- Interaction descriptions
- Success/failure indicators

If Optima-Regular is not available on the system, it gracefully falls back to the system font at the same size.

## Migration Benefits
- Better performance with UITableView vs SwiftUI LazyVStack
- More precise control over animations and scrolling
- Reduced memory usage
- Better compatibility with existing UIKit components
- Consistent layout across all view controllers

## Usage
```swift
// Direct UIKit usage in SceneView
let chatVM = ChatViewModel()
let chatController = ChatViewController(viewModel: chatVM)

// SwiftUI wrapper usage in MainSceneView
ChatViewControllerWrapper(eventsBus: DependencyManager.shared.resolve())
```

## Files Removed
- `ChatHistoryView.swift` (SwiftUI)
- `ChatMessageView.swift` (SwiftUI)
- `InteractionIconView.swift` (SwiftUI)
- `NPCIconView.swift` (SwiftUI)

These have been replaced with the UIKit implementation. 