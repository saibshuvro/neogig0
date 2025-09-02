import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neogig0/widgets/custom_drawer.dart';
import 'package:neogig0/application_page.dart';

class AppliedJobsPage extends StatefulWidget {
  final String userRole;
  
  const AppliedJobsPage({super.key, required this.userRole});

  @override
  State<AppliedJobsPage> createState() => _AppliedJobsPageState();
}

class _AppliedJobsPageState extends State<AppliedJobsPage> {
  bool _loading = true;
  List<dynamic> _appliedJobs = [];

  // Load applied jobs for the JobSeeker
  Future<void> _loadAppliedJobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final res = await http.get(
        Uri.parse('http://10.0.2.2:1060/api/application/my'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        setState(() {
          _appliedJobs = data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${res.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Withdraw an application
  Future<void> _withdrawApplication(String applicationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Withdrawal'),
          content: const Text('Are you sure you want to withdraw this application?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Withdraw'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('authToken');
        final res = await http.delete(
          Uri.parse('http://10.0.2.2:1060/api/application/$applicationId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Application withdrawn!')),
          );
          _loadAppliedJobs();  // Refresh the list after withdrawal
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${res.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAppliedJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applied Jobs')),
      drawer: CustomDrawer(userRole: widget.userRole),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: _appliedJobs.length,
                itemBuilder: (context, index) {
                  final job = _appliedJobs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: GestureDetector(
                        onTap: () {
                          // Navigate to ApplicationDetailsPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ApplicationPage(
                                userRole: widget.userRole,
                                applicationId: job['_id'],  // Pass the application ID
                              ),
                            ),
                          );
                        },
                        child: Text(
                          job['jobID']['title'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      subtitle: Text(
                        'Status: ${job['status']}\nApplied on: ${job['appliedOn']}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _withdrawApplication(job['_id']),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
