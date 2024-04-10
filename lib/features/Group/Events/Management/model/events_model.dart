import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String eventName;
  final String eventDescription;
  final DateTime urgencyDate;
  final String adminID;
  final String eventStatus;

  Event({
    required this.id,
    required this.eventName,
    required this.eventDescription,
    required this.urgencyDate,
    required this.adminID,
    required this.eventStatus,
  });

  factory Event.fromMap(Map<String, dynamic> data, String documentId) {
    return Event(
      id: documentId,
      eventName: data['EventName'],
      eventDescription: data['EventDescription'],
      urgencyDate: (data['UrgencyDate'] as Timestamp).toDate(),
      adminID: data['AdminID'],
      eventStatus: data['EventStatus'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'EventName': eventName,
      'EventDescription': eventDescription,
      'UrgencyDate': urgencyDate,
      'AdminID': adminID,
      'EventStatus': eventStatus,
    };
  }
}