import 'package:AmityLink/firebase_options.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:AmityLink/widget_tree.dart';
import 'package:flutter_no_internet_widget/flutter_no_internet_widget.dart';
import '../pages/login_register_page.dart';
import 'package:AmityLink/pages/join_add.dart';
import 'package:AmityLink/pages/add_group.dart';
import 'package:AmityLink/pages/User/user_dashboard.dart';
import 'package:AmityLink/pages/Group/BulletinBoard/bulletin_main.dart';
import 'package:AmityLink/pages/Group/GroupSettings/group_settings.dart';

Future<void>main()async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options:DefaultFirebaseOptions.currentPlatform,
    );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InternetWidget(
      offline: const FullScreenWidget(),
      // ignore: avoid_print
      whenOffline: () => print('No Internet'),
      // ignore: avoid_print
      whenOnline: () => print('Connected to internet'),
      loadingWidget: const Center(child: Text('Loading')),
      online: MaterialApp(
        debugShowCheckedModeBanner: false, // Remove debug banner
        title: 'Amity Link',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => WidgetTree(),
          '/login': (context) => LoginPage(),
          '/joinadd': (context) => JoinAddPage(),
          '/addgroup': (context) => AddGroupPage(),
          '/dashboard': (context) => UserDashboard(),
          '/bulletin_board': (context) {
            final String groupId = ModalRoute.of(context)!.settings.arguments as String;
            return GroupBulletinBoardPage(groupId: groupId);
          },

          '/group_settings': (context) {
            final String groupId = ModalRoute.of(context)!.settings.arguments as String;
            return GroupManagementPage(groupId: groupId);
          },

          // Define other routes here
        },
      ),
    );
  }
}