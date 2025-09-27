import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
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

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final _storage = GetStorage();

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

    print('✅ Working Notification Service initialized');
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      print('Basic notification permission requested');
    }
  }

  Future<bool> _requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        final status = await Permission.scheduleExactAlarm.status;

        if (status.isGranted) {
          print('Exact alarm permission already granted');
          return true;
        } else if (status.isDenied) {
          final shouldRequest = await _showPermissionExplanation();

          if (shouldRequest) {
            // Request permission
            final result = await Permission.scheduleExactAlarm.request();

            if (result.isGranted) {
              print('Exact alarm permission granted');
              _showPermissionGranted();
              return true;
            } else {
              print('Exact alarm permission denied');
              _showPermissionDenied();
              return false;
            }
          }
        }
      } catch (e) {
        print('Error requesting exact alarm permission: $e');
      }
    }

    return false;
  }

  Future<bool> _showPermissionExplanation() async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: Row(
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
                Text(
                  'NutriCheck needs permission to send meal reminders at exact times.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'This ensures you get:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Breakfast reminder at exactly 8:00 AM'),
                Text('• Lunch reminder at exactly 1:00 PM'),
                Text('• Dinner reminder at exactly 7:30 PM'),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
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
                child: Text('Not Now'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(
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
      duration: Duration(seconds: 3),
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

    print('Notifications initialized');
  }

  void _handleNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
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
    print('Scheduling meal reminders...');
    final hasExactPermission = await _requestExactAlarmPermission();

    // Cancel existing reminders
    await _notifications.cancel(1); // Breakfast
    await _notifications.cancel(2); // Lunch
    await _notifications.cancel(3); // Dinner

    final breakfast = breakfastTime ?? TimeOfDay(hour: 8, minute: 0);
    final lunch = lunchTime ?? TimeOfDay(hour: 13, minute: 0);
    final dinner = dinnerTime ?? TimeOfDay(hour: 19, minute: 30);

    if (enableBreakfast) {
      await _scheduleDaily(
        id: 1,
        title: '🌅 Breakfast Time!',
        body: 'Start your day with a nutritious breakfast',
        time: breakfast,
        useExactTiming: hasExactPermission,
      );
      print('Breakfast scheduled for ${breakfast.hour}:${breakfast.minute}');
    }

    if (enableLunch) {
      await _scheduleDaily(
        id: 2,
        title: '🌞 Lunch Time!',
        body: 'Keep your energy up with a balanced lunch',
        time: lunch,
        useExactTiming: hasExactPermission,
      );
      print('Lunch scheduled for ${lunch.hour}:${lunch.minute}');
    }

    if (enableDinner) {
      await _scheduleDaily(
        id: 3,
        title: '🌙 Dinner Time!',
        body: 'End your day with a healthy dinner',
        time: dinner,
        useExactTiming: hasExactPermission,
      );
      print('Dinner scheduled for ${dinner.hour}:${dinner.minute}');
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
      scheduledDate = scheduledDate.add(Duration(days: 1));
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
        iOS: DarwinNotificationDetails(
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
    print('Scheduling hydration reminders...');

    if (!enabled) {
      for (int i = 50; i < 58; i++) {
        await _notifications.cancel(i);
      }
      return;
    }

    final hasExactPermission = await _requestExactAlarmPermission();

    final waterTimes = [
      TimeOfDay(hour: 8, minute: 0),
      TimeOfDay(hour: 10, minute: 0),
      TimeOfDay(hour: 12, minute: 0),
      TimeOfDay(hour: 14, minute: 0),
      TimeOfDay(hour: 16, minute: 0),
      TimeOfDay(hour: 18, minute: 0),
      TimeOfDay(hour: 20, minute: 0),
      TimeOfDay(hour: 22, minute: 0),
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
        title: '💧 Hydration Time!',
        body: waterMessages[i],
        time: waterTimes[i],
        useExactTiming: hasExactPermission,
        payload: 'hydration',
      );
    }

    print('Scheduled ${waterTimes.length} daily hydration reminders');
  }

  Future<void> scheduleProteinAlerts({bool enabled = true}) async {
    print('Scheduling protein alerts...');

    await _notifications.cancel(60);
    await _notifications.cancel(61);

    if (!enabled) return;

    final hasExactPermission = await _requestExactAlarmPermission();

    await _scheduleDaily(
      id: 60,
      title: '💪 Protein Check!',
      body:
          'How\'s your protein intake today? Make sure you\'re hitting your goals!',
      time: TimeOfDay(hour: 15, minute: 0),
      useExactTiming: hasExactPermission,
      payload: 'protein',
    );

    await _scheduleDaily(
      id: 61,
      title: '💪 Evening Protein Review',
      body: 'Did you get enough protein today? Plan for tomorrow!',
      time: TimeOfDay(hour: 20, minute: 30),
      useExactTiming: hasExactPermission,
      payload: 'protein',
    );

    print('Scheduled 2 daily protein alerts');
  }

  Future<void> scheduleEveningReviews({bool enabled = true}) async {
    print('Scheduling evening reviews...');

    await _notifications.cancel(70);

    if (!enabled) return;

    final hasExactPermission = await _requestExactAlarmPermission();

    await _scheduleDaily(
      id: 70,
      title: 'Daily Nutrition Review',
      body:
          'How was your nutrition today? Check your progress and plan tomorrow!',
      time: TimeOfDay(hour: 21, minute: 0),
      useExactTiming: hasExactPermission,
      payload: 'evening_review',
    );

    print('Scheduled daily evening review');
  }

  Future<void> checkPending() async {
    final pending = await _notifications.pendingNotificationRequests();
    print('Pending notifications: ${pending.length}');
    for (var notification in pending) {
      print('  ID: ${notification.id}, Title: ${notification.title}');
    }

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
          color: Colors.black.withOpacity(0.3),
          offset: const Offset(0, 2),
          blurRadius: 6,
        ),
      ],
    ).show(Get.context!);
  }
}
