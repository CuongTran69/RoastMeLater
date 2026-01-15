# RoastMeLater Feature Enhancement Requirements

## Document Information
- **Version**: 1.0
- **Created**: 2026-01-13
- **Status**: Draft
- **Author**: August (Specification-Driven Development Agent)

---

## Executive Summary

This document outlines the comprehensive requirements specification for RoastMeLater app enhancement based on user insight research. The proposed features aim to increase user engagement, retention, and viral growth while maintaining the app's core value proposition of stress relief through workplace humor.

---

## 1. Streak & Daily Rewards System

### 1.1 Overview
A gamification system that tracks consecutive days of app usage and rewards users for maintaining streaks, creating habit-forming engagement patterns.

### 1.2 EARS-Formatted Requirements

#### Core Streak Tracking
- **REQ-STR-001**: WHEN a user opens the app for the first time in a calendar day THE SYSTEM SHALL increment the user's current streak count by 1
- **REQ-STR-002**: WHEN a user has not opened the app for more than 24 hours since their last recorded activity THE SYSTEM SHALL reset the streak count to 0
- **REQ-STR-003**: WHEN the streak count is updated THE SYSTEM SHALL persist the streak data to local storage immediately
- **REQ-STR-004**: WHEN the app launches THE SYSTEM SHALL display the current streak count prominently on the main screen

#### Streak Protection
- **REQ-STR-005**: WHEN a user's streak is about to expire (within 2 hours of midnight) THE SYSTEM SHALL send a reminder notification if notifications are enabled
- **REQ-STR-006**: WHEN a user loses a streak of 7+ days THE SYSTEM SHALL offer a one-time "streak freeze" option to restore the streak

#### Daily Rewards
- **REQ-STR-007**: WHEN a user maintains a streak of 3 days THE SYSTEM SHALL unlock the "Consistent Roaster" badge
- **REQ-STR-008**: WHEN a user maintains a streak of 7 days THE SYSTEM SHALL unlock access to "Premium Roast" category
- **REQ-STR-009**: WHEN a user maintains a streak of 30 days THE SYSTEM SHALL unlock the "Roast Master" title and special flame icon

### 1.3 Data Model

```swift
struct UserStreak: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date
    var streakFreezeAvailable: Bool
    var totalDaysActive: Int
}
```

### 1.4 Constraints
- Streak data must be stored locally using existing StorageService pattern
- Streak calculation must handle timezone changes gracefully
- Must not require internet connection for basic streak tracking

### 1.5 Success Criteria
- [ ] Streak count accurately reflects consecutive days of usage
- [ ] Streak persists across app restarts
- [ ] Notifications trigger at appropriate times
- [ ] UI displays streak information clearly

---

## 2. iOS Home Screen Widget

### 2.1 Overview
WidgetKit-based widgets that display "Roast of the Day" content directly on the user's home screen, increasing app visibility and engagement touchpoints.

### 2.2 EARS-Formatted Requirements

#### Widget Display
- **REQ-WDG-001**: WHEN the widget is added to home screen THE SYSTEM SHALL display a random roast from the user's preferred categories
- **REQ-WDG-002**: WHEN a new calendar day begins THE SYSTEM SHALL refresh the widget content with a new roast
- **REQ-WDG-003**: WHEN the user taps on the widget THE SYSTEM SHALL open the app and display the full roast with sharing options

#### Widget Sizes
- **REQ-WDG-004**: THE SYSTEM SHALL support small widget size (2x2) displaying roast preview with category icon
- **REQ-WDG-005**: THE SYSTEM SHALL support medium widget size (4x2) displaying full roast content with spice level
- **REQ-WDG-006**: THE SYSTEM SHALL support large widget size (4x4) displaying roast with streak info and quick actions

#### Widget Configuration
- **REQ-WDG-007**: WHEN configuring the widget THE SYSTEM SHALL allow users to select preferred roast categories
- **REQ-WDG-008**: WHEN configuring the widget THE SYSTEM SHALL allow users to set maximum spice level

### 2.3 Technical Requirements
- Requires iOS 14.0+ for WidgetKit support
- Must create new Widget Extension target
- Widget refresh timeline: every 24 hours minimum
- Must share data with main app via App Groups

### 2.4 Constraints
- Widget content must be pre-generated (no API calls from widget)
- Must respect user's spice level preferences
- Must handle case when no roasts are available

---

## 3. Enhanced Social Sharing

### 3.1 Overview
Generate visually appealing, branded images for sharing roasts on social media platforms, enabling viral growth through user-generated content distribution.

### 3.2 EARS-Formatted Requirements

#### Image Generation
- **REQ-SHR-001**: WHEN a user taps the share button THE SYSTEM SHALL generate a branded image containing the roast text
- **REQ-SHR-002**: WHEN generating a share image THE SYSTEM SHALL include the app logo, roast category icon, and spice level indicator
- **REQ-SHR-003**: WHEN generating a share image THE SYSTEM SHALL apply a visually appealing background based on the roast category

