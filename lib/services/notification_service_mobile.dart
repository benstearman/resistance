import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';

class MobileNotificationService implements NotificationService {
  @override
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  @override
  Future<bool> hasPermission() async {
    return await Permission.notification.isGranted;
  }
}

NotificationService getNotificationService() => MobileNotificationService();
