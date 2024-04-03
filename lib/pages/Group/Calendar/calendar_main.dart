import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';
import 'package:intl/intl.dart';

class Calendar extends StatelessWidget {
  final String groupId;

  Calendar({required this.groupId});

  @override
  Widget build(BuildContext context) {
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('amities')
                  .doc(groupId)
                  .collection('Events')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<DateTime> urgencyDates = [];
                  for (var doc in snapshot.data!.docs) {
                    var eventMap = doc.data() as Map<String, dynamic>;
                    var urgencyDate = eventMap['UrgencyDate'];
                    if (urgencyDate != null) {
                      DateTime urgencyDateTime = urgencyDate.toDate();
                      if (urgencyDateTime.isAfter(DateTime.now())) {
                        urgencyDates.add(urgencyDateTime);
                      }
                    }
                  }

                  return TableCalendar(
                    focusedDay: today,
                    firstDay: firstDay,
                    lastDay: lastDay,
                    calendarFormat: CalendarFormat.month,
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (urgencyDates.any((urgencyDate) => isSameDay(urgencyDate, date))) {
                          return CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Text(
                              date.day.toString(),
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('amities')
                  .doc(groupId)
                  .collection('Events')
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
                      var urgencyDate = eventMap['UrgencyDate'];
                      if (urgencyDate != null) {
                        DateTime urgencyDateTime = urgencyDate.toDate();
                        if (urgencyDateTime.isAfter(DateTime.now())) {
                          final formattedDate = DateFormat.yMd().format(urgencyDateTime);
                          return ListTile(
                            title: Text(
                              eventName,
                              style: TextStyle(color: Color.fromARGB(255, 101, 1, 163)),
                            ),
                            subtitle: Text(
                              'Vote by: $formattedDate',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }
                      }
                      return SizedBox();
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
      
    );
  }
}