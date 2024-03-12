import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:AmityLink/auth.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';

class AttendancePollPage extends StatefulWidget {
  final String documentId;
  final String groupId;

  const AttendancePollPage({Key? key, required this.documentId, required this.groupId}) : super(key: key);

  @override
  _AttendancePollPageState createState() => _AttendancePollPageState();
}

class _AttendancePollPageState extends State<AttendancePollPage> {
  bool goingSelected = false;
  bool notGoingSelected = false;

  int totalPeopleGoing = 0; // Counter for total people going
  String uid = FirebaseAuth.instance.currentUser!.uid;
  String adminId = '';

  List<String> goingUsers = [];
  List<String> notGoingUsers = [];

  void fetchAdminId() {
    FirebaseFirestore.instance
        .collection('amities')
        .doc(widget.groupId)
        .collection('Events')
        .doc(widget.documentId)
        .get()
        .then((DocumentSnapshot eventSnapshot) {
      if (eventSnapshot.exists) {
        setState(() {
          adminId = eventSnapshot['AdminID'] ?? '';
        });
      }
    });
  }

  void _showGoingUsersPopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Users Going'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: goingUsers.map((user) => Text(user)).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      );
    },
  );
}

void _showNotGoingUsersPopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Users Not Going'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: notGoingUsers.map((user) => Text(user)).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      );
    },
  );
}



  Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
  }

  @override
  void initState() {
    super.initState();
    // Fetch initial total people going count
    _updateTotalPeopleGoing();
    fetchAdminId();

    // Fetch the admin ID
    FirebaseFirestore.instance
        .collection('amities')
        .doc(widget.groupId)
        .get()
        .then((DocumentSnapshot groupSnapshot) {
      if (groupSnapshot.exists) {
        setState(() {
          adminId = groupSnapshot['AdminID'] ?? '';
        });
      }
    });

    // Check if the current user's UID is in the 'Attendance' map
    FirebaseFirestore.instance
        .collection('amities')
        .doc(widget.groupId)
        .collection('Events')
        .doc(widget.documentId)
        .get()
        .then((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic>? attendanceMap = snapshot['Attendance'];

        if (attendanceMap != null && attendanceMap.containsKey(uid)) {
          String status = attendanceMap[uid];
          setState(() {
            goingSelected = status == 'coming';
            notGoingSelected = status == 'not coming';
          });
        }
      }
    });

    // Fetch users who have voted
    _fetchVotedUsers();
  }

  void _updateTotalPeopleGoing() {
    FirebaseFirestore.instance
        .collection('amities')
        .doc(widget.groupId)
        .collection('Events')
        .doc(widget.documentId)
        .snapshots()
        .listen((DocumentSnapshot eventSnapshot) {
      if (eventSnapshot.exists) {
        var attendanceMap = eventSnapshot['Attendance'] as Map?;
        if (attendanceMap != null) {
          int count = attendanceMap.values.where((value) => value == 'coming').length;
          setState(() {
            totalPeopleGoing = count;
          });
        }
      }
    });
  }

  Future<void> _submitVote() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Update the 'coming' array if goingSelected is true
    if (goingSelected) {
      await FirebaseFirestore.instance
          .collection('amities')
          .doc(widget.groupId)
          .collection('Events')
          .doc(widget.documentId)
          .update({
        'Attendance.$uid': 'coming',
      });
    }

    // Update the 'not coming' array if notGoingSelected is true
    if (notGoingSelected) {
      await FirebaseFirestore.instance
          .collection('amities')
          .doc(widget.groupId)
          .collection('Events')
          .doc(widget.documentId)
          .update({
        'Attendance.$uid': 'not coming',
      });
    }

    Navigator.pop(context);
  }

  Future<void> moveDone() async {
    // Update EventStatus to 'Done'
    await FirebaseFirestore.instance
        .collection('amities')
        .doc(widget.groupId)
        .collection('Events')
        .doc(widget.documentId)
        .update({
      'EventStatus': 'Done',
    });

    // Move back a page
    Navigator.pop(context);
  }

  Future<void> _fetchVotedUsers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('amities')
        .doc(widget.groupId)
        .collection('Events')
        .doc(widget.documentId)
        .get();

    if (snapshot.exists) {
      final attendanceMap = snapshot['Attendance'] as Map<String, dynamic>?;

      if (attendanceMap != null) {
        final votedUserIds = attendanceMap.keys.toList();
        for (final userId in votedUserIds) {
          final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
          final userName = userSnapshot['name'] as String?;
          if (userName != null) {
            if (attendanceMap[userId] == 'coming') {
              setState(() {
                goingUsers.add(userName);
              });
            } else if (attendanceMap[userId] == 'not coming') {
              setState(() {
                notGoingUsers.add(userName);
              });
            }
          }
        }
      }
    }
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('amities')
                  .doc(widget.groupId)
                  .collection('Events')
                  .doc(widget.documentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return Text('No event data found');
                }

                final eventName = snapshot.data!['EventName'] as String;
                final finalDate = snapshot.data!['FinalDate'] as Timestamp;
                final formattedFinalDate = DateFormat('yyyy-MM-dd HH:mm').format(finalDate.toDate());

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventName,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Finalised Date: $formattedFinalDate',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  'Total People Going',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '$totalPeopleGoing',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          ListTile(
              title: Text('Going'),
              leading: Radio(
                value: true,
                groupValue: goingSelected ? true : null,
                onChanged: (value) {
                  setState(() {
                    goingSelected = true;
                    notGoingSelected = false;
                  });
                },
              ),
              trailing: IconButton(
                icon: Icon(Icons.open_in_full, size: 15),
                onPressed: () {
                  _showGoingUsersPopup(context);
                },
              ),
            ),

            ListTile(
              title: Text('Not Going'),
              leading: Radio(
                value: true,
                groupValue: notGoingSelected ? true : null,
                onChanged: (value) {
                  setState(() {
                    notGoingSelected = true;
                    goingSelected = false;
                  });
                },
              ),
              trailing: IconButton(
                icon: Icon(Icons.open_in_full, size: 15),
                onPressed: () {
                  _showNotGoingUsersPopup(context);
                },
              ),
            ),

        ],
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        height: 60,
        color: Colors.lightBlue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                _submitVote(); // Call _submitVote function
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Text(
                    'Submit Vote',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
            if (uid == adminId)
              GestureDetector(
                onTap: () {
                  moveDone();
                },
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.purple,
                  ),
                  child: Center(
                    child: Text(
                      'Event Done',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
