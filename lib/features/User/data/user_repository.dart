import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserRepository {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Future<Map<String, dynamic>> fetchUserData() async {
    final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userSnapshot.exists) {
      return userSnapshot.data()!;
    } else {
      throw Exception('User data not found.');
    }
  }

  Future<void> updateUserName(String newName) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'name': newName,
    });
  }

  Future<void> updateUserProfilePicture(String newImageUrl) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'ProfilePicture': newImageUrl,
    });
  }

  Future<void> updateFeelingStatus(int value) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'FeelingStatus': value,
    });
  }

  Future<void> deleteUserAccount() async {
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
  }

  Future<String> uploadImageToStorage(String imagePath) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference = FirebaseStorage.instance.ref().child('user_profile_pictures/$fileName');
    UploadTask uploadTask = storageReference.putFile(File(imagePath));
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    return await taskSnapshot.ref.getDownloadURL();
  }
}