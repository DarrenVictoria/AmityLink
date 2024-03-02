import 'package:firebase_auth/firebase_auth.dart';
import 'package:amity_link_mobile/auth.dart';



import 'package:flutter/material.dart';


class HomePage extends StatelessWidget{
  HomePage({Key?key}): super(key: key);

  final User? user = Auth().currentUser;

  Future<void> signOut() async{
    await Auth().signOut();
  }

  Widget _title() {
    return const Text('Firebase Auth');
  }

  Widget userUid() {
    return Text(user?.email ?? 'User email');
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: signOut,
      child: const Text('Sign Out'),
    );
  }



  
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: _title(),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            userUid(),
            _signOutButton(),
          ],
        ),
      ),
      
    );
  }
}