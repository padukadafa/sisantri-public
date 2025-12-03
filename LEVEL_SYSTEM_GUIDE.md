# Level System Implementation Guide

## Overview

The level system is a gamification feature that provides visual progression feedback to users based on their total points (poin). It consists of 10 progressive levels from "Santri Pemula" to "Santri Legend", each with unique badges, colors, and point thresholds.

## Level Structure

### Level Tiers

```
Level 1:  Santri Pemula       (0-99 poin)      🌱 #8BC34A (Light Green)
Level 2:  Santri Rajin        (100-249 poin)   🌿 #4CAF50 (Green)
Level 3:  Santri Tekun        (250-499 poin)   🍃 #009688 (Teal)
Level 4:  Santri Istiqomah    (500-799 poin)   ⭐ #00BCD4 (Cyan)
Level 5:  Santri Berprestasi  (800-1199 poin)  🌟 #2196F3 (Blue)
Level 6:  Santri Teladan      (1200-1699 poin) 💎 #3F51B5 (Indigo)
Level 7:  Santri Inspiratif   (1700-2299 poin) 🏆 #9C27B0 (Purple)
Level 8:  Santri Juara        (2300-2999 poin) 👑 #FF9800 (Orange)
Level 9:  Santri Master       (3000-3999 poin) 🔥 #FF5722 (Deep Orange)
Level 10: Santri Legend       (4000+ poin)     ⚡ #F44336 (Red)
```

## Core Components

### 1. LevelModel (`lib/shared/models/level_model.dart`)

The data model representing a level.

**Properties:**

- `level`: int - Level number (1-10)
- `title`: String - Level name (e.g., "Santri Pemula")
- `minPoin`: int - Minimum points required
- `maxPoin`: int - Maximum points for this level
- `badge`: String - Emoji badge (e.g., "🌱")
- `color`: String - Hex color code (e.g., "#8BC34A")

**Static Methods:**

```dart
// Get level from total points
LevelModel level = LevelModel.fromPoin(250); // Returns Level 3

// Get all levels
List<LevelModel> allLevels = LevelModel.getAllLevels();
```

**Instance Methods:**

```dart
// Get progress to next level (0.0 to 1.0)
double progress = level.getProgressToNextLevel(300); // Returns 0.2

// Get points needed for next level
int needed = level.getPoinToNextLevel(300); // Returns 200

// Check if max level
bool isMax = level.isMaxLevel(); // Returns false

// Get next level info
LevelModel? next = level.getNextLevel(); // Returns Level 4
```

### 2. LevelService (`lib/shared/services/level_service.dart`)

Helper service for level operations.

**Methods:**

```dart
// Detect level up
bool leveledUp = LevelService.didLevelUp(oldPoin: 90, newPoin: 105);

// Get new level after points increase
LevelModel? newLevel = LevelService.getNewLevel(90, 105);

// Get level up message
String message = LevelService.getLevelUpMessage(newLevel);

// Get current level
LevelModel current = LevelService.getCurrentLevel(500);

// Get progress percentage
double percent = LevelService.getProgressPercentage(300); // Returns 20.0

// Get progress text
String progress = LevelService.getProgressText(300); // Returns "50/250"
```

### 3. LevelBadgeWidget (`lib/shared/widgets/level_badge_widget.dart`)

Compact circular badge showing level emoji and number.

**Usage:**

```dart
LevelBadgeWidget(
  totalPoin: 500,
  size: 48.0,           // Badge diameter
  showTitle: true,      // Show "Lv.4" below badge
)
```

**Use Cases:**

- Profile pictures (small badge overlay)
- Leaderboard entries
- User avatars
- Dashboard headers

### 4. LevelProgressCard (`lib/shared/widgets/level_progress_card.dart`)

Full card showing level info with progress bar.

**Usage:**

```dart
LevelProgressCard(
  totalPoin: 500,
)
```

**Features:**

- Shows level badge, title, and number
- Progress bar to next level
- Points needed to next level
- Next level preview
- "MAX" indicator for level 10

**Use Cases:**

- Profile page
- Dashboard detailed view
- Statistics pages

### 5. LevelUpDialog (`lib/shared/widgets/level_up_dialog.dart`)

Celebration dialog when user levels up.

**Usage:**

```dart
// Show dialog
await LevelUpDialog.show(context, newLevel);
```

**Features:**

- Animated gradient background
- Large badge display
- Level title and number
- Motivational message
- Continue button

## Integration Guide

### Dashboard Integration

