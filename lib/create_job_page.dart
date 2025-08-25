import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'company_profile_page.dart';

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

  List<bool> selectedDays = List.generate(7, (_) => false); // For days selection
  bool isSameTime = true; // Whether all selected days have the same time
  bool isUrgent = false;

  // Time controllers for start and end times
  TextEditingController startHour = TextEditingController();
  TextEditingController startMinute = TextEditingController();
  TextEditingController startAmPm = TextEditingController();
  TextEditingController endHour = TextEditingController();
  TextEditingController endMinute = TextEditingController();
  TextEditingController endAmPm = TextEditingController();

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse("http://10.0.2.2:1060/api/job/create");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken'); // Retrieve JWT token from local storage

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first!')),
      );
      return;
    }

    List<Map<String, String>> schedule = [];

    String to24Hour(String hour, String minute, String ampm) {
      int h = int.parse(hour);
      if (ampm == 'PM' && h != 12) h += 12;
      if (ampm == 'AM' && h == 12) h = 0;
      return "${h.toString().padLeft(2, '0')}:${minute.padLeft(2, '0')}";
    }


    // If 'Same time for all selected days' is checked
    if (isSameTime) {
      for (int i = 0; i < 7; i++) {
        if (selectedDays[i]) {
          schedule.add({
            "day": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][i],
            "time_start": to24Hour(startHour.text, startMinute.text, startAmPm.text),
            "time_end": to24Hour(endHour.text, endMinute.text, endAmPm.text),
          });
        }
      }
    }
    // If 'Same time for all selected days' is not checked
    else {
      for (int i = 0; i < 7; i++) {
        if (selectedDays[i]) {
          schedule.add({
            "day": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][i],
            "time_start": to24Hour(startHour.text, startMinute.text, startAmPm.text),
            "time_end": to24Hour(endHour.text, endMinute.text, endAmPm.text),
          });
        }
      }
    }

    final jobData = {
      "title": _titleController.text,
      "pay": _payController.text,  // make sure this is number or convert
      "description": _descriptionController.text,
      "schedule": schedule.map((s) => {
        "day": s["day"],
        "time_start": s["start"],
        "time_end": s["end"],
      }).toList(),
      "isUrgent": isUrgent, // if you have a checkbox/switch for urgent
    };

    print("JOB DATA: ${jsonEncode(jobData)}"); // 👈 debug log

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Pass the token in the Authorization header
      },
      body: jsonEncode({
        "title": _titleController.text,
        "pay": _payController.text,
        "description": _descriptionController.text,
        "schedule": schedule,
        "isUrgent": isUrgent,
      }),
    );

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
                decoration: const InputDecoration(labelText: "Pay"),
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
                    isUrgent = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Days selection (Checkboxes)
              const Text("Select Days:"),
              ...List.generate(7, (index) {
                return CheckboxListTile(
                  title: Text(
                    ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][index],
                  ),
                  value: selectedDays[index],
                  onChanged: (bool? value) {
                    setState(() {
                      selectedDays[index] = value!;
                    });
                  },
                );
              }),

              // Checkbox for same or different times
              CheckboxListTile(
                title: const Text("Same time for all selected days"),
                value: isSameTime,
                onChanged: (bool? value) {
                  setState(() {
                    isSameTime = value!;
                  });
                },
              ),

              // If Same time is checked, show one time selection
              if (isSameTime)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select Time for all days:"),
                    const Text("Start Time:"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Start Time (Hour, Minute, AM/PM)
                        DropdownButton<int>(
                          value: startHour.text.isEmpty ? 1 : int.parse(startHour.text),
                          onChanged: (val) {
                            setState(() {
                              startHour.text = val.toString();
                            });
                          },
                          items: List.generate(12, (i) {
                            return DropdownMenuItem(
                              value: i + 1,
                              child: Text("${i + 1}"),
                            );
                          }),
                        ),
                        DropdownButton<String>(
                          value: startMinute.text.isEmpty ? '00' : startMinute.text,
                          onChanged: (val) {
                            setState(() {
                              startMinute.text = val!;
                            });
                          },
                          items: const [
                            DropdownMenuItem(value: '00', child: Text('00')),
                            DropdownMenuItem(value: '30', child: Text('30')),
                          ],
                        ),
                        DropdownButton<String>(
                          value: startAmPm.text.isEmpty ? 'AM' : startAmPm.text,
                          onChanged: (val) {
                            setState(() {
                              startAmPm.text = val!;
                            });
                          },
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
                        // End Time (Hour, Minute, AM/PM)
                        DropdownButton<int>(
                          value: endHour.text.isEmpty ? 1 : int.parse(endHour.text),
                          onChanged: (val) {
                            setState(() {
                              endHour.text = val.toString();
                            });
                          },
                          items: List.generate(12, (i) {
                            return DropdownMenuItem(
                              value: i + 1,
                              child: Text("${i + 1}"),
                            );
                          }),
                        ),
                        DropdownButton<String>(
                          value: endMinute.text.isEmpty ? '00' : endMinute.text,
                          onChanged: (val) {
                            setState(() {
                              endMinute.text = val!;
                            });
                          },
                          items: const [
                            DropdownMenuItem(value: '00', child: Text('00')),
                            DropdownMenuItem(value: '30', child: Text('30')),
                          ],
                        ),
                        DropdownButton<String>(
                          value: endAmPm.text.isEmpty ? 'AM' : endAmPm.text,
                          onChanged: (val) {
                            setState(() {
                              endAmPm.text = val!;
                            });
                          },
                          items: const [
                            DropdownMenuItem(value: 'AM', child: Text('AM')),
                            DropdownMenuItem(value: 'PM', child: Text('PM')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              // If Same time is not checked, show time selection for each day
              if (!isSameTime)
                ...List.generate(7, (index) {
                  if (selectedDays[index]) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Time for ${["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][index]}:"),
                        const Text("Start Time:"),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Start Time (Hour, Minute, AM/PM)
                            DropdownButton<int>(
                              value: startHour.text.isEmpty ? 1 : int.parse(startHour.text),
                              onChanged: (val) {
                                setState(() {
                                  startHour.text = val.toString();
                                });
                              },
                              items: List.generate(12, (i) {
                                return DropdownMenuItem(
                                  value: i + 1,
                                  child: Text("${i + 1}"),
                                );
                              }),
                            ),
                            DropdownButton<String>(
                              value: startMinute.text.isEmpty ? '00' : startMinute.text,
                              onChanged: (val) {
                                setState(() {
                                  startMinute.text = val!;
                                });
                              },
                              items: const [
                                DropdownMenuItem(value: '00', child: Text('00')),
                                DropdownMenuItem(value: '30', child: Text('30')),
                              ],
                            ),
                            DropdownButton<String>(
                              value: startAmPm.text.isEmpty ? 'AM' : startAmPm.text,
                              onChanged: (val) {
                                setState(() {
                                  startAmPm.text = val!;
                                });
                              },
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
                            // End Time (Hour, Minute, AM/PM)
                            DropdownButton<int>(
                              value: endHour.text.isEmpty ? 1 : int.parse(endHour.text),
                              onChanged: (val) {
                                setState(() {
                                  endHour.text = val.toString();
                                });
                              },
                              items: List.generate(12, (i) {
                                return DropdownMenuItem(
                                  value: i + 1,
                                  child: Text("${i + 1}"),
                                );
                              }),
                            ),
                            DropdownButton<String>(
                              value: endMinute.text.isEmpty ? '00' : endMinute.text,
                              onChanged: (val) {
                                setState(() {
                                  endMinute.text = val!;
                                });
                              },
                              items: const [
                                DropdownMenuItem(value: '00', child: Text('00')),
                                DropdownMenuItem(value: '30', child: Text('30')),
                              ],
                            ),
                            DropdownButton<String>(
                              value: endAmPm.text.isEmpty ? 'AM' : endAmPm.text,
                              onChanged: (val) {
                                setState(() {
                                  endAmPm.text = val!;
                                });
                              },
                              items: const [
                                DropdownMenuItem(value: 'AM', child: Text('AM')),
                                DropdownMenuItem(value: 'PM', child: Text('PM')),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),

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
