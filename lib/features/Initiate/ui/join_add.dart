import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:AmityLink/features/Initiate/data/auth.dart';
import 'package:AmityLink/features/Initiate/data/joinadd_repository.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';

class JoinAddPage extends StatefulWidget {
  JoinAddPage({Key? key}) : super(key: key);

  @override
  _JoinAddPageState createState() => _JoinAddPageState();
}

class _JoinAddPageState extends State<JoinAddPage> {
  final Auth _auth = Auth();
  final GroupRepository _groupRepository = GroupRepository();
  final TextEditingController _groupCodeController = TextEditingController();

  Future<void> _joinGroup(String groupCode) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _groupRepository.joinGroup(groupCode, user.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have successfully joined the group!'),
          ),
        );
        Navigator.pushNamed(context, '/');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group not found!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
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
            _signOut(context);
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
                          _joinGroup(groupCode);
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