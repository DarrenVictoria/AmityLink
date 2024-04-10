import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getEventsByStatus(String groupId, String status) async {
    final snapshot = await _firestore
        .collection('amities')
        .doc(groupId)
        .collection('Events')
        .where('EventStatus', isEqualTo: status)
        .get();

    return snapshot.docs.map((doc) {
      Map<String, dynamic> eventData = doc.data();
      eventData['id'] = doc.id;
      return eventData;
    }).toList();
  }

  Future<void> saveEventData(String groupId, String eventName, String eventDescription, DateTime urgencyDate) async {
    String? adminID = FirebaseAuth.instance.currentUser?.uid;

    await _firestore.collection('amities').doc(groupId).collection('Events').add({
      'EventName': eventName,
      'EventDescription': eventDescription,
      'UrgencyDate': urgencyDate,
      'AdminID': adminID,
      'EventStatus': 'Voting',
    });
  }

  Future<void> deleteEvent(String groupId, String eventId) async {
    await _firestore.collection('amities').doc(groupId).collection('Events').doc(eventId).delete();
  }
}