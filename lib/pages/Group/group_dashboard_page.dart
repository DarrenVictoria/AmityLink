
import 'package:AmityLink/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class GroupDashboardPage extends StatefulWidget {
  final String groupName;
  final String groupId;

  GroupDashboardPage({Key? key, required this.groupName, required this.groupId}) : super(key: key);

  @override
  _GroupDashboardPageState createState() => _GroupDashboardPageState();
}

class _GroupDashboardPageState extends State<GroupDashboardPage> {
  final User? user = Auth().currentUser;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? groupProfilePictureUrl;
  

  @override
  void initState() {
    super.initState();
    fetchGroupProfilePicture();
  }

  Future<void> fetchGroupProfilePicture() async {
    try {
      final DocumentSnapshot groupSnapshot = await _firestore.collection('amities').doc(widget.groupId).get();
      setState(() {
        groupProfilePictureUrl = groupSnapshot['GroupProfilePicture'];
      });
    } catch (error) {
      print('Error fetching group profile picture: $error');
    }
  }

  Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied group ID to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: TopNavigationBar(
          onBack: () {
            Navigator.of(context).pop();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 15),
                    child: Text(
                      'Welcome to ${widget.groupName}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              groupProfilePictureUrl != null
                  ? Padding(
                      padding: EdgeInsets.only(top: 10, right: 10,left:20),
                      child: ClipOval(
                        child: Image.network(
                          groupProfilePictureUrl!,
                          width: 100,
                          height: 100,
                          alignment: Alignment.centerRight,
                        ),
                      ),
                    )
                  : SizedBox(width: 100, height: 100), // Placeholder or loading indicator while fetching image
            ],
          ),
          SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    _copyToClipboard(context, widget.groupId);
                  },
                  child: Icon(
                    Icons.copy,
                    size: 17, // Adjust the size as desired
                  ),
                ),
                SizedBox(width: 5),
                GestureDetector(
                  onTap: () {
                    _copyToClipboard(context, widget.groupId);
                  },
                  child: Text(
                    'ID: ${widget.groupId}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                GestureDetector(
                  onTap: () {
                    // Redirect to group bulletin board page
                    Navigator.pushNamed(context, '/bulletin_board', arguments: widget.groupId);
                  },
                  child: Card(
                    color: Color(0xFFA0EAFD), // Set the background color to blue
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pin, // Change the icon to a pin
                          size: 40, // Increase the size of the icon
                        ),
                        SizedBox(height: 15), // Increase the spacing between the icon and the text
                        Text(
                          'Bulletin Board',
                          style: TextStyle(
                            fontSize: 22, // Increase the font size of the text
                            fontWeight: FontWeight.bold, // Make the text bold
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    // Redirect to group settings page
                    Navigator.pushNamed(context, '/group_settings', arguments: widget.groupId);
                  },
                  child: Card(
                    color: Colors.grey, // Set the background color to gray
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.settings, // Change the icon to a cogwheel
                          size: 40, // Set the font size to 20
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Group Settings',
                          style: TextStyle(
                            fontSize: 22, // Set the font size to 20
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Add more cards with different names, icons, and redirections here
              ],
            ),
          ),
        ],
      ),
      
    );
  }
}


// Center(
//         child: Text('Dashboard for $groupName (ID: $groupId)'),
//       ),