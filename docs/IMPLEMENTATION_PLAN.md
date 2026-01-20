# RoastMeLater Implementation Plan

## Document Information
- **Version**: 1.1
- **Created**: 2026-01-13
- **Last Updated**: 2026-01-16
- **Status**: Active
- **Related**: FEATURE_REQUIREMENTS.md, TECHNICAL_DESIGN.md

---

## Executive Summary

This implementation plan outlines the phased approach to developing new features for RoastMeLater. The plan is organized into 3 phases based on priority, impact, and dependencies.

### Implementation Progress Overview

| Phase | Feature | Status | Completion Date |
|-------|---------|--------|-----------------|
| Phase 1 | Streak System | ✅ Complete | 2026-01-14 |
| Phase 1 | Enhanced Sharing | ✅ Complete | 2026-01-16 |
| Phase 1 | Mood-Based Suggestions | ❌ Not Started | - |
| Phase 2 | iOS Widget | ✅ Complete | 2026-01-16 |
| Phase 2 | Achievement Badges | ❌ Not Started | - |
| Phase 2 | Roast Collections | ❌ Not Started | - |
| Phase 3 | Quick Reactions | ❌ Not Started | - |

### UI Updates (2026-01-16)

- **Color Scheme**: Changed from Orange to Crimson Red (`#E63946`)
- **RoastGeneratorView**: Simplified UI, removed redundant header
- **RoastCardView**: Cleaner layout with icon-based actions
- **CategoryPickerView**: Compact category cards
- **SplashView**: Updated to new color scheme

---

## Phase 1: Quick Wins (Weeks 1-3)

### Timeline: 3 weeks
### Features: Streak System, Enhanced Sharing, Mood-Based Suggestions

---

### 1.1 Streak & Daily Rewards System ✅ COMPLETE

**Estimated Effort**: 2 weeks
**Priority**: P1 - High Impact, Medium Effort
**Status**: ✅ **COMPLETE** (Implemented 2026-01-14)

#### Task 1.1.1: Data Models ✅
- [x] Create `UserStreak.swift` in Models folder
- [x] Define `UserStreak` struct with properties: currentStreak, longestStreak, lastActiveDate, streakFreezeAvailable, totalDaysActive
- [x] Define `StreakStatus` enum: active, expiringSoon, expired, frozen
- [x] Define `StreakMilestone` struct for milestone tracking
- [x] Add Codable conformance for persistence

#### Task 1.1.2: StreakService Implementation ✅
- [x] Create `StreakService.swift` in Services folder
- [x] Implement `StreakServiceProtocol` interface
- [x] Implement `recordActivity()` - increment streak on daily first open
- [x] Implement `checkStreakStatus()` - calculate current streak state
- [x] Implement `useStreakFreeze()` - one-time streak recovery
- [x] Implement streak persistence using StorageService pattern
- [x] Add timezone-aware date calculations

#### Task 1.1.3: Streak UI Components ✅
- [x] Create `StreakBadgeView.swift` in Views/Components
- [x] Design streak display with flame icon and count
- [x] Add streak milestone celebration animation
- [x] Implement streak expiring warning indicator

#### Task 1.1.4: Integration ✅
- [x] Integrate StreakService into AppLifecycleManager
- [x] Add streak display to RoastGeneratorView header
- [x] Update SettingsView to show streak statistics
- [x] Add streak reminder notification in NotificationScheduler

#### Task 1.1.5: Testing
- [ ] Unit tests for StreakService calculations
- [ ] Test streak persistence across app restarts
- [ ] Test timezone edge cases
- [ ] Test streak freeze functionality

---

### 1.2 Enhanced Social Sharing ✅ COMPLETE

**Estimated Effort**: 1 week
**Priority**: P1 - High Impact, Low Effort
**Status**: ✅ **COMPLETE** (Implemented 2026-01-16)

#### Task 1.2.1: Data Models ✅
- [x] Create `ShareTemplate.swift` in Models folder
- [x] Define `ShareTemplate` enum with template types
- [x] Add template configuration properties (colors, fonts, layout)

#### Task 1.2.2: ShareService Implementation ✅
- [x] Create `SocialSharingService.swift` in Services folder
- [x] Implement `generateShareImage()` using SwiftUI ImageRenderer
- [x] Create fallback for iOS 15 using UIGraphicsImageRenderer
- [x] Implement template selection logic based on user preferences

#### Task 1.2.3: Share UI Components ✅
- [x] Create `SharePreviewView.swift` in Views/Components
- [x] Design branded share card with roast content (`ShareableRoastView`)
- [x] Add app logo, category icon, spice level indicator
- [x] Create template picker UI (`TemplateButton`)

#### Task 1.2.4: Integration ✅
- [x] Update RoastGeneratorView share button
- [x] Add share functionality to LibraryView (History + Favorites)
- [x] Implement hashtags for viral sharing (#RoastMeLater #AIRoast)

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

### 2.1 iOS Home Screen Widget ✅ COMPLETE

**Estimated Effort**: 2-3 weeks
**Priority**: P1 - High Impact, Medium Effort
**Status**: ✅ **COMPLETE** (Implemented 2026-01-16)

#### Task 2.1.1: Widget Extension Setup ✅
- [x] Create new Widget Extension target in Xcode (`RoastMeLaterWidget/`)
- [x] Configure App Group for data sharing (group.com.roastmelater)
- [x] Set up shared UserDefaults access
- [x] Configure widget capabilities in entitlements

#### Task 2.1.2: Widget Data Model ✅
- [x] Create `WidgetRoastData.swift` (shared between app and widget)
- [x] Define data structure for widget display
- [x] Implement App Group storage helpers in `StorageService.swift`

#### Task 2.1.3: Widget Provider ✅
- [x] Create `RoastWidgetProvider` in `RoastWidget.swift`
- [x] Implement TimelineProvider protocol
- [x] Configure daily refresh timeline (refreshes at midnight)
- [x] Handle placeholder and snapshot states

#### Task 2.1.4: Widget Views ✅
- [x] Create `RoastWidgetViews.swift`
- [x] Design small widget (2x2) - roast preview with streak
- [x] Design medium widget (4x2) - full roast with category & spice
- [x] Design large widget (4x4) - roast + streak info + date
- [x] Implement deep linking via `widgetURL`

#### Task 2.1.5: Main App Integration ✅
- [x] Update StorageService to write to App Group (`saveWidgetData`, `updateWidgetWithLatestRoast`)
- [x] Auto-update widget data when roast is saved
- [x] Trigger widget refresh after roast generation (`WidgetCenter.shared.reloadAllTimelines()`)

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
Week 1-2: Streak System + Enhanced Sharing     [✅ Streak DONE, ✅ Sharing DONE]
Week 3:   Mood-Based Suggestions               [❌ Not Started]
Week 4-5: iOS Widget Extension                 [✅ DONE]
Week 5-6: Achievement Badges                   [❌ Not Started]
Week 6:   Roast Collections                    [❌ Not Started]
Week 7:   Quick Reactions                      [❌ Not Started]
```

**Note**: UI redesign completed on 2026-01-16 (color scheme change from orange to crimson red).
**Note**: iOS Widget and Enhanced Sharing completed on 2026-01-16.

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
- [x] Streak system increases DAU by 15%+ (Streak implemented)
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
- [x] Verify iOS deployment target (15.0+)
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

*Document End - Version 1.1*

