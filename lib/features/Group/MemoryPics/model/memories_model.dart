import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryFolder {
  final String id;
  final String eventName;
  final DateTime finalDate;
  final List<dynamic> footage;

  MemoryFolder({
    required this.id,
    required this.eventName,
    required this.finalDate,
    required this.footage,
  });

  factory MemoryFolder.fromMap(Map<String, dynamic> data, String documentId) {
    return MemoryFolder(
      id: documentId,
      eventName: data['EventName'],
      finalDate: (data['FinalDate'] as Timestamp).toDate(),
      footage: data['Footage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'EventName': eventName,
      'FinalDate': finalDate,
      'Footage': footage,
    };
  }
}