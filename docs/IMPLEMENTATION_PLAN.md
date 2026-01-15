# RoastMeLater Implementation Plan

## Document Information
- **Version**: 1.0
- **Created**: 2026-01-13
- **Status**: Draft
- **Related**: FEATURE_REQUIREMENTS.md, TECHNICAL_DESIGN.md

---

## Executive Summary

This implementation plan outlines the phased approach to developing new features for RoastMeLater. The plan is organized into 3 phases based on priority, impact, and dependencies.

---

## Phase 1: Quick Wins (Weeks 1-3)

### Timeline: 3 weeks
### Features: Streak System, Enhanced Sharing, Mood-Based Suggestions

---

### 1.1 Streak & Daily Rewards System

**Estimated Effort**: 2 weeks
**Priority**: P1 - High Impact, Medium Effort

#### Task 1.1.1: Data Models
- [ ] Create `UserStreak.swift` in Models folder
- [ ] Define `UserStreak` struct with properties: currentStreak, longestStreak, lastActiveDate, streakFreezeAvailable, totalDaysActive
- [ ] Define `StreakStatus` enum: active, expiringSoon, expired, frozen
- [ ] Define `StreakMilestone` struct for milestone tracking
- [ ] Add Codable conformance for persistence

#### Task 1.1.2: StreakService Implementation
- [ ] Create `StreakService.swift` in Services folder
- [ ] Implement `StreakServiceProtocol` interface
- [ ] Implement `recordActivity()` - increment streak on daily first open
- [ ] Implement `checkStreakStatus()` - calculate current streak state
- [ ] Implement `useStreakFreeze()` - one-time streak recovery
- [ ] Implement streak persistence using StorageService pattern
- [ ] Add timezone-aware date calculations

#### Task 1.1.3: Streak UI Components
- [ ] Create `StreakBadgeView.swift` in Views/Components
- [ ] Design streak display with flame icon and count
- [ ] Add streak milestone celebration animation
- [ ] Implement streak expiring warning indicator

#### Task 1.1.4: Integration
- [ ] Integrate StreakService into AppLifecycleManager
- [ ] Add streak display to RoastGeneratorView header
- [ ] Update SettingsView to show streak statistics
- [ ] Add streak reminder notification in NotificationScheduler

#### Task 1.1.5: Testing
- [ ] Unit tests for StreakService calculations
- [ ] Test streak persistence across app restarts
- [ ] Test timezone edge cases
- [ ] Test streak freeze functionality

---

### 1.2 Enhanced Social Sharing

**Estimated Effort**: 1 week
**Priority**: P1 - High Impact, Low Effort

#### Task 1.2.1: Data Models
- [ ] Create `ShareTemplate.swift` in Models folder
- [ ] Define `ShareTemplate` enum with template types
- [ ] Add template configuration properties (colors, fonts, layout)

#### Task 1.2.2: ShareService Implementation
- [ ] Create `ShareService.swift` in Services folder
- [ ] Implement `generateShareImage()` using SwiftUI ImageRenderer
- [ ] Create fallback for iOS 14-15 using UIGraphicsImageRenderer
- [ ] Implement template selection logic based on user preferences

#### Task 1.2.3: Share UI Components
- [ ] Create `SharePreviewView.swift` in Views/Components
- [ ] Design branded share card with roast content
- [ ] Add app logo, category icon, spice level indicator
- [ ] Create template picker UI

#### Task 1.2.4: Integration
- [ ] Update RoastGeneratorView share button
- [ ] Add share functionality to RoastHistoryView
- [ ] Add share functionality to FavoritesView
- [ ] Implement deep link generation for shared content

#### Task 1.2.5: Testing
- [ ] Test image generation performance (<2 seconds)
- [ ] Test all template variations
- [ ] Test share sheet integration
- [ ] Test on different device sizes

---

### 1.3 Mood-Based Suggestions

**Estimated Effort**: 1 week
**Priority**: P2 - Medium Impact, Low Effort

#### Task 1.3.1: Data Models
- [ ] Create `UserMood.swift` in Models folder
- [ ] Define `UserMood` enum with mood types
- [ ] Add `promptModifier` computed property for each mood
- [ ] Extend Roast model to include optional mood property

#### Task 1.3.2: Mood UI Components
- [ ] Create `MoodPickerView.swift` in Views/Components
- [ ] Design mood selection with emoji icons
- [ ] Add mood description tooltips
- [ ] Implement smooth selection animation

#### Task 1.3.3: AIService Integration
- [ ] Extend AIService to accept optional mood parameter
- [ ] Modify prompt generation to include mood context
- [ ] Test mood-adjusted roast quality

#### Task 1.3.4: Integration
- [ ] Add MoodPickerView to RoastGeneratorView
- [ ] Store mood with generated roasts
- [ ] Add mood filter to RoastHistoryView

