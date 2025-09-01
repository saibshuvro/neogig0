// home_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../widgets/job_card.dart';
import '../widgets/custom_drawer.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  final String userRole;

  const HomePage({super.key, required this.userRole});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  String? _error;

  List<dynamic> _jobs = [];
  List<dynamic> _filteredJobs = [];

  // search + filter state
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _minPayCtrl = TextEditingController();
  final TextEditingController _maxPayCtrl = TextEditingController();
  bool _urgentOnly = false;

  final List<bool> _filterDays = List<bool>.filled(7, false); // Mon..Sun
  final TextEditingController _timeFromCtrl = TextEditingController(); // "HH:MM"
  final TextEditingController _timeToCtrl   = TextEditingController(); // "HH:MM"

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _searchCtrl.addListener(() => _applyFilter());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _minPayCtrl.dispose();
    _maxPayCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
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

    final url = Uri.parse('http://10.0.2.2:1060/api/job');
    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (!mounted) return;

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final jobs = (body['jobs'] ?? []) as List<dynamic>;
      setState(() {
        _jobs = jobs;
        _filteredJobs = jobs;
        _loading = false;
      });
      _applyFilter(); // re-apply active filters/search
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load jobs (${res.statusCode})')),
      );
    }
  }

  // Safely parse string pay like "৳ 15,000", "$1,200.50", "20000", etc.
  num? _parsePay(dynamic payField) {
    if (payField == null) return null;
    final s = payField.toString();
    // keep digits and at most one dot
    final cleaned = s
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .replaceFirstMapped(RegExp(r'\.'), (m) => '.')
        .trim();
    if (cleaned.isEmpty) return null;
    return num.tryParse(cleaned);
  }

  // --- NEW: schedule helpers ---
int? _parseHHMM(String raw) {
  final s = raw.trim();
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s);
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  if (h < 0 || h > 23 || min < 0 || min > 59) return null;
  return h * 60 + min; // minutes since 00:00
}

// If a range crosses midnight (end <= start), split into two ranges on a 0..1440 day.
List<List<int>> _expandOvernight(int startMin, int endMin) {
  if (endMin > startMin) return [[startMin, endMin]];
  // crosses midnight: [start, 1440) U [0, end)
  return [
    [startMin, 1440],
    [0, endMin],
  ];
}

bool _rangesOverlap(int aStart, int aEnd, int bStart, int bEnd) {
  return aStart < bEnd && bStart < aEnd;
}

// Check if ANY segment overlaps (handles overnight by expansion)
bool _anyOverlapExpanded(int s1, int e1, int s2, int e2) {
  final segs1 = _expandOvernight(s1, e1);
  final segs2 = _expandOvernight(s2, e2);
  for (final r1 in segs1) {
    for (final r2 in segs2) {
      if (_rangesOverlap(r1[0], r1[1], r2[0], r2[1])) return true;
    }
  }
  return false;
}


  // --- MODIFY _applyFilter to include schedule filtering ---
