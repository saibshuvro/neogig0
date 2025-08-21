import 'package:flutter/material.dart';
import 'package:neogig0/main.dart';
// import other pages if needed

class CustomDrawer extends StatelessWidget {
  final String userRole; // Pass this variable to control visibility

  // Constructor accepting the userRole
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
              'Menu',
              style: TextStyle(fontSize: 20),
            ),
          ),
          ListTile(
            title: const Text('Map'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MyApp()),
              );
            },
          ),
          // Conditionally show/hide this item based on userRole
          if (userRole == 'admin') // For example, if the userRole is 'admin'
            ListTile(
              title: const Text('Admin Panel'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to the Admin Panel or any other page
              },
            ),
          if (userRole == 'user') // For example, if the userRole is 'user'
            ListTile(
              title: const Text('User Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to the User Settings page
              },
            ),
        ],
      ),
    );
  }
}
