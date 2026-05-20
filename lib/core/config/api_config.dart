import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class ApiConfig {
  static String get claudeApiKey => dotenv.env['CLAUDE_API_KEY'] ?? '';
  static const String claudeModel = 'claude-haiku-4-5-20251001';
}
