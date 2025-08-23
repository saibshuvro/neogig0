import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neogig0/widgets/custom_drawer.dart';

class EditJobSeekerPage extends StatefulWidget {
  final String userRole; // pass "JobSeeker" here
  const EditJobSeekerPage({super.key, required this.userRole});

  @override
  State<EditJobSeekerPage> createState() => _EditJobSeekerPageState();
}

class _EditJobSeekerPageState extends State<EditJobSeekerPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _resumeLink = TextEditingController();
  final _address = TextEditingController();
  final _contactInfo = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final res = await http.get(
        Uri.parse('http://10.0.2.2:1060/api/jobseeker/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final j = data['jobSeeker'] as Map<String, dynamic>;
        _name.text = j['name'] ?? '';
        _description.text = j['description'] ?? '';
        _resumeLink.text = j['resumeLink'] ?? '';
        _address.text = j['address'] ?? '';
        _contactInfo.text = j['contactInfo'] ?? '';
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${res.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Network error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final res = await http.put(
        Uri.parse('http://10.0.2.2:1060/api/jobseeker'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _name.text,
          'description': _description.text,
          'resumeLink': _resumeLink.text,
          'address': _address.text,
          'contactInfo': _contactInfo.text,
        }),
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated')));
        Navigator.pop(context, true); // signal caller to refresh
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${res.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Network error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
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
    final role = widget.userRole;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit JobSeeker Profile')),
      drawer: CustomDrawer(userRole: role),
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
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _description,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    TextFormField(
                      controller: _resumeLink,
                      decoration: const InputDecoration(labelText: 'Resume Link'),
                    ),
                    TextFormField(
                      controller: _address,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _contactInfo,
                      decoration: const InputDecoration(labelText: 'Contact Info'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Saving...' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
