import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<void> saveUserProfile(UserProfileModel profile) async {
    await _users.doc(profile.id).set(profile.toMap());
  }

  Future<UserProfileModel?> getUserProfile(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfileModel.fromMap(doc.data()!);
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await _users.doc(userId).update(updates);
  }

  Future<bool> userProfileExists(String userId) async {
    final doc = await _users.doc(userId).get();
    return doc.exists;
  }

  // Persists the Pro subscription flag directly on the user document.
  // Uses set+merge so it works even if the document doesn't exist yet.
  Future<void> setProStatus(String userId, bool isPro) async {
    await _users.doc(userId).set(
      {'isProUser': isPro},
      SetOptions(merge: true),
    );
  }

  Future<void> deleteUserData(String userId) async {
    final batch = _db.batch();

    final meals = await _users
        .doc(userId)
        .collection('meals')
        .get();
    for (final doc in meals.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_users.doc(userId));
    await batch.commit();
  }
}
