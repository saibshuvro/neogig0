import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeoGig',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const RoleSelectionPage(),
    );
  }
}

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('Select Your Role'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Select Your Role', style: TextStyle(fontSize: 24),),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 80,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to login page with role = Company
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(userRole: 'Company'),
                    ),
                  );
                },
                child: const Text(
                  'Company',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 80,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to login page with role = Job Seeker
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(userRole: 'Job Seeker'),
                    ),
                  );
                },
                child: const Text(
                  'Job Seeker',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
