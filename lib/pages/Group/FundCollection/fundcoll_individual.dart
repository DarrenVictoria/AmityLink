import 'package:flutter/material.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';
import 'package:AmityLink/auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:intl/intl.dart';

class PaymentDetailPage extends StatefulWidget {
  final String groupId;
  final String documentId;

  PaymentDetailPage({Key? key, required this.groupId, required this.documentId}) : super(key: key);

  @override
  _PaymentDetailPageState createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String? _currentUid;
  bool _isPayNowEnabled = false;

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

      if (paymentStatus != null && paymentStatus.containsKey(_currentUid)) {
        setState(() {
          _isPayNowEnabled = paymentStatus[_currentUid] == null;
        });
      } else {
        setState(() {
          _isPayNowEnabled = true; // Enable if currentUid not found in PaymentStatus
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
            _signOut(context);
          },
        ),
      ),
      body: FutureBuilder(
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
                            ],
                          ),
                          ...userInfoSnapshot.data!.entries.map((entry) {
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
                                    child: Text(paymentStatus[entry.key] != null ? paymentStatus[entry.key].toString() : 'Not Paid'),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        margin: EdgeInsets.all(20.0),
        child: Material(
          color: _isPayNowEnabled ? Colors.blue : Colors.grey, // Change button color based on enabled state
          borderRadius: BorderRadius.circular(10.0),
          child: InkWell(
            onTap: _isPayNowEnabled ? () {
              // Implement your pay now logic here
            } : null, // Disable onTap if button is not enabled
            borderRadius: BorderRadius.circular(10.0),
            child: Padding(
              padding: EdgeInsets.all(15.0),
              child: Text(
                'Pay Now',
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
}
