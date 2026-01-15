# RoastMeLater Technical Design Specification

## Document Information
- **Version**: 1.0
- **Created**: 2026-01-13
- **Status**: Draft
- **Related**: FEATURE_REQUIREMENTS.md

---

## 1. Architecture Overview

### 1.1 Current Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │Generator │ │ History  │ │Favorites │ │ Settings │       │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘       │
└───────┼────────────┼────────────┼────────────┼──────────────┘
        │            │            │            │
┌───────┴────────────┴────────────┴────────────┴──────────────┐
│                       ViewModels (MVVM)                      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐         │
│  │RoastGenerator│ │ RoastHistory │ │   Settings   │         │
│  │  ViewModel   │ │  ViewModel   │ │  ViewModel   │         │
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘         │
└─────────┼────────────────┼────────────────┼─────────────────┘
          │                │                │
┌─────────┴────────────────┴────────────────┴─────────────────┐
│                         Services                             │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────────┐    │
│  │   AI    │ │ Storage │ │ Safety  │ │  Notification   │    │
│  │ Service │ │ Service │ │ Filter  │ │    Manager      │    │
│  └─────────┘ └─────────┘ └─────────┘ └─────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Enhanced Architecture (With New Features)
```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │Generator │ │ History  │ │Favorites │ │ Settings │       │
│  │+MoodPick │ │+Reactions│ │ +Badges  │ │+Badges   │       │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘       │
└───────┼────────────┼────────────┼────────────┼──────────────┘
        │            │            │            │
┌───────┴────────────┴────────────┴────────────┴──────────────┐
│                       ViewModels (MVVM)                      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐         │
│  │RoastGenerator│ │ RoastHistory │ │   Badges     │ [NEW]   │
│  │  ViewModel   │ │  ViewModel   │ │  ViewModel   │         │
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘         │
└─────────┼────────────────┼────────────────┼─────────────────┘
          │                │                │
┌─────────┴────────────────┴────────────────┴─────────────────┐
│                         Services                             │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────────┐    │
│  │   AI    │ │ Storage │ │ Streak  │ │    Badge        │    │
│  │ Service │ │ Service │ │ Service │ │   Service       │    │
│  └─────────┘ └─────────┘ └─[NEW]───┘ └────[NEW]────────┘    │
│  ┌─────────┐ ┌─────────────┐ ┌──────────────────────┐       │
│  │ Share   │ │ Collection  │ │    Reaction          │       │
│  │ Service │ │  Service    │ │    Service           │       │
│  └─[NEW]───┘ └────[NEW]────┘ └────────[NEW]─────────┘       │
└─────────────────────────────────────────────────────────────┘
          │
┌─────────┴───────────────────────────────────────────────────┐
│                    Widget Extension [NEW]                    │
│  ┌─────────────────┐ ┌─────────────────────────────────┐    │
│  │  RoastWidget    │ │    Shared App Group Storage     │    │
│  │  (WidgetKit)    │ │                                 │    │
│  └─────────────────┘ └─────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. New Services Design

### 2.1 StreakService

**Purpose**: Manage user streak tracking, persistence, and streak-related notifications.

**Interface**:
```swift
protocol StreakServiceProtocol {
    var currentStreak: Int { get }
    var longestStreak: Int { get }
    var lastActiveDate: Date? { get }
    
    func recordActivity() -> UserStreak
    func checkStreakStatus() -> StreakStatus
    func useStreakFreeze() -> Bool
    func getStreakMilestones() -> [StreakMilestone]
}

enum StreakStatus {
    case active
    case expiringSoon(hoursRemaining: Int)
    case expired
    case frozen
}
```

**Storage Key**: `user_streak_data`

### 2.2 BadgeService

**Purpose**: Track badge progress, unlock badges, and manage badge display.

**Interface**:
```swift
protocol BadgeServiceProtocol {
    func getAllBadges() -> [Badge]
    func getUnlockedBadges() -> [Badge]
    func checkAndUnlockBadges(for event: BadgeEvent) -> [Badge]
    func getBadgeProgress(for badgeId: String) -> Double
}

enum BadgeEvent {
    case roastGenerated(count: Int)
    case streakUpdated(days: Int)
    case categoryUsed(category: RoastCategory)
    case spiceLevelUsed(level: Int)
    case roastFavorited(count: Int)
    case roastShared
}
```

**Storage Key**: `user_badges_data`

### 2.3 ShareService

**Purpose**: Generate branded share images and handle social sharing functionality.

**Interface**:
```swift
protocol ShareServiceProtocol {
    func generateShareImage(for roast: Roast, template: ShareTemplate) async -> UIImage?
    func getAvailableTemplates(for user: UserPreferences) -> [ShareTemplate]
    func shareToSocialMedia(image: UIImage, roast: Roast) -> Bool
}

