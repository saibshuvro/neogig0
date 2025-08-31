import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neogig0/widgets/custom_drawer.dart';

class EditJobPage extends StatefulWidget {
  final String userRole; // pass "Company" here
  final String jobId; // Job ID to edit
  const EditJobPage({super.key, required this.userRole, required this.jobId});

  @override
  State<EditJobPage> createState() => _EditJobPageState();
}

class _EditJobPageState extends State<EditJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _pay = TextEditingController();
  final _description = TextEditingController();
  bool _isUrgent = false;
  bool _loading = true;
  bool _saving = false;

  List<bool> selectedDays = List.generate(7, (_) => false); // For days selection
  bool isSameTime = true; // Whether all selected days have the same time
  TextEditingController startHour = TextEditingController();
  TextEditingController startMinute = TextEditingController();
  TextEditingController startAmPm = TextEditingController();
  TextEditingController endHour = TextEditingController();
  TextEditingController endMinute = TextEditingController();
  TextEditingController endAmPm = TextEditingController();

  // Load job data when the page is loaded
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final res = await http.get(
        Uri.parse('http://10.0.2.2:1060/api/job/${widget.jobId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final job = data['job'] as Map<String, dynamic>;

        _title.text = job['title'] ?? '';
        _pay.text = job['pay'] ?? '';
        _description.text = job['description'] ?? '';
        _isUrgent = job['isUrgent'] ?? false;

        // Load schedule
        final schedule = job['schedule'] as List<dynamic>;
        for (var item in schedule) {
          final dayIndex = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
              .indexOf(item['day']);
          if (dayIndex != -1) {
            selectedDays[dayIndex] = true;
            startHour.text = item['time_start'].split(':')[0];
            startMinute.text = item['time_start'].split(':')[1];
            endHour.text = item['time_end'].split(':')[0];
            endMinute.text = item['time_end'].split(':')[1];
          }
        }
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

  // Save the edited job information
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      // Prepare the job schedule
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

      final res = await http.put(
        Uri.parse('http://10.0.2.2:1060/api/job/${widget.jobId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': _title.text,
          'pay': _pay.text,
          'description': _description.text,
          'isUrgent': _isUrgent,
          'schedule': schedule,
        }),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Job updated')));
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
    _title.dispose();
    _pay.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.userRole;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Job')),
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
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Job Title'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _pay,
                      decoration: const InputDecoration(labelText: 'Pay'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _description,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    SwitchListTile(
                      title: const Text('Urgent'),
                      value: _isUrgent,
                      onChanged: (value) {
                        setState(() {
                          _isUrgent = value;
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
                              DropdownButton<int>(
                                value: startHour.text.isEmpty ? 1 : int.tryParse(startHour.text) ?? 1,
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
                      onPressed: _save,
                      child: Text(_saving ? 'Saving...' : 'Save'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
