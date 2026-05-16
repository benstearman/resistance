// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'notification_service.dart';

class WebNotificationService implements NotificationService {
  @override
  Future<bool> requestPermission() async {
    final permission = await html.Notification.requestPermission();
    return permission == 'granted';
  }

  @override
  Future<bool> hasPermission() async {
    return html.Notification.permission == 'granted';
  }
}

NotificationService getNotificationService() => WebNotificationService();
