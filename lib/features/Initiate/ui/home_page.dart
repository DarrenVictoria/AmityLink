import 'package:flutter/material.dart';
import 'package:AmityLink/features/Initiate/data/auth.dart';
import 'package:AmityLink/NavFooter/amitiesnav.dart';
import 'package:AmityLink/features/Group/group_dashboard_page.dart';
import 'package:AmityLink/features/Initiate/model/group.dart';
import 'package:AmityLink/features/Initiate/data/homepage_repository.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final Auth _auth = Auth();
  final GroupRepository _groupRepository = GroupRepository();

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: TopNavigationBar(
          onDashboardSelected: () {
            Navigator.pushNamed(context, '/dashboard');
          },
          onSignOutSelected: () {
            _signOut(context);
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'My Amities',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Group>>(
                    stream: _fetchJoinedGroups(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }

                      final groups = snapshot.data ?? [];

                      return ListView.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          return GroupCard(
                            group: group,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GroupDashboardPage(
                                    groupName: group.name!,
                                    groupId: group.id!,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/joinadd');
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Stream<List<Group>> _fetchJoinedGroups() async* {
    final user = _auth.currentUser;
    if (user != null) {
      final groups = await _groupRepository.getJoinedGroups(user.uid);
      yield groups;
    } else {
      yield [];
    }
  }
}

class GroupCard extends StatelessWidget {
  const GroupCard({
    Key? key,
    required this.group,
    required this.onTap,
  }) : super(key: key);

  final Group group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name ?? 'No Group Name',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'ID: ${group.id}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: ClipOval(
                  child: Container(
                    width: 100,
                    height: 100,
                    child: Image.network(
                      group.profilePictureUrl ?? 'https://static.thenounproject.com/png/1546235-200.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}