class LevelModel {
  final int level;
  final String title;
  final int minPoin;
  final int maxPoin;
  final String badge;
  final String color;

  LevelModel({
    required this.level,
    required this.title,
    required this.minPoin,
    required this.maxPoin,
    required this.badge,
    required this.color,
  });

  // Calculate level from total points
  static LevelModel fromPoin(int totalPoin) {
    final levels = getAllLevels();
    return levels.firstWhere(
      (level) => totalPoin >= level.minPoin && totalPoin <= level.maxPoin,
      orElse: () => levels.last,
    );
  }

  // Get progress to next level (0.0 to 1.0)
  double getProgressToNextLevel(int currentPoin) {
    if (currentPoin >= maxPoin) return 1.0;
    final range = maxPoin - minPoin;
    final progress = currentPoin - minPoin;
    return progress / range;
  }

  // Get points needed for next level
  int getPoinToNextLevel(int currentPoin) {
    if (currentPoin >= maxPoin) return 0;
    return maxPoin - currentPoin + 1;
  }

  // Check if at max level
  bool isMaxLevel() {
    return level == 10;
  }

  // Get next level
  LevelModel? getNextLevel() {
    if (isMaxLevel()) return null;
    return getAllLevels().firstWhere((l) => l.level == level + 1);
  }

  // Define all levels
  static List<LevelModel> getAllLevels() {
    return [
      LevelModel(
        level: 1,
        title: 'Santri Pemula',
        minPoin: 0,
        maxPoin: 99,
        badge: '🌱',
        color: '#8BC34A', // Light Green
      ),
      LevelModel(
        level: 2,
        title: 'Santri Rajin',
        minPoin: 100,
        maxPoin: 249,
        badge: '🌿',
        color: '#4CAF50', // Green
      ),
      LevelModel(
        level: 3,
        title: 'Santri Tekun',
        minPoin: 250,
        maxPoin: 499,
        badge: '🍃',
        color: '#009688', // Teal
      ),
      LevelModel(
        level: 4,
        title: 'Santri Istiqomah',
        minPoin: 500,
        maxPoin: 799,
        badge: '⭐',
        color: '#00BCD4', // Cyan
      ),
      LevelModel(
        level: 5,
        title: 'Santri Berprestasi',
        minPoin: 800,
        maxPoin: 1199,
        badge: '🌟',
        color: '#2196F3', // Blue
      ),
      LevelModel(
        level: 6,
        title: 'Santri Teladan',
        minPoin: 1200,
        maxPoin: 1699,
        badge: '💎',
        color: '#3F51B5', // Indigo
      ),
      LevelModel(
        level: 7,
        title: 'Santri Inspiratif',
        minPoin: 1700,
        maxPoin: 2299,
        badge: '🏆',
        color: '#9C27B0', // Purple
      ),
      LevelModel(
        level: 8,
        title: 'Santri Juara',
        minPoin: 2300,
        maxPoin: 2999,
        badge: '👑',
        color: '#FF9800', // Orange
      ),
      LevelModel(
        level: 9,
        title: 'Santri Master',
        minPoin: 3000,
        maxPoin: 3999,
        badge: '🔥',
        color: '#FF5722', // Deep Orange
      ),
      LevelModel(
        level: 10,
        title: 'Santri Legend',
        minPoin: 4000,
        maxPoin: 999999,
        badge: '⚡',
        color: '#F44336', // Red
      ),
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'title': title,
      'minPoin': minPoin,
      'maxPoin': maxPoin,
      'badge': badge,
      'color': color,
    };
  }

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      level: json['level'] ?? 1,
      title: json['title'] ?? '',
      minPoin: json['minPoin'] ?? 0,
      maxPoin: json['maxPoin'] ?? 99,
      badge: json['badge'] ?? '🌱',
      color: json['color'] ?? '#8BC34A',
    );
  }
}