#### Sharing Options
- **REQ-SHR-004**: WHEN the share image is generated THE SYSTEM SHALL present the iOS share sheet with all available sharing options
- **REQ-SHR-005**: WHEN sharing to Instagram Stories THE SYSTEM SHALL format the image for optimal story dimensions (9:16 aspect ratio)
- **REQ-SHR-006**: WHEN sharing THE SYSTEM SHALL include a deep link or app store link in the share content

#### Templates
- **REQ-SHR-007**: THE SYSTEM SHALL provide at least 3 different visual templates for share images
- **REQ-SHR-008**: WHEN the user has a streak of 7+ days THE SYSTEM SHALL unlock additional premium share templates

### 3.3 Technical Requirements
- Use SwiftUI's ImageRenderer for image generation (iOS 16+)
- Fallback to UIGraphicsImageRenderer for iOS 14-15
- Image resolution: 1080x1920 for stories, 1080x1080 for posts

### 3.4 Constraints
- Image generation must complete within 2 seconds
- Must work offline using cached templates
- Must respect user privacy (no tracking pixels in shared images)

---

## 4. Mood-Based Suggestions

### 4.1 Overview
Allow users to indicate their current mood, enabling the AI to generate more contextually appropriate and emotionally resonant roasts.

### 4.2 EARS-Formatted Requirements

#### Mood Selection
- **REQ-MOD-001**: WHEN the user opens the roast generator THE SYSTEM SHALL display mood selection options
- **REQ-MOD-002**: THE SYSTEM SHALL provide at least 5 mood options: Stressed, Frustrated, Bored, Tired, Annoyed
- **REQ-MOD-003**: WHEN a mood is selected THE SYSTEM SHALL adjust the AI prompt to generate mood-appropriate roasts

#### Mood-Based Customization
- **REQ-MOD-004**: WHEN the user selects "Stressed" mood THE SYSTEM SHALL generate lighter, more supportive roasts
- **REQ-MOD-005**: WHEN the user selects "Frustrated" mood THE SYSTEM SHALL generate more cathartic, relatable roasts
- **REQ-MOD-006**: WHEN the user selects "Bored" mood THE SYSTEM SHALL generate more creative, unexpected roasts

#### Mood History
- **REQ-MOD-007**: WHEN a roast is generated THE SYSTEM SHALL store the associated mood with the roast history
- **REQ-MOD-008**: WHEN viewing roast history THE SYSTEM SHALL allow filtering by mood

### 4.3 Data Model Extension

```swift
enum UserMood: String, Codable, CaseIterable {
    case stressed = "stressed"
    case frustrated = "frustrated"
    case bored = "bored"
    case tired = "tired"
    case annoyed = "annoyed"

    var promptModifier: String {
        switch self {
        case .stressed: return "supportive and light-hearted"
        case .frustrated: return "cathartic and relatable"
        case .bored: return "creative and unexpected"
        case .tired: return "energizing and motivational"
        case .annoyed: return "validating and humorous"
        }
    }
}
```

### 4.4 Constraints
- Mood selection must be optional (not blocking roast generation)
- Must integrate with existing AIService prompt system
- Mood data used only locally, never sent to external analytics

---

## 5. Achievement Badges System

### 5.1 Overview
A comprehensive achievement system that rewards users for various milestones and behaviors, providing sense of progression and accomplishment.

### 5.2 EARS-Formatted Requirements

#### Badge Categories
- **REQ-BDG-001**: THE SYSTEM SHALL support badges in categories: Streak, Generation, Favorites, Sharing, Exploration
- **REQ-BDG-002**: WHEN a badge is earned THE SYSTEM SHALL display a celebratory animation and notification
- **REQ-BDG-003**: WHEN viewing the profile/settings THE SYSTEM SHALL display all earned badges with progress toward locked badges

#### Streak Badges
- **REQ-BDG-004**: WHEN user reaches 3-day streak THE SYSTEM SHALL award "Getting Started" badge
- **REQ-BDG-005**: WHEN user reaches 7-day streak THE SYSTEM SHALL award "Week Warrior" badge
- **REQ-BDG-006**: WHEN user reaches 30-day streak THE SYSTEM SHALL award "Monthly Master" badge

#### Generation Badges
- **REQ-BDG-007**: WHEN user generates 10 roasts THE SYSTEM SHALL award "Roast Rookie" badge
- **REQ-BDG-008**: WHEN user generates 50 roasts THE SYSTEM SHALL award "Roast Regular" badge
- **REQ-BDG-009**: WHEN user generates 100 roasts THE SYSTEM SHALL award "Roast Veteran" badge

#### Exploration Badges
- **REQ-BDG-010**: WHEN user tries all 8 categories THE SYSTEM SHALL award "Explorer" badge
- **REQ-BDG-011**: WHEN user tries all 5 spice levels THE SYSTEM SHALL award "Spice Adventurer" badge

### 5.3 Data Model

```swift
struct Badge: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let category: BadgeCategory
    let iconName: String
    var isUnlocked: Bool
    var unlockedDate: Date?
    var progress: Double // 0.0 to 1.0
}

enum BadgeCategory: String, Codable {
    case streak, generation, favorites, sharing, exploration
}
```

