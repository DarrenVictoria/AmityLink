import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:AmityLink/auth.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:path_provider/path_provider.dart';


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
  late FijkPlayer _player;
  late Future<DocumentSnapshot> _memoryDocument;


  @override
  void initState() {
    super.initState();
    _player = FijkPlayer();
     _memoryDocument = _fetchMemoryDocument();
  }

  @override
  void dispose() {
    _player.release();
    super.dispose();
  }

  Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
  }

  

  

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
            future: _memoryDocument,
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
          // Thumbnails for images and videos
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80.0), // Adjust bottom padding for button space
              child: FutureBuilder<DocumentSnapshot>(
                future: _memoryDocument,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    final footage = snapshot.data!.get('Footage') as List<dynamic>? ?? [];
                    return SingleChildScrollView(
                      child: GridView.builder(
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
                              _handleMediaTap(mediaUrl);
                            },
                            child: Container(
                              color: Colors.grey[300],
                              child: _buildMediaThumbnail(mediaUrl),
                            ),
                          );
                        },
                      ),
                    );
                  }
                },
              ),
            ),
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


Widget _buildMediaThumbnail(String mediaUrl) {
  // Check if media is video
  if (_isVideo(mediaUrl)) {
    // Return video thumbnail
    return GestureDetector(
      onLongPress: () {
        _showDeleteDialog(context, mediaUrl);
      },
      child: _buildVideoThumbnail(mediaUrl),
    );
  } else {
    // Show image thumbnail for images
    return GestureDetector(
      onLongPress: () {
        _showDeleteDialog(context, mediaUrl);
      },
      child: Image.network(mediaUrl, fit: BoxFit.cover),
    );
  }
}

 Future<Uint8List?> _captureVideoThumbnail(String videoUrl) async {
  try {
    // Create a new FijkPlayer instance
    final FijkPlayer player = FijkPlayer();

    // Initialize the player with the video URL
    await player.setDataSource(videoUrl, autoPlay: false);

    // Wait until the player is prepared
    await player.setupSurface();

    // Capture the video thumbnail
    Uint8List? thumbnailBytes = await player.takeSnapShot();

    // Release the player resources
    player.release();

    // If thumbnailBytes is null, return a placeholder image
    if (thumbnailBytes == null) {
      // You can use a package like 'flutter_svg' to load an SVG placeholder image
      // or use a built-in placeholder image from your assets
      final placeholderImage = await rootBundle.load('assets/images/video_thumbnail_placeholder.jpg');
      return placeholderImage.buffer.asUint8List();
    }

    return thumbnailBytes;
  } catch (e) {
    print('Error capturing video thumbnail: $e');
    return null;
  }
}



Widget _buildVideoThumbnail(String videoUrl) {
  return FutureBuilder<Uint8List?>(
    future: _captureVideoThumbnail(videoUrl),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else if (snapshot.hasData) {
        return Image.memory(snapshot.data!, fit: BoxFit.cover);
      } else {
        // Return a placeholder or default thumbnail image
        return Image.asset('assets/images/video_thumbnail_placeholder.jpg', fit: BoxFit.cover);
      }
    },
  );
}



  bool _isVideo(String mediaUrl) {
    return mediaUrl.toLowerCase().contains('.mp4');
  }


  void _handleMediaTap(String mediaUrl) {
  // Check if media is video
  if (_isVideo(mediaUrl)) {
    // Play the video directly
    _playVideo(mediaUrl);
  } else {
    // Show image in dialog for images
    _showMediaDialog(context, mediaUrl);
  }
}


  // void _playVideo(String videoUrl) {
  //   _player.setDataSource(videoUrl, autoPlay: true);
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Dialog(
  //         child: FijkView(
  //           player: _player,
  //         ),
  //       );
  //     },
  //   );
  // }

  void _playVideo(String videoUrl) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return _showVideoDialog(videoUrl);
    },
  );
}

