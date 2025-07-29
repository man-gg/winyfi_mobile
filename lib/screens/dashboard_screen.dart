import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'reports_screen.dart';
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
  bool isLoading = true;
  String? errorMessage;
  bool _dialogIsOpen = false;
  Timer? _refreshTimer;

  // --- Double back to exit ---
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
    fetchRouters();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => fetchRouters(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchRouters() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final resp = await http
          .get(Uri.parse('http://192.168.1.19:5000/routers'))
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final data = body['data'] as List<dynamic>;
          setState(() {
            routers = data.map<Map<String, dynamic>>((item) {
              return {
                'id':          item['id'],
                'name':        item['name'],
                'ip_address':  item['ip_address'],
                'location':    item['location'],
                'status':      item['status'],
                'last_update': item['last_update'],
                'image_url':   item['image_url'],
                'error':       item['error'],
              };
            }).toList();
          });
          _dialogIsOpen = false;
        } else {
          throw Exception(body['message'] ?? 'Unknown server error');
        }
      } else {
        throw Exception('HTTP ${resp.statusCode}');
      }
    } on TimeoutException {
      errorMessage = 'Refresh failed: server did not respond.';
    } on SocketException {
      errorMessage = 'Refresh failed: cannot connect to server.';
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
      if (errorMessage != null && !_dialogIsOpen) {
        _dialogIsOpen = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Error'),
              content: Text(errorMessage!),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    fetchRouters();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ).then((_) => _dialogIsOpen = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = routers
        .where((r) {
          if (filter == 'All') return true;
          return r['status'].toString().toLowerCase() == filter.toLowerCase();
        })
        .toList()
      ..sort((a, b) => ascending
          ? a['name'].compareTo(b['name'])
          : b['name'].compareTo(a['name']));

    final onlineCount =
        routers.where((r) => r['status'] == 'online').length;
    final offlineCount =
        routers.where((r) => r['status'] == 'offline').length;

    // --- Double back to exit: Wrap Scaffold with WillPopScope ---
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > Duration(seconds: 2)) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Press again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true; // Now exit
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Dashboard'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: fetchRouters),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _confirmLogout(context),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircleAvatar(
                  backgroundImage: AssetImage('assets/images/winyfi_logo.png')),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: fetchRouters,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Search
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by name',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (txt) => setState(() {
                          filter = 'All';
                          routers = routers
                              .where((r) => r['name']
                                  .toString()
                                  .toLowerCase()
                                  .contains(txt.toLowerCase()))
                              .toList();
                        }),
                      ),
                      const SizedBox(height: 10),
                      // Status boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statusBox('online', onlineCount,
                              Colors.green.shade300, () {
                            setState(() => filter = 'online');
                          }),
                          _statusBox('offline', offlineCount,
                              Colors.red.shade300, () {
                            setState(() => filter = 'offline');
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Header + sort
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Devices',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => setState(() => filter = 'All'),
                            child: const Text('Show all',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(ascending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward),
                            onPressed: () =>
                                setState(() => ascending = !ascending),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Router list
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('No routers found.'))
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (ctx, i) {
                                  final r = filtered[i];
                                  // Always show the router icon, not the image
                                  Widget leading = Icon(
                                    Icons.router,
                                    color: r['status'] == 'online'
                                        ? Colors.green
                                        : Colors.red,
                                  );
                                  return Card(
                                    elevation: 3,
                                    child: ListTile(
                                      leading: leading,
                                      title: Text(r['name']),
                                      subtitle: Text(
                                          '${r['ip_address']}\n${r['location']}'),
                                      isThreeLine: true,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => RouterDetailScreen(r)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.report), label: 'Reports'),
          ],
          onTap: (i) {
            if (i == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _statusBox(
          String label, int count, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 150,
          height: 90,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label[0].toUpperCase() + label.substring(1),
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.router, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('$count routers',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 18)),
                ],
              )
            ],
          ),
        ),
      );

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          )
        ],
      ),
    );
  }
}


class RouterDetailScreen extends StatelessWidget {
  final Map<String, dynamic> router;
  const RouterDetailScreen(this.router, {super.key});

  @override
  Widget build(BuildContext context) {
    final imageUrl = router['image_url'] as String?;
    final status = (router['status'] ?? '').toString().toLowerCase();
    final isOnline = status == 'online';

    return Scaffold(
      appBar: AppBar(
        title: Text(router['name']),
        actions: [
          if (imageUrl != null)
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FullScreenImageView(imageUrl)),
                );
              },
              tooltip: 'View Image Full Screen',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Router location image with tap for full screen
              if (imageUrl != null) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FullScreenImageView(imageUrl)),
                    );
                  },
                  child: Hero(
                    tag: imageUrl,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl,
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (ctx, _, __) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Tap image to view full screen",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 18),
              ],

              // Router info card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.router,
                            color: isOnline ? Colors.green : Colors.red,
                            size: 38,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            router['name'],
                            style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                isOnline ? Icons.check_circle : Icons.cancel,
                                color: isOnline ? Colors.green : Colors.red,
                                size: 26,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOnline ? "Online" : "Offline",
                                style: TextStyle(
                                  color: isOnline ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      _infoTile(Icons.wifi, "IP Address", router['ip_address']),
                      _infoTile(Icons.place, "Location", router['location']),
                      _infoTile(Icons.update, "Last Update", router['last_update'] ?? '—'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for info tiles
  Widget _infoTile(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.grey[700]),
        const SizedBox(width: 13),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class FullScreenImageView extends StatelessWidget {
  final String url;
  const FullScreenImageView(this.url, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: Hero(
          tag: url,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 80, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
