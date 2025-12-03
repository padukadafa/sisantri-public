import 'package:sisantri/shared/models/level_model.dart';

/// Service to handle level-related operations and level-up detection
class LevelService {
  /// Check if user leveled up based on old and new points
  static bool didLevelUp(int oldPoin, int newPoin) {
    final oldLevel = LevelModel.fromPoin(oldPoin);
    final newLevel = LevelModel.fromPoin(newPoin);
    return newLevel.level > oldLevel.level;
  }

  /// Get the new level after points increase
  static LevelModel? getNewLevel(int oldPoin, int newPoin) {
    if (!didLevelUp(oldPoin, newPoin)) return null;
    return LevelModel.fromPoin(newPoin);
  }

  /// Get level-up message
  static String getLevelUpMessage(LevelModel newLevel) {
    return 'Selamat! Anda naik ke ${newLevel.title}! ${newLevel.badge}';
  }

  /// Get level up description
  static String getLevelUpDescription(LevelModel newLevel) {
    switch (newLevel.level) {
      case 2:
        return 'Terus rajin hadir untuk naik level!';
      case 3:
        return 'Ketekunan Anda sangat luar biasa!';
      case 4:
        return 'Istiqomah adalah kunci kesuksesan!';
      case 5:
        return 'Prestasi Anda sangat membanggakan!';
      case 6:
        return 'Anda adalah teladan bagi santri lain!';
      case 7:
        return 'Kehadiran Anda menginspirasi banyak orang!';
      case 8:
        return 'Anda adalah juara sejati!';
      case 9:
        return 'Master level! Dedikasi Anda luar biasa!';
      case 10:
        return 'Legenda! Anda telah mencapai puncak!';
      default:
        return 'Selamat naik level!';
    }
  }

  /// Get all levels as list for display
  static List<LevelModel> getAllLevels() {
    return LevelModel.getAllLevels();
  }

  /// Get current level from points
  static LevelModel getCurrentLevel(int poin) {
    return LevelModel.fromPoin(poin);
  }

  /// Get progress percentage (0-100)
  static double getProgressPercentage(int poin) {
    final level = LevelModel.fromPoin(poin);
    return level.getProgressToNextLevel(poin) * 100;
  }

  /// Get formatted progress text (e.g., "250/500")
  static String getProgressText(int poin) {
    final level = LevelModel.fromPoin(poin);
    if (level.isMaxLevel()) return 'MAX';

    final currentProgress = poin - level.minPoin;
    final maxProgress = level.maxPoin - level.minPoin;
    return '$currentProgress/$maxProgress';
  }
}
