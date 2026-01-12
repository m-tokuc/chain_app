import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // 🔥 Sabit Kanal ID (Kanalı sıfırlamak için v4 yaptık)
  static const String channelId = 'chain_daily_reminder_v4';

  Future<void> init(String userId) async {
    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    // 1. ADIM: Android Kanalını Sisteme Kaydet (Sende bu eksik)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      'Hatırlatıcılar',
      description: 'Zinciri kırmamanız için günlük hatırlatıcılar.',
      importance: Importance.max, // Bildirimin yukarıdan düşmesi için ŞART
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 2. ADIM: Başlatma Ayarları
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      ),
      onDidReceiveNotificationResponse: (details) {
        print("Bildirime tıklandı");
      },
    );

    await _requestExactAlarmPermission();
    
    // FCM İzinleri
    NotificationSettings settings = await _fcm.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _saveTokenToFirestore(userId);
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> _saveTokenToFirestore(String userId) async {
    String? token = await _fcm.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(time.hour, time.minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId, // Yukarıdaki kanal ID ile birebir aynı olmalı
            'Günlük Hatırlatıcı',
            channelDescription: 'Zinciri kırma hatırlatıcısı',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true, // Bazı cihazlarda şart
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // 🔥 Android 12+ için kritik
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print("✅ Bildirim kuruldu (ID: $id) - Zaman: ${time.hour}:${time.minute}");
    } catch (e) {
      print("❌ Bildirim kurulum hatası: $e");
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // Eğer seçilen saat geçmişse yarına kur
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
  Future<void> showImmediateNotification() async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'test_channel',
    'Test Notification',
    importance: Importance.max,
    priority: Priority.high,
  );

  await flutterLocalNotificationsPlugin.show(
    999,
    "Test Başlığı",
    "Bu bildirim hemen gelmeli!",
    const NotificationDetails(android: androidDetails),
  );
}
}