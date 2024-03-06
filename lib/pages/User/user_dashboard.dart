import 'dart:io';
import 'package:AmityLink/auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';
import 'package:flutter_emoji_feedback/flutter_emoji_feedback.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserDashboard extends StatefulWidget {
  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  String uid = FirebaseAuth.instance.currentUser!.uid;
  String name = '';
  String email = '';
  int? feelingStatus;
  late ImageProvider userProfilePicture;

  @override
  void initState() {
    super.initState();
    userProfilePicture = NetworkImage('https://example.com/placeholder_image.jpg');
    fetchUserData();
  }

  Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
  }

  String getFeelingStatusText(int? status) {
  switch (status) {
    case 1:
      return 'Terrible';
    case 2:
      return 'Bad';
    case 3:
      return 'Good';
    case 4:
      return 'Very Good';
    case 5:
      return 'Awesome';
    default:
      return '';
  }
}

  Future<void> fetchUserData() async {
  try {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userSnapshot.exists) {
      setState(() {
        name = (userSnapshot.data() as Map<String, dynamic>)['name'];
        email = (userSnapshot.data() as Map<String, dynamic>)['email'];
        feelingStatus = (userSnapshot.data() as Map<String, dynamic>)['FeelingStatus'];

        String? profilePictureUrl = (userSnapshot.data() as Map<String, dynamic>)['profilePicture'];
        if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
          // If profile picture URL is present, use it
          userProfilePicture = NetworkImage(profilePictureUrl);
        } else {
          // Otherwise, use a placeholder image from the internet
          userProfilePicture = NetworkImage('https://example.com/placeholder_image.jpg');
        }
      });
    } else {
      // Handle the case where the user document does not exist
      setState(() {
        print("User data not found.");
      });
    }
  } catch (e) {
    print("Error fetching user data: $e");
    // Handle the error appropriately, for example, displaying an error message
    setState(() {
      print("Error fetching user data. Please try again later.");
    });
  }
}

Future<void> updateUserName(String newName) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': newName,
      });
      setState(() {
        name = newName;
      });
    } catch (e) {
      print("Error updating user name: $e");
    }
  }

  Future<void> editGroupProfilePicture(String newImageUrl) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'ProfilePicture': newImageUrl,
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
    Reference storageReference = FirebaseStorage.instance.ref().child('user_profile_pictures/$fileName');
    UploadTask uploadTask = storageReference.putFile(File(imagePath));
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    editGroupProfilePicture(downloadUrl);
  } catch (e) {
    print("Error uploading image to Firebase Storage: $e");
  }
}

 Future<void> deleteAccount(BuildContext context) async {
  try {
    // Delete user document from Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();

    // Delete user account from Firebase Authentication
    await FirebaseAuth.instance.currentUser!.delete();

    // No need to navigate to another screen after deletion
  } catch (e) {
    print("Error deleting account: $e");
    // Handle error, e.g., display a message to the user
  }
}



Future<void> updateFeelingStatus(int value) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'FeelingStatus': value,
      });
      setState(() {
        feelingStatus = value;
      });
    } catch (e) {
      print("Error updating feeling status: $e");
    }
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
            body: Container(
              color: Colors.grey[200],
              padding: EdgeInsets.all(16.0),
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
                    'Name: $name',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Email: $email',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  feelingStatus != null
                    ? Text(
                        'Your current Status: ${getFeelingStatusText(feelingStatus)}',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : SizedBox.shrink(),

                  SizedBox(height: 50.0),
                  Text(
                    'How are you feeling today?',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  EmojiFeedback(
                    animDuration: const Duration(milliseconds: 300),
                    curve: Curves.bounceIn,
                    inactiveElementScale: .5,
                    onChanged: (value) {
                      updateFeelingStatus(value);
                    },
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showEditNameDialog(context);
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Color(0xFF615e5e),
                            onPrimary: Colors.white,
                          ),
                          icon: Icon(Icons.edit),
                          label: Text('Edit Profile Name'),
                        ),
                      ),
                    ],
                  ),
                   SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showDeleteAccountConfirmation(context);
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.red,
                            onPrimary: Colors.white,
                          ),
                          icon: Icon(Icons.delete),
                          label: Text('Delete profile'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            signOut(context);
                            Navigator.pushNamed(context, '/');
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Color(0xFF615e5e),
                            onPrimary: Colors.white,
                          ),
                          icon: Icon(Icons.logout),
                          label: Text('Logout'),
                        ),
                      ),
                    ],
                  ),
                 
                ],
              ),
            ),
          );
        }

        void _showEditNameDialog(BuildContext context) {
    String newName = '';

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Edit Profile Name'),
              content: TextField(
                onChanged: (value) {
                  newName = value;
                },
                decoration: InputDecoration(
                  hintText: 'Enter new name',
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    updateUserName(newName);
                    Navigator.of(context).pop();
                  },
                  child: Text('Update'),
                ),
              ],
            );
          },
        );
      }

      void _showDeleteAccountConfirmation(BuildContext context) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete Account'),
              content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    deleteAccount(context);
                    Navigator.pushNamed(context, '/');
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red,
                    onPrimary: Colors.white,
                  ),
                  child: Text('Delete'),
                ),
              ],
            );
          },
        );
      }

      }
