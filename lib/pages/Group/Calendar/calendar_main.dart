import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:AmityLink/NavFooter/usertopnav.dart';

class Calendar extends StatelessWidget {
  final String groupId;

  Calendar({required this.groupId});

  @override
  Widget build(BuildContext context) {
    // Define variables for the focusedDay, firstDay, and lastDay
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime firstDay = DateTime(now.year, now.month - 3, now.day);
    final DateTime lastDay = DateTime(now.year, now.month + 3, now.day);

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
            // Handle sign out
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TableCalendar(
              focusedDay: today,
              firstDay: firstDay,
              lastDay: lastDay,
              calendarFormat: CalendarFormat.month,
              // Add more calendar properties and callbacks as needed
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('amities')
                  .doc(groupId) // Use groupId to access the document
                  .collection('Events') // Access the Events collection
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    padding: EdgeInsets.all(16.0),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var event = snapshot.data!.docs[index];
                      var eventName = event['EventName'];
                      var eventMap = event.data() as Map<String, dynamic>;
                      var finalDate = eventMap['FinalDate'];
                      var urgencyDate = eventMap['UrgencyDate'];
                      var displayDate = finalDate != null ? finalDate.toDate() : (urgencyDate != null ? urgencyDate.toDate() : null); // Use FinalDate if available, else use UrgencyDate
                      var subtitle = finalDate != null ? 'Event Done Date: $displayDate' : (urgencyDate != null ? 'Vote by: $displayDate' : ''); // Set subtitle based on whether it's FinalDate or UrgencyDate
                      var subtitleColor = finalDate != null ? Colors.black : Colors.red; // Set subtitle color based on whether it's FinalDate or UrgencyDate
                      if (displayDate != null) {
                        return ListTile(
                          title: Text(
                            eventName,
                            style: TextStyle(color: Color.fromARGB(255, 101, 1, 163)), // Show event name in red color
                          ),
                          subtitle: Text(
                            subtitle,
                            style: TextStyle(color: subtitleColor), // Set subtitle text color based on the type of date
                          ),
                        );
                      } else {
                        return SizedBox(); // Return an empty widget if neither date exists
                      }
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle adding events
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
