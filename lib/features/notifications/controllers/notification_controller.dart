import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationController extends GetxController {
  static const _keyMealsEnabled = 'nf_notif_meals_enabled';
  static const _keyWaterEnabled = 'nf_notif_water_enabled';
  static const _keyStreakEnabled = 'nf_notif_streak_enabled';
  static const _keyBreakfastMin = 'nf_notif_breakfast_min';
  static const _keyLunchMin = 'nf_notif_lunch_min';
  static const _keyDinnerMin = 'nf_notif_dinner_min';
  static const _keyStreakMin = 'nf_notif_streak_min';

  static const _waterTimes = [
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 16, minute: 0),
    TimeOfDay(hour: 19, minute: 0),
  ];

  final RxBool mealRemindersEnabled = false.obs;
  final RxBool waterRemindersEnabled = false.obs;
  final RxBool streakReminderEnabled = false.obs;

  final Rx<TimeOfDay> breakfastTime =
      const TimeOfDay(hour: 8, minute: 0).obs;
  final Rx<TimeOfDay> lunchTime = const TimeOfDay(hour: 12, minute: 30).obs;
  final Rx<TimeOfDay> dinnerTime = const TimeOfDay(hour: 19, minute: 0).obs;
  final Rx<TimeOfDay> streakTime = const TimeOfDay(hour: 20, minute: 0).obs;

  late final SharedPreferences _prefs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();

    mealRemindersEnabled.value = _prefs.getBool(_keyMealsEnabled) ?? false;
    waterRemindersEnabled.value = _prefs.getBool(_keyWaterEnabled) ?? false;
    streakReminderEnabled.value = _prefs.getBool(_keyStreakEnabled) ?? false;

    breakfastTime.value = _timeFromMinutes(
        _prefs.getInt(_keyBreakfastMin), const TimeOfDay(hour: 8, minute: 0));
    lunchTime.value = _timeFromMinutes(
        _prefs.getInt(_keyLunchMin), const TimeOfDay(hour: 12, minute: 30));
    dinnerTime.value = _timeFromMinutes(
        _prefs.getInt(_keyDinnerMin), const TimeOfDay(hour: 19, minute: 0));
    streakTime.value = _timeFromMinutes(
        _prefs.getInt(_keyStreakMin), const TimeOfDay(hour: 20, minute: 0));

    // Re-apply schedules on every app start so a reinstalled/reset alarm
    // store stays consistent with saved preferences.
    if (mealRemindersEnabled.value) await _scheduleMeals();
    if (waterRemindersEnabled.value) await _scheduleWater();
    if (streakReminderEnabled.value) await _scheduleStreak();
  }

  TimeOfDay _timeFromMinutes(int? minutes, TimeOfDay fallback) {
    if (minutes == null) return fallback;
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  int _minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

  // ── Meal reminders ──────────────────────────────────────────────────────

  Future<bool> setMealRemindersEnabled(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.requestPermissions();
      if (!granted) return false;
      await _scheduleMeals();
    } else {
      await NotificationService.cancelAll([
        NotificationIds.breakfast,
        NotificationIds.lunch,
        NotificationIds.dinner,
      ]);
    }
    mealRemindersEnabled.value = enabled;
    await _prefs.setBool(_keyMealsEnabled, enabled);
    return true;
  }

  Future<void> _scheduleMeals() async {
    await NotificationService.scheduleDaily(
      id: NotificationIds.breakfast,
      title: 'Breakfast time 🌅',
      body: "Log what you're having to stay on track today.",
      time: breakfastTime.value,
    );
    await NotificationService.scheduleDaily(
      id: NotificationIds.lunch,
      title: 'Lunch time ☀️',
      body: "Don't forget to log your lunch.",
      time: lunchTime.value,
    );
    await NotificationService.scheduleDaily(
      id: NotificationIds.dinner,
      title: 'Dinner time 🌙',
      body: 'Log dinner to close out your daily targets.',
      time: dinnerTime.value,
    );
  }

  Future<void> setBreakfastTime(TimeOfDay time) async {
    breakfastTime.value = time;
    await _prefs.setInt(_keyBreakfastMin, _minutesOf(time));
    if (mealRemindersEnabled.value) {
      await NotificationService.scheduleDaily(
        id: NotificationIds.breakfast,
        title: 'Breakfast time 🌅',
        body: "Log what you're having to stay on track today.",
        time: time,
      );
    }
  }

  Future<void> setLunchTime(TimeOfDay time) async {
    lunchTime.value = time;
    await _prefs.setInt(_keyLunchMin, _minutesOf(time));
    if (mealRemindersEnabled.value) {
      await NotificationService.scheduleDaily(
        id: NotificationIds.lunch,
        title: 'Lunch time ☀️',
        body: "Don't forget to log your lunch.",
        time: time,
      );
    }
  }

  Future<void> setDinnerTime(TimeOfDay time) async {
    dinnerTime.value = time;
    await _prefs.setInt(_keyDinnerMin, _minutesOf(time));
    if (mealRemindersEnabled.value) {
      await NotificationService.scheduleDaily(
        id: NotificationIds.dinner,
        title: 'Dinner time 🌙',
        body: 'Log dinner to close out your daily targets.',
        time: time,
      );
    }
  }

  // ── Water reminders ─────────────────────────────────────────────────────

  Future<bool> setWaterRemindersEnabled(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.requestPermissions();
      if (!granted) return false;
      await _scheduleWater();
    } else {
      await NotificationService.cancelAll(NotificationIds.water);
    }
    waterRemindersEnabled.value = enabled;
    await _prefs.setBool(_keyWaterEnabled, enabled);
    return true;
  }

  Future<void> _scheduleWater() async {
    for (var i = 0; i < NotificationIds.water.length; i++) {
      await NotificationService.scheduleDaily(
        id: NotificationIds.water[i],
        title: 'Hydration check 💧',
        body: 'Time for a glass of water.',
        time: _waterTimes[i],
      );
    }
  }

  // ── Streak reminder ──────────────────────────────────────────────────────

  Future<bool> setStreakReminderEnabled(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.requestPermissions();
      if (!granted) return false;
      await _scheduleStreak();
    } else {
      await NotificationService.cancel(NotificationIds.streak);
    }
    streakReminderEnabled.value = enabled;
    await _prefs.setBool(_keyStreakEnabled, enabled);
    return true;
  }

  Future<void> _scheduleStreak() async {
    await NotificationService.scheduleDaily(
      id: NotificationIds.streak,
      title: "Don't lose your streak! 🔥",
      body: "You haven't logged a meal today — a quick entry keeps it alive.",
      time: streakTime.value,
    );
  }

  Future<void> setStreakTime(TimeOfDay time) async {
    streakTime.value = time;
    await _prefs.setInt(_keyStreakMin, _minutesOf(time));
    if (streakReminderEnabled.value) await _scheduleStreak();
  }
}
