import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'package:neogig0/widgets/custom_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');
  final role = prefs.getString('userRole');

  runApp(MyApp(
    token: token,
    role: role,
  ));
}

class MyApp extends StatelessWidget {
  final String? token;
  final String? role;

  const MyApp({super.key, this.token, this.role});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeoGig',
      theme: ThemeData(primarySwatch: Colors.green),
      // Decide the first page based on token/role
      home: (token != null && role != null)
          ? HomePage(userRole: role!)
          : const RoleSelectionPage(),
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
      drawer: CustomDrawer(userRole: 'Not Logged'),
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
