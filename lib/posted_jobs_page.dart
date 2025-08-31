import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neogig0/widgets/custom_drawer.dart';
import 'job_page.dart';  // Import the JobPage
import 'edit_job_page.dart';

class PostedJobsPage extends StatefulWidget {
  final String userRole;
  const PostedJobsPage({super.key, required this.userRole});

  @override
  State<PostedJobsPage> createState() => _PostedJobsPageState();
}

class _PostedJobsPageState extends State<PostedJobsPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _jobs = [];

  // Adjust as needed for your dev/prod base URL
  static const String baseUrl = "http://10.0.2.2:1060";

  @override
  void initState() {
    super.initState();
    _fetchMyJobs();
  }

  Future<void> _fetchMyJobs() async {
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
        Uri.parse("$baseUrl/api/job/mine"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _jobs = (data['jobs'] as List?) ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = "Error ${res.statusCode}: ${res.body}";
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
        setState(() {
          _jobs.removeWhere((j) => (j['_id'] ?? j['id']) == jobId);
        });
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

  String _formatPostedOn(dynamic postedOnValue) {
    // Schema uses: postedOn: Date
    if (postedOnValue == null) return '';
    try {
      final dt = postedOnValue is String
          ? DateTime.parse(postedOnValue)
          : (postedOnValue is int
              ? DateTime.fromMillisecondsSinceEpoch(postedOnValue)
              : DateTime.tryParse(postedOnValue.toString()) ?? DateTime.now());
      final local = dt.toLocal();
      return "${_mon(local.month)} ${local.day}, ${local.year} – "
          "${_two(local.hour % 12 == 0 ? 12 : local.hour % 12)}:"
          "${_two(local.minute)} ${local.hour >= 12 ? 'PM' : 'AM'}";
    } catch (_) {
      return postedOnValue.toString();
    }
  }

  String _mon(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  String _two(int n) => n.toString().padLeft(2, '0');

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _fetchMyJobs, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_jobs.isEmpty) {
      return const Center(child: Text("You haven't posted any jobs yet."));
    }

    return RefreshIndicator(
      onRefresh: _fetchMyJobs,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final job = _jobs[i];

          final id = job['_id'] ?? job['id'];
          final title = (job['title'] ?? '').toString();
          final pay = (job['pay'] ?? '').toString();
          final postedOn = _formatPostedOn(job['postedOn']);

          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobPage(userRole: widget.userRole, jobId: id), // Navigate to JobPage when title is clicked
                        ),
                      );
                    },
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        postedOn.isEmpty ? 'Posted: —' : 'Posted: $postedOn',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                      if (pay.isNotEmpty)
                        Text("Pay: $pay",
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          // Navigate to Applicants page for this job
                        },
                        child: const Text('Applicants'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          // Navigate to Edit page with this job
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditJobPage(userRole: widget.userRole, jobId: id), // Navigate to JobPage when title is clicked
                            ),
                          );
                        },
                        child: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: () => _deleteJob(id),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Posted Jobs')),
      body: _buildBody(),
      drawer: CustomDrawer(userRole: widget.userRole),
    );
  }
}
