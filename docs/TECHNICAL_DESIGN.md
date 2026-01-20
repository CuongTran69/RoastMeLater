# RoastMeLater Technical Design Specification

## Document Information
- **Version**: 1.1
- **Created**: 2026-01-13
- **Last Updated**: 2026-01-16
- **Status**: Active
- **Related**: FEATURE_REQUIREMENTS.md

---

## 0. Current Implementation Status

### 0.1 App Color Scheme (Updated 2026-01-16)

The app uses a **Crimson Red** theme replacing the previous orange color scheme:

| Color Role | Hex Code | RGB | Usage |
|------------|----------|-----|-------|
| **Primary** | `#E63946` | `(230, 57, 70)` | Main accent, buttons, icons |
| **Secondary** | `#1D3557` | `(29, 53, 87)` | Dark navy for contrast |
| **Accent** | `#F4A261` | `(244, 162, 97)` | Warm sand for highlights |
| **Gradient Start** | `#E63946` | `(230, 57, 70)` | Button gradient start |
| **Gradient End** | `#9D0208` | `(157, 2, 8)` | Deep red gradient end |

Colors are defined in `RoastMeLater/Utils/Constants.swift` under `Constants.UI.Colors`.

### 0.2 Implemented Features

| Feature | Status | Location |
|---------|--------|----------|
| Core Roast Generation | ✅ Complete | `RoastGeneratorView.swift`, `RoastGeneratorViewModel.swift` |
| Roast History | ✅ Complete | `LibraryView.swift`, `RoastHistoryViewModel.swift` |
| Favorites | ✅ Complete | `LibraryView.swift`, `FavoritesViewModel.swift` |
| Settings | ✅ Complete | `SettingsView.swift` |
| AI Integration (OpenAI/Gemini) | ✅ Complete | `AIService.swift` |
| Localization (VI/EN) | ✅ Complete | `Localization/` folder |
| Streak System | ✅ Complete | `StreakService.swift`, `StreakBadgeView.swift` |
| iOS Widget | ✅ Complete | `RoastMeLaterWidget/`, `StorageService.swift` (App Group) |
| Enhanced Sharing | ✅ Complete | `SocialSharingService.swift`, `SharePreviewView.swift` |
| Achievement Badges | ❌ Not Started | - |

### 0.3 UI Components (Updated 2026-01-16)

| Component | File | Description |
|-----------|------|-------------|
| `RoastGeneratorView` | `Views/RoastGeneratorView.swift` | Main roast generation screen (simplified UI) |
| `RoastCardView` | `Views/RoastGeneratorView.swift` | Displays generated roast with actions |
| `RoastPlaceholderView` | `Views/RoastGeneratorView.swift` | Empty state placeholder |
| `CategoryPickerView` | `Views/RoastGeneratorView.swift` | Category selection sheet |
| `CategoryCard` | `Views/RoastGeneratorView.swift` | Individual category card |
| `StreakBadgeView` | `Views/Components/StreakBadgeView.swift` | Streak display component |
| `SharePreviewView` | `Views/Components/SharePreviewView.swift` | Enhanced sharing with template selection |
| `ShareableRoastView` | `Services/SocialSharingService.swift` | Branded shareable roast card |
| `LibraryView` | `Views/LibraryView.swift` | Combined History + Favorites |
| `SettingsView` | `Views/SettingsView.swift` | App settings |
| `SplashView` | `Views/SplashView.swift` | App launch screen |

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

## 8. File Structure

### 8.1 Current Implemented Structure

```
RoastMeLater/
├── Models/
│   ├── Roast.swift               [IMPLEMENTED]
│   ├── RoastCategory.swift       [IMPLEMENTED]
│   ├── UserPreferences.swift     [IMPLEMENTED]
│   └── UserStreak.swift          [IMPLEMENTED] - Phase 1 Streak
├── Services/
│   ├── AIService.swift           [IMPLEMENTED]
│   ├── StorageService.swift      [IMPLEMENTED]
│   ├── SafetyFilter.swift        [IMPLEMENTED]
│   ├── NotificationScheduler.swift [IMPLEMENTED]
│   └── StreakService.swift       [IMPLEMENTED] - Phase 1 Streak
├── ViewModels/
│   ├── RoastGeneratorViewModel.swift [IMPLEMENTED]
│   ├── RoastHistoryViewModel.swift   [IMPLEMENTED]
│   └── FavoritesViewModel.swift      [IMPLEMENTED]
├── Views/
│   ├── ContentView.swift         [IMPLEMENTED]
│   ├── RoastGeneratorView.swift  [IMPLEMENTED] - Updated UI 2026-01-16
│   ├── LibraryView.swift         [IMPLEMENTED]
│   ├── SettingsView.swift        [IMPLEMENTED]
│   ├── SplashView.swift          [IMPLEMENTED] - Updated colors 2026-01-16
│   └── Components/
│       ├── StreakBadgeView.swift [IMPLEMENTED] - Phase 1 Streak
│       └── PrivacyNoticeView.swift [IMPLEMENTED]
├── Utils/
│   ├── Constants.swift           [IMPLEMENTED] - Updated colors 2026-01-16
│   └── Analytics.swift           [IMPLEMENTED]
└── Localization/
    ├── en.lproj/                 [IMPLEMENTED]
    └── vi.lproj/                 [IMPLEMENTED]
```

### 8.2 Planned New Files (Not Yet Implemented)

```
RoastMeLater/
├── Models/
│   ├── Badge.swift               [PLANNED - Phase 2]
│   ├── UserMood.swift            [PLANNED - Phase 2]
│   ├── RoastReaction.swift       [PLANNED - Phase 3]
│   ├── RoastCollection.swift     [PLANNED - Phase 2]
│   └── ShareTemplate.swift       [PLANNED - Phase 1]
├── Services/
│   ├── BadgeService.swift        [PLANNED - Phase 2]
│   ├── ShareService.swift        [PLANNED - Phase 1]
│   ├── CollectionService.swift   [PLANNED - Phase 2]
│   └── ReactionService.swift     [PLANNED - Phase 3]
├── ViewModels/
│   └── BadgesViewModel.swift     [PLANNED - Phase 2]
├── Views/
│   ├── Components/
│   │   ├── MoodPickerView.swift      [PLANNED - Phase 2]
│   │   ├── ReactionButtonsView.swift [PLANNED - Phase 3]
│   │   ├── BadgeGridView.swift       [PLANNED - Phase 2]
│   │   └── SharePreviewView.swift    [PLANNED - Phase 1]
│   └── BadgesView.swift          [PLANNED - Phase 2]
└── RoastMeLaterWidget/           [PLANNED - Phase 2 Widget Extension]
    ├── RoastWidget.swift
    ├── RoastWidgetProvider.swift
    └── RoastWidgetViews.swift
```

---

*Document End - Version 1.1*

