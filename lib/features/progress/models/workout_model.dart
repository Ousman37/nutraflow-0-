import 'package:cloud_firestore/cloud_firestore.dart';

enum WorkoutType {
  running,
  cycling,
  weightLifting,
  yoga,
  hiit,
  swimming,
  walking,
  other;

  String get label => switch (this) {
        WorkoutType.running => 'Running',
        WorkoutType.cycling => 'Cycling',
        WorkoutType.weightLifting => 'Weights',
        WorkoutType.yoga => 'Yoga',
        WorkoutType.hiit => 'HIIT',
        WorkoutType.swimming => 'Swimming',
        WorkoutType.walking => 'Walking',
        WorkoutType.other => 'Other',
      };

  String get emoji => switch (this) {
        WorkoutType.running => '🏃',
        WorkoutType.cycling => '🚴',
        WorkoutType.weightLifting => '🏋️',
        WorkoutType.yoga => '🧘',
        WorkoutType.hiit => '⚡',
        WorkoutType.swimming => '🏊',
        WorkoutType.walking => '🚶',
        WorkoutType.other => '💪',
      };

  static WorkoutType fromKey(String key) => WorkoutType.values.firstWhere(
        (t) => t.name == key,
        orElse: () => WorkoutType.other,
      );
}

class WorkoutModel {
  final String id;
  final String userId;
  final WorkoutType type;
  final int durationMinutes;
  final double? caloriesBurned;
  final String? notes;
  final DateTime createdAt;

  const WorkoutModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.durationMinutes,
    this.caloriesBurned,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'durationMinutes': durationMinutes,
        if (caloriesBurned != null) 'caloriesBurned': caloriesBurned,
        if (notes != null) 'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory WorkoutModel.fromMap(Map<String, dynamic> map) => WorkoutModel(
        id: map['id'] as String,
        userId: map['userId'] as String,
        type: WorkoutType.fromKey(map['type'] as String? ?? ''),
        durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 30,
        caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble(),
        notes: map['notes'] as String?,
        createdAt: _parseDate(map['createdAt']),
      );

  static DateTime _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.parse(v);
    return DateTime.now();
  }
}
