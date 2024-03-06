import 'package:flutter/material.dart';

class TopNavigationBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onDashboardSelected;
  final VoidCallback onSignOutSelected;

  const TopNavigationBar({
    Key? key,
    required this.onBack,
    required this.onDashboardSelected,
    required this.onSignOutSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // Disable default leading widget
      titleSpacing: 0, // Remove default title spacing
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          Image.asset(
            'assets/icons/Amity Link Black.png', // Provide your logo image path
            width: 120, // Set the desired width
            height: 60, // Set the desired height
            fit: BoxFit.contain,
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            onSignOutSelected();
            Navigator.pushNamed(context, '/');
          },
          icon: const Icon(Icons.exit_to_app),
        ),
        const SizedBox(width: 10), // Adjust spacing between avatar and icons as needed
        IconButton(
          onPressed: () {
            onDashboardSelected();
            Navigator.pushNamed(context, '/dashboard');
          },
           
          icon: const Icon(Icons.account_circle),
        ),
      ],
      backgroundColor: Colors.transparent, // Set AppBar background color to transparent
      elevation: 0, // Remove AppBar shadow
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4851D2), // Replace with your desired gradient colors
              Color(0xFF0F91CD),
            ],
          ),
        ),
      ),
    );
  }
}
