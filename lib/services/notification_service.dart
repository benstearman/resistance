import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  Future<bool> requestPermission() async {
    if (kIsWeb) {
      final permission = await html.Notification.requestPermission();
      return permission == 'granted';
    } else {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
  }

  Future<bool> hasPermission() async {
    if (kIsWeb) {
      return html.Notification.permission == 'granted';
    } else {
      return await Permission.notification.isGranted;
    }
  }
}