Widget _showVideoDialog(String videoUrl) {
  return WillPopScope(
    onWillPop: () async {
      _player.release(); // Release the player when the back button is pressed
      return true;
    },
    child: Dialog(
      child: StatefulBuilder(
        builder: (BuildContext context, setState) {
          // Reinitialize the player instance
          _player = FijkPlayer(); // <-- Create a new instance here

          // Initialize the player with the video URL
          _player.setDataSource(videoUrl, autoPlay: true);

          return Stack(
            children: [
              // Video player
              FijkView(
                player: _player,
                panelBuilder: (_, __, context, ___, ____) {
                  return Container(); // Returning an empty container to prevent errors
                },
              ),
              // Back button
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    _player.release(); // Release the player when the dialog is closed
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
                      downloadVideo(videoUrl, context);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

// Function to download video from URL and save it to device gallery
Future<void> downloadVideo(String videoUrl, BuildContext context) async {
  try {
    // Check if the video format is supported
    final isSupported = await _isSupportedVideoFormat(videoUrl);
    if (!isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unsupported video format')));
      return;
    }

    // Get temporary directory path to store the downloaded video
    final Directory tempDir = await getTemporaryDirectory();
    final String tempPath = tempDir.path;
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final File videoFile = File('$tempPath/$fileName');

    // Send a GET request to fetch the video
    final http.Response response = await http.get(Uri.parse(videoUrl));

    // Check if the request was successful
    if (response.statusCode == 200) {
      // Save the video to the temporary file
      await videoFile.writeAsBytes(response.bodyBytes);

      // Save the video to the device gallery
      final result = await ImageGallerySaver.saveFile(videoFile.path);

      // Show appropriate message based on the result
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video downloaded successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save video to gallery')));
      }
    } else {
      // Show error message if the request failed
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download video: ${response.reasonPhrase}')));
    }
  } catch (e) {
    // Show error message if an exception occurs
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading video: $e')));
  }
}

Future<void> _downloadImage(String imageUrl, BuildContext context) async {
    try {
      var request = await HttpClient().getUrl(Uri.parse(imageUrl));
      var response = await request.close();
      Uint8List bytes = await consolidateHttpClientResponseBytes(response);
      final result = await ImageGallerySaver.saveImage(bytes);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image downloaded successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download image')));
      }
    } on PlatformException catch (e) {
      print('Failed to save image: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download image')));
    }
  }


Future<bool> _isSupportedVideoFormat(String videoUrl) async {
  try {
    // Send a GET request to get the response headers and content length
    final http.Response response = await http.get(Uri.parse(videoUrl));

    // Check if the response has a non-zero content length
    if (response.contentLength != null && response.contentLength! > 0) {
      return true; // Assume it's a valid video file
    }
  } catch (e) {
    print('Error checking video format: $e');
  }

  // Return false if the format cannot be determined or the content length is zero or null
  return false;
}


  void _showMediaDialog(BuildContext context, String mediaUrl) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return GestureDetector(
        onLongPress: () {
          _showDeleteDialog(context, mediaUrl);
        },
        child: Dialog(
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
        ),
      );
    },
  );
}

void _showDeleteDialog(BuildContext context, String mediaUrl) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Delete Footage"),
        content: Text("Are you sure you want to delete this footage ?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _deleteImage(context, mediaUrl);
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text("Delete"),
          ),
        ],
      );
    },
  );
}


void _deleteImage(BuildContext context, String mediaUrl) async {
  try {
    // Remove the image URL from Firestore
    await _removeImageUrlFromFirestore(mediaUrl);
    // Delete the image file from Firebase Storage
    await _deleteImageFromStorage(mediaUrl);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image deleted successfully')));
    // Refresh the UI by triggering a rebuild
    setState(() {
      _memoryDocument = _fetchMemoryDocument(); // Fetch fresh data
    });
  } catch (e) {
    print('Error deleting image: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete image')));
  }
}

Future<void> _removeImageUrlFromFirestore(String mediaUrl) async {
  try {
    // Implement logic to remove the image URL from Firestore
    await _firestore
        .collection('amities')
        .doc(widget.groupId)
        .collection('MemoryPics')
        .doc(widget.documentId)
        .update({
          'Footage': FieldValue.arrayRemove([mediaUrl]),
        });
  } catch (e) {
    print('Error removing image URL from Firestore: $e');
    throw Exception('Failed to remove image URL from Firestore');
  }
}


