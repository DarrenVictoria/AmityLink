import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:AmityLink/features/Group/MemoryPics/model/memories_model.dart';

class MemoriesDataRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<MemoryFolder>> getMemoryFolders(String groupId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('amities')
          .doc(groupId)
          .collection('MemoryPics')
          .get();
      return querySnapshot.docs
          .map((doc) => MemoryFolder.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (error) {
      throw ('Error fetching memory folders: $error');
    }
  }

  Future<void> addMemoryFolder(String groupId, MemoryFolder memoryFolder) async {
    try {
      await _firestore
          .collection('amities')
          .doc(groupId)
          .collection('MemoryPics')
          .doc()
          .set(memoryFolder.toMap());
    } catch (error) {
      throw ('Error adding memory folder: $error');
    }
  }

  Future<void> deleteMemoryFolder(String groupId, String documentId) async {
    try {
      await _firestore
          .collection('amities')
          .doc(groupId)
          .collection('MemoryPics')
          .doc(documentId)
          .delete();
    } catch (error) {
      throw ('Error deleting memory folder: $error');
    }
  }
}