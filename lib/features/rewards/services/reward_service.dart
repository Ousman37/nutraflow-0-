import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward_model.dart';

class RewardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _rewards(String uid) =>
      _db.collection('users').doc(uid).collection('rewards');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  // Idempotent: creates missing milestone documents on first call.
  Future<void> ensureInitialized(String uid) async {
    final snap = await _rewards(uid).get();
    if (snap.docs.length >= kMilestones.length) return;

    final existing = snap.docs.map((d) => d.id).toSet();
    final batch = _db.batch();
    for (final m in kMilestones) {
      if (!existing.contains(m.id)) {
        batch.set(
          _rewards(uid).doc(m.id),
          RewardModel.initial(m).toMap(),
        );
      }
    }
    await batch.commit();
  }

  Future<List<RewardModel>> loadRewards(String uid) async {
    await ensureInitialized(uid);
    final snap = await _rewards(uid).get();
    final list = snap.docs
        .map((d) => RewardModel.fromMap(d.data()))
        .toList()
      ..sort((a, b) => a.milestoneDays.compareTo(b.milestoneDays));
    return list;
  }

  // Compare streak against milestones; unlock any newly eligible ones.
  // Returns a sorted list of the rewards that were just unlocked.
  Future<List<RewardModel>> checkAndUnlock(
      String uid, int streakCount) async {
    await ensureInitialized(uid);

    final snap = await _rewards(uid)
        .where('isUnlocked', isEqualTo: false)
        .get();
    final locked =
        snap.docs.map((d) => RewardModel.fromMap(d.data())).toList();

    if (locked.isEmpty) return [];

    final newlyUnlocked =
        locked.where((r) => streakCount >= r.milestoneDays).toList();
    final stillLocked =
        locked.where((r) => streakCount < r.milestoneDays).toList();

    final batch = _db.batch();
    final now = DateTime.now();

    for (final r in newlyUnlocked) {
      batch.update(_rewards(uid).doc(r.id), {
        'isUnlocked': true,
        'unlockedAt': Timestamp.fromDate(now),
        'progress': streakCount,
      });
    }

    for (final r in stillLocked) {
      batch.update(_rewards(uid).doc(r.id), {'progress': streakCount});
    }

    if (newlyUnlocked.isNotEmpty) {
      batch.set(
        _userDoc(uid),
        {
          'unlockedRewardIds': FieldValue.arrayUnion(
              newlyUnlocked.map((r) => r.id).toList()),
          'lastRewardUnlockedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();

    return newlyUnlocked
        .map((r) => r.copyWith(
              isUnlocked: true,
              unlockedAt: now,
              progress: streakCount,
            ))
        .toList()
      ..sort((a, b) => a.milestoneDays.compareTo(b.milestoneDays));
  }
}
