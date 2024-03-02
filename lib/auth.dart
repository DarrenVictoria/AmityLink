import 'package:firebase_auth/firebase_auth.dart';

class Auth{
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

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

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

// // sign in with email and password
  // Future signInWithEmailAndPassword(String email, String password) async{
  //   try{
  //     UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
  //     User user = result.user;
  //     return user;
  //   }catch(e){
  //     print(e.toString());
  //     return null;
  //   }
  // }

  // // register with email and password
  // Future registerWithEmailAndPassword(String email, String password) async{
  //   try{
  //     UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
  //     User user = result.user;
  //     return user;
  //   }catch(e){
  //     print(e.toString());
  //     return null;
  //   }
  // }

  // // sign out
  // Future signOut() async{
  //   try{
  //     return await _auth.signOut();
  //   }catch(e){
  //     print(e.toString());
  //     return null;
  //   }
  // }