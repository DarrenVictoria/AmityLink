import 'package:flutter/material.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';
import 'package:AmityLink/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PaymentDetailPage extends StatefulWidget {
  final String groupId;
  final String documentId;

  PaymentDetailPage({Key? key, required this.groupId, required this.documentId}) : super(key: key);

  @override
  _PaymentDetailPageState createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late String? _currentUid;
  bool _isPayNowEnabled = false;
  final ImagePicker _picker = ImagePicker();
  String? _poolName;
  DateTime? _paymentDue;
  int? _poolAmount;
  Map<String, dynamic>? _paymentStatus;
   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _getCurrentUserUid();
  }

  Future<void> _getCurrentUserUid() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUid = user.uid;
      });
    }
    _checkPayNowEnabled();
  }

  Future<void> _checkPayNowEnabled() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('amities')
        .doc(widget.groupId)
        .collection('FundCollection')
        .doc(widget.documentId)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final paymentStatus = data['PaymentStatus'] as Map<String, dynamic>?;
      final paymentEvidence = data['PaymentEvidence'] as Map<String, dynamic>?;

      // Check if both paymentStatus and paymentEvidence are null for the current user
      if (paymentStatus != null && paymentEvidence != null && paymentStatus[_currentUid] == null && paymentEvidence[_currentUid] == null) {
        setState(() {
          _isPayNowEnabled = true;
        });
      } else {
        setState(() {
          _isPayNowEnabled = false;
        });
      }
    }
  }

  Future<Map<String, String>> _fetchUserInfo(List<String> uids) async {
    final Map<String, String> userInfo = {};

    for (final uid in uids) {
      final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>?;
        final name = userData?['name'] as String?;
        if (name != null) {
          userInfo[uid] = name;
        }
      }
    }

    return userInfo;
  }

  Future<void> _fetchPaymentDetails() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('amities')
          .doc(widget.groupId)
          .collection('FundCollection')
          .doc(widget.documentId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final poolName = data['PoolName'];
        final paymentDue = (data['PaymentDue'] as Timestamp).toDate();
        final poolAmount = data['PoolAmount'];
        final paymentStatus = data['PaymentStatus'];

        setState(() {
          _poolName = poolName;
          _paymentDue = paymentDue;
          _poolAmount = poolAmount;
          _paymentStatus = paymentStatus;
        });
      } else {
        // Handle case where document doesn't exist
      }
    } catch (error) {
      print('Error fetching payment details: $error');
      // Handle error
    }
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
            _signOut(context);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPaymentDetails,
        child: FutureBuilder(
          future: FirebaseFirestore.instance
              .collection('amities')
              .doc(widget.groupId)
              .collection('FundCollection')
              .doc(widget.documentId)
              .get(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('Document does not exist'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final poolName = data['PoolName'];
            final paymentDue = (data['PaymentDue'] as Timestamp).toDate();
            final poolAmount = data['PoolAmount'];
            final paymentStatus = data['PaymentStatus'];

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$poolName',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Payment Due Date: ${DateFormat('yyyy-MM-dd').format(paymentDue)}',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Pool Amount: \LKR $poolAmount',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Payment Status:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  if (paymentStatus != null && paymentStatus is Map<String, dynamic>)
                    FutureBuilder(
                      future: _fetchUserInfo(paymentStatus.keys.toList()),
                      builder: (context, AsyncSnapshot<Map<String, String>> userInfoSnapshot) {
                        if (userInfoSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (userInfoSnapshot.hasError) {
                          return Center(child: Text('Error: ${userInfoSnapshot.error}'));
                        }
                        if (!userInfoSnapshot.hasData) {
                          return Center(child: Text('Loading...'));
                        }

                        final userInfoData = userInfoSnapshot.data;

                        if (userInfoData != null) {
                          return FutureBuilder(
                            future: FirebaseFirestore.instance
                                .collection('amities')
                                .doc(widget.groupId)
                                .collection('FundCollection')
                                .doc(widget.documentId)
                                .get(),
                            builder: (context, AsyncSnapshot<DocumentSnapshot> evidenceSnapshot) {
                              if (evidenceSnapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }
                              if (evidenceSnapshot.hasError) {
                                return Center(child: Text('Error: ${evidenceSnapshot.error}'));
                              }

                              final evidenceData = evidenceSnapshot.data!.data() as Map<String, dynamic>?;

                              return Table(
                                border: TableBorder.all(),
                                children: [
                                  TableRow(
                                    children: [
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Name',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Payment Amount (LKR)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Evidence Status',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ...userInfoData.entries.map((entry) {
                                    String paymentAmount = paymentStatus[entry.key] != null ? paymentStatus[entry.key].toString() : 'Not Paid';
                                    String evidenceStatus = (evidenceData != null && evidenceData['PaymentEvidence'] != null && evidenceData['PaymentEvidence'][entry.key] != null) ? 'Submitted' : 'No Evidence';

                                    return TableRow(
                                      children: [
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(entry.value),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(paymentAmount),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(evidenceStatus),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              );
                            },
                          );
                        } else {
                          return Container(); // Return empty container if userInfoData is null
                        }
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        margin: EdgeInsets.all(20.0),
        child: Material(
          color: _isPayNowEnabled ? Colors.blue : Colors.grey, // Change button color based on enabled state
          borderRadius: BorderRadius.circular(10.0),
          child: InkWell(
            onTap: _isPayNowEnabled ? () => _submitPaymentEvidence(context) : null,
            borderRadius: BorderRadius.circular(10.0),
            child: Padding(
              padding: EdgeInsets.all(15.0),
              child: Text(
                'Submit Payment Evidence',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _signOut(BuildContext context) async {
    await Auth().signOut();
  }

  Future<void> _submitPaymentEvidence(BuildContext context) async {
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
                    'Upload Image',
                    style: TextStyle(color: Colors.black),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    bool success = await _uploadImage(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Evidence uploaded successfully')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to upload evidence')),
                      );
                    }
                  },
                ),
                ListTile(
                  tileColor: Colors.white,
                  leading: Icon(Icons.camera_alt, color: Colors.black),
                  title: Text(
                    'Take Picture',
                    style: TextStyle(color: Colors.black),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    bool success = await _takePicture(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Evidence uploaded successfully')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to upload evidence')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _uploadImage(BuildContext context) async {
    try {
      XFile? imageFile = await _picker.pickImage(source: ImageSource.gallery); // Pick an image

      if (imageFile != null) {
        // Upload the selected image to Firebase Storage
        String downloadUrl = await _uploadToStorage(File(imageFile.path));

        // Update Firestore with the download URL
        await _updateFirestore(downloadUrl);

        return true; // Upload successful
      } else {
        return false; // Upload failed
      }
    } catch (e) {
      print('Error uploading evidence: $e');
      return false; // Upload failed
    }
  }

  Future<bool> _takePicture(BuildContext context) async {
    try {
      XFile? picture = await _picker.pickImage(source: ImageSource.camera); // Capture a picture

      if (picture != null) {
        // Upload the taken picture to Firebase Storage
        String downloadUrl = await _uploadToStorage(File(picture.path));

        // Update Firestore with the download URL
        await _updateFirestore(downloadUrl);

        return true; // Upload successful
      } else {
        return false; // Upload failed
      }
    } catch (e) {
      print('Error taking picture: $e');
      return false; // Upload failed
    }
  }

Future<String> _uploadToStorage(File file) async {
  try {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final Reference reference = _storage.ref().child('amities/${widget.groupId}/PaymentEvidences/${widget.documentId}/$fileName');
    final UploadTask uploadTask = reference.putFile(file);

    // Wait for the upload to complete
    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  } catch (e) {
    print('Error uploading file to storage: $e');
    throw Exception('Failed to upload file to storage');
  }
}

Future<bool> _updateFirestore(String downloadUrl) async {
  try {
    // Get the current user's UID
    String? currentUserUid = _currentUid;
    if (currentUserUid != null) {
      // Fetch the current document snapshot
      final DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('amities')
          .doc(widget.groupId)
          .collection('FundCollection')
          .doc(widget.documentId)
          .get();

      // Check if the document exists and contains the PaymentEvidence field
      if (documentSnapshot.exists && documentSnapshot.data() != null) {
        // Explicitly cast the data to Map<String, dynamic>
        Map<String, dynamic>? data = documentSnapshot.data() as Map<String, dynamic>?;

        // Check if the PaymentEvidence field exists in the data map
        if (data != null && data['PaymentEvidence'] != null) {
          // Get the current PaymentEvidence map
          Map<String, dynamic> paymentEvidence = Map<String, dynamic>.from(data['PaymentEvidence']);

          // Check if the current user's UID exists as a key in the PaymentEvidence map
          if (paymentEvidence.containsKey(currentUserUid)) {
            // Update the value of the current user's field with the downloadUrl
            paymentEvidence[currentUserUid] = downloadUrl;

            // Update only the PaymentEvidence field in Firestore using merge: true
            await FirebaseFirestore.instance
                .collection('amities')
                .doc(widget.groupId)
                .collection('FundCollection')
                .doc(widget.documentId)
                .set({'PaymentEvidence': paymentEvidence}, SetOptions(merge: true));

            // Show a success snackbar and navigate back
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Evidence uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
            return true; // Update successful
          } else {
            throw Exception('Current user UID not found in PaymentEvidence map');
          }
        } else {
          throw Exception('PaymentEvidence field not found in document data');
        }
      } else {
        throw Exception('Document does not exist or data is null');
      }
    } else {
      throw Exception('Current user UID is null');
    }
  } catch (e) {
    print('Error updating Firestore document: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to upload evidence'),
        backgroundColor: Colors.red,
      ),
    );
    throw Exception('Failed to update Firestore document');
  }
}

}