import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    // Initialize Android Alarm Manager
    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print('Notification clicked: ${response.payload}');
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // 1. Request POST_NOTIFICATIONS Permission (Android 13+)
      PermissionStatus notificationStatus =
          await Permission.notification.status;
      if (notificationStatus != PermissionStatus.granted) {
        // Request if not already granted
        await Permission.notification.request();
      }

      // 2. Request SCHEDULE_EXACT_ALARM Permission (Android 12+)
      // Note: This often requires navigating user to settings on newer Android versions if denied,
      // but asking explicitly helps.
      PermissionStatus alarmStatus = await Permission.scheduleExactAlarm.status;
      if (alarmStatus != PermissionStatus.granted) {
        await Permission.scheduleExactAlarm.request();
      }
    }
  }

  // Exposed method to trigger the alarm/notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? customSoundPath = prefs.getString('custom_sound_path');

    AndroidNotificationDetails androidPlatformChannelSpecifics;

    if (customSoundPath != null && File(customSoundPath).existsSync()) {
      // Use custom channel with unique ID based on path to ensure updates
      String channelId = 'daily_medicine_custom_${customSoundPath.hashCode}';

      // Clean up old channels if needed, but here we just create a fresh one for the specific sound.
      // Note: Accumulating channels is a minor risk but better than sound not updating.

      androidPlatformChannelSpecifics = AndroidNotificationDetails(
        channelId,
        'Medicine Reminders (Custom)',
        channelDescription: 'High priority alarms for medicine',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound:
            UriAndroidNotificationSound(File(customSoundPath).uri.toString()),
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );
    } else {
      androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'daily_medicine_channel_v6', // Unique channel ID
        'Medicine Reminders',
        channelDescription: 'High priority alarms for medicine',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );
    }

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: 'medicine_reminder',
    );
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? customSoundPath = prefs.getString('custom_sound_path');

      AndroidNotificationDetails androidPlatformChannelSpecifics;

      if (customSoundPath != null && File(customSoundPath).existsSync()) {
        String channelId = 'daily_medicine_custom_${customSoundPath.hashCode}';

        androidPlatformChannelSpecifics = AndroidNotificationDetails(
          channelId,
          'Medicine Reminders (Custom)',
          channelDescription: 'High priority alarms for medicine',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          playSound: true,
          sound:
              UriAndroidNotificationSound(File(customSoundPath).uri.toString()),
          enableVibration: true,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
        );
      } else {
        androidPlatformChannelSpecifics = const AndroidNotificationDetails(
          'daily_medicine_channel_v6',
          'Medicine Reminders',
          channelDescription: 'High priority alarms for medicine',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
        );
      }

      // 1. Schedule with Flutter Local Notifications (Good for foreground/standard reliability)
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(scheduledTime),
        NotificationDetails(
          android: androidPlatformChannelSpecifics,
        ),
        androidScheduleMode: AndroidScheduleMode
            .exactAllowWhileIdle, // Critical: exactAllowWhileIdle
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      /*
      // 2. Schedule with Android Alarm Manager (Backup - Disabled as per user request to use zonedSchedule only)
      if (Platform.isAndroid) {
        await AndroidAlarmManager.oneShotAt(
          _nextInstanceOfTime(scheduledTime),
          id, // Alarm ID
          alarmCallback, // Static callback function
          exact: true,
          wakeup: true,
          allowWhileIdle: true,
          alarmClock: true,
          rescheduleOnReboot: true,
          params: {
            'id': id,
            'title': title,
            'body': body,
          },
        );
      }
      */

      if (kDebugMode) {
        print('Scheduled notification & alarm $id for $scheduledTime');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling notification: $e');
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    if (Platform.isAndroid) {
      await AndroidAlarmManager.cancel(id);
    }
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    // Canceling all alarms in AlarmManager might be tricky if we don't track IDs,
    // but typically we cancel by ID. For now, rely on individual cancels or implementing a tracker if needed.
    // There is no global cancelAll for AlarmManager without IDs.
  }

  tz.TZDateTime _nextInstanceOfTime(DateTime time) {
    // Current time in the system/device timezone
    final DateTime now = DateTime.now();

    // create a DateTime object with today's date and the selected time components
    // This 'scheduledDate' assumes the device's local timezone
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has passed for today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Convert the Local DateTime to a TZDateTime using the initialized location (local/UTC)
    // .from() handles the conversion correctly (e.g. IST -> UTC absolute time)
    return tz.TZDateTime.from(scheduledDate, tz.local);
  }
}

// Top-level or static function for the background alarm callback
@pragma('vm:entry-point')
void alarmCallback(int id, Map<String, dynamic> params) async {
  // Initialize notification plugin again for the isolate
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // We don't need full init with settings here just to show, but it's safer to have basic init if needed.
  // Actually, 'show' works if the plugin was initialized in main, but this is a new isolate.
  // Re-initialization in background isolate might be needed.

  // Note: We cannot pass complex objects like NotificationDetails easily or rely on main Isolate state.
  // We define the details again here.

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'daily_medicine_channel_v5',
    'Medicine Reminders',
    channelDescription: 'High priority alarms for medicine',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    enableVibration: true,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    id,
    params['title'] ?? 'Medicine Reminder',
    params['body'] ?? 'Time to take your medicine!',
    platformChannelSpecifics,
  );

  if (kDebugMode) {
    print("Alarm fired for ID: $id");
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle background tap
}
