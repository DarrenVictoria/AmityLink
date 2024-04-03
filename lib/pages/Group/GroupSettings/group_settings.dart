import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';
import 'package:AmityLink/auth.dart';




class GroupManagementPage extends StatefulWidget {
  final String groupId;
  

  const GroupManagementPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupManagementPageState createState() => _GroupManagementPageState();
}

class _GroupManagementPageState extends State<GroupManagementPage> {
  String name = '';
  String description = '';
  late ImageProvider userProfilePicture;

  @override
  void initState() {
    super.initState();
    userProfilePicture = NetworkImage('https://example.com/placeholder_image.jpg');
    fetchGroupData();
  }

   Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
  }

  Future<void> fetchGroupData() async {
    try {
      DocumentSnapshot groupSnapshot =
          await FirebaseFirestore.instance.collection('amities').doc(widget.groupId).get();
      if (groupSnapshot.exists) {
        setState(() {
          name = groupSnapshot['GroupName'];
          description = groupSnapshot['GroupDescription'] ?? '';
          String? profilePictureUrl = groupSnapshot['GroupProfilePicture'];
          if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
            userProfilePicture = NetworkImage(profilePictureUrl);
          }
        });
      } else {
        print("Group data not found.");
      }
    } catch (e) {
      print("Error fetching group data: $e");
    }
  }

  Future<void> updateGroupName(String newName) async {
    try {
      await FirebaseFirestore.instance.collection('amities').doc(widget.groupId).update({
        'GroupName': newName,
      });
      setState(() {
        name = newName;
      });
    } catch (e) {
      print("Error updating group name: $e");
    }
  }

  Future<void> updateGroupDescription(String newDescription) async {
    try {
      await FirebaseFirestore.instance.collection('amities').doc(widget.groupId).update({
        'GroupDescription': newDescription,
      });
      setState(() {
        description = newDescription;
      });
    } catch (e) {
      print("Error updating group description: $e");
    }
  }

  Future<void> updateGroupProfilePicture(String newImageUrl) async {
    try {
      await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
        'profilePicture': newImageUrl,
      });
      setState(() {
        userProfilePicture = NetworkImage(newImageUrl);
      });
    } catch (e) {
      print("Error updating group profile picture: $e");
    }
  }

  Future<bool> isAdmin(String uid) {
  // Query the 'amities' collection to check if the user is an admin
  // You may need to adjust this query based on your Firestore schema
  // Assuming 'Admin' field contains the UID of the admin
      return FirebaseFirestore.instance
          .collection('amities')
          .doc(widget.groupId)
          .get()
          .then((doc) {
        if (doc.exists) {
          return doc['Admin'] == uid;
        }
        return false;
      }).catchError((error) {
        print("Error checking admin status: $error");
        return false;
      });
    }

void _deleteGroup() {
  FirebaseFirestore.instance.collection('amities').doc(widget.groupId).delete()
    .then((_) {
      print("Group deleted successfully");
      // Navigate back to previous screen or perform any necessary actions
    })
    .catchError((error) {
      print("Error deleting group: $error");
      // Handle the error, such as showing a snackbar or alert dialog
    });
}



    

void _leaveGroup(String uid) {
  // Remove the user's UID from the 'GroupMembers' array
  FirebaseFirestore.instance.collection('amities').doc(widget.groupId).update({
    'GroupMembers': FieldValue.arrayRemove([uid]),
  }).then((_) {
    print("Left the group successfully");
  }).catchError((error) {
    print("Error leaving the group: $error");
  });
}

void _removeUserFromGroup(String memberId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Remove Member'),
        content: Text('Are you sure you want to leave from the group?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Call a function to remove the user from the group members
              _removeMember(memberId);
              
              Navigator.pop(context); // Close the dialog

              Navigator.pushNamed(context, '/');
            },
            child: Text('Remove'),
          ),
        ],
      );
    },
  );
}

void _removeMember(String memberId) {
  FirebaseFirestore.instance.collection('amities').doc(widget.groupId).update({
    'GroupMembers': FieldValue.arrayRemove([memberId]),
  }).then((_) {
    print("User removed from the group successfully");
    
  }).catchError((error) {
    print("Error removing user from the group: $error");
  });
}


