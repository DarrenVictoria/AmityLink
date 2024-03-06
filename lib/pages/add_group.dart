import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../NavFooter/usertopnav.dart';
import 'package:AmityLink/auth.dart';
import 'package:image_cropper/image_cropper.dart';


class AddGroupPage extends StatefulWidget {
  @override
  _AddGroupPageState createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _titleController;
  TextEditingController? _descriptionController;
  String? _imageUrl;
  bool _isButtonDisabled = true; // To disable submit button initially

  final User? user = Auth().currentUser;

  Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
  }

  @override
  void initState() {
    super.initState();
    initializeFlutterFire();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  // Initialize Firebase
  void initializeFlutterFire() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }

  @override
  void dispose() {
    _titleController!.dispose();
    _descriptionController!.dispose();
    super.dispose();
  }

 

 Future<void> editGroupProfilePicture(String newImageUrl) async {
  try {
    
    setState(() {
      _imageUrl = newImageUrl;
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




  

  void _submitForm() {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      // Save form data to Firebase
      FirebaseFirestore.instance.collection('amities').add({
        'GroupName': _titleController!.text,
        'GroupDescription': _descriptionController!.text,
        'GroupProfilePicture': _imageUrl,
        'Admin': user?.uid,
        'GroupMembers': [user?.uid],
        // Add profile picture upload logic here
      }).then((value) {
        // Success
        print('Data saved to Firebase');
        // Reset form fields
        _titleController!.clear();
        _descriptionController!.clear();
        setState(() {
          _imageUrl = null; // Clear image URL after form submission
        });
      }).catchError((error) {
        // Error
        print('Failed to save data to Firebase: $error');
      });
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Card(
                  elevation: 2.0,
                  color: Colors.grey[200],
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.topLeft,
                          margin: EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            'Create Your Group',
                            style: TextStyle(
                              fontSize: 30.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(35.0),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                          onChanged: (_) => _validateForm(),
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: _descriptionController,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          maxLength: 250,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(35.0),
                            ),
                            counterText: '${_descriptionController?.text.length ?? 0}/250',
                          ),
                          onChanged: (_) => _validateForm(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            if (value.length > 250) {
                              return 'Description must be less than or equal to 250 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.0),
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.only(bottom: 20.0, top:20.0),
                          child: Text('Upload Group Profile Picture'),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            onPressed: ()async {
                                final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                                if (pickedFile != null) {
                                  uploadImageToStorage(pickedFile.path);
                                }
                              },
                            child: Text('Upload Image'),
                          ),
                        ),
                        SizedBox(height: 16.0),
                        if (_imageUrl != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ClipOval(
                              child: Image.network(
                                _imageUrl!,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _isButtonDisabled ? null : () {
                    _submitForm();
                    Navigator.pushNamed(context, '/');
                  },
                  child: Text('Create'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _validateForm() {
    setState(() {
      _isButtonDisabled = _titleController!.text.isEmpty || _descriptionController!.text.isEmpty;
    });
  }
}
 