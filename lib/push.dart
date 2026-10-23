import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Lets us show a message at the bottom of the screen from anywhere in the app.
final GlobalKey<ScaffoldMessengerState> messengerKey =
GlobalKey<ScaffoldMessengerState>();

// Asks the student for permission, signs the phone up to the "notices"
// channel, and shows a banner if a notice arrives while the app is open.
// When the app is closed or in the background, the phone shows the
// notification by itself.
Future<void> setUpPush() async {
  // push is tested on the Android emulator, not in Chrome
  if (kIsWeb) return;

  try {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission();
    await messaging.subscribeToTopic('notices');

    final token = await messaging.getToken();
    debugPrint('Push token: $token');

    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;

      final text = [n.title, n.body]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(' - ');

      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 6),
        ),
      );
    });
  } catch (e) {
    debugPrint('setUpPush failed: $e');
  }
}