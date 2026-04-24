import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'nutrition_analysis.dart';

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeExt on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast:
        return '🌅';
      case MealType.lunch:
        return '☀️';
      case MealType.dinner:
        return '🌙';
      case MealType.snack:
        return '🍎';
    }
  }

  PhosphorIconData get icon {
    switch (this) {
      case MealType.breakfast:
        return PhosphorIcons.sunHorizon();
      case MealType.lunch:
        return PhosphorIcons.sun();
      case MealType.dinner:
        return PhosphorIcons.moon();
      case MealType.snack:
        return PhosphorIcons.appleLogo();
    }
  }

  String get key => name;

  static MealType fromKey(String key) =>
      MealType.values.firstWhere((e) => e.name == key,
          orElse: () => MealType.breakfast);
}

class MealModel {
  final String id;
  final String userId;
  final String name;
  final MealType type;
  final String? imageUrl;
  final String? description;
  final NutritionAnalysis nutrition;
  final DateTime createdAt;

  const MealModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.imageUrl,
    this.description,
    required this.nutrition,
    required this.createdAt,
  });

  // Flat top-level fields so Firestore queries can filter/sort any macro directly.
  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'mealType': type.key,
        'imageUrl': imageUrl,
        'description': description,
        // ── flat nutrition fields ──────────────────────────────────────────
        'calories': nutrition.calories,
        'protein': nutrition.proteinG,
        'carbs': nutrition.carbsG,
        'fat': nutrition.fatG,
        'fiber': nutrition.fiberG,
        'nutritionScore': nutrition.score,
        'aiFeedback': nutrition.feedback,
        'suggestions': nutrition.suggestions,
        'colorGroups': nutrition.colorGroups.map((e) => e.toMap()).toList(),
        // ─────────────────────────────────────────────────────────────────
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(createdAt),
      };

  factory MealModel.fromMap(Map<String, dynamic> map) {
    // Support both the new flat layout and the old nested 'nutrition' map so
    // any documents written before this migration still parse correctly.
    final NutritionAnalysis nutrition;
    if (map['nutrition'] is Map) {
      nutrition = NutritionAnalysis.fromMap(
          Map<String, dynamic>.from(map['nutrition'] as Map));
    } else {
      nutrition = NutritionAnalysis(
        calories: (map['calories'] as num? ?? 0).toDouble(),
        proteinG: (map['protein'] as num? ?? 0).toDouble(),
        carbsG: (map['carbs'] as num? ?? 0).toDouble(),
        fatG: (map['fat'] as num? ?? 0).toDouble(),
        fiberG: (map['fiber'] as num? ?? 0).toDouble(),
        score: (map['nutritionScore'] as num? ?? 0).toInt(),
        feedback: map['aiFeedback'] as String? ?? '',
        suggestions: List<String>.from(map['suggestions'] ?? []),
        colorGroups: (map['colorGroups'] as List<dynamic>? ?? [])
            .map((e) => ColorGroup.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    }

    // Accept 'mealType' (new) or 'type' (old) so both schema versions work.
    final typeKey =
        (map['mealType'] ?? map['type'] ?? 'breakfast') as String;

    return MealModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      type: MealTypeExt.fromKey(typeKey),
      imageUrl: map['imageUrl'] as String?,
      description: map['description'] as String?,
      nutrition: nutrition,
      createdAt: _parseDate(map['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
