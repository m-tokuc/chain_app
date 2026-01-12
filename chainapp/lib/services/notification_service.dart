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

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // 🔥 Sabit Kanal ID
  static const String channelId = 'chain_daily_reminder_v4';
  static const String channelName = 'Günlük Hatırlatıcılar';

  // init fonksiyonunda userId'yi opsiyonel (?) yaptık.
  // Çünkü main.dart'ta uygulama açılırken user henüz null olabilir.
  Future<void> init({String? userId}) async {
    // 1. Zaman Dilimi Ayarları
    try {
      tz.initializeTimeZones();
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (e) {
      print("Zaman dilimi hatası: $e");
      // Hata olursa varsayılan olarak UTC veya bilinen bir yer ayarlanabilir
      // tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    // 2. Android Kanalını Oluştur
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Zinciri kırmamanız için günlük hatırlatıcılar.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Android 13+ İçin Bildirim İzni İste
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // 4. Başlatma Ayarları
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Ayarları
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
        print("Bildirime tıklandı: ${details.payload}");
      },
    );

    // 5. Alarm İzni (Android 12+)
    await _requestExactAlarmPermission();

    // 6. FCM İzinleri ve Token Kaydı
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('FCM İzni verildi: ${settings.authorizationStatus}');
      // Eğer userId geldiyse token'ı kaydet
      if (userId != null) {
        await _saveTokenToFirestore(userId);
      }
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // Token kaydetme fonksiyonu (Login olduktan sonra çağrılabilir)
  Future<void> _saveTokenToFirestore(String userId) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
        print("FCM Token kaydedildi.");
      }
    } catch (e) {
      print("Token kayıt hatası: $e");
    }
  }

  // 🔥 GÜNLÜK HATIRLATICI KURMA
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
            channelId, // Yukarıdaki ID ile aynı olmalı
            channelName,
            channelDescription: 'Zinciri kırma hatırlatıcısı',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Her gün tekrar et
      );
      print(
          "✅ Alarm kuruldu: ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}");
    } catch (e) {
      print("❌ Bildirim kurulum hatası: $e");
    }
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

  // TEST BİLDİRİMİ (Kanal ID düzeltildi)
  Future<void> showImmediateNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId, // 🔥 Düzeltildi: 'test_channel' yerine gerçek kanal ID
      channelName,
      importance: Importance.max,
      priority: Priority.high,
    );

    await flutterLocalNotificationsPlugin.show(
      999,
      "Test Başlığı",
      "Bu bildirim çalışıyorsa sistem harika işliyor! 🚀",
      const NotificationDetails(android: androidDetails),
    );
  }
}
