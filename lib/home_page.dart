import 'package:flutter/material.dart';
import 'package:neogig0/widgets/custom_drawer.dart';

class HomePage extends StatelessWidget {
  final String userRole;
  const HomePage({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      drawer: CustomDrawer(userRole: userRole),
      body: const Center(child: Text("Welcome!")),
    );
  }
}