Future<void> _deleteImageFromStorage(String mediaUrl) async {
  try {
    // Parse the media URL to extract the storage path
    String storagePath = Uri.parse(mediaUrl).path;

    // Remove the leading '/' character from the storage path
    storagePath = storagePath.substring(1);

    // Get a reference to the image file in Firebase Storage
    Reference imageRef = FirebaseStorage.instance.ref().child(storagePath);

    // Delete the image file
    await imageRef.delete();
  } catch (e) {
    print('Error deleting image from storage: $e');
    throw Exception('Failed to delete image from storage');
  }
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

Future<void> _downloadAllMedia(BuildContext context) async {
  final DocumentSnapshot documentSnapshot = await _fetchMemoryDocument();
  final footage = documentSnapshot.get('Footage') as List<dynamic>? ?? [];

  // Initialize progress variables
  int totalItems = footage.length;
  int completedItems = 0;

  for (String mediaUrl in footage) {
    try {
      if (_isVideo(mediaUrl)) {
        // If media is video, download it using the appropriate method
        await downloadVideo(mediaUrl, context);
      } else {
        // If media is image, download it using the existing method
        await _downloadImage(mediaUrl, context);
      }

      // Increment completed items count
      completedItems++;

      // Calculate progress percentage
      double progressPercentage = completedItems / totalItems * 100;

      // Show snackbar with progress percentage
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(
                child: Text('Downloading... ${(progressPercentage).toStringAsFixed(2)}%'),
              ),
              CircularProgressIndicator(
                value: progressPercentage / 100,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error downloading media: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download $mediaUrl'),
        ),
      );
    }
  }

  // Show snackbar indicating completion
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('All media downloaded successfully'),
    ),
  );
}



void _addImages(BuildContext context) async {
  try {
    // Pick images
    List<XFile>? pickedImages = await _picker.pickMultiImage(imageQuality: 0);

    if (pickedImages != null && pickedImages.isNotEmpty) {
      // Upload image files to Firebase Storage
      for (final imageFile in pickedImages) {
        await _uploadToStorage(File(imageFile.path));
      }

      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Images uploaded successfully')));
      // Refresh FutureBuilder
      setState(() {
        _memoryDocument = _fetchMemoryDocument(); // Fetch fresh data
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No images selected')));
    }
  } catch (e) {
    print('Error selecting images: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to select images')));
  }
}

void _addVideos(BuildContext context) async {
  try {
    // Pick videos
    XFile? pickedVideo = await _picker.pickVideo(source: ImageSource.gallery);

    if (pickedVideo != null) {
      // Upload video file to Firebase Storage
      await _uploadVideoToStorage(File(pickedVideo.path));

      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video uploaded successfully')));
      // Refresh FutureBuilder
      setState(() {
        _memoryDocument = _fetchMemoryDocument(); // Fetch fresh data
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No video selected')));
    }
  } catch (e) {
    print('Error selecting video: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to select video')));
  }
}


void _addFootage(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0.0)),
        child: Container(
          color: Colors.blue,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                tileColor: Colors.white,
                leading: Icon(Icons.image, color: Colors.black),
                title: Text(
                  'Add Images',
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _addImages(context);
                },
              ),
              ListTile(
                tileColor: Colors.white,
                leading: Icon(Icons.videocam, color: Colors.black),
                title: Text(
                  'Add Video',
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _addVideos(context);
                },
              ),
              ListTile(
                tileColor: Colors.white,
                leading: Icon(Icons.camera_alt, color: Colors.black),
                title: Text(
                  'Take Picture',
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _takePicture(BuildContext context) async {
  try {
    XFile? picture = await _picker.pickImage(source: ImageSource.camera); // Capture a picture

    if (picture != null) {
      // Upload the taken picture to Firebase Storage
      await _uploadToStorage(File(picture.path));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Picture taken and uploaded successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take picture')),
      );
    }
  } catch (e) {
    print('Error taking picture: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to take picture')),
    );
  }
}








Future<void> _uploadVideoToStorage(File file) async {
  try {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final Reference reference = _storage.ref().child('amities/${widget.groupId}/MemoryPics/${widget.documentId}/$fileName');
    await reference.putFile(file);
    final String downloadUrl = await reference.getDownloadURL();
    // Update Firestore document with downloadUrl
    await _updateFirestore(downloadUrl);
  } catch (e) {
    print('Error uploading video to storage: $e');
    throw Exception('Failed to upload video to storage');
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


  