import 'package:cloud_firestore/cloud_firestore.dart';

class GroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> joinGroup(String groupId, String userId) async {
    await _firestore.collection('amities').doc(groupId).update({
      'GroupMembers': FieldValue.arrayUnion([userId]),
    });
  }
}