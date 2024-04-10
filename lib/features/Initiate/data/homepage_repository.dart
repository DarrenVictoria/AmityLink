import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:AmityLink/features/Initiate/model/group.dart';

class GroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Group>> getJoinedGroups(String userId) async {
    final querySnapshot = await _firestore
        .collection('amities')
        .where('GroupMembers', arrayContains: userId)
        .get();

    return querySnapshot.docs.map((doc) {
      return Group(
        id: doc.id,
        name: doc['GroupName'] as String?,
        profilePictureUrl: doc['GroupProfilePicture'] as String?,
      );
    }).toList();
  }
}