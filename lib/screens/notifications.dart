import 'package:flutter/material.dart';
import '../app_state.dart';
import '../cloud.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // get the latest notices from Firestore when the screen opens
    loadNoticesFromCloud().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (notices.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No notices right now. Check back soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            for (var n in notices)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(
                            label: Text(n.type, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                          ),
                          const Spacer(),
                          Text(n.date, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(n.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(n.body),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}