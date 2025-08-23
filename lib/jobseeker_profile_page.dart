import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neogig0/widgets/custom_drawer.dart';
import 'edit_jobseeker_page.dart';
import 'package:neogig0/main.dart';

class JobSeekerProfilePage extends StatefulWidget {
  final String userRole; // pass "JobSeeker" here
  const JobSeekerProfilePage({super.key, required this.userRole});

  @override
  State<JobSeekerProfilePage> createState() => _JobSeekerProfilePageState();
}

class _JobSeekerProfilePageState extends State<JobSeekerProfilePage> {
  Map<String, dynamic>? _jobSeeker;
  bool _loading = true;

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final res = await http.get(
        Uri.parse('http://10.0.2.2:1060/api/jobseeker/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _jobSeeker = data['jobSeeker'] as Map<String, dynamic>;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${res.body}')));
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  Future<void> _deleteJobSeeker() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    try {
      final res = await http.delete(
        Uri.parse('http://10.0.2.2:1060/api/jobseeker'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        await prefs.remove('authToken');
        await prefs.remove('userRole');
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Account deleted')));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MyApp()),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${res.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.userRole;

    return Scaffold(
      appBar: AppBar(title: const Text('JobSeeker Profile')),
      drawer: CustomDrawer(userRole: role),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _jobSeeker == null
              ? const Center(child: Text('No profile found'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      _infoTile('Name', _jobSeeker!['name']),
                      _infoTile('Description', _jobSeeker!['description'] ?? ''),
                      _infoTile('Resume Link', _jobSeeker!['resumeLink'] ?? ''),
                      _infoTile('Address', _jobSeeker!['address']),
                      _infoTile('Contact Info', _jobSeeker!['contactInfo']),
                      _infoTile('Created', (_jobSeeker!['createdAt'] ?? '').toString()),
                      _infoTile('Updated', (_jobSeeker!['updatedAt'] ?? '').toString()),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final changed = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditJobSeekerPage(userRole: role),
                                  ),
                                );
                                if (changed == true) {
                                  _fetchProfile();
                                }
                              },
                              child: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Account'),
                                    content: const Text(
                                        'Are you sure you want to delete this jobseeker account? This cannot be undone.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  _deleteJobSeeker();
                                }
                              },
                              child: const Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(label),
        subtitle: Text(value.isEmpty ? '-' : value),
      ),
    );
  }
}
