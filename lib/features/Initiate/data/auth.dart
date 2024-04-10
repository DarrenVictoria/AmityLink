import 'package:firebase_auth/firebase_auth.dart';

class Auth {
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  User? get currentUser {
    return FirebaseAuth.instance.currentUser;
  }
}