#### Task 1.3.5: Testing
- [ ] Test mood selection UI
- [ ] Verify mood affects AI prompt
- [ ] Test mood persistence with roasts

---

## Phase 2: Engagement Features (Weeks 4-6)

### Timeline: 3 weeks
### Features: iOS Widget, Achievement Badges, Roast Collections

---

### 2.1 iOS Home Screen Widget

**Estimated Effort**: 2-3 weeks
**Priority**: P1 - High Impact, Medium Effort

#### Task 2.1.1: Widget Extension Setup
- [ ] Create new Widget Extension target in Xcode
- [ ] Configure App Group for data sharing (group.com.roastmelater)
- [ ] Set up shared UserDefaults access
- [ ] Configure widget capabilities in entitlements

#### Task 2.1.2: Widget Data Model
- [ ] Create `WidgetRoastData.swift` (shared between app and widget)
- [ ] Define data structure for widget display
- [ ] Implement App Group storage helpers

#### Task 2.1.3: Widget Provider
- [ ] Create `RoastWidgetProvider.swift`
- [ ] Implement TimelineProvider protocol
- [ ] Configure daily refresh timeline
- [ ] Handle placeholder and snapshot states

#### Task 2.1.4: Widget Views
- [ ] Create `RoastWidgetViews.swift`
- [ ] Design small widget (2x2) - roast preview
- [ ] Design medium widget (4x2) - full roast
- [ ] Design large widget (4x4) - roast + streak info
- [ ] Implement widget configuration intent

#### Task 2.1.5: Main App Integration
- [ ] Update StorageService to write to App Group
- [ ] Generate "Roast of the Day" on app launch
- [ ] Trigger widget refresh after roast generation
- [ ] Add widget promotion in Settings

#### Task 2.1.6: Testing
- [ ] Test widget display on all sizes
- [ ] Test widget tap deep linking
- [ ] Test data sync between app and widget
- [ ] Test widget refresh timing

---

### 2.2 Achievement Badges System

**Estimated Effort**: 2 weeks
**Priority**: P2 - Medium Impact, Medium Effort

#### Task 2.2.1: Data Models
- [ ] Create `Badge.swift` in Models folder
- [ ] Define `Badge` struct with all properties
- [ ] Define `BadgeCategory` enum
- [ ] Define `BadgeEvent` enum for trigger events
- [ ] Create predefined badge definitions

#### Task 2.2.2: BadgeService Implementation
- [ ] Create `BadgeService.swift` in Services folder
- [ ] Implement badge progress tracking
- [ ] Implement `checkAndUnlockBadges()` logic
- [ ] Implement badge persistence
- [ ] Create badge unlock notification system

#### Task 2.2.3: BadgesViewModel
- [ ] Create `BadgesViewModel.swift` in ViewModels folder
- [ ] Implement badge list management
- [ ] Implement progress calculation
- [ ] Handle badge unlock events

#### Task 2.2.4: Badge UI Components
- [ ] Create `BadgeGridView.swift` in Views/Components
- [ ] Design badge card with locked/unlocked states
- [ ] Create badge detail view
- [ ] Implement unlock celebration animation
- [ ] Create progress indicator for locked badges

#### Task 2.2.5: Integration
- [ ] Create `BadgesView.swift` main view
- [ ] Add badges section to SettingsView
- [ ] Integrate badge checks into roast generation flow
- [ ] Integrate with StreakService for streak badges
- [ ] Add badge unlock toast notifications

#### Task 2.2.6: Testing
- [ ] Test all badge unlock conditions
- [ ] Test badge persistence
- [ ] Test progress calculations
- [ ] Test unlock animations

---

### 2.3 Roast Collections/Themes

**Estimated Effort**: 1 week
**Priority**: P2 - Medium Impact, Low Effort

#### Task 2.3.1: Data Models
- [ ] Create `RoastCollection.swift` in Models folder
- [ ] Define collection structure with theme properties
- [ ] Create predefined collections data
- [ ] Add seasonal detection logic

#### Task 2.3.2: CollectionService Implementation
- [ ] Create `CollectionService.swift` in Services folder
- [ ] Implement collection retrieval
- [ ] Implement seasonal collection detection
- [ ] Implement collection progress tracking

#### Task 2.3.3: Collection UI
- [ ] Create collection picker component
- [ ] Design collection cards with theme colors
- [ ] Add seasonal banner component
- [ ] Implement collection detail view

#### Task 2.3.4: Integration
- [ ] Add collection selector to RoastGeneratorView
- [ ] Modify AIService to use collection prompts
- [ ] Track collection completion for badges

#### Task 2.3.5: Testing
- [ ] Test collection filtering
- [ ] Test seasonal detection
- [ ] Test collection progress tracking

---

## Phase 3: Feedback Loop (Week 7)

### Timeline: 1 week
### Features: Quick Reactions & Ratings

---

### 3.1 Quick Reactions System

