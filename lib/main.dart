import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // <-- added for JWT decode
import 'package:neogig0/login_page.dart';
import 'package:neogig0/home_page.dart';
import 'package:neogig0/widgets/custom_drawer.dart';
import 'package:neogig0/company_profile_page.dart';

Future<bool> _isJwtValid(String? token) async {
  if (token == null) return false;
  try {
    final parts = token.split('.');
    if (parts.length != 3) return false;

    // Decode payload (2nd part)
    String normalized = base64Url.normalize(parts[1]);
    final payloadJson = utf8.decode(base64Url.decode(normalized));
    final payload = json.decode(payloadJson) as Map<String, dynamic>;

    final exp = payload['exp'];
    if (exp is! int) return false;

    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return exp > nowSeconds; // valid if exp is in the future
  } catch (_) {
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');
  String? role = prefs.getString('userRole');

  final valid = await _isJwtValid(token);
  String? useToken = token;

  if (!valid) {
    // Clear stale creds
    await prefs.remove('authToken');
    await prefs.remove('userRole');
    useToken = null;
    role = null;
  }

  runApp(MyApp(
    token: useToken,
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
      // theme: ThemeData(primarySwatch: Colors.green),
      // Decide the first page based on token/role
      home: (token != null && role != null)
          ? (role == 'Company'
              ? CompanyProfilePage(userRole: role!)
              : HomePage(userRole: role!))
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
            const Text(
              'Select Your Role',
              style: TextStyle(fontSize: 24),
            ),
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
                      builder: (context) => LoginPage(userRole: 'JobSeeker'),
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
