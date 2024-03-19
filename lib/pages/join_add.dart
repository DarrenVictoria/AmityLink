import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:AmityLink/auth.dart';
import '../NavFooter/usertopnav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JoinAddPage extends StatelessWidget {
  JoinAddPage({Key? key}) : super(key: key);

  final User? user = Auth().currentUser;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void joinGroup(String groupCode, BuildContext context) async {
  // Check if the group document exists
  DocumentSnapshot groupSnapshot =
      await _firestore.collection('amities').doc(groupCode).get();

  if (groupSnapshot.exists) {
    // If the group exists, update Group Members array with current auth UserID
    await _firestore.collection('amities').doc(groupCode).update({
      'GroupMembers': FieldValue.arrayUnion([user!.uid]) // Assuming user is authenticated
    });
    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('You have successfully joined the group!'),
    ));
    // Redirect to the '/' page
    Navigator.pushNamed(context, '/');
  } else {
    // Show error snackbar indicating group not found
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Group not found!'),
      backgroundColor: Colors.red, // Optionally, set background color
    ));
  }
}

TextEditingController _groupCodeController = TextEditingController();

  Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: TopNavigationBar(
        onBack: () {
          Navigator.pushNamed(context, '/');
        },
        onDashboardSelected: () {
          Navigator.pushNamed(context, '/dashboard');
        },
        onSignOutSelected: () {
          signOut(context);
        },
      ),
    ),
    body: Column(
      children: [
        Flexible(
          child: Card(
            color: Color(0xFFD9D9D9),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Join a group',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Flexible(
                      child: TextField(
                        controller: _groupCodeController,
                        decoration: InputDecoration(
                          hintText: 'Enter group code here',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(35.0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        String groupCode = _groupCodeController.text;
                        joinGroup(groupCode, context);
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFF0F91CF),
                        onPrimary: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35.0),
                        ),
                      ),
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            color: Color(0xFFD9D9D9),
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.5,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No group yet?',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Create a group',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/addgroup');
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFF0F91CF),
                        onPrimary: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 24.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35.0),
                        ),
                      ),
                      child: Text(
                        'Create',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  }
}
