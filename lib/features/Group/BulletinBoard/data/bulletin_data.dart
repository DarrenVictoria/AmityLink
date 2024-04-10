import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:AmityLink/auth.dart';
import 'package:image_picker/image_picker.dart';
Future<void> signOut(BuildContext context) async {
  await Auth().signOut();
}

Future<String?> uploadImageToStorage(File? imageFile) async {
  if (imageFile == null) return null;

  final storageRef = FirebaseStorage.instance.ref().child('forum_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
  final uploadTask = storageRef.putFile(imageFile);
  final snapshot = await uploadTask.whenComplete(() {});

  final imageUrl = await snapshot.ref.getDownloadURL();
  return imageUrl;
}

Future<void> sendLocation(BuildContext context, String groupId) async {
  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Send Location?'),
        content: Text('Do you want to send your current location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              addLocationPost(position, groupId);
            },
            child: Text('Send'),
          ),
        ],
      );
    },
  );
}

Future<void> addLocationPost(Position position, String groupId) async {
  String title = 'Hey, I\'m here now';
  Timestamp timestamp = Timestamp.now();
  String uid = FirebaseAuth.instance.currentUser!.uid;

  try {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userSnapshot.exists) {
      String userName = userSnapshot.get('name');

      await FirebaseFirestore.instance.collection('amities').doc(groupId).collection('BulletinBoard').add({
        'Title': title,
        'Content': userName,
        'Location': GeoPoint(position.latitude, position.longitude),
        'uid': uid,
        'timestamp': timestamp,
      });
    } else {
      print('User data not found for UID: $uid');
    }
  } catch (e) {
    print('Error adding location post: $e');
  }
}


Future<void> addForumPost(
  String groupId,
  String title,
  String content,
  String? imageUrl,
  String uid,
  Timestamp timestamp,
) async {
  await FirebaseFirestore.instance.collection('amities').doc(groupId).collection('BulletinBoard').add({
    'Title': title,
    'Content': content,
    'ImageURL': imageUrl,
    'uid': uid,
    'timestamp': timestamp,
    'Comments': {},
    'Likes': [],
  });
}

