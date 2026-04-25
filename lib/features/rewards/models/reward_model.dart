import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Static milestone definitions — visual data lives in the app, not Firestore.
// ─────────────────────────────────────────────────────────────────────────────

class MilestoneInfo {
  final String id;
  final int days;
  final String title;
  final String description;
  final String emoji;
  final String motivationalMessage;
  final Color color1;
  final Color color2;

  const MilestoneInfo({
    required this.id,
    required this.days,
    required this.title,
    required this.description,
    required this.emoji,
    required this.motivationalMessage,
    required this.color1,
    required this.color2,
  });

  List<Color> get colors => [color1, color2];
}

const List<MilestoneInfo> kMilestones = [
  MilestoneInfo(
    id: 'getting_started',
    days: 3,
    title: 'Getting Started',
    description: 'You logged 3 days in a row. This is how habits begin.',
    emoji: '🌱',
    motivationalMessage:
        "You're building real momentum. Every great journey starts with a single step — this one counts.",
    color1: Color(0xFF4CAF82),
    color2: Color(0xFF00D4AA),
  ),
  MilestoneInfo(
    id: 'one_week_strong',
    days: 7,
    title: 'One Week Strong',
    description: 'A full week of consistency. You\'re making this a routine.',
    emoji: '⭐',
    motivationalMessage:
        "One week in. You're already proving this is more than motivation — it's discipline starting to form.",
    color1: Color(0xFF5B8BFF),
    color2: Color(0xFF7B6CF8),
  ),
  MilestoneInfo(
    id: 'consistency_builder',
    days: 14,
    title: 'Consistency Builder',
    description: 'Two weeks strong. You\'re wiring healthy habits into your life.',
    emoji: '🔥',
    motivationalMessage:
        "14 days. Science says habits form around 21 days — you're more than halfway. Keep the fire burning.",
    color1: Color(0xFFFFB443),
    color2: Color(0xFFFF6B9D),
  ),
  MilestoneInfo(
    id: 'health_momentum',
    days: 30,
    title: 'Health Momentum',
    description: 'A full month of dedication. You\'re in a different league now.',
    emoji: '💪',
    motivationalMessage:
        "30 days. You've crossed the threshold where this is no longer a challenge — it's just who you are.",
    color1: Color(0xFF9C27B0),
    color2: Color(0xFF673AB7),
  ),
  MilestoneInfo(
    id: 'lifestyle_champion',
    days: 55,
    title: 'Lifestyle Champion',
    description: '55 days of unstoppable consistency. Health is your lifestyle now.',
    emoji: '🏆',
    motivationalMessage:
        "55 days. You didn't just build a habit — you built a new identity. This is who you are now. Champion.",
    color1: Color(0xFFFFD700),
    color2: Color(0xFFFF8C00),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// RewardModel — persisted in Firestore under users/{uid}/rewards/{id}
// ─────────────────────────────────────────────────────────────────────────────

class RewardModel {
  final String id;
  final int milestoneDays;
  final String title;
  final String description;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progress; // streak count at last check

  const RewardModel({
    required this.id,
    required this.milestoneDays,
    required this.title,
    required this.description,
    required this.isUnlocked,
    this.unlockedAt,
    required this.progress,
  });

  // Visual data is always read from the static list, never from Firestore.
  MilestoneInfo get info => kMilestones.firstWhere(
        (m) => m.id == id,
        orElse: () => kMilestones.first,
      );

  // How far the user is toward this milestone (capped at 1.0 once unlocked).
  double progressFraction(int currentStreak) {
    if (isUnlocked) return 1.0;
    return (currentStreak / milestoneDays).clamp(0.0, 1.0);
  }

  int daysRemaining(int currentStreak) =>
      (milestoneDays - currentStreak).clamp(0, milestoneDays);

  RewardModel copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? progress,
  }) =>
      RewardModel(
        id: id,
        milestoneDays: milestoneDays,
        title: title,
        description: description,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
        progress: progress ?? this.progress,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'milestoneDays': milestoneDays,
        'title': title,
        'description': description,
        'isUnlocked': isUnlocked,
        'unlockedAt':
            unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
        'progress': progress,
      };

  factory RewardModel.fromMap(Map<String, dynamic> map) => RewardModel(
        id: map['id'] as String,
        milestoneDays: (map['milestoneDays'] as num).toInt(),
        title: map['title'] as String,
        description: map['description'] as String,
        isUnlocked: map['isUnlocked'] as bool? ?? false,
        unlockedAt: _parseDate(map['unlockedAt']),
        progress: (map['progress'] as num?)?.toInt() ?? 0,
      );

  factory RewardModel.initial(MilestoneInfo m) => RewardModel(
        id: m.id,
        milestoneDays: m.days,
        title: m.title,
        description: m.description,
        isUnlocked: false,
        progress: 0,
      );

  static DateTime? _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
