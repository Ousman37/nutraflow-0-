import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_model.dart';

class WorkoutService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _userWorkouts(String userId) =>
      _db.collection('users').doc(userId).collection('workouts');

  Future<WorkoutModel> saveWorkout({
    required String userId,
    required WorkoutType type,
    required int durationMinutes,
    double? caloriesBurned,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final workout = WorkoutModel(
      id: id,
      userId: userId,
      type: type,
      durationMinutes: durationMinutes,
      caloriesBurned: caloriesBurned,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _userWorkouts(userId).doc(id).set(workout.toMap());
    return workout;
  }

  Future<List<WorkoutModel>> getWorkoutsForDate({
    required String userId,
    required DateTime date,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final snapshot = await _userWorkouts(userId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt')
        .get();

    return snapshot.docs
        .map((doc) => WorkoutModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<WorkoutModel>> getWorkoutsForWeek({
    required String userId,
    required DateTime weekStart,
  }) async {
    final end = weekStart.add(const Duration(days: 7));

    final snapshot = await _userWorkouts(userId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart),
            isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => WorkoutModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> deleteWorkout({
    required String userId,
    required String workoutId,
  }) async {
    await _userWorkouts(userId).doc(workoutId).delete();
  }
}