**File:** `lib/features/santri/dashboard/presentation/widgets/dashboard_welcome_card.dart`

The welcome card now shows:

1. **Level badge** - Next to user name (top-right)
2. **Level title** - Below user greeting
3. **Progress bar** - Visual progress to next level
4. **Points needed** - "X poin lagi ke level berikutnya"
5. **Current points** - Badge showing total points

### Leaderboard Integration

**File:** `lib/features/santri/leaderboard/presentation/leaderboard_page.dart`

Changes made:

1. **Podium (Top 3):**
   - Level badge overlaid on avatar (bottom position)
2. **Leaderboard List:**
   - Level badge on profile picture (bottom-right)
   - Level title shown next to name (colored)
   - Format: "Santri Tekun • Santri Al-Awwabin"

### Profile Page Integration

**File:** `lib/features/santri/profile/presentation/pages/profile_page.dart`

Added `LevelProgressCard` between profile header and stats cards (santri only).

Shows:

- Current level badge and title
- Progress bar
- Points to next level
- Next level preview

## Detecting Level-Up Events

### Method 1: Point Comparison

```dart
// Before adding points
final oldPoin = aggregate.totalPoin;

// After adding points
final newPoin = aggregate.totalPoin + pointsEarned;

// Check level up
if (LevelService.didLevelUp(oldPoin, newPoin)) {
  final newLevel = LevelModel.fromPoin(newPoin);
  await LevelUpDialog.show(context, newLevel);
}
```

### Method 2: Stream Listener

```dart
// Listen to aggregate changes
final aggregateStream = PresensiAggregateService.streamAggregate(
  userId: userId,
  periode: 'yearly',
  date: DateTime.now(),
);

int? previousPoin;

aggregateStream.listen((aggregate) {
  if (previousPoin != null && aggregate != null) {
    if (LevelService.didLevelUp(previousPoin!, aggregate.totalPoin)) {
      final newLevel = LevelModel.fromPoin(aggregate.totalPoin);
      // Show notification or dialog
      LevelUpDialog.show(context, newLevel);
    }
  }
  previousPoin = aggregate?.totalPoin;
});
```

### Method 3: After Attendance Submission

```dart
// In manual_attendance_page.dart or similar
Future<void> _submitAttendance() async {
  // Get current aggregate
  final oldAggregate = await PresensiAggregateService.getAggregate(
    userId: santri.id,
    periode: 'yearly',
    date: DateTime.now(),
  );
  final oldPoin = oldAggregate?.totalPoin ?? 0;

  // Submit attendance (which updates aggregate)
  await _saveAttendance();

  // Get new aggregate
  final newAggregate = await PresensiAggregateService.getAggregate(
    userId: santri.id,
    periode: 'yearly',
    date: DateTime.now(),
  );
  final newPoin = newAggregate?.totalPoin ?? 0;

  // Check level up
  if (LevelService.didLevelUp(oldPoin, newPoin)) {
    final newLevel = LevelModel.fromPoin(newPoin);
    await LevelUpDialog.show(context, newLevel);
  }
}
```

## Best Practices

### 1. Always Use `fromPoin()` Method

```dart
// ✅ GOOD
final level = LevelModel.fromPoin(totalPoin);

// ❌ BAD - Don't hardcode levels
final level = LevelModel(level: 5, ...); // Wrong!
```

### 2. Use Aggregate Yearly for Total Points

```dart
// ✅ GOOD
final aggregate = await PresensiAggregateService.getAggregate(
  userId: userId,
  periode: 'yearly',
  date: DateTime.now(),
);
final totalPoin = aggregate?.totalPoin ?? 0;
final level = LevelModel.fromPoin(totalPoin);
```

### 3. Show Level-Up Dialog at Appropriate Times

```dart
// ✅ GOOD - After attendance submission
// ✅ GOOD - After aggregate update
// ❌ BAD - On page load
// ❌ BAD - Multiple times for same level
```

### 4. Handle Max Level Gracefully

```dart
final level = LevelModel.fromPoin(totalPoin);

if (level.isMaxLevel()) {
  // Don't show "X points to next level"
  Text('Level Maksimal! 🎉');
} else {
  // Show progress
  Text('${level.getPoinToNextLevel(totalPoin)} poin lagi');
}
```

## UI Design Guidelines

### Colors

- Always use the level's color from `level.color`
- Convert hex to Flutter Color: `Color(int.parse(level.color.replaceFirst('#', '0xFF')))`
- Use `.withOpacity()` for backgrounds

