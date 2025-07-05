import 'package:flutter/material.dart';

class AnimatedRouterCard extends StatefulWidget {
  final Map<String, dynamic> router;

  const AnimatedRouterCard({super.key, required this.router});

  @override
  State<AnimatedRouterCard> createState() => _AnimatedRouterCardState();
}

class _AnimatedRouterCardState extends State<AnimatedRouterCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isOnline = false;

  @override
  void initState() {
    super.initState();
    isOnline = widget.router['status'] == 'online';
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 0.3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = widget.router;

    return Card(
      elevation: 4,
      child: ListTile(
        leading: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Opacity(
              opacity: _animation.value,
              child: Icon(Icons.circle,
                  color: isOnline ? Colors.green : Colors.red, size: 16),
            );
          },
        ),
        title: Text('${router['name']} | ${router['status']}'),
        subtitle: Text('${router['ip_address']}\n${router['location']}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(router['name']),
              content: Text(
                  'IP: ${router['ip_address']}\nStatus: ${router['status']}\nLocation: ${router['location']}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