**Estimated Effort**: 1 week
**Priority**: P3 - Medium Impact, Low Effort

#### Task 3.1.1: Data Models
- [ ] Create `RoastReaction.swift` in Models folder
- [ ] Define `RoastReaction` enum with emoji values
- [ ] Define `ReactionStats` struct
- [ ] Extend Roast model with reaction property

#### Task 3.1.2: ReactionService Implementation
- [ ] Create `ReactionService.swift` in Services folder
- [ ] Implement reaction recording
- [ ] Implement statistics calculation
- [ ] Implement prompt adjustment suggestions

#### Task 3.1.3: Reaction UI Components
- [ ] Create `ReactionButtonsView.swift` in Views/Components
- [ ] Design reaction button row with emojis
- [ ] Add selection feedback animation
- [ ] Create reaction stats display

#### Task 3.1.4: Integration
- [ ] Add reactions to roast display views
- [ ] Show reactions in history view
- [ ] Add stats to Settings view
- [ ] (Optional) Feed reaction data to AIService

#### Task 3.1.5: Testing
- [ ] Test reaction recording
- [ ] Test stats calculation
- [ ] Test UI feedback

---

## Summary: Implementation Timeline

```
Week 1-2: Streak System + Enhanced Sharing
Week 3:   Mood-Based Suggestions
Week 4-5: iOS Widget Extension
Week 5-6: Achievement Badges
Week 6:   Roast Collections
Week 7:   Quick Reactions
```

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Widget Extension complexity | Medium | Start with simple widget, iterate |
| App Group data sync issues | Medium | Thorough testing, fallback handling |
| AI prompt quality with mood/collection | Low | A/B testing, user feedback |
| Badge unlock timing issues | Low | Comprehensive unit tests |
| Performance impact on app launch | Medium | Lazy loading, background processing |

---

## Success Metrics

### Phase 1 Success Criteria
- [ ] Streak system increases DAU by 15%+
- [ ] Share feature generates 10%+ organic installs
- [ ] Mood feature has 30%+ adoption rate

### Phase 2 Success Criteria
- [ ] Widget installed by 20%+ of users
- [ ] Badge system increases session duration by 10%+
- [ ] Collections increase category exploration by 25%+

### Phase 3 Success Criteria
- [ ] 50%+ of roasts receive reactions
- [ ] Reaction data improves AI quality scores

---

## Dependencies Summary

```
Phase 1 (Independent - can start immediately):
├── Streak System ────────► Foundation for Phase 2 badges
├── Enhanced Sharing ─────► Standalone feature
└── Mood Suggestions ─────► Requires AIService modification

Phase 2 (Depends on Phase 1):
├── iOS Widget ───────────► Requires Streak System data
├── Achievement Badges ───► Requires Streak System integration
└── Roast Collections ────► Requires AIService modification

Phase 3 (Depends on Phase 1):
└── Quick Reactions ──────► Extends Roast model
```

---

## Technical Checklist

### Before Starting Development
- [ ] Review existing codebase patterns (MVVM, RxSwift usage)
- [ ] Set up App Group capability in Xcode
- [ ] Verify iOS deployment target (14.0+)
- [ ] Review StorageService implementation
- [ ] Review AIService prompt structure

### Code Quality Gates
- [ ] All new code follows existing patterns
- [ ] Unit tests for all services
- [ ] UI tests for critical flows
- [ ] No memory leaks in new components
- [ ] Localization for all new strings (Vietnamese)

### Pre-Release Checklist
- [ ] Performance testing (app launch time)
- [ ] Battery usage testing (widget refresh)
- [ ] Accessibility review
- [ ] Privacy review (no external data sharing)
- [ ] App Store screenshot updates

---

## Appendix: Localization Keys

New localization keys required for Vietnamese support:

```swift
// Streak
"streak.current" = "Chuỗi hiện tại"
"streak.longest" = "Chuỗi dài nhất"
"streak.days" = "ngày"
"streak.expiring" = "Sắp hết hạn!"
"streak.frozen" = "Đã đóng băng"

// Badges
"badges.title" = "Huy hiệu"
"badges.locked" = "Chưa mở khóa"
"badges.unlocked" = "Đã mở khóa"
"badges.progress" = "Tiến độ"

// Mood
"mood.title" = "Tâm trạng hôm nay"
"mood.stressed" = "Căng thẳng"
"mood.frustrated" = "Bực bội"
"mood.bored" = "Chán"
"mood.tired" = "Mệt mỏi"
"mood.annoyed" = "Khó chịu"

// Sharing
"share.title" = "Chia sẻ Roast"
"share.template" = "Chọn mẫu"

// Collections
"collections.title" = "Bộ sưu tập"
"collections.seasonal" = "Theo mùa"

// Reactions
"reactions.title" = "Đánh giá"
"reactions.stats" = "Thống kê phản hồi"
```

---

*Document End - Version 1.0*

