class NutritionAnalysis {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final int score;
  final String feedback;
  final List<String> suggestions;
  final List<ColorGroup> colorGroups;

  const NutritionAnalysis({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.score,
    required this.feedback,
    required this.suggestions,
    required this.colorGroups,
  });

  Map<String, dynamic> toMap() => {
        'calories': calories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'fiberG': fiberG,
        'score': score,
        'feedback': feedback,
        'suggestions': suggestions,
        'colorGroups': colorGroups.map((e) => e.toMap()).toList(),
      };

  factory NutritionAnalysis.fromMap(Map<String, dynamic> map) {
    return NutritionAnalysis(
      calories: (map['calories'] as num).toDouble(),
      proteinG: (map['proteinG'] as num).toDouble(),
      carbsG: (map['carbsG'] as num).toDouble(),
      fatG: (map['fatG'] as num).toDouble(),
      fiberG: (map['fiberG'] as num? ?? 0).toDouble(),
      score: (map['score'] as num).toInt(),
      feedback: map['feedback'] as String,
      suggestions: List<String>.from(map['suggestions'] ?? []),
      colorGroups: (map['colorGroups'] as List<dynamic>? ?? [])
          .map((e) => ColorGroup.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  double get totalMacroCalories =>
      (proteinG * 4) + (carbsG * 4) + (fatG * 9);

  double get proteinPercent =>
      totalMacroCalories > 0 ? (proteinG * 4) / totalMacroCalories : 0;
  double get carbsPercent =>
      totalMacroCalories > 0 ? (carbsG * 4) / totalMacroCalories : 0;
  double get fatPercent =>
      totalMacroCalories > 0 ? (fatG * 9) / totalMacroCalories : 0;
}

class ColorGroup {
  final String color;
  final String foodName;
  final bool present;

  const ColorGroup({
    required this.color,
    required this.foodName,
    required this.present,
  });

  Map<String, dynamic> toMap() => {
        'color': color,
        'foodName': foodName,
        'present': present,
      };

  factory ColorGroup.fromMap(Map<String, dynamic> map) => ColorGroup(
        color: map['color'] as String,
        foodName: map['foodName'] as String,
        present: map['present'] as bool? ?? false,
      );
}
