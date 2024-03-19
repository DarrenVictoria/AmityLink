import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:AmityLink/auth.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class IndividualMemoryPage extends StatelessWidget {
  final String groupId;
  final String documentId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  IndividualMemoryPage({Key? key, required this.groupId, required this.documentId}) : super(key: key);

  Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: TopNavigationBar(
          onBack: () {
            Navigator.of(context).pop();
          },
          onDashboardSelected: () {
            Navigator.pushNamed(context, '/dashboard');
          },
          onSignOutSelected: () {
            signOut(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            // Display EventName from the document
            FutureBuilder<DocumentSnapshot>(
              future: _fetchMemoryDocument(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final eventName = snapshot.data!.get('EventName') ?? 'Event Name Not Available';
                  final footageCount = (snapshot.data!.get('Footage') as List<dynamic>?)?.length ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName,
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      // Display footage count
                      Text(
                        'Footage Count: $footageCount',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  );
                }
              },
            ),
            SizedBox(height: 20),
            // Thumbnails for images
            FutureBuilder<DocumentSnapshot>(
              future: _fetchMemoryDocument(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final footage = snapshot.data!.get('Footage') as List<dynamic>? ?? [];
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: footage.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final mediaUrl = footage[index];
                      return GestureDetector(
                        onTap: () {
                          _showMediaDialog(context, mediaUrl);
                        },
                        child: Container(
                          color: Colors.grey[300],
                          child: Image.network(
                            mediaUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaDialog(BuildContext context, String mediaUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Stack(
            children: [
              // Media display
              GestureDetector(
                onTap: () {
                  // Do something when tapped
                },
                child: Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                ),
              ),
              // Back button
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              // Download button
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 0), // changes position of shadow
                      ),
                    ],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.download),
                    onPressed: () {
                      _downloadMedia(context, mediaUrl); // Pass the context here
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Download media to device
  void _downloadMedia(BuildContext context, String mediaUrl) async {
    try {
      var request = await HttpClient().getUrl(Uri.parse(mediaUrl));
      var response = await request.close();
      Uint8List bytes = await consolidateHttpClientResponseBytes(response);
      final result = await ImageGallerySaver.saveImage(bytes);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Media downloaded successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download media')));
      }
    } on PlatformException catch (e) {
      print('Failed to save media: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download media')));
    }
  }

  // Fetch the memory document from Firestore based on groupId and documentId
  Future<DocumentSnapshot> _fetchMemoryDocument() async {
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('amities')
          .doc(groupId)
          .collection('MemoryPics')
          .doc(documentId)
          .get();
      return documentSnapshot;
    } catch (error) {
      throw ('Error fetching memory document: $error');
    }
  }
}
