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
import 'package:AmityLink/pages/Group/Events/events_home.dart';
import 'package:AmityLink/pages/Group/Events/Upcoming/attendance_poll.dart';
import 'package:AmityLink/pages/Group/Events/Voting/attendance_date.dart';
import 'package:AmityLink/pages/Group/MemoryPics/event_memories.dart';
import 'package:AmityLink/pages/Group/MemoryPics/individual_memories.dart';
import 'package:AmityLink/pages/Group/Calendar/calendar_main.dart';
import 'package:AmityLink/pages/Group/FundCollection/fundcoll_home.dart';
import 'package:AmityLink/pages/Group/FundCollection/fundcoll_individual.dart';
import 'package:AmityLink/pages/Group/FundCollection/fundcoll_manage.dart';


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

           '/events_home': (context) {
            final String groupId = ModalRoute.of(context)!.settings.arguments as String;
            return EventsPage(groupId: groupId);
          },

          '/attendance_poll': (context) {
            final Map<String, dynamic> arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            final String documentId = arguments['documentId']!;
            final String groupId = arguments['groupId']!;
            return AttendancePollPage(documentId: documentId, groupId: groupId);
          },

          '/attendance_date': (context) {
            final Map<String, dynamic> arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            final String documentId = arguments['documentId']!;
            final String groupId = arguments['groupId']!;
            return AttendanceDatePage(documentId: documentId, groupId: groupId);
          },

          '/event_memories': (context) {
            final String groupId = ModalRoute.of(context)!.settings.arguments as String;
            return MemoryPicsPage(groupId: groupId);
          },

          '/individual_memory_page': (context) {
          final Map<String, dynamic> arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          final String groupId = arguments['groupId']!;
          final String documentId = arguments['documentId']!;
          return IndividualMemoryPage(groupId: groupId, documentId: documentId);
        },

         '/calendar': (context) {
            final String groupId = ModalRoute.of(context)!.settings.arguments as String;
            return  Calendar(groupId: groupId);
          },

          '/fundcollection': (context) {
            final String groupId = ModalRoute.of(context)!.settings.arguments as String;
            return  FundCollectionPage(groupId: groupId);
          },

          '/paymentdetail': (context) {
          final Map<String, dynamic> arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          final String groupId = arguments['groupId']!;
          final String documentId = arguments['documentId']!;
          return  PaymentDetailPage(groupId: groupId, documentId: documentId);
        },

        '/paymentmanage': (context) {
          final Map<String, dynamic> arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          final String groupId = arguments['groupId']!;
          final String documentId = arguments['documentId']!;
          return  EventManagementPage(groupId: groupId, documentId: documentId);
        },


        },
      ),
    );
  }
}