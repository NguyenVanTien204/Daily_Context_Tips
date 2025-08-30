import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class AppPermissionHandler {
  static Future<void> requestInitialPermissions() async {
    // Request notification permission
    await Permission.notification.request();
    
    // Request location permission
    await _requestLocationPermission();
    
    // Request usage stats permission (Android only)
    if (await Permission.systemAlertWindow.isDenied) {
      await Permission.systemAlertWindow.request();
    }
  }

  static Future<bool> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
           permission == LocationPermission.whileInUse;
  }

  static Future<bool> hasNotificationPermission() async {
    return await Permission.notification.isGranted;
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  static Future<bool> requestUsageStatsPermission() async {
    // This is Android-specific and needs to be handled differently
    // The user needs to manually enable it in Settings
    return await Permission.systemAlertWindow.request().isGranted;
  }
}