Future<void> editGroupProfilePicture(String newImageUrl) async {
  try {
    await FirebaseFirestore.instance.collection('amities').doc(widget.groupId).update({
      'GroupProfilePicture': newImageUrl,
    });
    setState(() {
      userProfilePicture = NetworkImage(newImageUrl);
    });
  } catch (e) {
    print("Error updating group profile picture: $e");
  }
}


void uploadImageToStorage(String imagePath) async {
  try {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference = FirebaseStorage.instance.ref().child('group_profile_pictures/$fileName');
    UploadTask uploadTask = storageReference.putFile(File(imagePath));
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    editGroupProfilePicture(downloadUrl);
  } catch (e) {
    print("Error uploading image to Firebase Storage: $e");
  }
}



void _showDeleteGroupDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Delete Group'),
        content: Text('Are you sure you want to delete this group?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              _deleteGroup(); // Call the delete function
              Navigator.pushNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(
              primary: Colors.red, // Set the button color to red
            ),
            child: Text('Delete'),
          ),
        ],
      );
    },
  );
}




  @override
 @override
@override
Widget build(BuildContext context) {
  String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

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
    body: FutureBuilder<bool>(
      future: isAdmin(currentUserUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          ); // Placeholder widget while loading
        } else {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            bool isAdmin = snapshot.data!;
            return Container(
              padding: EdgeInsets.all(16.0),
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50.0,
                    backgroundImage: userProfilePicture,
                  ),
                  SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: ()async {
                        final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          uploadImageToStorage(pickedFile.path);
                        }
                      },
                    child: Text('Update Profile Picture'),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    '$name',
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                   SizedBox(height: 16.0),
                    Text(
                      '$description', // Display group description
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  SizedBox(height: 16.0),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showEditGroupNameDialog(context);
                      },
                      child: Text(
                        'Edit Group Name',
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                       _showEditGroupDescriptionDialog(context);
                      },
                      child: Text(
                        'Edit Group Description',
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (isAdmin) {
                          _showDeleteGroupDialog(context);
                        } else {
                          _leaveGroup(currentUserUid);
                          Navigator.pushNamed(context, '/');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.red, // Set the button color to red
                      ),
                      icon: Icon(isAdmin ? Icons.delete : Icons.exit_to_app, color: Colors.white),
                      label: Text(
                        isAdmin ? 'Delete Group' : 'Leave Group',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Members',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('amities').doc(widget.groupId).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                            return Center(
                              child: const Text('No members found'),
                            );
                          }
                          List<String> groupMembers = List.from(snapshot.data!.get('GroupMembers'));
                          return ListView.builder(
                              itemCount: groupMembers.length,
                              itemBuilder: (context, index) {
                                  String memberId = groupMembers[index];
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance.collection('users').doc(memberId).get(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                                        return const SizedBox.shrink();
                                      }
                                      String memberName = snapshot.data!.get('name');  
                                      String? memberProfilePicture = snapshot.data!.get('ProfilePicture'); // Nullable URL

                                      return Card(
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundImage: memberProfilePicture != null
                                                ? NetworkImage(memberProfilePicture)
                                                : AssetImage('assets/default_profile_picture.png') as ImageProvider<Object>, // Use default profile picture
                                            ),
                                            title: Text(memberName),
                                            trailing: isAdmin
                                                ? IconButton(
                                                    icon: Icon(Icons.remove_circle),
                                                    onPressed: () {
                                                      // Call a function to remove the user from the group members
                                                      _removeUserFromGroup(memberId);
                                                       
                                                      
                                                    },
                                                  )
                                                : null,
                                          ),
                                        );

                                  },
                                );
                              },

                          );

                      },
                    ),
                  ),
                ],
              ),
            );
          }
        }
      },
    ),
  );
}

  void _showEditGroupNameDialog(BuildContext context) {
    TextEditingController _nameEditingController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Group Name'),
          content: TextField(
            controller: _nameEditingController,
            decoration: InputDecoration(hintText: 'Enter new group name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                updateGroupName(_nameEditingController.text);
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showEditGroupDescriptionDialog(BuildContext context) {
    TextEditingController _descriptionEditingController = TextEditingController(text: description);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Group Description'),
          content: TextField(
            controller: _descriptionEditingController,
            decoration: InputDecoration(hintText: 'Enter new group description'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                updateGroupDescription(_descriptionEditingController.text);
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  

  

  
}
