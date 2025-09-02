import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:neogig0/job_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobCard extends StatefulWidget {
  final String pageFrom;
  final String userRole;
  final String jobId;
  final String title;
  final String pay;
  final String companyName;
  final bool isUrgent;
  final DateTime postedOn;

  const JobCard({
    super.key,
    required this.pageFrom,
    required this.userRole,
    required this.jobId,
    required this.title,
    required this.pay,
    required this.companyName,
    required this.isUrgent,
    required this.postedOn,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _saving = false;
  bool _unsaving = false;
  String? _error;

  Future<void> _saveJob() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) {
      setState(() {
        _error = 'Please log in first.';
        _saving = false;
      });
      return;
    }

    final url = Uri.parse('http://10.0.2.2:1060/api/savedjob/${widget.jobId}');
    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    setState(() => _saving = false);

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job saved successfully!')),
      );
    } else {
      final body = jsonDecode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(body['error'] ?? 'Error saving job')),
      );
    }
  }

  Future<void> _unsaveJob() async {
    setState(() {
      _unsaving = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) {
      setState(() {
        _error = 'Please log in first.';
        _unsaving = false;
      });
      return;
    }

    final url = Uri.parse('http://10.0.2.2:1060/api/savedjob/${widget.jobId}');
    final res = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    setState(() => _unsaving = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job unsaved successfully!')),
      );
    } else {
      final body = jsonDecode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(body['error'] ?? 'Error unsaving job')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat.yMMMd().format(widget.postedOn);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title clickable
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => JobPage(
                          userRole: widget.userRole, jobId: widget.jobId)),
                );
              },
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text("Company: ${widget.companyName}",
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            Text("Pay (per Hour): ${widget.pay}"),
            if (widget.isUrgent)
              const Text("Urgent!",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            Text("Posted on: $dateFormatted"),
            const SizedBox(height: 10),

            // Save + Unsave buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.pageFrom == 'Home')
                  ElevatedButton(
                    onPressed: _saving ? null : _saveJob,
                    //style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreenAccent.shade200),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Save"),
                  ),
                // const SizedBox(width: 8),
                if (widget.pageFrom == 'Saved')
                  ElevatedButton(
                    onPressed: _unsaving ? null : _unsaveJob,
                    //style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade200),
                    child: _unsaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Unsave"),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
