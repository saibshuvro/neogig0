import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neogig0/widgets/custom_drawer.dart';
import 'package:neogig0/edit_job_page.dart';
import 'package:neogig0/create_application_page.dart';
import 'package:neogig0/company_public_page.dart';

class JobPage extends StatefulWidget {
  final String userRole;
  final String jobId;

  const JobPage({super.key, required this.userRole, required this.jobId});

  @override
  State<JobPage> createState() => _JobPageState();
}

class _JobPageState extends State<JobPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _job = {};

  static const String baseUrl = "http://10.0.2.2:1060";

  @override
  void initState() {
    super.initState();
    _fetchJobDetails();
  }

  Future<void> _fetchJobDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        setState(() {
          _error = 'Please log in first.';
          _loading = false;
        });
        return;
      }

      final res = await http.get(
        Uri.parse("$baseUrl/api/job/${widget.jobId}"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _job = data['job'];
          _loading = false;
        });
      } else {
        setState(() {
          _error = "Error: ${res.statusCode}";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteJob(String jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete job?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first.')),
        );
        return;
      }

      final res = await http.delete(
        Uri.parse("$baseUrl/api/job/$jobId"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job deleted')),
        );
        Navigator.pop(context);  // Go back to the previous page (jobs list)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${res.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _infoTile(String label, String value, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(label),
        subtitle: Text(value.isEmpty ? '-' : value),
        onTap: onTap,
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      ),
    );
  }

  Widget _buildJobDetails() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    final companyObj = _job['companyID'];
    final companyName = companyObj?['name'] ?? 'N/A';
    // Try to get an id whether the backend uses _id or id, or even a plain string
    String? companyId;
    if (companyObj is Map) {
      companyId = (companyObj['_id'] ?? companyObj['id'])?.toString();
    } else if (companyObj is String) {
      companyId = companyObj; // sometimes relations are stored as string ids
    }
    final title = _job['title'] ?? 'N/A';
    final pay = _job['pay'] ?? 'N/A';
    final description = _job['description'] ?? 'N/A';
    final schedule = _job['schedule'] ?? [];
    final postedOn = _job['postedOn'] != null
        ? DateTime.parse(_job['postedOn']).toLocal().toString()
        : 'N/A';
    final isUrgent = _job['isUrgent'] ?? false;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _infoTile('Title', title),
          _infoTile(
            'Company',
            companyName,
            onTap: companyId == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CompanyPublicPage(
                          userRole: widget.userRole,
                          companyId: companyId!,
                        ),
                      ),
                    );
                  },
          ),
          _infoTile('Pay (per Hour)', pay),
          _infoTile('Description', description),
          _infoTile('Posted On', postedOn),
          _infoTile('Urgent', isUrgent ? 'Yes' : 'No'),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Text('Schedule:', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...schedule.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('${s['day']} - ${s['time_start']} to ${s['time_end']}'),
            );
          }).toList(),
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.userRole == 'Company')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditJobPage(userRole: widget.userRole, jobId: widget.jobId),
                        ),
                      );
                    },
                    child: const Text('Edit'),
                  ),
                ),
              if (widget.userRole == 'Company')
                const SizedBox(width: 12),
              if (widget.userRole == 'Company')
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade300),
                    onPressed: () async {
                      await _deleteJob(widget.jobId);  // Delete the job when pressed
                    },
                    child: const Text('Delete'),
                  ),
                ),
              if (widget.userRole == 'Company')
                const SizedBox(width: 12),
              if (widget.userRole == 'JobSeeker')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Add logic for "Apply" button if needed
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateApplicationPage(userRole: widget.userRole, jobId: widget.jobId),
                        ),
                      );
                    },
                    child: const Text('Apply'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: _buildJobDetails(),
      drawer: CustomDrawer(userRole: widget.userRole),
    );
  }
}
