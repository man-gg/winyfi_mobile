import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'reports_screen.dart';
import 'router_card.dart';
import 'splash_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> routers = [];
  String filter = 'All';
  bool ascending = true;
  Timer? _refreshTimer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRouters();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

Future<void> fetchRouters() async {
  setState(() => isLoading = true);

  try {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/routers'));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded['success'] == true) {
        List<dynamic> routerList = decoded['data'];

        setState(() {
          routers = routerList.map<Map<String, dynamic>>((item) => {
            'name': item['name'],
            'ip_address': item['ip_address'],
            'location': item['location'],
            'status': item['status'],
            'last_update': item['last_update'],
          }).toList();
        });
      } else {
        debugPrint('Failed to fetch routers: ${decoded['message']}');
      }
    } else {
      debugPrint('HTTP error: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error fetching routers: $e');
  } finally {
    setState(() => isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredRouters = routers.where((router) {
      if (filter == 'All') return true;
      return router['status'].toString().toLowerCase() == filter.toLowerCase();
    }).toList();

    filteredRouters.sort((a, b) => ascending
        ? a['name'].compareTo(b['name'])
        : b['name'].compareTo(a['name']));

    int onlineCount = routers.where((r) => r['status'] == 'online').length;
    int offlineCount = routers.where((r) => r['status'] == 'offline').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _confirmLogout(context);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/winyfi_logo.png'),
            ),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchRouters,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statusBox('online', onlineCount, Colors.green.shade300, () {
                          setState(() => filter = 'online');
                        }),
                        _statusBox('offline', offlineCount, Colors.red.shade300, () {
                          setState(() => filter = 'offline');
                        }),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => setState(() => filter = 'All'),
                          child: const Text('Show all', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward),
                          onPressed: () => setState(() => ascending = !ascending),
                        )
                      ],
                    ),
                    const SizedBox(height: 5),
                   Expanded(
                      child: RefreshIndicator(
                        onRefresh: fetchRouters, // your async function
                        child: filteredRouters.isEmpty
                            ? ListView( // must be scrollable for RefreshIndicator to work
                                children: const [
                                  SizedBox(height: 200),
                                  Center(child: Text('No routers found.')),
                                ],
                              )
                            : ListView.builder(
                                itemCount: filteredRouters.length,
                                itemBuilder: (context, index) {
                                  final router = filteredRouters[index];
                                  return AnimatedRouterCard(router: router);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _statusBox(String label, int count, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 90,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label[0].toUpperCase() + label.substring(1), style: const TextStyle(color: Colors.white, fontSize: 16)),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.router, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '$count routers',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close the dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }


