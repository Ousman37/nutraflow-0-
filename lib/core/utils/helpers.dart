import 'package:intl/intl.dart';

class Helpers {
  static String formatCalories(double cal) => '${cal.round()}';

  static String formatGrams(double g) => '${g.round()}g';

  static String formatDate(DateTime dt) => DateFormat('EEEE, MMM d').format(dt);

  static String formatShortDate(DateTime dt) => DateFormat('MMM d').format(dt);

  static String formatTime(DateTime dt) => DateFormat('h:mm a').format(dt);

  static String greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String scoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Work';
  }

  static String scoreFeedback(int score) {
    if (score >= 80) return 'Great nutrition balance today!';
    if (score >= 60) return 'You\'re on the right track.';
    if (score >= 40) return 'Room for improvement.';
    return 'Focus on balanced nutrition.';
  }

  static String mealTypeEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '☀️';
      case 'dinner':
        return '🌙';
      case 'snack':
        return '🍎';
      default:
        return '🍽️';
    }
  }

  static String dayShort(DateTime dt) => DateFormat('EEE').format(dt);
}