void _applyFilter() {
  final q = _searchCtrl.text.trim().toLowerCase();

  num? minPay = _minPayCtrl.text.trim().isEmpty
      ? null
      : num.tryParse(_minPayCtrl.text.trim());
  num? maxPay = _maxPayCtrl.text.trim().isEmpty
      ? null
      : num.tryParse(_maxPayCtrl.text.trim());

  // schedule filter intent
  final bool anyDaySelected = _filterDays.contains(true);
  final int? fStart = _parseHHMM(_timeFromCtrl.text);
  final int? fEnd   = _parseHHMM(_timeToCtrl.text);
  final bool hasTimeWindow = (fStart != null && fEnd != null);

  setState(() {
    _filteredJobs = _jobs.where((job) {
      // SEARCH
      final title = (job['title'] ?? '').toString().toLowerCase();
      final matchesSearch = q.isEmpty ? true : title.contains(q);

      // URGENT
      final isUrgent = (job['isUrgent'] ?? false) == true;
      final matchesUrgent = _urgentOnly ? isUrgent : true;

      // PAY
      final payNum = _parsePay(job['pay']);
      final matchesPay = () {
        if (minPay == null && maxPay == null) return true;
        if (payNum == null) return false;
        if (minPay != null && payNum < minPay) return false;
        if (maxPay != null && payNum > maxPay) return false;
        return true;
      }();

      // SCHEDULE
      final matchesSchedule = () {
        // no schedule filter provided
        if (!anyDaySelected && !hasTimeWindow) return true;

        final List<dynamic> sched = (job['schedule'] ?? []) as List<dynamic>;
        if (sched.isEmpty) return false;

        // Map index to day name
        const days = [
          "Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"
        ];

        // Iterate each schedule item: match if selected day AND (no time window OR overlap)
        for (final it in sched) {
          final dayStr = (it['day'] ?? '').toString();
          final dayIdx = days.indexOf(dayStr);
          if (dayIdx == -1) continue;

          // Day must be selected if any day filter is on; if no day selected but time filter exists, accept any day.
          final dayOk = anyDaySelected ? (_filterDays[dayIdx]) : true;
          if (!dayOk) continue;

          // If no time window, day match is enough
          if (!hasTimeWindow) return true;

          final ts = (it['time_start'] ?? '').toString();
          final te = (it['time_end'] ?? '').toString();
          final js = _parseHHMM(ts);
          final je = _parseHHMM(te);
          if (js == null || je == null) continue;

          if (_anyOverlapExpanded(js, je, fStart!, fEnd!)) {
            return true;
          }
        }
        return false;
      }();

      return matchesSearch && matchesUrgent && matchesPay && matchesSchedule;
    }).toList();
  });
}

  Future<void> _openFilterSheet() async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          void toggleDay(int i, bool v) {
            setModalState(() => _filterDays[i] = v);
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              top: 8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text('Filters',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Pay range (existing)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minPayCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Min pay',
                            hintText: 'e.g., 10000',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _maxPayCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Max pay',
                            hintText: 'e.g., 50000',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Urgent
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Urgent only'),
                    value: _urgentOnly,
                    onChanged: (v) => setModalState(() => _urgentOnly = v ?? false),
                  ),

                  const Divider(height: 20),

                  // Days
                  const Text('Days', style: TextStyle(fontWeight: FontWeight.w600)),
                  Column(
                    children: List.generate(7, (i) {
                      const dayNames = [
                        "Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"
                      ];
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(dayNames[i]),
                        value: _filterDays[i],
                        onChanged: (v) => toggleDay(i, v ?? false),
                      );
                    }),
                  ),

                  const SizedBox(height: 8),
                  // Time window
                  const Text('Time window (24-hour, overlaps allowed)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _timeFromCtrl,
                          decoration: const InputDecoration(
                            labelText: 'From (HH:MM)',
                            hintText: '09:00',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _timeToCtrl,
                          decoration: const InputDecoration(
                            labelText: 'To (HH:MM)',
                            hintText: '17:30',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _minPayCtrl.clear();
                            _maxPayCtrl.clear();
                            _urgentOnly = false;
                            for (int i=0;i<7;i++) _filterDays[i] = false;
                            _timeFromCtrl.clear();
                            _timeToCtrl.clear();
                            _applyFilter();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Optional: warn if only one of the time boxes is filled
                            final fs = _timeFromCtrl.text.trim();
                            final ts = _timeToCtrl.text.trim();
                            if ((fs.isEmpty) ^ (ts.isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Enter both From and To times (HH:MM)')),
                              );
                              return;
                            }
                            // Optional: validate HH:MM format strictly
                            if (fs.isNotEmpty && (_parseHHMM(fs) == null || _parseHHMM(ts) == null)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Use valid 24-hour times like 09:00, 18:30')),
                              );
                              return;
                            }
                            _applyFilter();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by job title…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchCtrl.clear();
                              _applyFilter();
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
              ),

              // Filter button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _openFilterSheet,
                      icon: const Icon(Icons.tune),
                      label: const Text('Filter'),
                    ),
                    const Spacer(),
                    // Tiny status hint
                    Text(
                      '${_filteredJobs.length} of ${_jobs.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchJobs,
                  child: _filteredJobs.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No jobs match your criteria')),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _filteredJobs.length,
                          itemBuilder: (context, index) {
                            final job = _filteredJobs[index];
                            return JobCard(
                              pageFrom: 'Home',
                              userRole: widget.userRole,
                              jobId: job['_id'],
                              title: job['title'] ?? '',
                              pay: job['pay'] ?? '',
                              companyName:
                                  job['companyID']?['name'] ?? 'Unknown',
                              isUrgent: job['isUrgent'] ?? false,
                              postedOn: DateTime.tryParse(
                                      job['postedOn'] ?? '') ??
                                  DateTime.now(),
                            );
                          },
                        ),
                ),
              ),
            ],
          );

    return Scaffold(
      appBar: AppBar(title: const Text("Available Jobs")),
      drawer: CustomDrawer(userRole: widget.userRole),
      body: body,
    );
  }
}
