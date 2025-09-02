import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:neogig0/widgets/custom_drawer.dart';

class CompanyPublicPage extends StatefulWidget {
  final String userRole;   // e.g., "JobSeeker" or "Company"
  final String companyId;  // pass the actual company _id (or "me" to use /me)
  const CompanyPublicPage({super.key, required this.userRole, required this.companyId});

  @override
  State<CompanyPublicPage> createState() => _CompanyPublicPageState();
}

class _CompanyPublicPageState extends State<CompanyPublicPage> {
  Map<String, dynamic>? _company;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCompany();
  }

  Future<void> _fetchCompany() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      // If you pass "me", it will hit /api/company/me; otherwise /api/company/:id
      final endpoint = widget.companyId == 'me'
          ? 'http://10.0.2.2:1060/api/company/me'
          : 'http://10.0.2.2:1060/api/company/${widget.companyId}';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final res = await http.get(Uri.parse(endpoint), headers: headers);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        // Support both { company: {...} } and a direct {...} payload
        final company = (json is Map && json['company'] is Map)
            ? (json['company'] as Map<String, dynamic>)
            : (json as Map<String, dynamic>);

        setState(() {
          _company = company;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'Failed to load (${res.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Network error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company')),
      // drawer: CustomDrawer(userRole: widget.userRole),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchCompany,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _company == null
                  ? const Center(child: Text('No data'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView(
                        children: [
                          _infoTile('Name', _company!['name']),
                          _infoTile('Description', _company!['description'] ?? ''),
                          _infoTile('Location', _company!['location']),
                          _infoTile('Contact Info', _company!['contactInfo']),
                        ],
                      ),
                    ),
    );
  }

  Widget _infoTile(String label, String? value) {
    final v = (value ?? '').toString().trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(label),
        subtitle: Text(v.isEmpty ? '-' : v),
      ),
    );
  }
}