enum ShareTemplate: String, CaseIterable {
    case classic = "classic"
    case minimal = "minimal"
    case vibrant = "vibrant"
    case story = "story"      // 9:16 aspect ratio
    case square = "square"    // 1:1 aspect ratio
}
```

### 2.4 CollectionService

**Purpose**: Manage roast collections, themes, and seasonal content.

**Interface**:
```swift
protocol CollectionServiceProtocol {
    func getAllCollections() -> [RoastCollection]
    func getActiveSeasonalCollections() -> [RoastCollection]
    func getCollectionPromptModifier(for collectionId: String) -> String?
    func markCollectionProgress(collectionId: String, roastGenerated: Bool)
}
```

**Storage Key**: `roast_collections_data`

### 2.5 ReactionService

**Purpose**: Track user reactions to roasts and provide feedback for AI improvement.

**Interface**:
```swift
protocol ReactionServiceProtocol {
    func recordReaction(_ reaction: RoastReaction, for roastId: UUID)
    func getReactionStats() -> ReactionStats
    func getPromptAdjustment(for category: RoastCategory) -> String?
}

struct ReactionStats: Codable {
    var totalReactions: Int
    var reactionBreakdown: [RoastReaction: Int]
    var categoryFeedback: [String: CategoryFeedback]
}
```

---

## 3. Sequence Diagrams

### 3.1 Streak Recording Flow

```
┌──────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ User │     │    App      │     │StreakService│     │StorageService│
└──┬───┘     └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
   │                │                   │                   │
   │  Opens App     │                   │                   │
   │───────────────>│                   │                   │
   │                │                   │                   │
   │                │  checkStreakStatus()                  │
   │                │──────────────────>│                   │
   │                │                   │                   │
   │                │                   │  load("user_streak_data")
   │                │                   │──────────────────>│
   │                │                   │                   │
   │                │                   │<──────────────────│
   │                │                   │   UserStreak      │
   │                │                   │                   │
   │                │                   │  Calculate streak │
   │                │                   │  status           │
   │                │                   │                   │
   │                │<──────────────────│                   │
   │                │   StreakStatus    │                   │
   │                │                   │                   │
   │                │  recordActivity() │                   │
   │                │──────────────────>│                   │
   │                │                   │                   │
   │                │                   │  save(updatedStreak)
   │                │                   │──────────────────>│
   │                │                   │                   │
   │  Display       │<──────────────────│<──────────────────│
   │  Streak UI     │                   │                   │
   │<───────────────│                   │                   │
```

### 3.2 Badge Unlock Flow

```
┌──────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ User │     │  ViewModel  │     │BadgeService │     │StorageService│
└──┬───┘     └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
   │                │                   │                   │
   │ Generate Roast │                   │                   │
   │───────────────>│                   │                   │
   │                │                   │                   │
   │                │ (After roast generated)               │
   │                │                   │                   │
   │                │ checkAndUnlockBadges(.roastGenerated) │
   │                │──────────────────>│                   │
   │                │                   │                   │
   │                │                   │  load badges      │
   │                │                   │──────────────────>│
   │                │                   │<──────────────────│
   │                │                   │                   │
   │                │                   │  Check criteria   │
   │                │                   │  for each badge   │
   │                │                   │                   │
   │                │                   │  [If badge unlocked]
   │                │                   │  save updated badges
   │                │                   │──────────────────>│
   │                │                   │                   │
   │                │<──────────────────│                   │
   │                │  [Badge] (newly unlocked)             │
   │                │                   │                   │
   │  Show Badge    │                   │                   │
   │  Animation     │                   │                   │
   │<───────────────│                   │                   │
```

### 3.3 Share Image Generation Flow

```
┌──────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ User │     │    View     │     │ShareService │     │ iOS Share   │
└──┬───┘     └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
   │                │                   │                   │
   │  Tap Share     │                   │                   │
   │───────────────>│                   │                   │
   │                │                   │                   │
   │                │ generateShareImage(roast, template)   │
   │                │──────────────────>│                   │
   │                │                   │                   │
   │                │                   │  Create SwiftUI   │
   │                │                   │  View with roast  │
   │                │                   │                   │
   │                │                   │  Render to UIImage│
   │                │                   │  (ImageRenderer)  │
   │                │                   │                   │
   │                │<──────────────────│                   │
   │                │      UIImage      │                   │
   │                │                   │                   │
   │                │  Present UIActivityViewController     │
   │                │──────────────────────────────────────>│
   │                │                   │                   │
   │  Select Share  │                   │                   │
   │  Destination   │                   │                   │
   │<───────────────────────────────────────────────────────│
