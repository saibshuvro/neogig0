import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neogig0/widgets/custom_drawer.dart';

class EditJobPage extends StatefulWidget {
  final String userRole; // pass "Company" here
  final String jobId;    // Job ID to edit
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

  // Selected days (Mon..Sun)
  List<bool> selectedDays = List.generate(7, (_) => false);

  // Single time block for ALL selected days
  final TextEditingController startHour = TextEditingController();
  final TextEditingController startMinute = TextEditingController();
  final TextEditingController startAmPm = TextEditingController();
  final TextEditingController endHour = TextEditingController();
  final TextEditingController endMinute = TextEditingController();
  final TextEditingController endAmPm = TextEditingController();

  final List<String> _dayNames = const [
    "Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"
  ];

  @override
  void initState() {
    super.initState();
    // sensible defaults
    startHour.text = '9';
    startMinute.text = '00';
    startAmPm.text = 'AM';
    endHour.text = '5';
    endMinute.text = '00';
    endAmPm.text = 'PM';
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _pay.dispose();
    _description.dispose();
    startHour.dispose();
    startMinute.dispose();
    startAmPm.dispose();
    endHour.dispose();
    endMinute.dispose();
    endAmPm.dispose();
    super.dispose();
  }

  // Convert "HH:MM" (24h) -> (hour 1..12, "MM", "AM"/"PM")
  void _from24To12(String hhmm, TextEditingController hCtrl, TextEditingController mCtrl, TextEditingController apCtrl) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return;
    int hh = int.tryParse(parts[0]) ?? 9;
    final mm = parts[1].padLeft(2, '0');

    final ampm = (hh >= 12) ? 'PM' : 'AM';
    if (hh == 0) hh = 12;
    else if (hh > 12) hh -= 12;

    hCtrl.text = hh.toString();
    mCtrl.text = mm;
    apCtrl.text = ampm;
  }

  String _to24Hour(String hour, String minute, String ampm) {
    int h = int.tryParse(hour) ?? 9;
    if (ampm == 'PM' && h != 12) h += 12;
    if (ampm == 'AM' && h == 12) h = 0;
    return "${h.toString().padLeft(2, '0')}:${minute.padLeft(2, '0')}";
  }

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
        _pay.text = job['pay'] ?? ''; // pay stays STRING
        _description.text = job['description'] ?? '';
        _isUrgent = job['isUrgent'] ?? false;

        // Days + time (use first schedule item's times if available)
        selectedDays = List<bool>.filled(7, false);
        final sched = (job['schedule'] ?? []) as List<dynamic>;
        if (sched.isNotEmpty) {
          // mark selected days
          for (final it in sched) {
            final idx = _dayNames.indexOf((it['day'] ?? '').toString());
            if (idx != -1) selectedDays[idx] = true;
          }
          // take first item's time as canonical (UI is single time block)
          final first = sched.first as Map<String, dynamic>;
          final ts = (first['time_start'] ?? '09:00').toString();
          final te = (first['time_end'] ?? '17:00').toString();
          _from24To12(ts, startHour, startMinute, startAmPm);
          _from24To12(te, endHour, endMinute, endAmPm);
        }
        if (mounted) setState(() {});
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: ${res.body}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Network error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!selectedDays.contains(true)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select at least one day')));
      return;
    }

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final start24 = _to24Hour(startHour.text, startMinute.text, startAmPm.text);
      final end24   = _to24Hour(endHour.text, endMinute.text, endAmPm.text);

      final List<Map<String, String>> schedule = [];
      for (int i = 0; i < 7; i++) {
        if (selectedDays[i]) {
          schedule.add({
            "day": _dayNames[i],
            "time_start": start24,
            "time_end": end24,
          });
        }
      }

      final res = await http.put(
        Uri.parse('http://10.0.2.2:1060/api/job/${widget.jobId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': _title.text.trim(),
          'pay': _pay.text.trim(), // string
          'description': _description.text.trim(),
          'isUrgent': _isUrgent,
          'schedule': schedule,
        }),
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Job updated')));
        Navigator.pop(context, true); // signal caller to refresh
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${res.body}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Network error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                      decoration: const InputDecoration(labelText: 'Pay (per Hour)'),
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
                      onChanged: (value) => setState(() => _isUrgent = value),
                    ),
                    const SizedBox(height: 20),

                    // Days
                    const Text("Select Days:"),
                    ...List.generate(7, (index) {
                      return CheckboxListTile(
                        title: Text(_dayNames[index]),
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
                          items: List.generate(12, (i) => DropdownMenuItem(
                            value: i + 1, child: Text("${i + 1}"),
                          )),
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
                          items: List.generate(12, (i) => DropdownMenuItem(
                            value: i + 1, child: Text("${i + 1}"),
                          )),
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
                          value: endAmPm.text.isEmpty ? 'PM' : endAmPm.text,
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
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving...' : 'Save'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
