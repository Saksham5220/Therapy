// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUserAnswers(List<String> answers) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not signed in');

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('formResponses')
        .add({
      'answers': answers,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
