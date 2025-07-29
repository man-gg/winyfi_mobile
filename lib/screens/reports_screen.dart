import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dashboard_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Logs tab: filter state
  DateTime logsStartDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime logsEndDate = DateTime.now();
  List<Map<String, dynamic>> routersList = [];
  String? logsSelectedRouterId;
  String logsSortOrder = 'desc'; // 'asc' or 'desc'

  // Uptime/Offenders: search and sort state
  bool isLoadingRouters = false;
  String uptimeSearch = '';
  String offendersSearch = '';
  String uptimeSortField = 'name';
  bool uptimeAscending = true;
  String offendersSortField = 'downtime_minutes';
  bool offendersDescending = true;

  @override
  void initState() {
    super.initState();
    fetchRoutersList();
  }

  Future<void> fetchRoutersList() async {
    setState(() => isLoadingRouters = true);
    try {
      final routersResp = await http.get(Uri.parse('http://192.168.1.19:5000/routers'));
      if (routersResp.statusCode != 200) throw Exception('Failed to load routers');
      final routersData = jsonDecode(routersResp.body)['data'] as List;
      setState(() {
        routersList = List<Map<String, dynamic>>.from(routersData);
        if (routersList.isNotEmpty && logsSelectedRouterId == null) {
          logsSelectedRouterId = routersList[0]['id'].toString();
        }
      });
    } finally {
      setState(() => isLoadingRouters = false);
    }
  }

  Future<double> fetchUptimePercentage(String routerId, DateTime start, DateTime end) async {
    final url = Uri.parse(
      'http://192.168.1.19:5000/reports/uptime'
      '?router_id=$routerId'
      '&start_date=${start.toIso8601String()}'
      '&end_date=${end.toIso8601String()}',
    );
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return (data['uptime_percentage'] as num).toDouble();
    }
    throw Exception('Unable to load uptime');
  }

  Future<List<Map<String, dynamic>>> fetchStatusLogs(
      String routerId, DateTime start, DateTime end, String sortOrder) async {
    final url = Uri.parse(
      'http://192.168.1.19:5000/reports/logs'
      '?router_id=$routerId'
      '&start_date=${start.toIso8601String()}'
      '&end_date=${end.toIso8601String()}'
      '&sort_order=$sortOrder',
    );
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data['logs']);
    }
    throw Exception('Unable to load logs');
  }

  Future<List<Map<String, dynamic>>> fetchAllUptime() async {
    if (routersList.isEmpty) await fetchRoutersList();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return Future.wait(routersList.map((r) async {
      final pct = await fetchUptimePercentage(
        r['id'].toString(),
        weekAgo,
        now,
      );
      return {
        'router': r['name'],
        'router_id': r['id'].toString(),
        'uptime': pct,
      };
    }));
  }

  Future<List<Map<String, dynamic>>> fetchAllOffenders() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));
    final url = Uri.parse(
      'http://192.168.1.19:5000/reports/offenders'
      '?start_date=${weekAgo.toIso8601String()}'
      '&end_date=${now.toIso8601String()}',
    );
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return List<Map<String, dynamic>>.from(data['offenders']);
    }
    throw Exception('Unable to load offenders');
  }

  String formatDurationFromMinutes(double minutes) {
    int secs = (minutes * 60).round();
    int years = secs ~/ (365 * 24 * 3600);
    secs %= (365 * 24 * 3600);
    int months = secs ~/ (30 * 24 * 3600);
    secs %= (30 * 24 * 3600);
    int days = secs ~/ (24 * 3600);
    secs %= (24 * 3600);
    int hours = secs ~/ 3600;
    secs %= 3600;
    int mins = secs ~/ 60;
    secs = secs % 60;

    final List<String> parts = [];
    if (years > 0) parts.add("$years year${years > 1 ? 's' : ''}");
    if (months > 0) parts.add("$months month${months > 1 ? 's' : ''}");
    if (days > 0) parts.add("$days day${days > 1 ? 's' : ''}");
    if (hours > 0) parts.add("$hours hour${hours > 1 ? 's' : ''}");
    if (mins > 0) parts.add("$mins minute${mins > 1 ? 's' : ''}");
    if (secs > 0 || parts.isEmpty) parts.add("$secs second${secs > 1 ? 's' : ''}");
    return parts.join(", ");
  }

  void showUptimeDetail(BuildContext context, String routerId, String routerName) async {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Uptime Details: $routerName'),
          content: FutureBuilder<double>(
            future: fetchUptimePercentage(
              routerId,
              DateTime.now().subtract(const Duration(days: 7)),
              DateTime.now(),
            ),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) return Text('Error: ${snap.error}');
              final pct = snap.data ?? 0.0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Uptime last 7 days:', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text('${pct.toStringAsFixed(2)}%', style: TextStyle(fontSize: 22, color: Colors.green[700], fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Text(
                    pct >= 99
                        ? "Excellent! Almost always online."
                        : pct >= 90
                            ? "Very good, minor interruptions."
                            : pct >= 70
                                ? "Some outages detected."
                                : "Low uptime. Check router status.",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Close")),
          ],
        );
      },
    );
  }

  void showDowntimeDetail(BuildContext context, String routerId, String routerName) async {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Downtime Details: $routerName'),
          content: FutureBuilder<Map<String, dynamic>>(
            future: fetchRouterDowntimeDates(routerId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) return Text('Error: ${snap.error}');
              final mins = (snap.data?['total_downtime_minutes'] as num?)?.toDouble() ?? 0.0;
              final downtimeList = snap.data?['downtimes'] as List<dynamic>? ?? [];
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total Downtime:', style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    Text(
                      formatDurationFromMinutes(mins),
                      style: TextStyle(fontSize: 20, color: Colors.red[700], fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 18),
                    Text('Downtime periods:', style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    downtimeList.isEmpty
                        ? Text("No recent downtime records.")
                        : Column(
                            children: downtimeList.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 5.0),
                                child: Text(
                                  "Down: ${item['start']}  -  Up: ${item['end'] ?? "Ongoing"}"
                                  "${item['duration_seconds'] != null ? " (${_humanizeDuration(item['duration_seconds'])})" : ""}",
                                  style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Close")),
          ],
        );
      },
    );
  }

  String _humanizeDuration(dynamic durationSeconds) {
    if (durationSeconds == null) return "";
    int secs = (durationSeconds as num).toInt();
    int hours = secs ~/ 3600;
    int mins = (secs % 3600) ~/ 60;
    int sec = secs % 60;
    final List<String> out = [];
    if (hours > 0) out.add('${hours}h');
    if (mins > 0) out.add('${mins}m');
    if (sec > 0) out.add('${sec}s');
    return out.isEmpty ? "0s" : out.join(' ');
  }

  Future<Map<String, dynamic>> fetchRouterDowntimeDates(String routerId) async {
    final url = Uri.parse(
      'http://192.168.1.19:5000/reports/downtime_detail?router_id=$routerId',
    );
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw Exception('Unable to load downtime details');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Reports'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Uptime'),
              Tab(text: 'Logs'),
              Tab(text: 'Offenders'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/images/winyfi_logo.png'),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // ===== UPTIME TAB =====
            isLoadingRouters
                ? Center(child: CircularProgressIndicator())
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchAllUptime(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                      List<Map<String, dynamic>> list = snap.data ?? [];
                      if (uptimeSearch.isNotEmpty) {
                        list = list
                            .where((r) => r['router']
                                .toLowerCase()
                                .contains(uptimeSearch.toLowerCase()))
                            .toList();
                      }
                      // Sort
                      list.sort((a, b) {
                        int cmp;
                        if (uptimeSortField == 'name') {
                          cmp = a['router'].toLowerCase().compareTo(b['router'].toLowerCase());
                        } else {
                          cmp = (a['uptime'] as double).compareTo(b['uptime'] as double);
                        }
                        return uptimeAscending ? cmp : -cmp;
                      });
                      if (list.isEmpty) return Center(child: Text("No routers."));
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Search router',
                                      prefixIcon: Icon(Icons.search),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
                                    ),
                                    onChanged: (txt) => setState(() => uptimeSearch = txt),
                                  ),
                                ),
                                SizedBox(width: 10),
                                PopupMenuButton<String>(
                                  onSelected: (val) {
                                    setState(() {
                                      if (val == 'name') {
                                        uptimeSortField = 'name';
                                      } else if (val == 'uptime') {
                                        uptimeSortField = 'uptime';
                                      }
                                    });
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(child: Text('Sort by Name'), value: 'name'),
                                    PopupMenuItem(child: Text('Sort by Uptime'), value: 'uptime'),
                                  ],
                                  child: Row(
                                    children: [
                                      Text(
                                        uptimeSortField == 'name' ? 'Name' : 'Uptime',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Icon(uptimeAscending ? Icons.arrow_upward : Icons.arrow_downward),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(uptimeAscending ? Icons.arrow_upward : Icons.arrow_downward),
                                  onPressed: () => setState(() => uptimeAscending = !uptimeAscending),
                                )
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              itemCount: list.length,
                              separatorBuilder: (_, __) => Divider(),
                              itemBuilder: (ctx, idx) {
                                final r = list[idx];
                                return ListTile(
                                  leading: Icon(Icons.router, color: r['uptime'] >= 90 ? Colors.green : Colors.red),
                                  title: Text(r['router']),
                                  subtitle: Text('Uptime: ${r['uptime'].toStringAsFixed(2)}%'),
                                  onTap: () => showUptimeDetail(ctx, r['router_id'], r['router']),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),

            // ===== LOGS TAB =====
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: logsStartDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2026),
                            );
                            if (picked != null) setState(() => logsStartDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Text("Start: ${DateFormat('MM/dd/yy').format(logsStartDate)}"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: logsEndDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2026),
                            );
                            if (picked != null) setState(() => logsEndDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Text("End: ${DateFormat('MM/dd/yy').format(logsEndDate)}"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: logsSortOrder,
                        items: [
                          DropdownMenuItem(value: 'asc', child: Text('Oldest')),
                          DropdownMenuItem(value: 'desc', child: Text('Newest')),
                        ],
                        onChanged: (v) => setState(() => logsSortOrder = v!),
                        underline: Container(),
                      ),
                    ],
                  ),
                ),
                if (routersList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: DropdownButton<String>(
                      value: logsSelectedRouterId,
                      items: routersList.map((r) {
                        return DropdownMenuItem(
                          value: r['id'].toString(),
                          child: Text(r['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          logsSelectedRouterId = value;
                        });
                      },
                      hint: Text('Select Router'),
                      isExpanded: true,
                    ),
                  ),
                const SizedBox(height: 10),
                Expanded(
                  child: logsSelectedRouterId == null
                      ? Center(child: Text('No router selected.'))
                      : FutureBuilder<List<Map<String, dynamic>>>(
                          future: fetchStatusLogs(
                            logsSelectedRouterId!,
                            logsStartDate,
                            logsEndDate,
                            logsSortOrder,
                          ),
                          builder: (context, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snap.hasError) {
                              return Center(child: Text('Error: ${snap.error}'));
                            }
                            final logs = snap.data ?? [];
                            if (logs.isEmpty) return Center(child: Text("No logs."));
                            return Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: 560,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: logs.length + 1,
                                    itemBuilder: (ctx, idx) {
                                      if (idx == 0) {
                                        return Row(
                                          children: [
                                            _logsHeader('Router', 120),
                                            _logsHeader('Timestamp', 220),
                                            _logsHeader('Status', 120),
                                          ],
                                        );
                                      }
                                      final log = logs[idx - 1];
                                      return Row(
                                        children: [
                                          _logsCell(
                                              routersList.firstWhere((r) => r['id'].toString() == logsSelectedRouterId)['name'],
                                              120),
                                          _logsCell(log['timestamp'].toString(), 220),
                                          _logsCell(log['status'].toString(), 120),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

            // ===== OFFENDERS TAB =====
            isLoadingRouters
                ? Center(child: CircularProgressIndicator())
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchAllOffenders(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                      List<Map<String, dynamic>> list = snap.data ?? [];
                      if (offendersSearch.isNotEmpty) {
                        list = list
                            .where((r) => r['router']
                                .toLowerCase()
                                .contains(offendersSearch.toLowerCase()))
                            .toList();
                      }
                      // Sort by downtime descending (default)
                      list.sort((a, b) {
                        int cmp;
                        if (offendersSortField == 'name') {
                          cmp = a['router'].toLowerCase().compareTo(b['router'].toLowerCase());
                        } else {
                          cmp = (a['downtime_minutes'] as double).compareTo(b['downtime_minutes'] as double);
                        }
                        return offendersDescending ? -cmp : cmp;
                      });
                      if (list.isEmpty) return Center(child: Text("No routers."));
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Search router',
                                      prefixIcon: Icon(Icons.search),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
                                    ),
                                    onChanged: (txt) => setState(() => offendersSearch = txt),
                                  ),
                                ),
                                SizedBox(width: 10),
                                PopupMenuButton<String>(
                                  onSelected: (val) {
                                    setState(() {
                                      if (val == 'name') {
                                        offendersSortField = 'name';
                                      } else if (val == 'downtime') {
                                        offendersSortField = 'downtime_minutes';
                                      }
                                    });
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(child: Text('Sort by Name'), value: 'name'),
                                    PopupMenuItem(child: Text('Sort by Downtime'), value: 'downtime'),
                                  ],
                                  child: Row(
                                    children: [
                                      Text(
                                        offendersSortField == 'name' ? 'Name' : 'Downtime',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Icon(offendersDescending ? Icons.arrow_downward : Icons.arrow_upward),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(offendersDescending ? Icons.arrow_downward : Icons.arrow_upward),
                                  onPressed: () => setState(() => offendersDescending = !offendersDescending),
                                )
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              itemCount: list.length,
                              separatorBuilder: (_, __) => Divider(),
                              itemBuilder: (ctx, idx) {
                                final r = list[idx];
                                return ListTile(
                                  leading: Icon(Icons.warning, color: (r['downtime_minutes'] < 60) ? Colors.green : Colors.red),
                                  title: Text(r['router']),
                                  subtitle: Text('Offline: ${r['downtime_pct'].toStringAsFixed(2)}%'),
                                  onTap: () => showDowntimeDetail(ctx, r['router_id'].toString(), r['router']),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.report), label: 'Reports'),
          ],
          onTap: (i) {
            if (i == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const DashboardScreen()),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _logsHeader(String text, double width) => Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        color: Colors.grey[200],
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
      );

  Widget _logsCell(String text, double width) => Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 15, color: Colors.black87)),
      );
}
