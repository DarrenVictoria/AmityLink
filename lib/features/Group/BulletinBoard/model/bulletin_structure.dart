import 'package:cloud_firestore/cloud_firestore.dart';

class ForumPost {
  final String uid;
  final String title;
  final String content;
  final String imageUrl;
  final Map<String, String> comments;
  final List<String> likes;
  final GeoPoint? location;

  ForumPost({
    required this.uid,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.comments,
    required this.likes,
    this.location,
  });
}