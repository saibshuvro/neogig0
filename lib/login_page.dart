import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:neogig0/signup_company_page.dart';
import 'package:neogig0/signup_jobseeker_page.dart';
import 'package:neogig0/home_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neogig0/widgets/custom_drawer.dart';
import 'package:neogig0/company_profile_page.dart';

class LoginPage extends StatefulWidget {
  final String userRole; // Receive role from previous page
  const LoginPage({super.key, required this.userRole});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRole = widget.userRole;

    return Scaffold(
      appBar: AppBar(
          // title: Text('$userRole Login'), // Show role in the AppBar
          ),
      drawer: CustomDrawer(userRole: 'Not Logged'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$userRole Login',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    final email = _emailController.text;
                    final password = _passwordController.text;

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Please enter email and password')),
                      );
                      return;
                    }

                    final url = Uri.parse(userRole == 'Company'
                        ? 'http://10.0.2.2:1060/api/login/company'
                        : 'http://10.0.2.2:1060/api/login/jobseeker');

                    final response = await http.post(
                      url,
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(
                          {'email': email, 'password': password}),
                    );

                    if (response.statusCode == 200) {
                      final data = jsonDecode(response.body);
                      final token = data['token'];

                      // Store token locally for session persistence
                      final prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setString('authToken', token);
                      await prefs.setString('userRole', userRole);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Login successful!')),
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) {
                            if (userRole == 'Company') {
                              return CompanyProfilePage(userRole: userRole);
                            } else if (userRole == 'JobSeeker') {
                              return HomePage(userRole: userRole);
                            } else {
                              // If for some reason the user role is invalid, you could add a fallback or error page
                              return const Scaffold(
                                body: Center(child: Text('Invalid Role')),
                              );
                            }
                          },
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error: ${response.body}')),
                      );
                    }
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  text: "Don't Have an Account? ",
                  style:
                      const TextStyle(color: Colors.black, fontSize: 16),
                  children: [
                    TextSpan(
                      text: 'Sign Up',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          if (userRole == 'Company') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => SignUpCompanyPage(
                                        userRole: userRole,
                                      )),
                            );
                          } else if (userRole == 'JobSeeker') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => SignUpJobSeekerPage(
                                        userRole: userRole,
                                      )),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Unknown role')),
                            );
                          }
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
