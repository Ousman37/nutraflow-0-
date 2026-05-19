import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/nutrition_analysis.dart';
import '../../../core/config/api_config.dart';

class AINutritionService {
  final _rng = Random();

  Future<NutritionAnalysis> analyzeMeal({
    String? description,
    String? imagePath,
  }) async {
    final hasKey = ApiConfig.claudeApiKey.isNotEmpty &&
        ApiConfig.claudeApiKey != 'YOUR_API_KEY_HERE';

    if (imagePath != null && hasKey) {
      try {
        return await _analyzeWithClaude(
          imagePath: imagePath,
          description: description,
        );
      } catch (_) {
        // Fall back to mock if the API call fails
      }
    }

    await Future.delayed(const Duration(milliseconds: 1800));
    return _estimateFromKeywords((description ?? '').toLowerCase());
  }

  Future<NutritionAnalysis> _analyzeWithClaude({
    required String imagePath,
    String? description,
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    final ext = imagePath.split('.').last.toLowerCase();
    final mediaType = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg';

    final promptBuf = StringBuffer(
      'Analyze this food/meal image and estimate its nutritional content.',
    );
    if (description != null && description.isNotEmpty) {
      promptBuf.write(' The user described it as: "$description".');
    }
    promptBuf.write('''

Return ONLY valid JSON — no markdown, no extra text:
{
  "calories": <number>,
  "proteinG": <number>,
  "carbsG": <number>,
  "fatG": <number>,
  "fiberG": <number>,
  "score": <integer 0-100 representing overall nutritional quality>,
  "feedback": "<one concise sentence assessing this meal>",
  "suggestions": ["<actionable tip 1>", "<actionable tip 2>", "<actionable tip 3>"],
  "colorGroups": {
    "red": <true/false — red fruits/vegetables present>,
    "orange": <true/false — orange vegetables present>,
    "yellow": <true/false — yellow fruits/vegetables present>,
    "green": <true/false — green vegetables present>,
    "bluePurple": <true/false — blue or purple produce present>,
    "whiteBrown": <true/false — grains or protein present>
  }
}''');

    final response = await http
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'x-api-key': ApiConfig.claudeApiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'model': ApiConfig.claudeModel,
            'max_tokens': 512,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'image',
                    'source': {
                      'type': 'base64',
                      'media_type': mediaType,
                      'data': base64Image,
                    },
                  },
                  {
                    'type': 'text',
                    'text': promptBuf.toString(),
                  },
                ],
              }
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Claude API error ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (body['content'] as List).first['text'] as String;

    // Strip any accidental markdown code fences
    final cleaned = text.replaceAll(RegExp(r'```[a-z]*'), '').trim();
    final n = jsonDecode(cleaned) as Map<String, dynamic>;
    final cg = n['colorGroups'] as Map<String, dynamic>;

    return NutritionAnalysis(
      calories: (n['calories'] as num).toDouble(),
      proteinG: (n['proteinG'] as num).toDouble(),
      carbsG: (n['carbsG'] as num).toDouble(),
      fatG: (n['fatG'] as num).toDouble(),
      fiberG: (n['fiberG'] as num).toDouble(),
      score: (n['score'] as num).toInt().clamp(0, 100),
      feedback: n['feedback'] as String,
      suggestions: List<String>.from(n['suggestions'] ?? []),
      colorGroups: [
        ColorGroup(
          color: 'Red',
          foodName: 'Tomatoes / Berries',
          present: cg['red'] as bool? ?? false,
        ),
        ColorGroup(
          color: 'Orange',
          foodName: 'Carrots / Sweet Potato',
          present: cg['orange'] as bool? ?? false,
        ),
        ColorGroup(
          color: 'Yellow',
          foodName: 'Banana / Corn',
          present: cg['yellow'] as bool? ?? false,
        ),
        ColorGroup(
          color: 'Green',
          foodName: 'Vegetables / Avocado',
          present: cg['green'] as bool? ?? false,
        ),
        ColorGroup(
          color: 'Blue/Purple',
          foodName: 'Blueberries / Eggplant',
          present: cg['bluePurple'] as bool? ?? false,
        ),
        ColorGroup(
          color: 'White/Brown',
          foodName: 'Grains / Protein',
          present: cg['whiteBrown'] as bool? ?? false,
        ),
      ],
    );
  }

  // ── Mock fallback ─────────────────────────────────────────────────────────

  NutritionAnalysis _estimateFromKeywords(String input) {
    double calories = 400 + _rng.nextDouble() * 300;
    double protein = 15 + _rng.nextDouble() * 30;
    double carbs = 30 + _rng.nextDouble() * 50;
    double fat = 10 + _rng.nextDouble() * 20;
    double fiber = 2 + _rng.nextDouble() * 8;

    if (_contains(input, ['salad', 'vegetables', 'veggies', 'greens'])) {
      calories = 150 + _rng.nextDouble() * 150;
      protein = 8 + _rng.nextDouble() * 12;
      carbs = 15 + _rng.nextDouble() * 20;
      fat = 5 + _rng.nextDouble() * 10;
      fiber = 5 + _rng.nextDouble() * 8;
    } else if (_contains(input, ['burger', 'pizza', 'fried', 'fast food'])) {
      calories = 600 + _rng.nextDouble() * 400;
      protein = 20 + _rng.nextDouble() * 20;
      carbs = 60 + _rng.nextDouble() * 40;
      fat = 25 + _rng.nextDouble() * 20;
      fiber = 1 + _rng.nextDouble() * 3;
    } else if (_contains(input, ['chicken', 'fish', 'steak', 'beef', 'turkey'])) {
      calories = 300 + _rng.nextDouble() * 200;
      protein = 35 + _rng.nextDouble() * 20;
      carbs = 5 + _rng.nextDouble() * 20;
      fat = 10 + _rng.nextDouble() * 15;
      fiber = 0 + _rng.nextDouble() * 3;
    } else if (_contains(input, ['oatmeal', 'oats', 'granola', 'cereal'])) {
      calories = 250 + _rng.nextDouble() * 150;
      protein = 8 + _rng.nextDouble() * 10;
      carbs = 45 + _rng.nextDouble() * 25;
      fat = 5 + _rng.nextDouble() * 8;
      fiber = 4 + _rng.nextDouble() * 6;
    } else if (_contains(input, ['smoothie', 'juice', 'shake'])) {
      calories = 200 + _rng.nextDouble() * 200;
      protein = 10 + _rng.nextDouble() * 15;
      carbs = 35 + _rng.nextDouble() * 30;
      fat = 3 + _rng.nextDouble() * 8;
      fiber = 3 + _rng.nextDouble() * 5;
    } else if (_contains(input, ['pasta', 'rice', 'noodles', 'bread'])) {
      calories = 350 + _rng.nextDouble() * 250;
      protein = 10 + _rng.nextDouble() * 15;
      carbs = 60 + _rng.nextDouble() * 40;
      fat = 5 + _rng.nextDouble() * 12;
      fiber = 2 + _rng.nextDouble() * 5;
    }

    final score = _calculateScore(calories, protein, carbs, fat);
    return NutritionAnalysis(
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      fiberG: fiber,
      score: score,
      feedback: _generateFeedback(score, protein, carbs, fat),
      suggestions: _generateSuggestions(protein, carbs, fat, fiber),
      colorGroups: _detectColorGroups(input),
    );
  }

  bool _contains(String input, List<String> keywords) =>
      keywords.any((k) => input.contains(k));

  int _calculateScore(double cal, double protein, double carbs, double fat) {
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
    if (cal < 800) score = min(score + 5, 100);
    if (cal > 1000) score = max(score - 10, 0);
    return score.clamp(20, 98);
  }

  String _generateFeedback(int score, double protein, double carbs, double fat) {
    if (score >= 80) return 'Excellent nutritional balance!';
    if (score >= 65) return 'Good meal choice, well balanced.';
    if (protein < 20) return 'Consider adding more protein to this meal.';
    if (carbs > 80) return 'This meal is high in carbohydrates.';
    if (fat > 35) return 'This meal is higher in fat than ideal.';
    return 'Decent meal — room for improvement.';
  }

  List<String> _generateSuggestions(
    double protein,
    double carbs,
    double fat,
    double fiber,
  ) {
    final suggestions = <String>[];
    if (protein < 20) suggestions.add('Add more protein (eggs, chicken, legumes)');
    if (fiber < 4) suggestions.add('Include fiber-rich foods (vegetables, beans)');
    if (carbs > 80) suggestions.add('Reduce simple carbohydrates');
    if (fat > 35) suggestions.add('Opt for healthier fat sources');
    if (suggestions.isEmpty) suggestions.add('Great macro balance — keep it up!');
    return suggestions.take(3).toList();
  }

  List<ColorGroup> _detectColorGroups(String input) {
    return [
      ColorGroup(
        color: 'Red',
        foodName: 'Tomatoes / Berries',
        present: _contains(input, ['tomato', 'berry', 'berries', 'red', 'apple']),
      ),
      ColorGroup(
        color: 'Orange',
        foodName: 'Carrots / Sweet Potato',
        present: _contains(input, ['carrot', 'sweet potato', 'orange', 'pumpkin']),
      ),
      ColorGroup(
        color: 'Yellow',
        foodName: 'Banana / Corn',
        present: _contains(input, ['banana', 'corn', 'yellow', 'lemon']),
      ),
      ColorGroup(
        color: 'Green',
        foodName: 'Vegetables / Avocado',
        present: _contains(
            input, ['green', 'spinach', 'broccoli', 'avocado', 'salad', 'kale']),
      ),
      ColorGroup(
        color: 'Blue/Purple',
        foodName: 'Blueberries / Eggplant',
        present: _contains(
            input, ['blueberry', 'blueberries', 'eggplant', 'grape', 'plum']),
      ),
      ColorGroup(
        color: 'White/Brown',
        foodName: 'Grains / Protein',
        present: _contains(
            input, ['rice', 'bread', 'pasta', 'oat', 'chicken', 'fish', 'egg']),
      ),
    ];
  }
}