### 5.4 Constraints
- Badge progress must be calculated efficiently on app launch
- Badge unlock animations must not block user interaction
- Must integrate with existing UserPreferences storage pattern

---

## 6. Roast Collections/Themes

### 6.1 Overview
Curated collections of roasts organized by themes, seasons, or special events, providing fresh content and encouraging exploration.

### 6.2 EARS-Formatted Requirements

#### Collection Display
- **REQ-COL-001**: THE SYSTEM SHALL display available collections on the main screen or dedicated tab
- **REQ-COL-002**: WHEN a collection is selected THE SYSTEM SHALL filter roast generation to that theme
- **REQ-COL-003**: WHEN viewing a collection THE SYSTEM SHALL display collection description, roast count, and preview

#### Seasonal Collections
- **REQ-COL-004**: THE SYSTEM SHALL automatically feature seasonal collections based on current date (Tết, Mid-Autumn, etc.)
- **REQ-COL-005**: WHEN a seasonal event is active THE SYSTEM SHALL display a special banner on the home screen

#### Collection Types
- **REQ-COL-006**: THE SYSTEM SHALL include permanent collections: "Classic Office", "Tech Life", "Meeting Madness"
- **REQ-COL-007**: THE SYSTEM SHALL include rotating collections that change monthly
- **REQ-COL-008**: WHEN user completes all roasts in a collection THE SYSTEM SHALL award a collection-specific badge

### 6.3 Data Model

```swift
struct RoastCollection: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let themeColor: String
    let promptModifier: String
    let isSeasonalEvent: Bool
    let startDate: Date?
    let endDate: Date?
    var isCompleted: Bool
}
```

### 6.4 Constraints
- Collections must work offline with cached prompts
- Seasonal detection must handle Vietnamese calendar events
- Must not require app update to add new collections (consider remote config)

---

## 7. Quick Reactions & Ratings

### 7.1 Overview
Simple feedback mechanism allowing users to rate roasts, enabling quality improvement and personalization of future content.

### 7.2 EARS-Formatted Requirements

#### Reaction Options
- **REQ-RCT-001**: WHEN a roast is displayed THE SYSTEM SHALL show quick reaction buttons (😂, 🔥, 😐, 👎)
- **REQ-RCT-002**: WHEN a reaction is selected THE SYSTEM SHALL store the reaction with the roast record
- **REQ-RCT-003**: WHEN a reaction is selected THE SYSTEM SHALL display brief visual feedback

#### Rating Impact
- **REQ-RCT-004**: WHEN multiple roasts receive 👎 reactions in a category THE SYSTEM SHALL adjust AI prompts for that category
- **REQ-RCT-005**: WHEN a roast receives 🔥 reaction THE SYSTEM SHALL increase likelihood of similar content
- **REQ-RCT-006**: WHEN viewing roast history THE SYSTEM SHALL display the user's reaction for each roast

#### Analytics (Local Only)
- **REQ-RCT-007**: THE SYSTEM SHALL track reaction statistics locally for user insights
- **REQ-RCT-008**: WHEN viewing settings THE SYSTEM SHALL display "Your Roast Stats" showing reaction breakdown

### 7.3 Data Model Extension

```swift
enum RoastReaction: String, Codable {
    case hilarious = "😂"
    case fire = "🔥"
    case meh = "😐"
    case dislike = "👎"
}

// Extension to existing Roast model
extension Roast {
    var reaction: RoastReaction?
    var reactionDate: Date?
}
```

### 7.4 Constraints
- Reactions must be optional and non-intrusive
- All reaction data stored locally only (privacy-first)
- Must not slow down roast generation flow

---

## Appendix A: Priority Matrix

| Feature | Impact | Effort | Priority | Recommended Phase |
|---------|--------|--------|----------|-------------------|
| Streak & Daily Rewards | High | Medium | P1 | Phase 1 |
| iOS Widget | High | Medium | P1 | Phase 1 |
| Enhanced Sharing | High | Low | P1 | Phase 1 |
| Mood-Based Suggestions | Medium | Low | P2 | Phase 2 |
| Achievement Badges | Medium | Medium | P2 | Phase 2 |
| Roast Collections | Medium | Low | P2 | Phase 2 |
| Quick Reactions | Medium | Low | P3 | Phase 3 |

## Appendix B: Dependencies

```
Streak System ──────┬──► Achievement Badges
                    │
                    └──► Widget (streak display)

Mood System ────────────► AI Service (prompt modification)

Collections ────────────► AI Service (theme prompts)

Reactions ──────────────► Roast Model (extension)
                    │
                    └──► AI Service (quality feedback loop)
```

## Appendix C: Technical Constraints Summary

1. **Storage**: All features must use existing StorageService/UserDefaults pattern
2. **Offline**: Core features must work without internet connection
3. **Privacy**: No user data sent to external services without explicit consent
4. **Performance**: No feature should add >100ms to app launch time
5. **Compatibility**: Must support iOS 14.0+ (Widget requires iOS 14+)
6. **Localization**: All new UI strings must support Vietnamese localization

---

*Document End - Version 1.0*

