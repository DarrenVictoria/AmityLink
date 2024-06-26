import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:AmityLink/features/Group/BulletinBoard/data/bulletin_data.dart';
import 'package:AmityLink/features/Group/BulletinBoard/model/bulletin_structure.dart';

class GroupBulletinBoardPage extends StatefulWidget {
  final String groupId;

  GroupBulletinBoardPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupBulletinBoardPageState createState() => _GroupBulletinBoardPageState();
}

class _GroupBulletinBoardPageState extends State<GroupBulletinBoardPage> {
  String uid = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final picker = ImagePicker();

  File? _imageFile;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Group Bulletin Board',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('amities').doc(widget.groupId).collection('BulletinBoard').orderBy('timestamp', descending: true).snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                List<ForumPost> posts = snapshot.data!.docs.map((DocumentSnapshot document) {
                  Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                  return ForumPost(
                    uid: data['uid'] ?? '',
                    title: data['Title'] ?? '',
                    content: data['Content'] ?? '',
                    imageUrl: data['ImageURL'] ?? '',
                    comments: Map<String, String>.from(data['Comments'] ?? {}),
                    likes: List<String>.from(data['Likes'] ?? []),
                    location: data['Location'] != null ? GeoPoint(data['Location'].latitude, data['Location'].longitude) : null,
                  );
                }).toList();

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (BuildContext context, int index) {
                    ForumPost post = posts[index];
                    return Card(
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(post.title),
                                subtitle: Text(post.content),
                              ),
                              if (post.imageUrl.isNotEmpty)
                                Container(
                                  alignment: Alignment.center,
                                  child: Image.network(post.imageUrl),
                                ),
                              SizedBox(height: 8),
                              if (post.location != null)
                                Container(
                                  height: 200,
                                  child: FlutterMap(
                                    options: MapOptions(
                                      center: LatLng(post.location!.latitude, post.location!.longitude),
                                      zoom: 15.0,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        subdomains: ['a', 'b', 'c'],
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            width: 80.0,
                                            height: 80.0,
                                            point: LatLng(post.location!.latitude, post.location!.longitude),
                                            child: Icon(
                                              Icons.location_on,
                                              color: Colors.red,
                                              size: 50.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.thumb_up),
                                        color: post.likes.contains(uid) ? Colors.blue : Colors.grey,
                                        onPressed: () async {
                                          List<String> updatedLikes = List.from(post.likes);

                                          if (post.likes.contains(uid)) {
                                            // Unlike
                                            updatedLikes.remove(uid);
                                          } else {
                                            // Like
                                            updatedLikes.add(uid);
                                          }

                                          await FirebaseFirestore.instance.collection('amities').doc(widget.groupId).collection('BulletinBoard').doc(snapshot.data!.docs[index].id).update({
                                            'Likes': updatedLikes,
                                          });
                                        },
                                      ),
                                      Text('${post.likes.length} Likes'),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 8, right: 10),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text('Opinion Pins'),
                                              content: Container(
                                                width: double.maxFinite,
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    ListView.builder(
                                                      shrinkWrap: true,
                                                      itemCount: post.comments.length,
                                                      itemBuilder: (BuildContext context, int index) {
                                                        String userId = post.comments.keys.elementAt(index);
                                                        String commentText = post.comments.values.elementAt(index);
                                                        return FutureBuilder<DocumentSnapshot>(
                                                          future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                                                          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                                                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                                                              return CircularProgressIndicator();
                                                            }
                                                            if (userSnapshot.hasError) {
                                                              return Text('Error fetching user data: ${userSnapshot.error}');
                                                            }
                                                            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                                                              return Text('User data not found');
                                                            }

                                                            String userName = userSnapshot.data!.get('name');
                                                            return Card(
                                                              child: ListTile(
                                                                title: Text(commentText),
                                                                subtitle: Text(userName),
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                    ),
                                                    SizedBox(height: 16),
                                                    TextField(
                                                      controller: _commentController,
                                                      decoration: InputDecoration(
                                                        hintText: 'Add your opinion...',
                                                        border: OutlineInputBorder(),
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        String newComment = _commentController.text.trim();
                                                        if (newComment.isNotEmpty) {
                                                          FirebaseFirestore.instance.collection('amities').doc(widget.groupId).collection('BulletinBoard').doc(snapshot.data!.docs[index].id).update({
                                                            'Comments.${uid}': newComment,
                                                          });
                                                          Navigator.pop(context);
                                                        }
                                                      },
                                                      child: Text('Update Opinion'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Text('View/Add Opinion'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (post.uid == uid)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () async {
                                  // Show a confirmation dialog before deleting the post
                                  bool confirmDelete = await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Delete Post'),
                                        content: Text('Are you sure you want to delete this post?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirmDelete == true) {
                                    // Delete the document from Firestore
                                    await FirebaseFirestore.instance.collection('amities').doc(widget.groupId).collection('BulletinBoard').doc(snapshot.data!.docs[index].id).delete();
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
              onPressed: () async {
                await sendLocation(context, widget.groupId); // Pass both arguments
              },
              tooltip: 'Send Location',
              child: Icon(Icons.location_on),
            ),

          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return ListView(    
                    shrinkWrap: true,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _titleController,
                              decoration: InputDecoration(hintText: 'Title'),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _contentController,
                              decoration: InputDecoration(hintText: 'Content'),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: uploadImage,
                              icon: Icon(Icons.cloud_upload, color: Color.fromARGB(255, 63, 66, 97)),
                              label: Text('Upload Image'),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.lightBlue[100],
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                String title = _titleController.text.trim();
                                String content = _contentController.text.trim();
                                String? imageUrl = await uploadImageToStorage(_imageFile);
                                Timestamp timestamp = Timestamp.now();

                                if (title.isNotEmpty && content.isNotEmpty) {
                                  try {
                                    await addForumPost(
                                      widget.groupId,
                                      title,
                                      content,
                                      imageUrl,
                                      uid,
                                      timestamp,
                                    );

                                    _titleController.clear();
                                    _contentController.clear();
                                    _imageFile = null;
                                    Navigator.pop(context);
                                  } catch (e) {
                                    print('Error adding forum post: $e');
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Please fill in all the fields'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: Text('Post Now'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Future<void> uploadImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    _imageFile = File(pickedFile.path);
  } else {
    print('No image selected.');
  }
}
}

