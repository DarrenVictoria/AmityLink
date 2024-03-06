import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:AmityLink/auth.dart';
import '../NavFooter/amitiesnav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:AmityLink/pages/Group/group_dashboard_page.dart';


class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final User? user = Auth().currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: TopNavigationBar(
          onDashboardSelected: () {
            // Navigate to the dashboard screen
            Navigator.pushNamed(context, '/dashboard');
          },
          onSignOutSelected: () {
            signOut(context);
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'My Amities',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                    .collection('amities')
                    .where('GroupMembers', arrayContains: user?.uid)
                    .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }

                    return Expanded(
                      child: ListView(
                        children: snapshot.data!.docs.map((doc) {
                          final groupName = doc['GroupName'] as String?;
                          final docId = doc.id;
                          final groupProfilePicture = doc['GroupProfilePicture'] as String?;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GroupDashboardPage(groupName: groupName!, groupId: docId),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Card(
                                elevation: 2,
                                margin: EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              groupName ?? 'No Group Name', // Use default value if groupName is null
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'ID: $docId' ?? 'No Group ID', // Use default value if admin is null
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(10),
                                      child: ClipOval(
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          child: Image.network(
                                            groupProfilePicture ?? 'https://static.thenounproject.com/png/1546235-200.png', // Use default image if groupProfilePicture is null
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                )


              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/joinadd');
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
