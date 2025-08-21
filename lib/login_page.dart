import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'signup_company_page.dart';
import 'signup_jobseeker_page.dart';

class LoginPage extends StatelessWidget {
  final String userRole; // Receive role from previous page

  const LoginPage({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text('$userRole Login'), // Show role in the AppBar
      ),
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
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement login logic here
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$userRole Login'),
                      ),
                    );
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
                  style: const TextStyle(color: Colors.black, fontSize: 16),
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
                              MaterialPageRoute(builder: (_) => const SignUpCompanyPage()),
                            );
                          } else if (userRole == 'Job Seeker') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignUpJobSeekerPage()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Unknown role')),
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
