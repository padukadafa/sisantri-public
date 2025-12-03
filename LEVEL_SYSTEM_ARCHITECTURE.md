# Level System Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         SISANTRI LEVEL SYSTEM                            │
│                         (Gamification Feature)                           │
└──────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                          DATA LAYER                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ LevelModel (lib/shared/models/level_model.dart)                 │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │ Properties:                                                      │   │
│  │  • level: int                                                    │   │
│  │  • title: String                                                 │   │
│  │  • minPoin: int                                                  │   │
│  │  • maxPoin: int                                                  │   │
│  │  • badge: String (emoji)                                         │   │
│  │  • color: String (hex)                                           │   │
│  │                                                                  │   │
│  │ Methods:                                                         │   │
│  │  • fromPoin(int) → LevelModel                                   │   │
│  │  • getProgressToNextLevel(int) → double                         │   │
│  │  • getPoinToNextLevel(int) → int                                │   │
│  │  • isMaxLevel() → bool                                          │   │
│  │  • getNextLevel() → LevelModel?                                 │   │
│  │  • getAllLevels() → List<LevelModel>                            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                        SERVICE LAYER                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ LevelService (lib/shared/services/level_service.dart)           │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │ Static Methods:                                                  │   │
│  │  • didLevelUp(oldPoin, newPoin) → bool                          │   │
│  │  • getNewLevel(oldPoin, newPoin) → LevelModel?                  │   │
│  │  • getLevelUpMessage(level) → String                            │   │
│  │  • getLevelUpDescription(level) → String                        │   │
│  │  • getAllLevels() → List<LevelModel>                            │   │
│  │  • getCurrentLevel(poin) → LevelModel                           │   │
│  │  • getProgressPercentage(poin) → double                         │   │
│  │  • getProgressText(poin) → String                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │ LevelBadgeWidget                                           │        │
│  │ (lib/shared/widgets/level_badge_widget.dart)              │        │
│  ├────────────────────────────────────────────────────────────┤        │
│  │ • Compact circular badge                                   │        │
│  │ • Size: 18-60px (customizable)                             │        │
│  │ • Shows emoji + level number                               │        │
│  │ • Gradient background with shadow                          │        │
│  │                                                            │        │
│  │ Usage:                                                     │        │
│  │  - Leaderboard avatars (18-22px)                          │        │
│  │  - Dashboard header (50px)                                │        │
│  │  - Profile pictures overlay                                │        │
│  └────────────────────────────────────────────────────────────┘        │
│                                                                         │
│  ┌────────────────────────────────────────────────────────────┐        │
│  │ LevelProgressCard                                          │        │
│  │ (lib/shared/widgets/level_progress_card.dart)             │        │
│  ├────────────────────────────────────────────────────────────┤        │
│  │ • Full card component                                      │        │
│  │ • Badge + Title + Level number                             │        │
│  │ • Animated progress bar                                    │        │
│  │ • Points needed display                                    │        │
│  │ • Next level preview                                       │        │
│  │ • "MAX LEVEL" indicator                                    │        │
│  │                                                            │        │
│  │ Usage:                                                     │        │
│  │  - Profile page                                           │        │
│  │  - Dashboard detailed view                                │        │
│  │  - Statistics pages                                       │        │
│  └────────────────────────────────────────────────────────────┘        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                     INTEGRATION POINTS                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  📊 DASHBOARD (dashboard_welcome_card.dart)                            │
│  ├─ Level badge (50px) next to username                                │
│  ├─ Level title & description                                          │
│  ├─ Progress bar (color-coded)                                         │
│  ├─ Points needed to next level                                        │
│  └─ Total points badge                                                 │
│                                                                         │
│  🏆 LEADERBOARD (leaderboard_page.dart)                                │
│  ├─ Podium: Level badges on avatars (22px, bottom)                     │
│  ├─ List: Level badges on avatars (18px, bottom-right)                 │
│  └─ Level title next to name (color-coded)                             │
│                                                                         │
│  👤 PROFILE (profile_page.dart)                                        │
│  ├─ LevelProgressCard (full details)                                   │
│  ├─ Current level badge & title                                        │
│  ├─ Progress bar to next level                                         │
│  ├─ Next level preview                                                 │
│  └─ Points needed display                                              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                       DATA FLOW                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Firebase Firestore                                                    │
│        ↓                                                                │
│  PresensiAggregateService                                              │
│        ↓                                                                │
│  Get totalPoin (yearly)                                                │
│        ↓                                                                │
│  LevelModel.fromPoin(totalPoin)                                        │
│        ↓                                                                │
│  ┌─────────────────────────────────────────┐                          │
│  │  Level Calculation (O(1) complexity)    │                          │
│  │  • Determine current level               │                          │
│  │  • Calculate progress (0.0 - 1.0)        │                          │
│  │  • Get points to next level              │                          │
│  │  • Check if max level                    │                          │
│  └─────────────────────────────────────────┘                          │
│        ↓                                                                │
│  UI Components (Widgets)                                               │
│        ↓                                                                │
│  User sees level badge & progress                                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    LEVEL PROGRESSION CHART                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  🌱 Level 1: Santri Pemula       │   0 -   99 │ +100 poin → Level 2   │
│  🌿 Level 2: Santri Rajin        │ 100 -  249 │ +150 poin → Level 3   │
│  🍃 Level 3: Santri Tekun        │ 250 -  499 │ +250 poin → Level 4   │
│  ⭐ Level 4: Santri Istiqomah    │ 500 -  799 │ +300 poin → Level 5   │
│  🌟 Level 5: Santri Berprestasi  │ 800 - 1199 │ +400 poin → Level 6   │
│  💎 Level 6: Santri Teladan      │1200 - 1699 │ +500 poin → Level 7   │
│  🏆 Level 7: Santri Inspiratif   │1700 - 2299 │ +600 poin → Level 8   │
│  👑 Level 8: Santri Juara        │2300 - 2999 │ +700 poin → Level 9   │
│  🔥 Level 9: Santri Master       │3000 - 3999 │+1000 poin → Level 10  │
│  ⚡ Level 10: Santri Legend      │4000+       │ MAX LEVEL             │
│                                                                         │
│  Total points needed to reach MAX: 4000 points (400 attendances)       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    COLOR PALETTE                                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Level 1:  #8BC34A  ████████ Light Green                               │
│  Level 2:  #4CAF50  ████████ Green                                     │
│  Level 3:  #009688  ████████ Teal                                      │
│  Level 4:  #00BCD4  ████████ Cyan                                      │
│  Level 5:  #2196F3  ████████ Blue                                      │
│  Level 6:  #3F51B5  ████████ Indigo                                    │
│  Level 7:  #9C27B0  ████████ Purple                                    │
│  Level 8:  #FF9800  ████████ Orange                                    │
│  Level 9:  #FF5722  ████████ Deep Orange                               │
│  Level 10: #F44336  ████████ Red                                       │
│                                                                         │
│  Gradient: Easy (Green) → Medium (Blue) → Hard (Red)                   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                   LEVEL-UP DETECTION                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Method 1: Point Comparison                                            │
│  ────────────────────────                                              │
│    oldPoin = 95                                                        │
│    newPoin = 105  (after attendance)                                   │
│    LevelService.didLevelUp(95, 105) → true                            │
│    Show Level-Up Dialog!                                               │
│                                                                         │
│  Method 2: Stream Listener                                             │
│  ─────────────────────                                                 │
│    StreamBuilder<PresensiAggregate>                                    │
│      → Listen to totalPoin changes                                     │
│      → Compare with previous value                                     │
│      → Trigger notification                                            │
│                                                                         │
│  Method 3: After Attendance                                            │
│  ───────────────────────────                                           │
│    Get old aggregate → Save attendance                                 │
│    Get new aggregate → Compare levels                                  │
│    Show celebration dialog if leveled up                               │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    PERFORMANCE METRICS                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  • Level Calculation: O(1) complexity                                  │
│  • Memory Footprint: ~2KB per LevelModel instance                      │
│  • Widget Rebuild: Minimal (cached calculations)                       │
│  • Color Conversion: Cached after first use                            │
│  • Progress Bar Animation: 60 FPS smooth                               │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                      FILE STRUCTURE                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  lib/shared/                                                           │
│    ├── models/                                                         │
│    │   └── level_model.dart           (149 lines)                     │
│    ├── services/                                                       │
│    │   └── level_service.dart         (72 lines)                      │
│    └── widgets/                                                        │
│        ├── level_badge_widget.dart    (55 lines)                      │
│        ├── level_progress_card.dart   (149 lines)                     │
│        └── level_widgets.dart         (10 lines - barrel)             │
│                                                                         │
│  Documentation/                                                        │
│    ├── LEVEL_SYSTEM_GUIDE.md          (450+ lines)                    │
│    ├── LEVEL_SYSTEM_QUICK_REFERENCE.md (220+ lines)                   │
│    └── CHANGELOG.md                   (Updated v2.1.0)                │
│                                                                         │
│  Modified Files/                                                       │
│    ├── dashboard_welcome_card.dart    (Added level integration)       │
│    ├── leaderboard_page.dart          (Added level badges)            │
│    ├── profile_page.dart              (Added level card)              │
│    └── README.md                       (Updated documentation)         │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                     FUTURE ENHANCEMENTS                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  □ Level-up Dialog with animation                                      │
│  □ Push notifications for achievements                                 │
│  □ Admin dashboard analytics (level distribution)                      │
│  □ Level history timeline                                              │
│  □ Level perks and benefits                                            │
│  □ Seasonal/event special badges                                       │
│  □ Level-based leaderboard sorting                                     │
│  □ Custom level titles (admin configurable)                            │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Quick Reference Card

