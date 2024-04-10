import 'package:flutter/material.dart';
import 'package:AmityLink/features/User/data/auth.dart';
import 'package:AmityLink/features/User/data/user_repository.dart';
import 'package:AmityLink/features/User/model/user.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';
import 'package:flutter_emoji_feedback/flutter_emoji_feedback.dart';
import 'package:image_picker/image_picker.dart';

class UserDashboard extends StatefulWidget {
  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  late User _user = User(
    name: '',
    email: '',
    feelingStatus: null,
    profilePictureUrl: null,
  );

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final userRepository = UserRepository();
    final userData = await userRepository.fetchUserData();
    setState(() {
      _user = User(
        name: userData['name'],
        email: userData['email'],
        feelingStatus: userData['FeelingStatus'],
        profilePictureUrl: userData['ProfilePicture'],
      );
    });
  }

  Future<void> _updateUserName(String newName) async {
    final userRepository = UserRepository();
    await userRepository.updateUserName(newName);
    setState(() {
      _user = _user.copyWith(name: newName);
    });
  }

  Future<void> _updateUserProfilePicture(String newImageUrl) async {
    final userRepository = UserRepository();
    await userRepository.updateUserProfilePicture(newImageUrl);
    setState(() {
      _user = _user.copyWith(profilePictureUrl: newImageUrl);
    });
  }

  Future<void> _updateFeelingStatus(int value) async {
    final userRepository = UserRepository();
    await userRepository.updateFeelingStatus(value);
    setState(() {
      _user = _user.copyWith(feelingStatus: value);
    });
  }

  Future<void> _deleteAccount() async {
    final auth = Auth();
    final userRepository = UserRepository();
    await userRepository.deleteUserAccount();
    await auth.deleteAccount();
    Navigator.pushNamed(context, '/');
  }

  Future<void> _uploadImageToStorage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final userRepository = UserRepository();
      final newImageUrl = await userRepository.uploadImageToStorage(pickedFile.path);
      await _updateUserProfilePicture(newImageUrl);
    }
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
                _updateUserName(newName);
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
                _deleteAccount();
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
            final auth = Auth();
            auth.signOut();
            Navigator.pushNamed(context, '/');
          },
        ),
      ),
      body: SafeArea(
        child: Container(
          color: Colors.grey[200],
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50.0,
                  backgroundImage: _user.profilePictureUrl != null
                      ? NetworkImage(_user.profilePictureUrl!)
                      : null,
                ),
                SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed: _uploadImageToStorage,
                  child: Text('Update Profile Picture'),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Name: ${_user.name}',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  'Email: ${_user.email}',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.0),
                _user.feelingStatus != null
                    ? Text(
                        'Your current Status: ${getFeelingStatusText(_user.feelingStatus!)}',
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
                    _updateFeelingStatus(value);
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
                          final auth = Auth();
                          auth.signOut();
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
        ),
      ),
    );
  }

  String getFeelingStatusText(int status) {
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
}