import 'package:flutter/material.dart';
import 'package:neogig0/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomDrawer extends StatelessWidget {
  final String userRole; // Pass this variable to control visibility

  const CustomDrawer({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green,
            ),
            child: Text(
              'NeoGig',
              style: TextStyle(fontSize: 20),
            ),
          ),
          ListTile(
            title: const Text('About Us'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('FAQ'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          if (userRole == 'Company' || userRole == 'Job Seeker')
            ListTile(
              title: const Text('Logout'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('authToken'); // Clear session
                await prefs.remove('userRole');

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                );
              },
            ),
        ],
      ),
    );
  }
}
