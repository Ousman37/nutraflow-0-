import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/meal_model.dart';
import '../models/nutrition_analysis.dart';

class MealService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // Scoped to the authenticated user — no top-level meals collection.
  CollectionReference<Map<String, dynamic>> _userMeals(String userId) =>
      _db.collection('users').doc(userId).collection('meals');

  Future<String?> uploadMealImage(String userId, File imageFile) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref('meal_images/$userId/$fileName');
    final task = await ref.putFile(imageFile);
    return await task.ref.getDownloadURL();
  }

  Future<MealModel> saveMeal({
    required String userId,
    required String name,
    required MealType type,
    required NutritionAnalysis nutrition,
    String? imageUrl,
    String? description,
  }) async {
    final id = _uuid.v4();
    final meal = MealModel(
      id: id,
      userId: userId,
      name: name,
      type: type,
      imageUrl: imageUrl,
      description: description,
      nutrition: nutrition,
      createdAt: DateTime.now(),
    );
    await _userMeals(userId).doc(id).set(meal.toMap());
    return meal;
  }

  Future<List<MealModel>> getMealsForDate({
    required String userId,
    required DateTime date,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final snapshot = await _userMeals(userId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt')
        .get();

    return snapshot.docs
        .map((doc) => MealModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<MealModel>> getMealsForWeek({
    required String userId,
    required DateTime weekStart,
  }) async {
    final end = weekStart.add(const Duration(days: 7));

    final snapshot = await _userMeals(userId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart),
            isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt')
        .get();

    return snapshot.docs
        .map((doc) => MealModel.fromMap(doc.data()))
        .toList();
  }

  /// Fetches the most recent meals for a user, sorted newest-first.
  /// Used by the Journal screen. [limitDays] caps how far back we look.
  Future<List<MealModel>> getRecentMeals({
    required String userId,
    int limitDays = 90,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: limitDays));

    final snapshot = await _userMeals(userId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MealModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> deleteMeal({
    required String userId,
    required String mealId,
  }) async {
    await _userMeals(userId).doc(mealId).delete();
  }

  Stream<List<MealModel>> watchTodaysMeals(String userId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return _userMeals(userId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => MealModel.fromMap(doc.data())).toList());
  }
}
