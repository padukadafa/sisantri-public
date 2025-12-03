# Changelog

All notable changes to the SiSantri project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2024-12-03

### Added - Level System Implementation 🎮

#### Core Components

- **LevelModel** (`lib/shared/models/level_model.dart`)

  - 10 progressive levels from "Santri Pemula" (0-99 points) to "Santri Legend" (4000+ points)
  - Each level has unique emoji badge: 🌱🌿🍃⭐🌟💎🏆👑🔥⚡
  - Color-coded from Light Green to Red
  - Methods: `fromPoin()`, `getProgressToNextLevel()`, `getPoinToNextLevel()`, `isMaxLevel()`, `getNextLevel()`
  - JSON serialization support

- **LevelService** (`lib/shared/services/level_service.dart`)

  - Helper methods for level operations
  - Level-up detection: `didLevelUp()`, `getNewLevel()`
  - Progress formatting and calculations
  - Motivational messages for each level achievement

- **LevelBadgeWidget** (`lib/shared/widgets/level_badge_widget.dart`)

  - Compact circular badge component
  - Customizable size (default 48px)
  - Optional title display ("Lv.X")
  - Gradient background with shadow effects

- **LevelProgressCard** (`lib/shared/widgets/level_progress_card.dart`)

  - Full card showing complete level information
  - Animated progress bar to next level
  - Points needed display
  - Next level preview
  - "MAX LEVEL" indicator for level 10

- **Level Widgets Barrel** (`lib/shared/widgets/level_widgets.dart`)
  - Single import for all level widgets

#### UI Integration

- **Dashboard Welcome Card** (`lib/features/santri/dashboard/presentation/widgets/dashboard_welcome_card.dart`)

  - Added level badge (50px) next to user name
  - Level title and current level display
  - Progress bar with color coding
  - Points needed to next level
  - Replaced old single point badge with comprehensive level info

- **Leaderboard** (`lib/features/santri/leaderboard/presentation/leaderboard_page.dart`)

  - Level badges on podium avatars (22px, bottom position)
  - Level badges on list item avatars (18px, bottom-right position)
  - Level title displayed next to username with color coding
  - Format: "Level Title • Institution"

- **Profile Page** (`lib/features/santri/profile/presentation/pages/profile_page.dart`)
  - Added `LevelProgressCard` between header and stats
  - Shows current level with full details
  - Progress bar to next level
  - Points needed with next level preview
  - Only shown for santri role

#### Documentation

- **LEVEL_SYSTEM_GUIDE.md**

  - Complete API reference for all components
  - Integration guide with code examples
  - Level-up detection methods (3 approaches)
  - UI design guidelines and best practices
  - Performance optimization tips
  - Testing scenarios and troubleshooting
  - Future enhancement ideas

- **LEVEL_SYSTEM_QUICK_REFERENCE.md**

  - Quick usage examples
  - Level structure table
  - Widget examples for common use cases
  - Common patterns (FutureBuilder, StreamBuilder, Riverpod)
  - Performance tips and troubleshooting

- **README.md Updates**
  - Added Level System section in features
  - Updated Profil & Dashboard section
  - Added Level System table in Gamifikasi section
  - Updated feature descriptions

### Changed

- Removed unused imports from dashboard welcome card and profile page
- Optimized dashboard welcome card to use single FutureBuilder for level calculations

### Technical Details

**Level Progression:**

- Level 1→2: 100 points (10 attendances)
- Level 2→3: 150 points (15 attendances)
- Level 3→4: 250 points (25 attendances)
- Level 4→5: 300 points (30 attendances)
- Level 5→6: 400 points (40 attendances)
- Level 6→7: 500 points (50 attendances)
- Level 7→8: 600 points (60 attendances)
- Level 8→9: 700 points (70 attendances)
- Level 9→10: 1000 points (100 attendances)

**Design System:**

- Consistent color palette from green to red
- Emoji badges for universal compatibility
- Responsive sizing (18px to 60px range)
- Material Design 3 compliance

**Performance:**

- Efficient level calculation with O(1) complexity
- Cached color conversions
- Minimal widget rebuilds
- Optimized FutureBuilder usage

## [2.0.0] - 2024-11-30

### Added - Previous Updates

#### Manual Attendance Optimizations

- Loading dialog during batch attendance processing
- Disabled dropdown when no activity selected
- Fixed dropdown overflow (reduced width to 110px)

#### IoT Backend Aggregate Integration

- `getPeriodeKey()` helper function
- `getAllPeriodeKeys()` helper function
- `updateAggregates()` for all 5 periods (daily, weekly, monthly, semester, yearly)
- Integrated aggregate updates in attendance creation flow

#### Announcement Features

- Delete functionality with popup menu
- Confirmation dialog before deletion
- Three-dot menu icon in announcement cards

#### K6 Load Testing

- Fixed smoke test for scan endpoint
- Load test configuration for 300 concurrent users
- Improved thresholds (p95<3s, p99<5s, error rate<30%)
- Duration: ~10.5 minutes with ramp-up and cool-down

#### Documentation

- **GAMIFIKASI_TEST_CASES.md** - 30 comprehensive test cases
- Test coverage for all gamification features
- Includes severity levels, platforms, and detailed steps

## Future Roadmap

### Planned Features

#### Level System Enhancements

- [ ] Level-up dialog with animation
- [ ] Push notifications for level achievements
- [ ] Admin dashboard for level distribution analytics
- [ ] Level history tracking
- [ ] Level perks and benefits
- [ ] Seasonal/event-based special badges
- [ ] Level leaderboard (sort by level instead of points)

#### General Improvements

- [ ] Web dashboard implementation
- [ ] Advanced analytics and reporting
- [ ] Bulk operations for admin
- [ ] Enhanced notification system
- [ ] Multi-language support
- [ ] Dark mode theme

---

**Legend:**

- `Added` - New features
- `Changed` - Changes in existing functionality
- `Deprecated` - Soon-to-be removed features
- `Removed` - Removed features
- `Fixed` - Bug fixes
- `Security` - Security improvements

**Version Format:** MAJOR.MINOR.PATCH

- MAJOR: Incompatible API changes
- MINOR: New functionality (backwards-compatible)
- PATCH: Bug fixes (backwards-compatible)
