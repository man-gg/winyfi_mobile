import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dashboard_screen.dart';



class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final List<Map<String, String>> allReports = [
    {
      'router': 'Router 4',
      'status': 'Offline',
      'location': 'SSC OFFICE',
      'date': '06/18/25'
    },
    {
      'router': 'Router 6',
      'status': 'Offline',
      'location': 'Multimedia',
      'date': '06/17/25'
    },
    {
      'router': 'Router 10',
      'status': 'Offline',
      'location': 'VMB HALLWAY',
      'date': '06/10/25'
    },
    {
      'router': 'Router 15',
      'status': 'Offline',
      'location': 'LDC',
      'date': '06/05/25'
    },
  ];

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  List<Map<String, String>> get filteredReports {
    final formatter = DateFormat('MM/dd/yy');
    final String dateStr = formatter.format(selectedDate!);
    return allReports.where((report) => report['date'] == dateStr).toList();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate!,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MM/dd/yy');
    final displayDate = formatter.format(selectedDate!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/winyfi_logo.png'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search by Date: $displayDate',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.red),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Router No.', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredReports.isEmpty
                  ? const Center(child: Text('No reports found for this date.'))
                  : ListView.builder(
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = filteredReports[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.router, color: Colors.red),
                            title: Text(
                              report['router']!,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Offline'),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  report['location']!,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(report['date']!),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );

          }
        },
      ),
    );
  }
}
