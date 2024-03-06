import 'package:flutter/material.dart';

class GroupBulletinBoardPage extends StatelessWidget {
  final String groupId;

  const GroupBulletinBoardPage({Key? key, required this.groupId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bulletin Board'),
      ),
      body: Center(
        child: Text(
          'Bulletin Board for Group ID: $groupId',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
