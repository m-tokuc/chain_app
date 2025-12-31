import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔥 FCM İÇİN ŞART
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 TOKEN KAYDI İÇİN ŞART
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm =
      FirebaseMessaging.instance; // 🔥 Firebase Mesajlaşma objesi

  Future<void> init(String userId) async {
    // 🔥 userId parametresi eklendi
    tz.initializeTimeZones();

    // 1. Yerel Bildirim Ayarları
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // 2. 🔥 BİLDİRİM İZNİ ALMA
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Kullanıcı bildirim izni verdi.');
      // 3. 🔥 TOKEN AL VE KAYDET
      await _saveTokenToFirestore(userId);
    } else {
      print('Kullanıcı bildirim iznini reddetti.');
    }
  }

  // 🔥 TOKEN'I ALIP FIRESTORE'A YAZAN KRİTİK FONKSİYON
  Future<void> _saveTokenToFirestore(String userId) async {
    String? token = await _fcm.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token, // Artık Firestore'da bu alanı görebileceksin!
      });
      print("FCM Token başarıyla kaydedildi: $token");
    }
  }

  // --- GÜNLÜK HATIRLATICI KUR --- (Mevcut kodun devamı)
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time.hour, time.minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Reminders to keep your chain alive',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
