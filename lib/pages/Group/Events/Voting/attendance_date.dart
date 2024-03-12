import 'package:flutter/material.dart';
import 'package:AmityLink/auth.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceDatePage extends StatefulWidget {
  final String documentId;
  final String groupId;

  const AttendanceDatePage({Key? key, required this.documentId, required this.groupId}) : super(key: key);

  @override
  _AttendanceDatePageState createState() => _AttendanceDatePageState();
}

class _AttendanceDatePageState extends State<AttendanceDatePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, dynamic> dateOptionsMap = {};

  String uid = FirebaseAuth.instance.currentUser!.uid;
  String? adminId;

  late String eventName = '';
  late String eventDescription = '';
  late List<DateTime> dateOptions = [];
  Set<String> votedUids = {}; // Set to store UIDs of users who have voted
  late String selectedDate = ''; // Define selectedDate variable
  late String selectedTime = ''; // Define selectedTime variable

  @override
  void initState() {
    super.initState();
    _fetchEventData();
    _fetchAdminId();
  }

  Future<void> _fetchAdminId() async {
    try {
      DocumentSnapshot eventSnapshot = await _firestore.collection('amities').doc(widget.groupId).collection('Events').doc(widget.documentId).get();
      Map<String, dynamic>? eventData = eventSnapshot.data() as Map<String, dynamic>?;

      if (eventData != null) {
        setState(() {
          adminId = eventData['AdminID'];
        });
      }
    } catch (error) {
      print('Error fetching AdminID: $error');
    }
  }


  Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
  }

  Future<void> _fetchEventData() async {
    try {
      DocumentSnapshot eventSnapshot = await _firestore.collection('amities').doc(widget.groupId).collection('Events').doc(widget.documentId).get();
      Map<String, dynamic>? eventData = eventSnapshot.data() as Map<String, dynamic>?;

      if (eventData != null) {
        setState(() {
          eventName = eventData['EventName'] ?? '';
          eventDescription = eventData['EventDescription'] ?? '';

          // Populate the dateOptionsMap with voting data
          dateOptionsMap = (eventData['DateOptions'] as Map<String, dynamic>?) ?? {};

          // Populate the votedUids set with the user IDs who have voted
          dateOptionsMap.keys.forEach((uid) {
            votedUids.add(uid);
          });

          // Check if the date options map exists and is not empty
          if (dateOptionsMap.isNotEmpty) {
            // Clear existing date options
            dateOptions.clear();

            // Iterate over the date options map
            dateOptionsMap.values.forEach((timestamp) {
              // Convert timestamp to DateTime and add to dateOptions list
              dateOptions.add((timestamp as Timestamp).toDate());
            });
          }
        });
      }
    } catch (error) {
      print('Error fetching event data: $error');
    }
  }

  void _handleDateSelection(DateTime date) {
    final formatter = DateFormat('yyyy-MM-dd');
    selectedDate = formatter.format(date);
    setState(() {});
  }

  void _handleTimeSelection(TimeOfDay time) {
    final formatter = DateFormat('HH:mm');
    selectedTime = formatter.format(DateTime(2024, 1, 1, time.hour, time.minute));
    setState(() {});
  }

  void _submitRequestDate() {
    _selectDateAndTime(context);
  }

  Future<void> _selectDateAndTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        _handleDateSelection(pickedDate);
        _handleTimeSelection(pickedTime);
      }
    }
  }

  Future<void> _requestDate(BuildContext context) async {
    try {
      if (selectedDate.isEmpty || selectedTime.isEmpty) {
        print('Selected date or time is empty. Aborting request.');
        return;
      }

      // Show snackbar to indicate that the date is being updated
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Updating date and time..."),
            ],
          ),
          duration: Duration(seconds: 2), // Adjust duration as needed
        ),
      );

      // Convert the selected date and time to a DateTime object
      DateTime selectedDateTime = DateTime.parse('$selectedDate $selectedTime');

      // Convert the selected date to a timestamp
      Timestamp timestamp = Timestamp.fromDate(selectedDateTime);

      if (votedUids.contains(uid)) {
        // If the user has already voted, update their vote
        await _firestore
            .collection('amities')
            .doc(widget.groupId)
            .collection('Events')
            .doc(widget.documentId)
            .update({
          'DateOptions.$uid': timestamp,
        });
      } else {
        // If the user hasn't voted yet, add their vote
        await _firestore
            .collection('amities')
            .doc(widget.groupId)
            .collection('Events')
            .doc(widget.documentId)
            .update({
          'DateOptions.$uid': timestamp,
        });

        // Update votedUids locally
        votedUids.add(uid);
      }

      setState(() {
        // Remove the old selected date from dateOptions list
        dateOptions.removeWhere((date) => DateFormat('yyyy-MM-dd HH:mm').format(date) == '$selectedDate $selectedTime');

        // Add the new selected date to dateOptions list
        dateOptions.add(selectedDateTime);

        // Update selectedDate
        selectedDate = DateFormat('yyyy-MM-dd').format(selectedDateTime);
        selectedTime = DateFormat('HH:mm').format(selectedDateTime);
      });

      print('Date requested successfully');
    } catch (error) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting date: $error'),
        ),
      );
      print('Error requesting date: $error');
    }
  }

  Map<String, int> countVotes() {
    Map<String, int> votesCount = {};
    dateOptions.forEach((date) {
      String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(date);
      votesCount.update(formattedDateTime, (value) => value + 1, ifAbsent: () => 1);
    });
    return votesCount;
  }

  void _showFinalizeDatesPopup(Map<String, int> votesCount) {
  String selectedDate = '';
  String selectedTime = '';

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, setState) {
          return AlertDialog(
            title: Text('Finalize Dates'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose from existing options:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: votesCount.entries.map((entry) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDate = entry.key.split(' ')[0];
                            selectedTime = entry.key.split(' ')[1];
                          });
                        },
                        child: Card(
                          color: selectedDate == entry.key.split(' ')[0] && selectedTime == entry.key.split(' ')[1] ? Colors.blueAccent : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key.split(' ')[0]), // Date
                                Text(entry.key.split(' ')[1]), // Time
                                Text(
                                  '${entry.value}',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ), // Vote count
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Or select a new date and time:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                              });
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(selectedDate.isNotEmpty ? selectedDate : 'Select Date'),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                selectedTime = pickedTime.format(context);
                              });
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(selectedTime.isNotEmpty ? selectedTime : 'Select Time'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _finalizeDates(selectedDate, selectedTime);
                  Navigator.of(context).pop();
                },
                child: Text('Finalize'),
              ),
            ],
          );
        },
      );
    },
  );
}

