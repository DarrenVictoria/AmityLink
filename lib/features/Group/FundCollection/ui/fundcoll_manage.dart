import 'package:AmityLink/auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:AmityLink/NavFooter/usertopnav.dart';

class EventManagementPage extends StatefulWidget {
  final String groupId;
  final String documentId;

  const EventManagementPage({
    Key? key,
    required this.groupId,
    required this.documentId,
  }) : super(key: key);

  @override
  _EventManagementPageState createState() => _EventManagementPageState(
        groupId: groupId,
        documentId: documentId,
      );
}

class _EventManagementPageState extends State<EventManagementPage> {
  late String eventName = '';
  late int poolAmount = 0;
  late Map<String, dynamic> paymentEvidence = {};
  late Map<String, dynamic> paymentStatus = {};
  late List<String> participantIds = [];
  final String groupId;
  final String documentId;

  _EventManagementPageState({
    required this.groupId,
    required this.documentId,
  });

  @override
  void initState() {
    super.initState();
    _fetchEventData();
  }

  Future<void> signOut(BuildContext context) async {
    await Auth().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchEventData,
      child: Scaffold(
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
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '$eventName',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Collection Amount: $poolAmount',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: EventList(
                groupId: groupId,
                documentId: documentId,
                paymentEvidence: paymentEvidence,
                paymentStatus: paymentStatus,
                participantIds: participantIds,
                onUpdate: _fetchEventData,
              ),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _fetchEventData() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('amities')
        .doc(groupId)
        .collection('FundCollection')
        .doc(documentId)
        .get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      setState(() {
        eventName = data['PoolName'] ?? '';
        // Convert the 'PoolAmount' value to an integer
        poolAmount = int.tryParse(data['PoolAmount'] ?? '0') ?? 0;
        paymentEvidence = data['PaymentEvidence'] ?? {};
        paymentStatus = data['PaymentStatus'] ?? {};
        participantIds = paymentEvidence.keys.toList();
      });
    }
  } catch (error) {
    print('Error refreshing data: $error');
    // Handle error
  }
}


}

class EventList extends StatefulWidget {
  final String groupId;
  final String documentId;
  final Map<String, dynamic> paymentEvidence;
  final Map<String, dynamic> paymentStatus;
  final List<String> participantIds;
  final VoidCallback onUpdate;

  const EventList({
    Key? key,
    required this.groupId,
    required this.documentId,
    required this.paymentEvidence,
    required this.paymentStatus,
    required this.participantIds,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _EventListState createState() => _EventListState();
}

class _EventListState extends State<EventList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.participantIds.length,
      itemBuilder: (context, index) {
        final participantId = widget.participantIds[index];
        return FutureBuilder(
          future: FirebaseFirestore.instance.collection('users').doc(participantId).get(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return ListTile(
                title: Text('Loading...'),
              );
            }
            if (userSnapshot.hasError) {
              return ListTile(
                title: Text('Error loading user: ${userSnapshot.error}'),
              );
            }
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return ListTile(
                title: Text('User not found'),
              );
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final participantName = userData['name']; // Assuming 'name' is the field for the user's name

            final evidenceUploaded = widget.paymentEvidence[participantId] != null;
            final statusVerified = widget.paymentStatus[participantId] != null;

            return Card(
              color: Colors.white, // Set the background color of the card
              child: ListTile(
                title: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(evidenceUploaded ? 'Evidence Uploaded' : 'Evidence Not Uploaded'),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      statusVerified ? Icons.check : Icons.close,
                      color: statusVerified ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                subtitle: Text(participantName),
                trailing: evidenceUploaded && !statusVerified
                    ? ElevatedButton(
                        onPressed: () {
                          // Handle review evidence action
                          _showReviewEvidenceDialog(context, participantId, widget.paymentEvidence[participantId]);
                        },
                        child: Text('Review Evidence'),
                      )
                    : null, // Disable the button if evidence is not uploaded or payment status exists
              ),
            );
          },
        );
      },
    );
  }

  void _showReviewEvidenceDialog(BuildContext context, String participantId, String? evidenceUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String amount = '';
        return AlertDialog(
          title: Text('Review Evidence'),
          content: SingleChildScrollView( // Wrap content in SingleChildScrollView
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (evidenceUrl != null) Image.network(evidenceUrl), // Show image if evidence is uploaded
                TextField(
                  decoration: InputDecoration(hintText: 'Enter amount'),
                  onChanged: (value) {
                    amount = value;
                  },
                ),
              ],
            ),
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 16), // Padding for the actions
          actions: [
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () {
                  // Update PaymentStatus with the entered amount
                  // Assuming you have a function to update PaymentStatus
                  _updatePaymentStatus(context, participantId, amount);
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.green, // Background color for the Tick button
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.white), // Tick icon
                    SizedBox(width: 8),
                    Text('Approve Payment', style: TextStyle(color: Colors.white)), // Tick button text
                  ],
                ),
              ),
            ),
            SizedBox(width: 16), // Space between buttons
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () {
                  // Clear payment evidence for the particular UID
                  _clearPaymentEvidence(context, participantId);
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.red, // Background color for the Cross button
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, color: Colors.white), // Cross icon
                    SizedBox(width: 8),
                    Text('Decline Payment', style: TextStyle(color: Colors.white)), // Cross button text
                  ],
                ),
              ),
            ),
            SizedBox(width: 16),
          ],
        );
      },
    );
  }

  void _updatePaymentStatus(BuildContext context, String participantId, String amount) async {
    if (amount.isNotEmpty) {
      try {
        // Update PaymentStatus with the entered amount
        await FirebaseFirestore.instance
            .collection('amities')
            .doc(widget.groupId)
            .collection('FundCollection')
            .doc(widget.documentId)
            .update({
          'PaymentStatus.$participantId': amount,
        });
        // Close the dialog
        Navigator.of(context).pop();
        // Trigger update of parent widget
        widget.onUpdate();
      } catch (e) {
        print('Error updating payment status: $e');
        // Show an error message or handle the error accordingly
      }
    } else {
      // Show a message indicating that the amount is required
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter the amount')),
      );
    }
  }

  void _clearPaymentEvidence(BuildContext context, String participantId) async {
    try {
      // Clear the value for the participantId key in the PaymentEvidence map
      await FirebaseFirestore.instance
          .collection('amities')
          .doc(widget.groupId)
          .collection('FundCollection')
          .doc(widget.documentId)
          .update({
        'PaymentEvidence.$participantId': null,
        'PaymentStatus.$participantId': null, // Clear the value in PaymentStatus
      });
      // Close the dialog
      Navigator.of(context).pop();
      // Trigger update of parent widget
      widget.onUpdate();
    } catch (e) {
      print('Error clearing payment evidence: $e');
      // Show an error message or handle the error accordingly
    }
  }
}
