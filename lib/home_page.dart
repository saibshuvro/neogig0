import 'package:flutter/material.dart';
import 'package:neogig0/widgets/custom_drawer.dart';
import 'jobseeker_profile_page.dart';

class HomePage extends StatelessWidget {
  final String userRole;
  const HomePage({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      drawer: CustomDrawer(userRole: userRole),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome!"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JobSeekerProfilePage(userRole: userRole),
                  ),
                );
              },
              child: const Text('Job Seeker Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
