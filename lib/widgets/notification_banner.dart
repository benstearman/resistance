import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationBanner extends StatefulWidget {
  const NotificationBanner({super.key});

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await NotificationService.instance.hasPermission();
    if (!hasPermission && mounted) {
      setState(() => _isVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "resistance.chat works best with notifications.",
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () async {
              final granted = await NotificationService.instance.requestPermission();
              if (granted && mounted) {
                setState(() => _isVisible = false);
              }
            },
            child: const Text("ALLOW", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            onPressed: () => setState(() => _isVisible = false),
          ),
        ],
      ),
    );
  }
}
