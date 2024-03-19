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
import 'package:image_picker/image_picker.dart';

class IndividualMemoryPage extends StatefulWidget {
  final String groupId;
  final String documentId;

  IndividualMemoryPage({Key? key, required this.groupId, required this.documentId}) : super(key: key);

  @override
  _IndividualMemoryPageState createState() => _IndividualMemoryPageState();
}

class _IndividualMemoryPageState extends State<IndividualMemoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();


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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: () => _downloadAllMedia(context),
            icon: Icon(Icons.download),
            label: Text('Download All'),
            backgroundColor: Colors.blue,
          ),
          SizedBox(height: 16.0),
          FloatingActionButton.extended(
            onPressed: () => _addFootage(context),
            icon: Icon(Icons.add),
            label: Text('Add Footage'),
            backgroundColor: Colors.blue,
          ),
        ],
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
          .doc(widget.groupId)
          .collection('MemoryPics')
          .doc(widget.documentId)
          .get();
      return documentSnapshot;
    } catch (error) {
      throw ('Error fetching memory document: $error');
    }
  }

        void _downloadAllMedia(BuildContext context) async {
        final DocumentSnapshot documentSnapshot = await _fetchMemoryDocument();
        final footage = documentSnapshot.get('Footage') as List<dynamic>? ?? [];

        for (String mediaUrl in footage) {
          try {
            var request = await HttpClient().getUrl(Uri.parse(mediaUrl));
            var response = await request.close();
            Uint8List bytes = await consolidateHttpClientResponseBytes(response);
            final result = await ImageGallerySaver.saveImage(bytes);
            if (result == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to download $mediaUrl'),
                ),
              );
            }
          } on PlatformException catch (e) {
            print('Failed to save media: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to download $mediaUrl'),
              ),
            );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All media downloaded successfully'),
          ),
        );
      }

      Future<void> _addFootage(BuildContext context) async {
  try {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Upload picked image to Firebase Storage
      await _uploadToStorage(File(pickedFile.path));
      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image uploaded successfully')));
      // Refresh FutureBuilder
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No image selected')));
    }
  } catch (e) {
    print('Error selecting image: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to select image')));
  }
}


  Future<void> _uploadToStorage(File file) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final Reference reference = _storage.ref().child('amities/${widget.groupId}/MemoryPics/${widget.documentId}/$fileName');
      await reference.putFile(file);
      final String downloadUrl = await reference.getDownloadURL();
      // Update Firestore document with downloadUrl
      await _updateFirestore(downloadUrl);
    } catch (e) {
      print('Error uploading file to storage: $e');
      throw Exception('Failed to upload file to storage');
    }
  }

  Future<void> _updateFirestore(String downloadUrl) async {
    try {
      await _firestore.collection('amities').doc(widget.groupId).collection('MemoryPics').doc(widget.documentId).update({
        'Footage': FieldValue.arrayUnion([downloadUrl]),
      });
    } catch (e) {
      print('Error updating Firestore document: $e');
      throw Exception('Failed to update Firestore document');
    }
  }


}
