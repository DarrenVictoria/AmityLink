import 'package:AmityLink/auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';
import 'package:intl/intl.dart';

class MemoryPicsPage extends StatefulWidget {
  final String groupId;

  const MemoryPicsPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _MemoryPicsPageState createState() => _MemoryPicsPageState();
}

class _MemoryPicsPageState extends State<MemoryPicsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _eventNameController;
  DateTime? _selectedDate;
  late Future<List<DocumentSnapshot>> _memoryPicsFuture;

  @override
  void initState() {
    super.initState();
    _eventNameController = TextEditingController();
    _memoryPicsFuture = _fetchMemoryPicsData();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    super.dispose();
  }

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
      body: RefreshIndicator(
        onRefresh: () {
          setState(() {
            _memoryPicsFuture = _fetchMemoryPicsData();
          });
          return _memoryPicsFuture;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Memory Footage',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: _memoryPicsFuture,
                builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    List<DocumentSnapshot> documents = snapshot.data!;
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        return _buildFolderIcon(documents[index]);
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMemoryFolderPanel(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<List<DocumentSnapshot>> _fetchMemoryPicsData() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('amities')
          .doc(widget.groupId)
          .collection('MemoryPics')
          .get();
      return querySnapshot.docs;
    } catch (error) {
      throw ('Error fetching memory pics data: $error');
    }
  }

  Widget _buildFolderIcon(DocumentSnapshot document) {
    Map<String, dynamic>? data = document.data() as Map<String, dynamic>?; // Explicit cast
    List<dynamic> pics = data?['Footage'] ?? []; // Accessing 'Footage' field
    String folderName = data?['EventName'] ?? ''; // Accessing 'EventName' field
    int count = pics.length;

    return InkWell(
      onLongPress: () {
        _showDeleteConfirmationDialog(document.id, folderName);
      },
      onTap: () {
        Navigator.pushNamed(
          context,
          '/individual_memory_page',
          arguments: {'groupId': widget.groupId, 'documentId': document.id},
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder,
            size: 64,
            color: Colors.blue,
          ),
          SizedBox(height: 8),
          Text(
            folderName, // Displaying folder name
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Count: $count', // Displaying count
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String documentId, String folderName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the folder "$folderName"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteMemoryFolder(documentId); // Delete folder from Firestore
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteMemoryFolder(String documentId) async {
    try {
      // Delete folder from Firestore
      await _firestore
          .collection('amities')
          .doc(widget.groupId)
          .collection('MemoryPics')
          .doc(documentId)
          .delete();

      // Perform any other cleanup or UI updates here
    } catch (error) {
      print('Error deleting memory folder: $error');
    }
  }

void _showAddMemoryFolderPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: TextFormField(
                    controller: _eventNameController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Event Name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the event name';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('Select Date:'),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _selectDate(context);
                      },
                      child: Text('Select Date'),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                _selectedDate != null
                    ? Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          'Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : SizedBox(),

                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _submitMemoryFolder();
                    },
                    child: Text('Add Memory Folder'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _selectDate(BuildContext context) async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: _selectedDate ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );
  if (pickedDate != null) {
    setState(() {
      _selectedDate = pickedDate;
    });
  }
}


  Future<void> _submitMemoryFolder() async {
    if (_formKey.currentState!.validate()) {
      // Form is valid, proceed with updating Firebase document
      try {
        await _firestore
            .collection('amities')
            .doc(widget.groupId)
            .collection('MemoryPics')
            .doc()
            .set({
          'EventName': _eventNameController.text.trim(),
          'FinalDate': _selectedDate,
          'Footage': [],
        });

        // Clear the form fields and close the modal sheet
        _eventNameController.clear();
        setState(() {
          _selectedDate = null;
        });

        Navigator.pop(context); // Close the bottom modal panel
        // Optionally, you can show a success message or navigate to another screen
      } catch (error) {
        // Handle error
        print('Error adding memory folder: $error');
      }
    }
  }
}