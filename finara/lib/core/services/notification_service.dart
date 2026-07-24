import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_service.g.dart';

@Riverpod(keepAlive: true)
NotificationService notificationService(NotificationServiceRef ref) {
  return NotificationService();
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle tap
      },
    );

    // Request permissions
    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();

    _isInitialized = true;
  }

  Future<void> scheduleCreditCardReminders({
    required int accountId,
    required String accountName,
    required int billGenerationDay,
    required int dueDay,
    required DateTime currentDate,
  }) async {
    // Generate unique base ID for this account's notifications
    final baseId = accountId * 1000;

    // First, cancel existing reminders for this account
    await cancelAccountReminders(accountId);

    // Determine the current or next bill generation date
    DateTime nextGenDate = DateTime(
      currentDate.year,
      currentDate.month,
      billGenerationDay,
      9,
      0,
    ); // 9 AM
    if (currentDate.isAfter(nextGenDate)) {
      // If we passed this month's gen date, schedule for next month
      nextGenDate = DateTime(
        currentDate.year,
        currentDate.month + 1,
        billGenerationDay,
        9,
        0,
      );
    }

    DateTime nextDueDate = DateTime(
      nextGenDate.year,
      nextGenDate.month,
      dueDay,
      9,
      0,
    );
    // Handle case where due date wraps to next month (e.g., gen: 20th, due: 5th)
    if (dueDay < billGenerationDay) {
      nextDueDate = DateTime(
        nextGenDate.year,
        nextGenDate.month + 1,
        dueDay,
        9,
        0,
      );
    }

    const androidDetails = AndroidNotificationDetails(
      'credit_card_reminders',
      'Credit Card Reminders',
      channelDescription:
          'Reminders for credit card bill generation and due dates',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    final prefs = await SharedPreferences.getInstance();
    final reminderIntervalDays = prefs.getInt('cc_reminder_interval_days') ?? 3;
    final preGenReminderDays = prefs.getInt('cc_pre_gen_reminder_days') ?? 1;

    // 1. Reminder before generation
    final preGenDate = nextGenDate.subtract(Duration(days: preGenReminderDays));
    if (preGenDate.isAfter(currentDate)) {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: baseId + 1,
        title: 'Bill Generation Upcoming',
        body:
            'Your bill for $accountName will be generated in $preGenReminderDays day(s).',
        scheduledDate: tz.TZDateTime.from(preGenDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    // 2. Reminder on generation date
    if (nextGenDate.isAfter(currentDate)) {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: baseId + 2,
        title: 'Bill Generated',
        body:
            'Your bill for $accountName has been generated. Please check the amount and pay by the due date (Day $dueDay).',
        scheduledDate: tz.TZDateTime.from(nextGenDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    // 3. Repeated reminders every N days between Gen and Due date
    DateTime reminderDate = nextGenDate.add(
      Duration(days: reminderIntervalDays),
    );
    int reminderOffset = 3;
    while (reminderDate.isBefore(nextDueDate)) {
      if (reminderDate.isAfter(currentDate)) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: baseId + reminderOffset,
          title: 'Bill Payment Reminder',
          body:
              'Have you paid your $accountName bill yet? Due date is approaching on Day $dueDay.',
          scheduledDate: tz.TZDateTime.from(reminderDate, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
      reminderDate = reminderDate.add(Duration(days: reminderIntervalDays));
      reminderOffset++;
    }

    // 4. Final reminder on due date
    if (nextDueDate.isAfter(currentDate)) {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: baseId + 999,
        title: 'BILL DUE TODAY',
        body: 'Today is the final due date for your $accountName bill!',
        scheduledDate: tz.TZDateTime.from(nextDueDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelAccountReminders(int accountId) async {
    final baseId = accountId * 1000;
    for (int i = 0; i < 20; i++) {
      await _flutterLocalNotificationsPlugin.cancel(id: baseId + i);
    }
    await _flutterLocalNotificationsPlugin.cancel(id: baseId + 999);
  }
}