```

---

## 4. Widget Extension Design

### 4.1 Widget Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Main App Target                           │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              StorageService                          │    │
│  │  - Saves roast data to App Group container          │    │
│  │  - Updates widget-specific data on roast generation │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ App Group: group.com.roastmelater
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Widget Extension Target                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              RoastWidget                             │    │
│  │  - Reads from App Group container                   │    │
│  │  - Displays "Roast of the Day"                      │    │
│  │  - Timeline: refreshes daily                        │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Widget Data Model

```swift
struct WidgetRoastData: Codable {
    let roastOfTheDay: String
    let category: String
    let spiceLevel: Int
    let generatedDate: Date
    let currentStreak: Int
}
```

### 4.3 Widget Timeline Provider

```swift
struct RoastWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> RoastEntry {
        RoastEntry(date: Date(), roastData: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (RoastEntry) -> Void) {
        let entry = RoastEntry(date: Date(), roastData: loadRoastData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RoastEntry>) -> Void) {
        let currentDate = Date()
        let nextMidnight = Calendar.current.startOfDay(for: currentDate.addingTimeInterval(86400))

        let entry = RoastEntry(date: currentDate, roastData: loadRoastData())
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }
}
```

---

## 5. Data Model Extensions

### 5.1 Extended Roast Model

```swift
// Extension to existing Roast.swift
extension Roast {
    var mood: UserMood?
    var reaction: RoastReaction?
    var reactionDate: Date?
    var collectionId: String?
}
```

### 5.2 New Models Location

All new models should be added to `RoastMeLater/Models/`:

| File | Models |
|------|--------|
| `UserStreak.swift` | UserStreak, StreakStatus, StreakMilestone |
| `Badge.swift` | Badge, BadgeCategory, BadgeEvent |
| `UserMood.swift` | UserMood |
| `RoastReaction.swift` | RoastReaction, ReactionStats |
| `RoastCollection.swift` | RoastCollection |
| `ShareTemplate.swift` | ShareTemplate |

---

## 6. Storage Keys Reference

| Key | Data Type | Service |
|-----|-----------|---------|
| `user_streak_data` | UserStreak | StreakService |
| `user_badges_data` | [Badge] | BadgeService |
| `roast_collections_data` | [RoastCollection] | CollectionService |
| `reaction_stats_data` | ReactionStats | ReactionService |
| `widget_roast_data` | WidgetRoastData | StorageService (App Group) |

---

## 7. Integration Points

### 7.1 AIService Modifications

The existing `AIService` needs to be extended to support:

1. **Mood-based prompts**: Accept optional `UserMood` parameter
2. **Collection themes**: Accept optional `RoastCollection` for themed prompts
3. **Feedback loop**: Use `ReactionService` data to adjust prompts

```swift
// Extended AIService interface
func generateRoast(
    category: RoastCategory,
    spiceLevel: Int,
    mood: UserMood? = nil,
    collection: RoastCollection? = nil
) async throws -> String
```

### 7.2 StorageService Modifications

Add App Group support for widget data sharing:

```swift
extension StorageService {
    private var appGroupDefaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.roastmelater")
    }

    func saveWidgetData(_ data: WidgetRoastData) {
        // Save to App Group container
    }
}
```

---

## 8. File Structure (New Files)

```
RoastMeLater/
├── Models/
│   ├── UserStreak.swift          [NEW]
│   ├── Badge.swift               [NEW]
│   ├── UserMood.swift            [NEW]
│   ├── RoastReaction.swift       [NEW]
│   ├── RoastCollection.swift     [NEW]
│   └── ShareTemplate.swift       [NEW]
├── Services/
│   ├── StreakService.swift       [NEW]
│   ├── BadgeService.swift        [NEW]
│   ├── ShareService.swift        [NEW]
│   ├── CollectionService.swift   [NEW]
│   └── ReactionService.swift     [NEW]
├── ViewModels/
│   └── BadgesViewModel.swift     [NEW]
├── Views/
│   ├── Components/
│   │   ├── StreakBadgeView.swift     [NEW]
│   │   ├── MoodPickerView.swift      [NEW]
│   │   ├── ReactionButtonsView.swift [NEW]
│   │   ├── BadgeGridView.swift       [NEW]
│   │   └── SharePreviewView.swift    [NEW]
│   └── BadgesView.swift          [NEW]
└── RoastMeLaterWidget/           [NEW - Widget Extension]
    ├── RoastWidget.swift
    ├── RoastWidgetProvider.swift
    └── RoastWidgetViews.swift
```

---

*Document End - Version 1.0*

