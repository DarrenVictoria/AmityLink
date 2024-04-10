import 'package:flutter/material.dart';
import 'package:AmityLink/features/Initiate/data/auth.dart';
import 'package:AmityLink/features/Initiate/data/group_repository.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';
import 'package:image_picker/image_picker.dart';

class AddGroupPage extends StatefulWidget {
  @override
  _AddGroupPageState createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _imageUrl;
  bool _isButtonDisabled = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _uploadImageToStorage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final groupRepository = GroupRepository();
      final newImageUrl = await groupRepository.uploadImageToStorage(pickedFile.path);
      setState(() {
        _imageUrl = newImageUrl;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final groupRepository = GroupRepository();
      groupRepository.createGroup(
        _titleController.text,
        _descriptionController.text,
        _imageUrl,
      );
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _imageUrl = null;
      });
      Navigator.pushNamed(context, '/');
    }
  }

  void _validateForm() {
    setState(() {
      _isButtonDisabled = _titleController.text.isEmpty || _descriptionController.text.isEmpty;
    });
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Card(
                  color: Color(0xFFD9D9D9),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Your Group',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16.0),
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
                            counterText: '${_descriptionController.text.length}/250',
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
                        Text('Upload Group Profile Picture'),
                        SizedBox(height: 8.0),
                        ElevatedButton(
                          onPressed: _uploadImageToStorage,
                          child: Text('Upload Image'),
                        ),
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
                  onPressed: _isButtonDisabled ? null : _submitForm,
                  child: Text('Create'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}