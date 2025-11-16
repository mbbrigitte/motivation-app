import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokensKey = 'tokens_collected';
  static const String _totalTokensKey = 'total_tokens_ever';
  static const String _pointsKey = 'points_total'; // NEW: separate points counter
  static const String _lastMilestoneKey = 'last_handled_milestone';

  // Knight animation keys
  static const String _animatedXKey = 'animated_x';
  static const String _animatedYKey = 'animated_y';
  static const String _animatedSizeKey = 'animated_size';

  // -----------------------------
  // 🪙 TOKENS (redeemable)
  // -----------------------------

  static Future<void> saveTokens(int tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tokensKey, tokens);
  }

  static Future<int> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_tokensKey) ?? 0;
  }

  static Future<void> saveTotalTokens(int total) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalTokensKey, total);
  }

  static Future<int> loadTotalTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalTokensKey) ?? 0;
  }

  // -----------------------------
  // ⭐ POINTS (lifetime, never decrease)
  // -----------------------------

  static Future<void> savePoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsKey, points);
  }

  static Future<int> loadPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 0;
  }

  static Future<void> addPoints(int pointsToAdd) async {
    final currentPoints = await loadPoints();
    await savePoints(currentPoints + pointsToAdd);
  }

  // -----------------------------
  // 🧩 MILESTONES
  // -----------------------------

  static Future<void> saveLastHandledMilestone(int milestone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastMilestoneKey, milestone);
  }

  static Future<int> loadLastHandledMilestone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastMilestoneKey) ?? 0;
  }

  // -----------------------------
  // 🧍‍♂️ KNIGHT POSITION + SIZE
  // -----------------------------

  static Future<void> saveAnimatedX(double? x) async {
    final prefs = await SharedPreferences.getInstance();
    if (x == null) {
      await prefs.remove(_animatedXKey);
    } else {
      await prefs.setDouble(_animatedXKey, x);
    }
  }

  static Future<double?> loadAnimatedX() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_animatedXKey);
  }

  static Future<void> saveAnimatedY(double? y) async {
    final prefs = await SharedPreferences.getInstance();
    if (y == null) {
      await prefs.remove(_animatedYKey);
    } else {
      await prefs.setDouble(_animatedYKey, y);
    }
  }

  static Future<double?> loadAnimatedY() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_animatedYKey);
  }

  static Future<void> saveAnimatedSize(double? size) async {
    final prefs = await SharedPreferences.getInstance();
    if (size == null) {
      await prefs.remove(_animatedSizeKey);
    } else {
      await prefs.setDouble(_animatedSizeKey, size);
    }
  }

  static Future<double?> loadAnimatedSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_animatedSizeKey);
  }

  // Clear knight position (used when tokens are redeemed)
  static Future<void> clearKnightPosition() async {
    await saveAnimatedX(null);
    await saveAnimatedY(null);
    await saveAnimatedSize(null);
  }

  // -----------------------------
  // 🧹 CLEAR ALL (for testing)
  // -----------------------------

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // -----------------------------
  // 🧭 DEBUG (optional helper)
  // -----------------------------

  static Future<void> debugPrintAll() async {
    final prefs = await SharedPreferences.getInstance();
    print('🔹 Tokens collected: ${prefs.getInt(_tokensKey) ?? 0}');
    print('🔹 Total tokens ever: ${prefs.getInt(_totalTokensKey) ?? 0}');
    print('🔹 Points (lifetime): ${prefs.getInt(_pointsKey) ?? 0}');
    print('🔹 Last handled milestone: ${prefs.getInt(_lastMilestoneKey) ?? 0}');
    print('🔹 Knight position: X=${prefs.getDouble(_animatedXKey)}, '
        'Y=${prefs.getDouble(_animatedYKey)}, '
        'Size=${prefs.getDouble(_animatedSizeKey)}');
  }
}