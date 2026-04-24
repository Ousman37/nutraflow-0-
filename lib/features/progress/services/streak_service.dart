import 'package:cloud_firestore/cloud_firestore.dart';
import '../../meal/services/meal_service.dart';
import './workout_service.dart';

class StreakData {
  final int streakCount;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  final List<DateTime> recentCompletedDays;

  const StreakData({
    this.streakCount = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.recentCompletedDays = const [],
  });

  // Which days of the current week (index 0=Mon … 6=Sun) are completed.
  List<bool> get weekDots {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return recentCompletedDays.any(
          (d) => d.year == day.year && d.month == day.month && d.day == day.day);
    });
  }

  int get completedDaysThisWeek => weekDots.where((b) => b).length;
}

class StreakService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _mealService = MealService();
  final _workoutService = WorkoutService();

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _db.collection('users').doc(userId);

  // Reads streak fields from the user document (1 Firestore read).
  Future<StreakData> loadStreak(String userId) async {
    final doc = await _userDoc(userId).get();
    if (!doc.exists || doc.data() == null) return const StreakData();
    return _fromMap(doc.data()!);
  }

  // Updates streak for today. At most 3 reads: user doc, today's meals, today's workouts.
  Future<StreakData> updateStreak(String userId) async {
    final now = DateTime.now();
    final todayNorm = DateTime(now.year, now.month, now.day);
    final yesterdayNorm = todayNorm.subtract(const Duration(days: 1));

    // Read 1: existing streak data.
    final doc = await _userDoc(userId).get();
    final existing = (doc.exists && doc.data() != null)
        ? _fromMap(doc.data()!)
        : const StreakData();

    // Already counted today — nothing to do.
    final last = existing.lastCompletedDate;
    if (last != null) {
      final lastNorm = DateTime(last.year, last.month, last.day);
      if (lastNorm == todayNorm) return existing;
    }

    // Reads 2 & 3 in parallel: today's meals and workouts.
    late final List mealsResult;
    late final List workoutsResult;
    await Future.wait([
      _mealService
          .getMealsForDate(userId: userId, date: now)
          .then((v) => mealsResult = v),
      _workoutService
          .getWorkoutsForDate(userId: userId, date: now)
          .then((v) => workoutsResult = v),
    ]);

    // Day is complete if ≥ 2 distinct meal types OR any workout logged.
    final uniqueMealTypes = mealsResult.map((m) => m.type).toSet().length;
    final isComplete = uniqueMealTypes >= 2 || workoutsResult.isNotEmpty;

    if (!isComplete) return existing;

    // Compute new streak.
    int newStreak;
    final lastNorm = last != null
        ? DateTime(last.year, last.month, last.day)
        : null;

    if (lastNorm == yesterdayNorm) {
      newStreak = existing.streakCount + 1;
    } else {
      newStreak = 1;
    }

    final newLongest =
        newStreak > existing.longestStreak ? newStreak : existing.longestStreak;

    // Keep up to 30 recent completed days (newest first).
    final recent = List<DateTime>.from(existing.recentCompletedDays);
    if (!recent.any((d) =>
        d.year == todayNorm.year &&
        d.month == todayNorm.month &&
        d.day == todayNorm.day)) {
      recent.insert(0, todayNorm);
      if (recent.length > 30) recent.removeLast();
    }

    final newData = StreakData(
      streakCount: newStreak,
      longestStreak: newLongest,
      lastCompletedDate: todayNorm,
      recentCompletedDays: recent,
    );

    // Merge so profile fields (displayName, targets, etc.) are not overwritten.
    await _userDoc(userId).set(
      {
        'streakCount': newStreak,
        'longestStreak': newLongest,
        'lastCompletedDate': Timestamp.fromDate(todayNorm),
        'recentCompletedDays':
            recent.map((d) => Timestamp.fromDate(d)).toList(),
      },
      SetOptions(merge: true),
    );

    return newData;
  }

  StreakData _fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final rawDays = map['recentCompletedDays'];
    final days = rawDays is List
        ? rawDays.map(parseDate).whereType<DateTime>().toList()
        : <DateTime>[];

    return StreakData(
      streakCount: (map['streakCount'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
      lastCompletedDate: parseDate(map['lastCompletedDate']),
      recentCompletedDays: days,
    );
  }
}
