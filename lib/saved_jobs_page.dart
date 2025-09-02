import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neogig0/widgets/job_card.dart';
import 'package:neogig0/widgets/custom_drawer.dart';

class SavedJobsPage extends StatefulWidget {
  final String userRole;
  
  const SavedJobsPage({super.key, required this.userRole});

  @override
  State<SavedJobsPage> createState() => _SavedJobsPageState();
}

class _SavedJobsPageState extends State<SavedJobsPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _savedJobs = [];

  @override
  void initState() {
    super.initState();
    _fetchSavedJobs();
  }

  Future<void> _fetchSavedJobs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) {
        setState(() {
          _error = 'Please log in first.';
          _loading = false;
        });
        return;
      }
    
    final url = Uri.parse('http://10.0.2.2:1060/api/savedjob');
    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      setState(() {
        _savedJobs = body['saved'];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load saved jobs (${res.statusCode})')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Jobs"),
      ),
      drawer: CustomDrawer(userRole: widget.userRole),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSavedJobs,
              child: _savedJobs.isEmpty
                  ? const Center(child: Text("No saved jobs yet"))
                  : ListView.builder(
                      itemCount: _savedJobs.length,
                      itemBuilder: (context, index) {
                        final saved = _savedJobs[index];
                        final job = saved['jobID'];

                        return JobCard(
                          pageFrom: 'Saved',
                          userRole: widget.userRole,
                          jobId: job['_id'],
                          title: job['title'] ?? '',
                          pay: job['pay'] ?? '',
                          companyName: job['companyID']?['name'] ?? 'Unknown',
                          isUrgent: job['isUrgent'] ?? false,
                          postedOn: DateTime.tryParse(job['postedOn'] ?? '') ??
                              DateTime.now(),
                        );
                      },
                    ),
            ),
    );
  }
}
