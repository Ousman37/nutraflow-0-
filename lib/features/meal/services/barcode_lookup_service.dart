import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nutrition_analysis.dart';

/// Thrown when a barcode doesn't match any product in Open Food Facts.
class BarcodeProductNotFoundException implements Exception {
  final String barcode;
  const BarcodeProductNotFoundException(this.barcode);
  @override
  String toString() => 'No product found for barcode $barcode';
}

/// Resolves a scanned barcode to nutrition info via Open Food Facts —
/// a free, public product database that requires no API key.
/// https://world.openfoodfacts.org/data
class BarcodeLookupService {
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  Future<NutritionAnalysis> lookup(String barcode) async {
    final uri = Uri.parse(
      '$_baseUrl/$barcode.json'
      '?fields=product_name,brands,nutriments,serving_size',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception(
          'Barcode lookup failed: HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    // Open Food Facts returns status: 0 (and no `product`) for an unknown barcode.
    if (body['status'] != 1 || body['product'] is! Map) {
      throw BarcodeProductNotFoundException(barcode);
    }

    final product = body['product'] as Map<String, dynamic>;
    final nutriments =
        (product['nutriments'] as Map<String, dynamic>?) ?? const {};

    final name = (product['product_name'] as String?)?.trim() ?? '';
    final brand = (product['brands'] as String?)?.trim() ?? '';
    final displayName = [
      if (name.isNotEmpty) name,
      if (brand.isNotEmpty) brand,
    ].join(' — ');

    // Prefer the per-serving figures when the product declares a serving
    // size; Open Food Facts exposes those under a "_serving" suffix.
    // Falls back to per-100g otherwise — still a genuine reported value,
    // never fabricated.
    double numFor(String key) {
      final value = nutriments['${key}_serving'] ?? nutriments[key];
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    final calories = numFor('energy-kcal');
    final protein = numFor('proteins');
    final carbs = numFor('carbohydrates');
    final fat = numFor('fat');
    final fiber = numFor('fiber');

    if (calories == 0 && protein == 0 && carbs == 0 && fat == 0) {
      // Product exists but has no usable nutrition data — treat the same
      // as "not found" rather than saving an all-zero meal.
      throw BarcodeProductNotFoundException(barcode);
    }

    return NutritionAnalysis(
      foodName: displayName.isNotEmpty ? displayName : 'Scanned product',
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      fiberG: fiber,
      score: _estimateScore(calories, protein, carbs, fat),
      feedback: 'Nutrition data from the product\'s Open Food Facts listing.',
      suggestions: const [],
      colorGroups: const [],
    );
  }

  // Same macro-balance heuristic used for the description-based fallback
  // in AINutritionService, so barcode-sourced meals score consistently
  // with the rest of the app.
  int _estimateScore(double cal, double protein, double carbs, double fat) {
    int score = 50;
    final totalCal = (protein * 4) + (carbs * 4) + (fat * 9);
    if (totalCal > 0) {
      final protRatio = (protein * 4) / totalCal;
      final carbRatio = (carbs * 4) / totalCal;
      final fatRatio = (fat * 9) / totalCal;
      if (protRatio >= 0.25 && protRatio <= 0.40) score += 20;
      if (carbRatio >= 0.40 && carbRatio <= 0.55) score += 15;
      if (fatRatio >= 0.20 && fatRatio <= 0.35) score += 15;
    }
    return score.clamp(20, 98);
  }
}
