import 'package:shared_preferences/shared_preferences.dart';

class StreakData {
  final int count;
  final bool isActive;

  StreakData({required this.count, required this.isActive});
}

class StreakSystem {
  static const String _keyStreakCount = 'streak_count';
  static const String _keyLastActivity = 'streak_last_activity';
  static const String _keyLastStreakDate = 'streak_last_date';

  static String _formatDateKey(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  // Seri durumunu kontrol eder (Uygulama açılışında çağrılır)
  static Future<StreakData> checkStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final int count = prefs.getInt(_keyStreakCount) ?? 0;
    final String? lastActivityStr = prefs.getString(_keyLastActivity);

    if (lastActivityStr == null) {
      return StreakData(count: 0, isActive: false);
    }

    final DateTime lastActivity = DateTime.parse(lastActivityStr);
    final difference = DateTime.now().difference(lastActivity);

    // 48 saatten fazla süre geçtiyse seri söner ve sıfırlanır
    if (difference.inHours >= 48) {
      await prefs.setInt(_keyStreakCount, 0);
      return StreakData(count: 0, isActive: false);
    }

    return StreakData(count: count, isActive: count > 0);
  }

  // Kullanıcı herhangi bir geliştirme/görev yaptığında çağrılır
  static Future<StreakData> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = _formatDateKey(now);

    int currentCount = prefs.getInt(_keyStreakCount) ?? 0;
    final String? lastActivityStr = prefs.getString(_keyLastActivity);
    final String? lastStreakDate = prefs.getString(_keyLastStreakDate);

    if (lastActivityStr != null) {
      final lastActivity = DateTime.parse(lastActivityStr);
      if (now.difference(lastActivity).inHours >= 48) {
        currentCount = 0; // 48 saat dolduğu için sıfırdan başlar
      }
    }

    // Bugün ilk kez aktivite yapılıyorsa seri 1 artar
    if (lastStreakDate != todayKey) {
      currentCount += 1;
      await prefs.setString(_keyLastStreakDate, todayKey);
    }

    await prefs.setInt(_keyStreakCount, currentCount);
    await prefs.setString(_keyLastActivity, now.toIso8601String());

    return StreakData(count: currentCount, isActive: true);
  }
}