### Badges

- Emoji badges are native Unicode, work on all platforms
- Size recommendation: 48-60px for main display, 18-24px for compact
- Always centered in circular container

### Progress Bars

```dart
LinearProgressIndicator(
  value: level.getProgressToNextLevel(totalPoin),
  backgroundColor: color.withOpacity(0.2),
  valueColor: AlwaysStoppedAnimation<Color>(color),
  minHeight: 6,
)
```

### Text Hierarchy

1. **Level Title** - Large, bold, colored (e.g., "Santri Tekun")
2. **Level Number** - Medium, colored (e.g., "Level 3")
3. **Progress Text** - Small, gray (e.g., "50 poin lagi")

## Testing Scenarios

### Test Case 1: Level Progression

```
User at Level 1 (0 poin)
+ 100 poin → Level 2 ✅ (Level up dialog shown)
+ 150 poin → Level 3 ✅ (Level up dialog shown)
+ 250 poin → Level 4 ✅ (Level up dialog shown)
```

### Test Case 2: Multiple Levels

```
User at Level 1 (0 poin)
+ 500 poin → Level 4 ✅ (Should show Level 4 dialog, not 2 & 3)
```

### Test Case 3: Max Level

```
User at Level 10 (5000 poin)
+ 100 poin → No level up ✅ (Already at max)
isMaxLevel() → true ✅
```

### Test Case 4: Progress Calculation

```
User at Level 3 (300 poin)
- minPoin: 250
- maxPoin: 499
- Progress: (300-250) / (499-250) = 50/249 = 20% ✅
```

## Performance Considerations

### 1. Caching

```dart
// ✅ Cache level calculation in FutureProvider
final userLevelProvider = FutureProvider.family<LevelModel, String>((ref, userId) async {
  final aggregate = await PresensiAggregateService.getAggregate(
    userId: userId,
    periode: 'yearly',
    date: DateTime.now(),
  );
  return LevelModel.fromPoin(aggregate?.totalPoin ?? 0);
});
```

### 2. Avoid Recalculation

```dart
// ✅ Calculate once, reuse
final level = LevelModel.fromPoin(totalPoin);
final color = Color(int.parse(level.color.replaceFirst('#', '0xFF')));
final progress = level.getProgressToNextLevel(totalPoin);

// ❌ Don't recalculate in build
Widget build(BuildContext context) {
  return Text(LevelModel.fromPoin(totalPoin).title); // Recalculates every build!
}
```

### 3. Use StreamProvider for Real-Time

```dart
final userLevelStreamProvider = StreamProvider.family<LevelModel, String>((ref, userId) {
  return PresensiAggregateService.streamAggregate(
    userId: userId,
    periode: 'yearly',
    date: DateTime.now(),
  ).map((agg) => LevelModel.fromPoin(agg?.totalPoin ?? 0));
});
```

## Troubleshooting

### Issue: Level not updating after points increase

**Solution:** Ensure aggregate is recalculated. Use `ref.invalidate()` or listen to stream.

### Issue: Progress bar stuck at 0%

**Solution:** Check if `getProgressToNextLevel()` is being called with correct `currentPoin`.

### Issue: Level up dialog shows multiple times

**Solution:** Add flag to track if dialog already shown for this level.

### Issue: Color not displaying correctly

**Solution:** Ensure hex color conversion includes '0xFF' prefix: `Color(int.parse(color.replaceFirst('#', '0xFF')))`

## Future Enhancements

### Possible Additions:

1. **Level Achievements** - Unlock badges for reaching certain levels
2. **Level Perks** - Benefits for higher levels (priority scheduling, etc.)
3. **Level History** - Track when user reached each level
4. **Level Leaderboard** - Sort by level instead of points
5. **Custom Level Titles** - Allow admins to customize level names
6. **Seasonal Levels** - Special badges for events
7. **Level Decay** - Reduce level if inactive (optional)
8. **Level Boost** - Temporary XP multipliers

## Summary

The level system enhances user engagement by:

- ✅ Providing clear progression milestones
- ✅ Visual feedback with badges and colors
- ✅ Motivation through level titles and achievements
- ✅ Social comparison in leaderboards
- ✅ Psychological rewards for consistent attendance

**Key Files:**

- Model: `lib/shared/models/level_model.dart`
- Service: `lib/shared/services/level_service.dart`
- Widgets: `lib/shared/widgets/level_*.dart`
- Integrations: Dashboard, Leaderboard, Profile pages
