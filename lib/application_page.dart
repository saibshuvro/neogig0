import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neogig0/widgets/custom_drawer.dart';

class ApplicationPage extends StatefulWidget {
  final String userRole;
  final String applicationId;  // Passed from ApplicantsPage

  const ApplicationPage({super.key, required this.userRole, required this.applicationId});

  @override
  State<ApplicationPage> createState() => _ApplicationPageState();
}

class _ApplicationPageState extends State<ApplicationPage> {
  bool _loading = true;
  Map<String, dynamic> _applicationDetails = {};
  String _selectedStatus = "Pending"; // Default status

  // Load the application details based on the applicationId
  Future<void> _loadApplicationDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final res = await http.get(
        Uri.parse('http://10.0.2.2:1060/api/application/${widget.applicationId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _applicationDetails = data['application'];
          _selectedStatus = _applicationDetails['status']; // Set initial status
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

  // Withdraw the application (delete operation)
  Future<void> _withdrawApplication() async {
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
          Uri.parse('http://10.0.2.2:1060/api/application/${widget.applicationId}'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Application withdrawn!')),
          );
          Navigator.pop(context, true); // Go back after withdrawal
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

  // Update the application status
  Future<void> _updateApplicationStatus(String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final res = await http.put(
        Uri.parse('http://10.0.2.2:1060/api/application/${widget.applicationId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application status updated!')),
        );
        setState(() {
          _selectedStatus = newStatus;
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
    }
  }

  @override
  void initState() {
    super.initState();
    _loadApplicationDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Details')),
      drawer: CustomDrawer(userRole: widget.userRole),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Title: ${_applicationDetails['jobID']['title']}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('Name: ${_applicationDetails['name']}'),
                  const SizedBox(height: 10),
                  Text('Description: ${_applicationDetails['description']}'),
                  const SizedBox(height: 10),
                  Text('Resume Link: ${_applicationDetails['resumeLink']}'),
                  const SizedBox(height: 10),
                  Text('Address: ${_applicationDetails['address']}'),
                  const SizedBox(height: 10),
                  Text('Contact Info: ${_applicationDetails['contactInfo']}'),
                  const SizedBox(height: 10),
                  Text('Status: ${_applicationDetails['status']}'),
                  const SizedBox(height: 10),
                  Text('Applied On: ${_applicationDetails['appliedOn']}'),
                  const SizedBox(height: 20),
                  if (widget.userRole == 'JobSeeker')
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _withdrawApplication,
                        child: const Text('Withdraw'),
                      ),
                    ),
                  if (widget.userRole == 'Company')
                    // Add dropdown to change application status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Change Status:'),
                        DropdownButton<String>(
                          value: _selectedStatus,
                          items: <String>['Pending', 'Shortlisted', 'Accepted', 'Rejected']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null && newValue != _selectedStatus) {
                              _updateApplicationStatus(newValue);
                            }
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
