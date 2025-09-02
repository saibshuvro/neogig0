import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neogig0/company_profile_page.dart';
import 'package:neogig0/widgets/custom_drawer.dart';

class CreateJobPage extends StatefulWidget {
  final String userRole;
  const CreateJobPage({super.key, required this.userRole});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _payController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Selected days (Mon..Sun)
  List<bool> selectedDays = List.generate(7, (_) => false);
  bool isUrgent = false;

  // One time block for ALL selected days
  final TextEditingController startHour = TextEditingController();
  final TextEditingController startMinute = TextEditingController();
  final TextEditingController startAmPm = TextEditingController();
  final TextEditingController endHour = TextEditingController();
  final TextEditingController endMinute = TextEditingController();
  final TextEditingController endAmPm = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default times to avoid parsing empty strings
    startHour.text = '9';
    startMinute.text = '00';
    startAmPm.text = 'AM';
    endHour.text = '5';
    endMinute.text = '00';
    endAmPm.text = 'PM';
  }

  String to24Hour(String hour, String minute, String ampm) {
    int h = int.tryParse(hour) ?? 9;
    if (ampm == 'PM' && h != 12) h += 12;
    if (ampm == 'AM' && h == 12) h = 0;
    return "${h.toString().padLeft(2, '0')}:${minute.padLeft(2, '0')}";
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) return;

    // Basic guards so we don't post bad data
    if (!selectedDays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one day')),
      );
      return;
    }
    if (startHour.text.isEmpty ||
        startMinute.text.isEmpty ||
        startAmPm.text.isEmpty ||
        endHour.text.isEmpty ||
        endMinute.text.isEmpty ||
        endAmPm.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end time')),
      );
      return;
    }

    final url = Uri.parse("http://10.0.2.2:1060/api/job/create");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first!')),
      );
      return;
    }

    final dayNames = [
      "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
    ];

    // Build one time block applied to all selected days
    final String start24 = to24Hour(startHour.text, startMinute.text, startAmPm.text);
    final String end24   = to24Hour(endHour.text, endMinute.text, endAmPm.text);

    final List<Map<String, String>> schedule = [];
    for (int i = 0; i < 7; i++) {
      if (selectedDays[i]) {
        schedule.add({
          "day": dayNames[i],
          "time_start": start24,
          "time_end": end24,
        });
      }
    }

    final bodyObj = {
      "title": _titleController.text.trim(),
      "pay": _payController.text.trim(), // pay stays STRING as requested
      "description": _descriptionController.text.trim(),
      "schedule": schedule,               // correct keys already
      "isUrgent": isUrgent,
    };

    // Debug print of EXACT payload we send
    // ignore: avoid_print
    print("JOB DATA: ${jsonEncode(bodyObj)}");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bodyObj),
    );

    if (!mounted) return;

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job created successfully!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CompanyProfilePage(userRole: widget.userRole)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Job")),
      drawer: CustomDrawer(userRole: widget.userRole),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Job Title"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _payController,
                decoration: const InputDecoration(labelText: "Pay (per Hour)"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              CheckboxListTile(
                title: const Text("Urgent"),
                value: isUrgent,
                onChanged: (bool? value) {
                  setState(() {
                    isUrgent = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Days selection
              const Text("Select Days:"),
              ...List.generate(7, (index) {
                return CheckboxListTile(
                  title: Text(
                    ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][index],
                  ),
                  value: selectedDays[index],
                  onChanged: (bool? value) {
                    setState(() {
                      selectedDays[index] = value ?? false;
                    });
                  },
                );
              }),

              const SizedBox(height: 12),

              // Single time block for ALL selected days
              const Text("Select Time for all days:"),
              const Text("Start Time:"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<int>(
                    value: startHour.text.isEmpty ? 1 : int.parse(startHour.text),
                    onChanged: (val) => setState(() => startHour.text = (val ?? 1).toString()),
                    items: List.generate(12, (i) {
                      return DropdownMenuItem(
                        value: i + 1,
                        child: Text("${i + 1}"),
                      );
                    }),
                  ),
                  DropdownButton<String>(
                    value: startMinute.text.isEmpty ? '00' : startMinute.text,
                    onChanged: (val) => setState(() => startMinute.text = val ?? '00'),
                    items: const [
                      DropdownMenuItem(value: '00', child: Text('00')),
                      DropdownMenuItem(value: '30', child: Text('30')),
                    ],
                  ),
                  DropdownButton<String>(
                    value: startAmPm.text.isEmpty ? 'AM' : startAmPm.text,
                    onChanged: (val) => setState(() => startAmPm.text = val ?? 'AM'),
                    items: const [
                      DropdownMenuItem(value: 'AM', child: Text('AM')),
                      DropdownMenuItem(value: 'PM', child: Text('PM')),
                    ],
                  ),
                ],
              ),

              const Text("End Time:"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<int>(
                    value: endHour.text.isEmpty ? 1 : int.parse(endHour.text),
                    onChanged: (val) => setState(() => endHour.text = (val ?? 1).toString()),
                    items: List.generate(12, (i) {
                      return DropdownMenuItem(
                        value: i + 1,
                        child: Text("${i + 1}"),
                      );
                    }),
                  ),
                  DropdownButton<String>(
                    value: endMinute.text.isEmpty ? '00' : endMinute.text,
                    onChanged: (val) => setState(() => endMinute.text = val ?? '00'),
                    items: const [
                      DropdownMenuItem(value: '00', child: Text('00')),
                      DropdownMenuItem(value: '30', child: Text('30')),
                    ],
                  ),
                  DropdownButton<String>(
                    value: endAmPm.text.isEmpty ? 'AM' : endAmPm.text,
                    onChanged: (val) => setState(() => endAmPm.text = val ?? 'PM'),
                    items: const [
                      DropdownMenuItem(value: 'AM', child: Text('AM')),
                      DropdownMenuItem(value: 'PM', child: Text('PM')),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createJob,
                child: const Text("Create Job"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
