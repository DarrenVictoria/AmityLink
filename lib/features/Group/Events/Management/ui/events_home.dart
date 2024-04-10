import 'package:AmityLink/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:AmityLink/features/Group/Events/Management/data/events_data.dart';
import 'package:AmityLink/features/Group/Events/Management/model/events_model.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';


class EventsPageUI extends StatefulWidget {
  final String groupId;

  EventsPageUI({Key? key, required this.groupId}) : super(key: key);

  @override
  _EventsPageUIState createState() => _EventsPageUIState();
}

class _EventsPageUIState extends State<EventsPageUI> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, bool> _sectionStates = {
    'Upcoming': true,
    'Voting': true,
    'Done': true,
  };

   Map<String, List<Event>> _cachedEventData = {
    'Upcoming': [],
    'Voting': [],
    'Done': [],
  };

  @override
  void initState() {
    super.initState();
    // Fetch events from Firestore and populate _cachedEventData
    _fetchEvents();
  }

 


  Future<void> _refreshEvents() async {
  await _fetchEvents(); // Refresh events data
  setState(() {}); // Update the UI
}


   Future<void> _fetchEvents() async {
    try {
      final upcomingEvents = await FirestoreService().getEventsByStatus(widget.groupId, 'Upcoming');
      final votingEvents = await FirestoreService().getEventsByStatus(widget.groupId, 'Voting');
      final doneEvents = await FirestoreService().getEventsByStatus(widget.groupId, 'Done');
      
      setState(() {
        _cachedEventData['Upcoming'] = upcomingEvents.map((eventData) => Event.fromMap(eventData, eventData['id'])).toList();
        _cachedEventData['Voting'] = votingEvents.map((eventData) => Event.fromMap(eventData, eventData['id'])).toList();
        _cachedEventData['Done'] = doneEvents.map((eventData) => Event.fromMap(eventData, eventData['id'])).toList();
      });
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  Future<void> _signOut(BuildContext context) async {
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
            _signOut(context);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: Center(
                child: FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('amities').doc(widget.groupId).get(),
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
                  _buildEventSection('Upcoming', _cachedEventData['Upcoming']!),
                  _buildEventSection('Voting', _cachedEventData['Voting']!),
                  _buildEventSection('Done', _cachedEventData['Done']!),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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

  Widget _buildEventSection(String status, List<Event> events) {
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
            ? Column(
                children: events.map((event) {
                  return _buildEventCard(event);
                }).toList(),
              )
            : SizedBox.shrink(),
      ],
    );
  }

  Widget _buildEventCard(Event event) {
  String title;
  String subtitle;
  Widget button;
  Color buttonColor;
  IconData icon;
  String buttonText;

  if (event.eventStatus == 'Upcoming') {
    title = event.eventName;
    subtitle = DateFormat('yyyy-MM-dd HH:mm').format(event.urgencyDate);
    buttonText = 'Going to';
    buttonColor = Colors.lightGreen;
    icon = Icons.arrow_forward;
  } else if (event.eventStatus == 'Voting') {
    title = event.eventName;
    subtitle = event.eventDescription;
    buttonText = 'Date Set';
    buttonColor = Colors.lightBlue;
    icon = Icons.arrow_forward;
  } else {
    // For 'Done' status
    title = event.eventName;
    subtitle = DateFormat('yyyy-MM-dd HH:mm').format(event.urgencyDate);
    buttonText = ''; // No button for 'Done' events
    buttonColor = Colors.transparent;
    icon = Icons.check_circle;
  }

  button = buttonText.isNotEmpty
      ? ElevatedButton(
          onPressed: () {
            if (event.eventStatus == 'Upcoming') {
              Navigator.pushNamed(context, '/attendance_poll', arguments: {'documentId': event.id, 'groupId': widget.groupId});
            } else if (event.eventStatus == 'Voting') {
              Navigator.pushNamed(context, '/attendance_date', arguments: {'documentId': event.id, 'groupId': widget.groupId});
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
        )
      : SizedBox.shrink();

  return Dismissible(
    key: Key(event.id),
    background: Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20.0),
      child: Icon(Icons.delete, color: Colors.white),
    ),
    child: Card(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: button,
      ),
    ),
    direction: DismissDirection.endToStart,
    confirmDismiss: (direction) async {
      return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Confirm"),
            content: Text("Are you sure you want to delete this event?"),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text("Delete Event"),
              ),
            ],
          );
        },
      );
    },
    onDismissed: (direction) {
      // Delete the document from Firestore
      FirestoreService().deleteEvent(widget.groupId, event.id);
    },
  );
}


  Widget _buildBottomSheet(BuildContext context) {
    DateTime? selectedDate;
    String eventName = '';
    String eventDescription = '';

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
                    onPressed: () async {
                          if (eventName.isNotEmpty && eventDescription.isNotEmpty && selectedDate != null) {
                            await FirestoreService().saveEventData(
                              widget.groupId,
                              eventName,
                              eventDescription,
                              selectedDate!,
                            );
                            Navigator.of(context).pop(); // Close the bottom sheet
                            _refreshEvents(); // Refresh events data
                          } else {
                            // Display an error message or handle accordingly
                            print('Please fill in all fields');
                          }
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
}