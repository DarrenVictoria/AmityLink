import 'package:AmityLink/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EventsPage extends StatefulWidget {
  final String groupId;

  EventsPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final User? user = Auth().currentUser;

  Map<String, bool> _sectionStates = {
    'Upcoming': true,
    'Voting': true,
    'Done': true,
  };

  Map<String, List<Map<String, dynamic>>> _cachedEventData = {
    'Upcoming': [],
    'Voting': [],
    'Done': [],
  };

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
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Center(
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('amities')
                    .doc(widget.groupId)
                    .get(),
                builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (!snapshot.hasData || snapshot.data == null) {
                    return Text('No data found');
                  }

                  final groupName = snapshot.data!.get('GroupName') as String;

                  return Text(
                    'Events for $groupName',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildEventSection('Upcoming'),
                _buildEventSection('Voting'),
                _buildEventSection('Done'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show the bottom sheet when the FAB is clicked
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return _buildBottomSheet(context);
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventSection(String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _sectionStates[status] = !_sectionStates[status]!;
                  });
                },
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8.0),
              IconButton(
                icon: Icon(_sectionStates[status]! ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _sectionStates[status] = !_sectionStates[status]!;
                  });
                },
              ),
            ],
          ),
        ),
        _sectionStates[status]!
            ? StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('amities')
              .doc(widget.groupId)
              .collection('Events')
              .where('EventStatus', isEqualTo: status)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return SizedBox.shrink();
            } else {
              _cachedEventData[status] = snapshot.data!.docs.map((eventDoc) {
                Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
                eventData['id'] = eventDoc.id; // Add the document ID to the event data
                return eventData;
              }).toList();
              return Column(
                children: _cachedEventData[status]!.map((event) {
                  return _buildEventCard(event, status);
                }).toList(),
              );
            }
          },
        )
            : SizedBox.shrink(),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, String status) {
  String title;
  String subtitle;
  Widget button;
  Color buttonColor;
  IconData icon;
  String buttonText;

  // Extracting data from the event map
  String docId = event['id'] ?? ''; // This is the document ID
  String eventName = event['EventName'] ?? '';
  String eventDescription = event['EventDescription'] ?? '';
  Timestamp finalDate = event['FinalDate'] ?? Timestamp.now();
  DateTime finalDateTime = finalDate.toDate();
  String formattedFinalDateTime = DateFormat('yyyy-MM-dd HH:mm').format(finalDateTime);


  if (status == 'Upcoming') {
    title = eventName;
    subtitle = formattedFinalDateTime ;
    buttonText = 'Going to';
    buttonColor = Colors.lightGreen;
    icon = Icons.arrow_forward;
  } else if (status == 'Voting') {
    title = eventName;
    subtitle = eventDescription;
    buttonText = 'Date Set';
    buttonColor = Colors.lightBlue;
    icon = Icons.arrow_forward;
  } else {
    // For 'Done' status
    title = eventName;
    subtitle = formattedFinalDateTime ;
    buttonText = ''; // No button for 'Done' events
    buttonColor = Colors.transparent;
    icon = Icons.check_circle;
  }

  button = buttonText.isNotEmpty ? ElevatedButton(
    onPressed: () {
      if (status == 'Upcoming' && docId.isNotEmpty) {
        Navigator.pushNamed(context, '/attendance_poll', arguments: {'documentId': docId, 'groupId': widget.groupId}); // No need for the as String here
      }
      else if (status == 'Voting' && docId.isNotEmpty) {
          Navigator.pushNamed(context, '/attendance_date', arguments: {'documentId': docId, 'groupId': widget.groupId});
        }
         else {
        print('Event ID is null');
      }
    },
    child: Text(
      buttonText,
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(primary: buttonColor),
  ) : SizedBox.shrink();

  return Card(
    margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    child: ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: button,
      // onTap: () {
        
      // },
    ),
  );
}


Widget _buildBottomSheet(BuildContext context) {
  DateTime? selectedDate; // Variable to store the selected date
  String eventName = ''; // Variable to store the event name
  String eventDescription = ''; // Variable to store the event description

  // Method to show info popup
  void _showInfoPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Urgency Date Information'),
          content: Text('This is the date by which you would prefer the event planning to be finalised. This can be the event date or a date before the event.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  return StatefulBuilder(
    builder: (context, setState) {
      return SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Event Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              TextFormField(
                onChanged: (value) {
                  if (value.length <= 25) { // Limit the character count
                    setState(() {
                      eventName = value;
                    });
                  }
                },
                maxLength: 25, // Set max length
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40.0), // Circular edges
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              TextFormField(
                onChanged: (value) {
                  setState(() {
                    eventDescription = value;
                  });
                },
                maxLength: 80,
                maxLines: null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40.0), // Circular edges
                  ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Urgency Date ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 1),
                  GestureDetector(
                    onTap: _showInfoPopup,
                    child: Icon(
                      Icons.info_outline,
                      size: 16, // Set the size of the icon
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate; // Update the selected date
                          });
                        }
                      },
                      child: Text('Select Date'),
                    ),
                  ),
                ],
              ),
              if (selectedDate != null) // Show selected date if available
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Selected Date: ${selectedDate!.toString().substring(0, 10)}',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Add functionality to save the event data to Firestore
                    _saveEventData(eventName, eventDescription, selectedDate);
                  },
                  child: Text('Create Event'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Method to save event data to Firestore and clear fields on success
void _saveEventData(String eventName, String eventDescription, DateTime? selectedDate) {
  if (eventName.isNotEmpty && eventDescription.isNotEmpty && selectedDate != null) {
    // Get the current user ID from FirebaseAuth
    String? adminID = FirebaseAuth.instance.currentUser?.uid;

    // Add data to Firestore
    FirebaseFirestore.instance.collection('amities').doc(widget.groupId).collection('Events').add({
      'EventName': eventName,
      'EventDescription': eventDescription,
      'UrgencyDate': selectedDate,
      'AdminID': adminID,
      'EventStatus': 'Voting', // Set the initial status to 'Voting'
    }).then((value) {
      // Data added successfully
      print('Event data added to Firestore');

      // Clear fields and close bottom sheet
      setState(() {
        eventName = '';
        eventDescription = '';
        selectedDate = null;
      });
      
      Navigator.of(context).pop(); // Close the bottom sheet
    }).catchError((error) {
      // Error handling
      print('Failed to add event data: $error');
    });
  } else {
    // Fields are empty, display an error message or handle accordingly
    print('Please fill in all fields');
  }       
}

  // Method to show date picker
  Future<void> _selectUrgencyDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      // Do something with the selected date
    }
  }
}
