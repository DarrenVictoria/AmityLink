import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class Auth{
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
   final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

   Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user;
      
    } catch (e) {
      print("Error creating user: $e");
      throw e; // Rethrow the error to handle it in UI
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}



