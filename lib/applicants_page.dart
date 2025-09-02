import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neogig0/application_page.dart';  // Import the ApplicationDetailsPage
import 'package:neogig0/widgets/custom_drawer.dart';

class ApplicantsPage extends StatefulWidget {
  final String jobId;
  final String userRole;

  const ApplicantsPage({super.key, required this.userRole, required this.jobId});

  @override
  State<ApplicantsPage> createState() => _ApplicantsPageState();
}

class _ApplicantsPageState extends State<ApplicantsPage> {
  bool _loading = true;
  List<dynamic> _applications = [];

  // Load all applications for the specific job
  Future<void> _loadApplications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final res = await http.get(
        Uri.parse('http://10.0.2.2:1060/api/application/job/${widget.jobId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // print(data);
        setState(() {
          _applications = data['applications'];
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

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applicants for Job')),
      drawer: CustomDrawer(userRole: widget.userRole),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: _applications.length,
                itemBuilder: (context, index) {
                  final application = _applications[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: GestureDetector(
                        onTap: () {
                          // Navigate to the ApplicationDetailsPage
                          // print(application['_id']);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ApplicationPage(
                                userRole: widget.userRole,
                                applicationId: application['_id'],
                              ),
                            ),
                          );
                        },
                        child: Text(
                          application['jobseekerID']['name'] ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      subtitle: Text(
                        'Status: ${application['status']}\nApplied on: ${application['appliedOn']}',
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
