import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage = '';
  bool isLogin = true;

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerName = TextEditingController();

  Future<void> signInWithEmailAndPassword() async {
    try {
      await Auth().signInWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
        );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = "Incorrect credentials provided.If you don't have account please register";
      });
    }
  }

Future<void> createUserWithEmailAndPassword() async {
  try {
    final userCredential = await Auth().createUserWithEmailAndPassword(
      email: _controllerEmail.text,
      password: _controllerPassword.text,
    );

    if (userCredential != null) {
      await FirebaseFirestore.instance.collection('users').doc(userCredential?.uid).set({
        'name': _controllerName.text,
        'email': _controllerEmail.text,
        'ProfilePicture': '',
      });
    } else {
      // Handle the case where userCredential.user is null
      setState(() {
        errorMessage = "User creation failed. Please try again.";
      });
    }
  } on FirebaseAuthException catch (e) {
    setState(() {
      errorMessage = e.message;
    });
  }
}

Future<void> signInWithGoogle() async {
  try {
    // Configure GoogleSignIn options
    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

    // Sign out the user from Google sign-in
    await googleSignIn.signOut();

    // Trigger the Google sign-in flow
    final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

    if (googleSignInAccount != null) {
      // Obtain the GoogleSignInAuthentication object
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Get the user details
      final User? user = userCredential.user;

      // Check if the user is signing in for the first time
      if (user != null && userCredential.additionalUserInfo!.isNewUser) {
        // If it's a new user, fetch user details from Google
        final googleUser = await googleSignIn.currentUser;

        // Create a new document in Firestore for the user
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': googleUser!.displayName,
          'email': googleUser.email,
          'ProfilePicture': googleUser.photoUrl,
          // You can add more fields as needed
        });
      }
    }

    // Navigate to the home page or perform any other desired action
  } catch (e) {
    // Handle errors
    print("Error signing in with Google: $e");
  }
}






  Widget _title() {
    return const Text('Amity Link');
  }

  Widget _entryField(
    String title,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: title,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
      ),
    );
  }

  Widget _errorMessage() {
    return Container(
      margin: EdgeInsets.only(top: 10, bottom: 15),
      child: Center(
        child: Text(
          errorMessage == '' ? '' : '$errorMessage',
          style: TextStyle(
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
          softWrap: true, // Wrap text after full stop
        ),
      ),
    );
  }

  Widget _submitButton() {
  return Container(
    width: double.infinity,
    child: Column(
      children: [
        ElevatedButton(
          onPressed: isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword,
          child: Text(isLogin ? 'Login' : 'Register Now'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            textStyle: TextStyle(fontSize: 15.0),
            minimumSize: Size(double.infinity, 50.0), // Set the minimum width and height
          ),
        ),
        SizedBox(height: 10), // Add some spacing between buttons
        if (isLogin) // Show "Sign in with Google" button only when logging in
          OutlinedButton.icon(
            onPressed: signInWithGoogle,
            icon: Icon(Icons.account_circle), // Use Icons.account_circle for Google sign-in
            label: Text('Sign in with Google'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(50.0, 50.0), // Set the minimum width and height
            ),
        ),
      ],
    ),
  );
}


  Widget _loginOrRegisterButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          isLogin = !isLogin;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(isLogin ? 'No account yet ? Register instead' : 'Aldready have an account ? Login instead'),
      ),
    );
  }
  @override
  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(142, 72, 81, 210),
              Color.fromARGB(144, 15, 145, 205),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            Image.asset(
              'assets/icons/Amity Link Black.png',
              width: 225,
              height: 225,
            ),
            SizedBox(height: 20),
            if (!isLogin) _entryField('Name', _controllerName),
            _entryField('Email', _controllerEmail),
            _entryField('Password', _controllerPassword),
            _errorMessage(),
            _submitButton(),
            _loginOrRegisterButton(),
            SizedBox(height: 16), // Added SizedBox to create some space at the bottom
          ],
        ),
      ),
    ),
  );
}

}