import 'package:flutter/material.dart';
// import 'package:neogig0/widgets/custom_drawer.dart';

class AboutUsPage extends StatelessWidget {
  final String userRole;

  const AboutUsPage({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      // drawer: CustomDrawer(userRole: userRole),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About NeoGig',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'NeoGig is a platform designed to connect job seekers and companies with ease. '
              'Whether you are a job seeker looking for your next opportunity or a company looking to hire the best talent, '
              'NeoGig offers tools to streamline your job search and recruitment process.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Our Mission:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'To create a seamless, efficient, and user-friendly platform that connects job seekers and employers. '
              'We aim to provide opportunities for individuals to grow professionally and for companies to build their teams with top talent.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Contact Us:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Email: support@neogig.com',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Phone: +1 234 567 890',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
