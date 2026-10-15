import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Oyun içi yerel bildirim servisi.
/// Android, iOS ve test ortamı uyumlu çalışır.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  static const int cargoNotificationId = 1001;
  static const int dailyDutyNotificationId = 1002;
  static const int inactivityNotificationId = 1003;

  static const String channelId = 'mine_alerts';
  static const String channelName = 'Maden Telsizi Bildirimleri';
  static const String channelDescription =
      'Ambar dolumu, günlük vardiyalar ve sismik keşif bildirimleri';

  /// Servisi başlatır ve zaman dilimlerini yükler.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Sadece mobil platformlarda başlat
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _isInitialized = true;
      return;
    }

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(settings: initSettings);
      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  /// Kullanıcıdan bildirim gönderme izni ister.
  Future<bool> requestPermission() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return true;
    }

    try {
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission();
        return granted ?? false;
      } else if (Platform.isIOS) {
        final iosImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('NotificationService requestPermission error: $e');
    }
    return false;
  }

  /// Tüm zamanlanmış bildirimleri iptal eder.
  Future<void> cancelAll() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService cancelAll error: $e');
    }
  }

  /// Ambar dolum bildirimi zamanlar.
  Future<void> scheduleCargoFullNotification(Duration delay) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    // Çok kısa sürede bildirim atmamak için minimum 10 dakika gecikme
    final effectiveDelay = delay < const Duration(minutes: 10)
        ? const Duration(minutes: 10)
        : delay;

    final scheduledDate = tz.TZDateTime.now(tz.local).add(effectiveDelay);

    try {
      await _notificationsPlugin.zonedSchedule(
        id: cargoNotificationId,
        title: '⛏️ Ambarın Tıkabasa Doldu Şef!',
        body:
            'Madencilerin kazmayı bıraktı çünkü koyacak yer kalmadı. Gel ve cevherleri satıp servetine servet kat!',
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('NotificationService scheduleCargoFull error: $e');
    }
  }

  /// Günlük vardiya yenilenme bildirimi (24 saat sonra).
  Future<void> scheduleDailyDutyNotification() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));

    try {
      await _notificationsPlugin.zonedSchedule(
        id: dailyDutyNotificationId,
        title: '📋 Yeni Günlük Vardiya Başladı!',
        body:
            'Maden müfettişi yeni görevler ve bolca maden parası getirdi. Vardiyanı kaçırma!',
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('NotificationService scheduleDailyDuty error: $e');
    }
  }

  /// 48 saat oyuna girmeyen oyuncuyu çağırma bildirimi.
  Future<void> scheduleInactivityNotification() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(const Duration(hours: 48));

    try {
      await _notificationsPlugin.zonedSchedule(
        id: inactivityNotificationId,
        title: '🌋 Derinliklerde Sismik Hareket!',
        body:
            'Sensörlerimiz alt katmanlarda gizemli bir elmas damarı tespit etti. Kazmanı kap ve derinlere in!',
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('NotificationService scheduleInactivity error: $e');
    }
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
