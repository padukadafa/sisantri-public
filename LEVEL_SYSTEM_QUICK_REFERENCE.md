# Level System - Quick Reference

## 🎯 Quick Usage

### Import

```dart
import 'package:sisantri/shared/models/level_model.dart';
import 'package:sisantri/shared/services/level_service.dart';
import 'package:sisantri/shared/widgets/level_widgets.dart';
```

### Get Level from Points

```dart
final level = LevelModel.fromPoin(totalPoin);
print(level.title);  // "Santri Tekun"
print(level.badge);  // "🍃"
print(level.level);  // 3
```

### Show Level Badge

```dart
LevelBadgeWidget(
  totalPoin: 500,
  size: 48,
  showTitle: true,
)
```

### Show Level Progress Card

```dart
LevelProgressCard(totalPoin: 500)
```

### Check Level Up

```dart
if (LevelService.didLevelUp(oldPoin, newPoin)) {
  final newLevel = LevelModel.fromPoin(newPoin);
  print('Level Up! ${newLevel.title}');
}
```

## 📊 Level Structure

| Level | Title              | Points    | Badge | Color       |
| ----- | ------------------ | --------- | ----- | ----------- |
| 1     | Santri Pemula      | 0-99      | 🌱    | Light Green |
| 2     | Santri Rajin       | 100-249   | 🌿    | Green       |
| 3     | Santri Tekun       | 250-499   | 🍃    | Teal        |
| 4     | Santri Istiqomah   | 500-799   | ⭐    | Cyan        |
| 5     | Santri Berprestasi | 800-1199  | 🌟    | Blue        |
| 6     | Santri Teladan     | 1200-1699 | 💎    | Indigo      |
| 7     | Santri Inspiratif  | 1700-2299 | 🏆    | Purple      |
| 8     | Santri Juara       | 2300-2999 | 👑    | Orange      |
| 9     | Santri Master      | 3000-3999 | 🔥    | Deep Orange |
| 10    | Santri Legend      | 4000+     | ⚡    | Red         |

## 🎨 Widget Examples

### Compact Badge (Leaderboard)

```dart
Stack(
  children: [
    CircleAvatar(radius: 20),
    Positioned(
      bottom: -4,
      right: -4,
      child: LevelBadgeWidget(
        totalPoin: poin,
        size: 18,
        showTitle: false,
      ),
    ),
  ],
)
```

### Dashboard Header

```dart
Row(
  children: [
    Text(user.nama),
    Spacer(),
    LevelBadgeWidget(
      totalPoin: poin,
      size: 50,
      showTitle: true,
    ),
  ],
)
```

### Profile Card

```dart
LevelProgressCard(totalPoin: totalPoin)
```

## 🔧 Common Operations

### Get Progress Percentage

```dart
final level = LevelModel.fromPoin(300);
final progress = level.getProgressToNextLevel(300);
print('${(progress * 100).toInt()}%');  // "20%"
```

### Get Points to Next Level

```dart
final level = LevelModel.fromPoin(300);
final needed = level.getPoinToNextLevel(300);
print('$needed poin lagi');  // "200 poin lagi"
```

### Check Max Level

```dart
final level = LevelModel.fromPoin(5000);
if (level.isMaxLevel()) {
  print('Sudah level maksimal!');
}
```

### Get All Levels (for display)

```dart
final allLevels = LevelModel.getAllLevels();
for (var level in allLevels) {
  print('${level.badge} ${level.title}');
}
```

## 🎯 Integration Points

### Dashboard Welcome Card

✅ Level badge next to user name  
✅ Progress bar with percentage  
✅ Points needed to next level

### Leaderboard

✅ Level badges on avatars (podium & list)  
✅ Level title next to names

### Profile Page

✅ Full level progress card  
✅ Next level preview

## 📝 Common Patterns

### FutureBuilder Pattern

```dart
FutureBuilder<int>(
  future: PresensiAggregateService.getAggregate(
    userId: userId,
    periode: 'yearly',
    date: DateTime.now(),
  ).then((agg) => agg?.totalPoin ?? 0),
  builder: (context, snapshot) {
    final poin = snapshot.data ?? 0;
    return LevelBadgeWidget(totalPoin: poin);
  },
)
```

### StreamBuilder Pattern

```dart
StreamBuilder<PresensiAggregate?>(
  stream: PresensiAggregateService.streamAggregate(
    userId: userId,
    periode: 'yearly',
    date: DateTime.now(),
  ),
  builder: (context, snapshot) {
    final poin = snapshot.data?.totalPoin ?? 0;
    return LevelProgressCard(totalPoin: poin);
  },
)
```

### Riverpod Pattern

```dart
final userLevelProvider = Provider.family<LevelModel, int>((ref, poin) {
  return LevelModel.fromPoin(poin);
});

// Usage:
Consumer(
  builder: (context, ref, child) {
    final level = ref.watch(userLevelProvider(totalPoin));
    return Text(level.title);
  },
)
```

## 🚀 Performance Tips

1. **Cache level calculations** - Don't recalculate in every build
2. **Use const widgets** - Where possible for static content
3. **Lazy load** - Only calculate when needed
4. **Memoize** - Store level in provider/state

## 🐛 Troubleshooting

| Issue                 | Solution                                                                   |
| --------------------- | -------------------------------------------------------------------------- |
| Level not updating    | Invalidate provider or refresh FutureBuilder                               |
| Progress stuck at 0%  | Check if correct poin value passed                                         |
| Color not showing     | Ensure hex conversion: `Color(int.parse(color.replaceFirst('#', '0xFF')))` |
| Badge too small/large | Adjust `size` parameter (recommended: 18-60px)                             |

## 📚 Full Documentation

See `LEVEL_SYSTEM_GUIDE.md` for complete documentation.
