import 'package:firebase_auth/firebase_auth.dart';

class Auth {
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> deleteAccount() async {
    await FirebaseAuth.instance.currentUser!.delete();
  }
}