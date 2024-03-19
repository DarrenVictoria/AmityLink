import 'package:flutter/material.dart';

class Offline extends StatelessWidget {
  const Offline({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Set debugShowCheckedModeBanner to false
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/No_Connection.png', // Adjust the path according to your project structure
                width: 350,
                height: 350,
              ),
              const SizedBox(height: 20),
              const Text(
                'You are currently offline',
                style: TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Retry action
                  // You can put your retry logic here
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
