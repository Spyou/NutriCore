import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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
    // Initialize timezone
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    // Request permissions
    await _requestPermissions();

    // Initialize notifications
    await _initializeNotifications();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Request notification permissions
      await Permission.notification.request();

      // Request exact alarm permission for Android 12+
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }
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
  }

  void _handleNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Navigate based on notification
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

    await _notifications.cancel(1); // Breakfast
    await _notifications.cancel(2); // Lunch
    await _notifications.cancel(3); // Dinner

    final breakfast = breakfastTime ?? TimeOfDay(hour: 8, minute: 0);
    final lunch = lunchTime ?? TimeOfDay(hour: 13, minute: 0);
    final dinner = dinnerTime ?? TimeOfDay(hour: 19, minute: 30);

    if (enableBreakfast) {
      await _scheduleDaily(
        id: 1,
        title: 'Breakfast Time!',
        body: 'Start your day with a nutritious breakfast',
        time: breakfast,
      );
      print('Breakfast scheduled for ${breakfast.hour}:${breakfast.minute}');
    }

    if (enableLunch) {
      await _scheduleDaily(
        id: 2,
        title: 'Lunch Time!',
        body: 'Keep your energy up with a balanced lunch',
        time: lunch,
      );
      print('Lunch scheduled for ${lunch.hour}:${lunch.minute}');
    }

    if (enableDinner) {
      await _scheduleDaily(
        id: 3,
        title: 'Dinner Time!',
        body: 'End your day with a healthy dinner',
        time: dinner,
      );
      print('Dinner scheduled for ${dinner.hour}:${dinner.minute}');
    }

    // Save preferences
    _storage.write('breakfast_enabled', enableBreakfast);
    _storage.write('lunch_enabled', enableLunch);
    _storage.write('dinner_enabled', enableDinner);
    _storage.write('breakfast_time', '${breakfast.hour}:${breakfast.minute}');
    _storage.write('lunch_time', '${lunch.hour}:${lunch.minute}');
    _storage.write('dinner_time', '${dinner.hour}:${dinner.minute}');
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
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

    // If time has passed today, schedule for tomorrow
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> checkPending() async {
    final pending = await _notifications.pendingNotificationRequests();
    print('Pending notifications: ${pending.length}');
    for (var notification in pending) {
      print('  ID: ${notification.id}, Title: ${notification.title}');
    }

    Get.snackbar(
      'Scheduled Notifications',
      'Found ${pending.length} scheduled notifications. Check console.',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  Future<void> scheduleHydrationReminders({bool enabled = true}) async {
    print('💧 Scheduling hydration reminders...');

    // Cancel existing hydration reminders (IDs 50-57)
    for (int i = 50; i < 58; i++) {
      await _notifications.cancel(i);
    }

    if (!enabled) {
      print('💧 Hydration reminders disabled');
      return;
    }

    final waterTimes = [
      TimeOfDay(hour: 8, minute: 0), // 8:00 AM
      TimeOfDay(hour: 10, minute: 0), // 10:00 AM
      TimeOfDay(hour: 12, minute: 0), // 12:00 PM
      TimeOfDay(hour: 14, minute: 0), // 2:00 PM
      TimeOfDay(hour: 16, minute: 0), // 4:00 PM
      TimeOfDay(hour: 18, minute: 0), // 6:00 PM
      TimeOfDay(hour: 20, minute: 0), // 8:00 PM
      TimeOfDay(hour: 22, minute: 0), // 10:00 PM
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
        payload: 'hydration',
      );
    }

    print('Scheduled ${waterTimes.length} daily hydration reminders');
  }

  Future<void> scheduleProteinAlerts({bool enabled = true}) async {
    print('Scheduling protein alerts...');
    await _notifications.cancel(60);
    await _notifications.cancel(61);

    if (!enabled) {
      print('Protein alerts disabled');
      return;
    }

    // Schedule protein check reminders
    await _scheduleDaily(
      id: 60,
      title: 'Protein Check!',
      body:
          'How\'s your protein intake today? Make sure you\'re hitting your goals!',
      time: TimeOfDay(hour: 15, minute: 0), // 3:00 PM
      payload: 'protein',
    );

    await _scheduleDaily(
      id: 61,
      title: 'Evening Protein Review',
      body: 'Did you get enough protein today? Plan for tomorrow!',
      time: TimeOfDay(hour: 20, minute: 30), // 8:30 PM
      payload: 'protein',
    );

    print('Scheduled 2 daily protein alerts');
  }

  Future<void> scheduleEveningReviews({bool enabled = true}) async {
    print('Scheduling evening reviews...');
    await _notifications.cancel(70);

    if (!enabled) {
      print('Evening reviews disabled');
      return;
    }

    // Schedule daily evening review
    await _scheduleDaily(
      id: 70,
      title: 'Daily Nutrition Review',
      body:
          'How was your nutrition today? Check your progress and plan tomorrow!',
      time: TimeOfDay(hour: 21, minute: 0), // 9:00 PM
      payload: 'evening_review',
    );

    print('Scheduled daily evening review');
  }
}
