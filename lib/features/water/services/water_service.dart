import 'package:cloud_firestore/cloud_firestore.dart';

class WaterService {
  final _db = FirebaseFirestore.instance;

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DocumentReference<Map<String, dynamic>> _doc(String uid, DateTime date) =>
      _db.collection('users').doc(uid).collection('water_logs').doc(_dateKey(date));

  Future<int> getGlasses(String uid, DateTime date) async {
    final snap = await _doc(uid, date).get();
    return (snap.data()?['glasses'] as int?) ?? 0;
  }

  Future<void> setGlasses(String uid, DateTime date, int glasses) async {
    await _doc(uid, date).set({'glasses': glasses, 'date': _dateKey(date)});
  }
}
