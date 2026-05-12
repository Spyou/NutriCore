import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  // Centralised toggle so emojis can be disabled globally if devices report
  // rendering issues (missing emoji fonts show tofu boxes instead).
  static const bool _useEmoji = true;

  static String _withEmoji(String emoji, String text) =>
      _useEmoji ? '$emoji $text' : text;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeService();
  }

  Future<void> _initializeService() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    // Request permissions
    await _requestPermissions();

    await _initializeNotifications();

    if (kDebugMode) {
      print('Working Notification Service initialized');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      if (kDebugMode) {
        print('Basic notification permission requested');
      }
    }
  }

  Future<bool> _requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        final status = await Permission.scheduleExactAlarm.status;

        if (status.isGranted) {
          if (kDebugMode) {
            print('Exact alarm permission already granted');
          }
          return true;
        } else if (status.isDenied) {
          final shouldRequest = await _showPermissionExplanation();

          if (shouldRequest) {
            // Request permission
            final result = await Permission.scheduleExactAlarm.request();

            if (result.isGranted) {
              if (kDebugMode) {
                print('Exact alarm permission granted');
              }
              _showPermissionGranted();
              return true;
            } else {
              if (kDebugMode) {
                print('Exact alarm permission denied');
              }
              _showPermissionDenied();
              return false;
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error requesting exact alarm permission: $e');
        }
      }
    }

    return false;
  }

  Future<bool> _showPermissionExplanation() async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.alarm, color: Colors.green),
                SizedBox(width: 8),
                Text('Precise Meal Reminders'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NutriCheck needs permission to send meal reminders at exact times.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This ensures you get:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('• Breakfast reminder at exactly 8:00 AM'),
                const Text('• Lunch reminder at exactly 1:00 PM'),
                const Text('• Dinner reminder at exactly 7:30 PM'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '💡 You can disable this anytime in your phone settings.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Not Now'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  'Allow Exact Timing',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showPermissionGranted() {
    Get.snackbar(
      'Permission Granted',
      'Your meal reminders will now work at exact times!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _showPermissionDenied() {
    CustomThemeFlushbar.show(
      title: 'Approximate Timing',
      message:
          'Reminders may be delayed by a few minutes without exact alarm permission',
    );
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    if (kDebugMode) {
      print('Notifications initialized');
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
    Get.toNamed('/nutrition');
  }

  Future<void> scheduleMealReminders({
    TimeOfDay? breakfastTime,
    TimeOfDay? lunchTime,
    TimeOfDay? dinnerTime,
    bool enableBreakfast = true,
    bool enableLunch = true,
    bool enableDinner = true,
  }) async {
    if (kDebugMode) {
      print('Scheduling meal reminders...');
    }
    final hasExactPermission = await _requestExactAlarmPermission();

    // Cancel existing reminders
    await _notifications.cancel(1); // Breakfast
    await _notifications.cancel(2); // Lunch
    await _notifications.cancel(3); // Dinner

    final breakfast = breakfastTime ?? const TimeOfDay(hour: 8, minute: 0);
    final lunch = lunchTime ?? const TimeOfDay(hour: 13, minute: 0);
    final dinner = dinnerTime ?? const TimeOfDay(hour: 19, minute: 30);

    if (enableBreakfast) {
      await _scheduleDaily(
        id: 1,
        title: _withEmoji('🌅', 'Breakfast Time!'),
        body: 'Start your day with a nutritious breakfast',
        time: breakfast,
        useExactTiming: hasExactPermission,
      );
      if (kDebugMode) {
        print('Breakfast scheduled for ${breakfast.hour}:${breakfast.minute}');
      }
    }

    if (enableLunch) {
      await _scheduleDaily(
        id: 2,
        title: _withEmoji('🌞', 'Lunch Time!'),
        body: 'Keep your energy up with a balanced lunch',
        time: lunch,
        useExactTiming: hasExactPermission,
      );
      if (kDebugMode) {
        print('Lunch scheduled for ${lunch.hour}:${lunch.minute}');
      }
    }

    if (enableDinner) {
      await _scheduleDaily(
        id: 3,
        title: _withEmoji('🌙', 'Dinner Time!'),
        body: 'End your day with a healthy dinner',
        time: dinner,
        useExactTiming: hasExactPermission,
      );
      if (kDebugMode) {
        print('Dinner scheduled for ${dinner.hour}:${dinner.minute}');
      }
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    bool useExactTiming = false,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminders',
          'Meal Reminders',
          channelDescription: 'Daily meal reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/launcher_icon',
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: useExactTiming
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexact,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> scheduleHydrationReminders({bool enabled = true}) async {
    if (kDebugMode) {
      print('Scheduling hydration reminders...');
    }

    if (!enabled) {
      for (int i = 50; i < 58; i++) {
        await _notifications.cancel(i);
      }
      return;
    }

    final hasExactPermission = await _requestExactAlarmPermission();

    final waterTimes = [
      const TimeOfDay(hour: 8, minute: 0),
      const TimeOfDay(hour: 10, minute: 0),
      const TimeOfDay(hour: 12, minute: 0),
      const TimeOfDay(hour: 14, minute: 0),
      const TimeOfDay(hour: 16, minute: 0),
      const TimeOfDay(hour: 18, minute: 0),
      const TimeOfDay(hour: 20, minute: 0),
      const TimeOfDay(hour: 22, minute: 0),
    ];

    final waterMessages = [
      'Start your day with water! 🌅',
      'Mid-morning hydration break! 💧',
      'Lunch time - have water with your meal! 🥛',
      'Afternoon water boost! ⚡',
      'Time for your afternoon water break! 💦',
      'Evening hydration - keep it up! 🌆',
      'Dinner time water! 🍽️',
      'Last water reminder before bed! 🌙',
    ];

    for (int i = 0; i < waterTimes.length; i++) {
      await _scheduleDaily(
        id: 50 + i,
        title: _withEmoji('💧', 'Hydration Time!'),
        body: waterMessages[i],
        time: waterTimes[i],
        useExactTiming: hasExactPermission,
        payload: 'hydration',
      );
    }

    if (kDebugMode) {
      print('Scheduled ${waterTimes.length} daily hydration reminders');
    }
  }

  Future<void> scheduleProteinAlerts({bool enabled = true}) async {
    if (kDebugMode) {
      print('Scheduling protein alerts...');
    }

    await _notifications.cancel(60);
    await _notifications.cancel(61);

    if (!enabled) return;

    final hasExactPermission = await _requestExactAlarmPermission();

    await _scheduleDaily(
      id: 60,
      title: _withEmoji('💪', 'Protein Check!'),
      body:
          'How\'s your protein intake today? Make sure you\'re hitting your goals!',
      time: const TimeOfDay(hour: 15, minute: 0),
      useExactTiming: hasExactPermission,
      payload: 'protein',
    );

    await _scheduleDaily(
      id: 61,
      title: _withEmoji('💪', 'Evening Protein Review'),
      body: 'Did you get enough protein today? Plan for tomorrow!',
      time: const TimeOfDay(hour: 20, minute: 30),
      useExactTiming: hasExactPermission,
      payload: 'protein',
    );

    if (kDebugMode) {
      print('Scheduled 2 daily protein alerts');
    }
  }

  Future<void> scheduleEveningReviews({bool enabled = true}) async {
    if (kDebugMode) {
      print('Scheduling evening reviews...');
    }

    await _notifications.cancel(70);

    if (!enabled) return;

    final hasExactPermission = await _requestExactAlarmPermission();

    await _scheduleDaily(
      id: 70,
      title: 'Daily Nutrition Review',
      body:
          'How was your nutrition today? Check your progress and plan tomorrow!',
      time: const TimeOfDay(hour: 21, minute: 0),
      useExactTiming: hasExactPermission,
      payload: 'evening_review',
    );

    if (kDebugMode) {
      print('Scheduled daily evening review');
    }
  }

  /// Cancels all known scheduled notifications and re-schedules each enabled
  /// one from the persisted settings in `GetStorage`. Safe to call whenever a
  /// toggle changes — it ensures the OS-level schedule matches the latest
  /// user-facing settings.
  Future<void> applyAllSettings() async {
    final storage = GetStorage();

    final breakfastEnabled =
        storage.read('working_breakfast_enabled') ?? true;
    final lunchEnabled = storage.read('working_lunch_enabled') ?? true;
    final dinnerEnabled = storage.read('working_dinner_enabled') ?? true;
    final hydrationEnabled =
        storage.read('working_hydration_enabled') ?? true;
    final proteinEnabled = storage.read('working_protein_enabled') ?? true;
    final eveningEnabled = storage.read('working_evening_enabled') ?? true;
    final weeklyEnabled = storage.read('working_weekly_enabled') ?? true;

    final breakfastTime = _readTime(
      storage,
      'working_breakfast_time',
      const TimeOfDay(hour: 8, minute: 0),
    );
    final lunchTime = _readTime(
      storage,
      'working_lunch_time',
      const TimeOfDay(hour: 13, minute: 0),
    );
    final dinnerTime = _readTime(
      storage,
      'working_dinner_time',
      const TimeOfDay(hour: 19, minute: 30),
    );

    await scheduleMealReminders(
      breakfastTime: breakfastTime,
      lunchTime: lunchTime,
      dinnerTime: dinnerTime,
      enableBreakfast: breakfastEnabled,
      enableLunch: lunchEnabled,
      enableDinner: dinnerEnabled,
    );
    await scheduleHydrationReminders(enabled: hydrationEnabled);
    await scheduleProteinAlerts(enabled: proteinEnabled);
    await scheduleEveningReviews(enabled: eveningEnabled);
    await scheduleWeeklyReport(enabled: weeklyEnabled);
  }

  TimeOfDay _readTime(GetStorage storage, String key, TimeOfDay fallback) {
    final raw = storage.read(key);
    if (raw is String) {
      final parts = raw.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
      }
    }
    return fallback;
  }

  /// Weekly nutrition report — fired Sunday 18:00 local time. Uses id 80.
  Future<void> scheduleWeeklyReport({bool enabled = true}) async {
    await _notifications.cancel(80);
    if (!enabled) return;

    final hasExactPermission = await _requestExactAlarmPermission();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      18,
      0,
    );
    // Advance to next Sunday (DateTime.sunday == 7).
    while (scheduledDate.weekday != DateTime.sunday ||
        !scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      80,
      'Your Weekly Nutrition Report',
      'See how your week went and plan the next one.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_reports',
          'Weekly Reports',
          channelDescription: 'Weekly nutrition summary',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: hasExactPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexact,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_report',
    );

    if (kDebugMode) {
      print('Scheduled weekly report for $scheduledDate');
    }
  }

  Future<void> checkPending() async {
    final pending = await _notifications.pendingNotificationRequests();
    if (kDebugMode) {
      print('Pending notifications: ${pending.length}');
      for (var notification in pending) {
        print('  ID: ${notification.id}, Title: ${notification.title}');
      }
    }

    final ctx = Get.context;
    if (ctx == null) return;

    Flushbar(
      title: 'Scheduled Notifications',
      message:
          'Found ${pending.length} scheduled notifications. Check console.',
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.blue,
      messageColor: Colors.white,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      margin: const EdgeInsets.all(16),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          offset: const Offset(0, 2),
          blurRadius: 6,
        ),
      ],
    ).show(ctx);
  }
}
