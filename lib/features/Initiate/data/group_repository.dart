import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class GroupRepository {
  Future<void> createGroup(String title, String description, String? imageUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('amities').add({
        'GroupName': title,
        'GroupDescription': description,
        'GroupProfilePicture': imageUrl,
        'Admin': user.uid,
        'GroupMembers': [user.uid],
      });
    }
  }

  Future<String> uploadImageToStorage(String imagePath) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference = FirebaseStorage.instance.ref().child('group_profile_pictures/$fileName');
    UploadTask uploadTask = storageReference.putFile(File(imagePath));
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    return await taskSnapshot.ref.getDownloadURL();
  }
}