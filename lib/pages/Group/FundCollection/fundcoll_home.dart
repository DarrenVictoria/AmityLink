import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import DateFormat for date formatting
import 'package:AmityLink/NavFooter/usertopnav.dart';
import 'package:AmityLink/auth.dart'; // Import your authentication logic
import 'package:flutter/cupertino.dart';

class FundCollectionPage extends StatelessWidget {
  final String groupId;

  const FundCollectionPage({Key? key, required this.groupId}) : super(key: key);

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
        onRefresh: () async {
          // Implement your refresh logic here
          // For example, refetch data from Firestore
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Fund Collection',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('amities')
                    .doc(groupId)
                    .collection('FundCollection')
                    .snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text('No funds collected yet.'),
                    );
                  }

                  // Separate payments into upcoming and past due
                  final now = DateTime.now();
                  final upcomingPayments = <QueryDocumentSnapshot>[];
                  final pastDuePayments = <QueryDocumentSnapshot>[];

                  for (final payment in snapshot.data!.docs) {
                    final paymentDue = (payment.data() as Map)['PaymentDue'] as Timestamp;
                    if (paymentDue.toDate().isAfter(now)) {
                      upcomingPayments.add(payment);
                    } else {
                      pastDuePayments.add(payment);
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (upcomingPayments.isNotEmpty)
                        ExpansionTile(
                          title: Text('Upcoming Payments'),
                          initiallyExpanded: true, // Keep the section expanded by default
                          tilePadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          childrenPadding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                          children: [
                            for (final payment in upcomingPayments)
                              Dismissible(
                                key: Key(payment.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20.0),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (direction) {
                                  // Delete the item from Firestore
                                  FirebaseFirestore.instance
                                      .collection('amities')
                                      .doc(groupId)
                                      .collection('FundCollection')
                                      .doc(payment.id)
                                      .delete()
                                      .then((value) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Payment dismissed'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }).catchError((error) {
                                    print('Error deleting payment: $error');
                                  });
                                },
                                child: _buildPaymentTile(context, payment),
                              ),
                          ],
                        ),
                      if (pastDuePayments.isNotEmpty)
                        ExpansionTile(
                          title: Text('Past Due Payments'),
                          tilePadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          childrenPadding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                          children: [
                            for (final payment in pastDuePayments)
                              Dismissible(
                                key: Key(payment.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20.0),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (direction) {
                                  // Delete the item from Firestore
                                  FirebaseFirestore.instance
                                      .collection('amities')
                                      .doc(groupId)
                                      .collection('FundCollection')
                                      .doc(payment.id)
                                      .delete()
                                      .then((value) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Payment dismissed'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }).catchError((error) {
                                    print('Error deleting payment: $error');
                                  });
                                },
                                child: _buildPaymentTile(context, payment),
                              ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open the bottom panel to add new fund pool
          showModalBottomSheet(
            context: context,
            builder: (context) => AddFundPoolBottomPanel(groupId: groupId),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }



Widget _buildPaymentTile(BuildContext context, QueryDocumentSnapshot payment) {
  final data = payment.data() as Map<String, dynamic>;
  final paymentDue = (data['PaymentDue'] as Timestamp).toDate();
  final initiatedBy = data['InitiatedBy'] as String;

  // Check if the payment is initiated by the current user
  final bool isInitiatedByCurrentUser = initiatedBy == FirebaseAuth.instance.currentUser!.uid;

  return Card(
    margin: EdgeInsets.all(8.0),
    child: ListTile(
      title: Text(data['PoolName']),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount: \LKR ${data['PoolAmount']}'),
          Text('Payment Due: ${DateFormat('yyyy-MM-dd').format(paymentDue)}'),
        ],
      ),
      onTap: () {
        // Redirect to PaymentDetailPage with groupId and documentId
        Navigator.pushNamed(
          context,
          '/paymentdetail',
          arguments: {'groupId': groupId, 'documentId': payment.id},
        );
      },
      // Add a button if the payment is initiated by the current user
      trailing: isInitiatedByCurrentUser
          ? ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/paymentmanage',
                  arguments: {'groupId': groupId, 'documentId': payment.id},
                );
              },

              child: Text(
                'Manage',
                style: TextStyle(color: Colors.white), // Set text color to white
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green), // Set button background color to green
              ),
            )
          : null, // If not initiated by current user, show nothing
    ),
  );
}



}

class AddFundPoolBottomPanel extends StatefulWidget {
  final String groupId;

  const AddFundPoolBottomPanel({Key? key, required this.groupId}) : super(key: key);

  @override
  _AddFundPoolBottomPanelState createState() => _AddFundPoolBottomPanelState();
}

class _AddFundPoolBottomPanelState extends State<AddFundPoolBottomPanel> {
  DateTime? selectedDate;
  TextEditingController poolNameController = TextEditingController();
  TextEditingController poolAmountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add New Fund Pool',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: poolNameController,
              decoration: InputDecoration(
                labelText: 'Pool Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              ),
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            TextField(
              controller: poolAmountController,
              decoration: InputDecoration(
                labelText: 'Pool Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Payment Due ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 1),
                GestureDetector(
                  onTap: _showInfoPopup,
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Text('Select Date'),
                  ),
                ),
              ],
            ),
            if (selectedDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Selected Date: ${selectedDate!.toString().substring(0, 10)}',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _addFundPoolToFirestore();
                },
                child: Text('Add'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Payment Due Information'),
          content: Text('This is the date by which the payment for the fund pool is due.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

        void _addFundPoolToFirestore() {
        String poolName = poolNameController.text;
        String poolAmount = poolAmountController.text;

        if (poolName.isEmpty || poolAmount.isEmpty || selectedDate == null) {
          // Show error message if any of the fields are empty
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please fill in all fields.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Get current user's UID
        String currentUserId = FirebaseAuth.instance.currentUser!.uid;

        // Fetch group members' UIDs
        FirebaseFirestore.instance
            .collection('amities')
            .doc(widget.groupId)
            .get()
            .then((DocumentSnapshot snapshot) {
              
          // Cast the data to Map<String, dynamic>
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

          // Get group members' UIDs from the 'GroupMembers' array
          List<String> groupMembers = List<String>.from(data['GroupMembers']);

          // Initialize PaymentStatus and PaymentEvidence maps
          Map<String, dynamic> paymentStatus = {};
          Map<String, dynamic> paymentEvidence = {};
          for (String memberId in groupMembers) {
            paymentStatus[memberId] = null;
            paymentEvidence[memberId] = null;
          }

          // Add new fund pool to Firestore
          FirebaseFirestore.instance
              .collection('amities')
              .doc(widget.groupId)
              .collection('FundCollection')
              .add({
            'PoolName': poolName,
            'PoolAmount': poolAmount,
            'PaymentDue': selectedDate,
            'InitiatedBy': currentUserId,
            'PaymentStatus': paymentStatus,
            'PaymentEvidence': paymentEvidence, // Add PaymentEvidence map
          }).then((value) {
            // Fund pool added successfully
            Navigator.of(context).pop(); // Close the bottom panel
          }).catchError((error) {
            // Handle error
            print('Error adding fund pool: $error');
          });
        });
      }

}