void _finalizeDates(String selectedDate, String selectedTime) async {
  try {
    if (selectedDate.isEmpty || selectedTime.isEmpty) {
      print('Selected date or time is empty. Aborting finalization.');
      return;
    }

    // Convert the selected date and time to a DateTime object
    DateTime selectedDateTime = DateFormat('yyyy-MM-dd hh:mm a').parse('$selectedDate $selectedTime');

    // Convert the selected date to a timestamp
    Timestamp timestamp = Timestamp.fromDate(selectedDateTime);

    // Update the Firestore document with the finalized date and time
    await _firestore
      .collection('amities')
      .doc(widget.groupId)
      .collection('Events')
      .doc(widget.documentId)
      .update({
        'FinalDate': timestamp,
        'EventStatus': 'Upcoming',
      });

    print('Dates finalized successfully');
    Navigator.pop(context);
  } catch (error) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error finalizing dates: $error'),
      ),
    );
    print('Error finalizing dates: $error');
  }
}



  @override
  Widget build(BuildContext context) {
    Map<String, int> votesCount = countVotes();

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$eventName',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '$eventDescription',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Votes Summary:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              // Display symbol and text when there are no votes
              if (votesCount.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Nothing here yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              if (votesCount.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: votesCount.entries.map((entry) {
                    return GestureDetector(
                      onTap: () {
                        _showVotersDialog(entry.key);
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key.split(' ')[0]), // Date
                              Text(entry.key.split(' ')[1]), // Time
                              Text('${entry.value} people voted'), // Vote count
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              SizedBox(height: 20),
              Center(
                child: Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitRequestDate,
                    child: Text('Suggest an event date and time'),
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (selectedDate.isNotEmpty && selectedTime.isNotEmpty)
                Center(
                  child: Text(
                    'You selected: $selectedDate at $selectedTime',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              SizedBox(height: 20),
            ],
          ),
        ),
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
                if (selectedDate.isNotEmpty && selectedTime.isNotEmpty) {
                  print('Request Date button pressed');
                  _requestDate(context); // Pass the context here
                  Navigator.pop(context); // Navigate back one page
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select a date and time first.'),
                    ),
                  );
            }
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Text(
                    'Request Date & Time',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
            if (uid == adminId) // Show the "Finalize Dates" button only if the current user is the admin
              GestureDetector(
                onTap: () {
                  _showFinalizeDatesPopup(votesCount);
                },
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    // borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Finalise Dates',
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

  void _showVotersDialog(String selectedDateTime) async {
    List<String> voterNames = [];

    // Fetch user data for each voted UID
    for (String uid in votedUids) {
      if (dateOptionsMap.containsKey(uid) &&
          DateFormat('yyyy-MM-dd HH:mm').format(dateOptionsMap[uid].toDate()) == selectedDateTime) {
        DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(uid).get();
        if (userSnapshot.exists) {
          Map<String, dynamic>? userData = userSnapshot.data() as Map<String, dynamic>?;
          String userName = userData?['name'] ?? 'Unknown';
          voterNames.add(userName);
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Voters for $selectedDateTime'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: voterNames.map((userName) {
                return Text(userName);
              }).toList(),
            ),
          ),
          actions: <Widget>[
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

  
}
