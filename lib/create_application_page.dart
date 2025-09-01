import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class CreateApplicationPage extends StatefulWidget {
  final String jobId;
  final String userRole;

  const CreateApplicationPage({
    super.key,
    required this.jobId,
    required this.userRole,
  });

  @override
  State<CreateApplicationPage> createState() => _CreateApplicationPageState();
}

class _CreateApplicationPageState extends State<CreateApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _resumeLink = TextEditingController();
  final _address = TextEditingController();
  final _contactInfo = TextEditingController();

  bool _loading = true;
  bool _submitting = false;

  Future<void> _loadJobSeeker() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final res = await http.get(
        Uri.parse('http://10.0.2.2:1060/api/jobseeker/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final js = data['jobSeeker'] as Map<String, dynamic>;
        _name.text = js['name'] ?? '';
        _description.text = js['description'] ?? '';
        _resumeLink.text = js['resumeLink'] ?? '';
        _address.text = js['address'] ?? '';
        _contactInfo.text = js['contactInfo'] ?? '';
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

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final res = await http.post(
        Uri.parse('http://10.0.2.2:1060/api/application'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'jobID': widget.jobId,
          'name': _name.text,
          'description': _description.text,
          'resumeLink': _resumeLink.text,
          'address': _address.text,
          'contactInfo': _contactInfo.text,
          // jobseekerID comes from JWT on server
          // status and appliedOn handled server-side
        }),
      );

      if (res.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted!')),
        );
        Navigator.pop(context, true);
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadJobSeeker();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _resumeLink.dispose();
    _address.dispose();
    _contactInfo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Job')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _description,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    TextFormField(
                      controller: _resumeLink,
                      decoration:
                          const InputDecoration(labelText: 'Resume Link'),
                    ),
                    TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _contactInfo,
                      decoration:
                          const InputDecoration(labelText: 'Contact Info'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submitApplication,
                        child: Text(
                            _submitting ? 'Submitting...' : 'Submit Application'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