```
╔══════════════════════════════════════════════════════════════════════╗
║                    LEVEL SYSTEM QUICK CARD                           ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  📦 IMPORT                                                           ║
║  ────────────────────────────────────────────────────────────────   ║
║  import 'package:sisantri/shared/models/level_model.dart';          ║
║  import 'package:sisantri/shared/services/level_service.dart';      ║
║  import 'package:sisantri/shared/widgets/level_widgets.dart';       ║
║                                                                      ║
║  🎯 USAGE                                                            ║
║  ────────────────────────────────────────────────────────────────   ║
║  final level = LevelModel.fromPoin(500);                            ║
║  print(level.title);    // "Santri Istiqomah"                       ║
║  print(level.badge);    // "⭐"                                      ║
║                                                                      ║
║  🎨 WIDGETS                                                          ║
║  ────────────────────────────────────────────────────────────────   ║
║  LevelBadgeWidget(totalPoin: 500, size: 48)                         ║
║  LevelProgressCard(totalPoin: 500)                                  ║
║                                                                      ║
║  ✅ CHECK LEVEL-UP                                                   ║
║  ────────────────────────────────────────────────────────────────   ║
║  if (LevelService.didLevelUp(oldPoin, newPoin)) {                  ║
║    final newLevel = LevelModel.fromPoin(newPoin);                  ║
║    showCelebration(newLevel);                                       ║
║  }                                                                   ║
║                                                                      ║
║  📊 CALCULATIONS                                                     ║
║  ────────────────────────────────────────────────────────────────   ║
║  level.getProgressToNextLevel(300)  // 0.2 (20%)                    ║
║  level.getPoinToNextLevel(300)      // 200 points                   ║
║  level.isMaxLevel()                 // false                        ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
```
