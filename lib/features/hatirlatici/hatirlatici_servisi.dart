import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzveri;
import 'package:timezone/timezone.dart' as tz;

/// Cihaz üstü (yerel) hatırlatıcı bildirimleri. Bildirim içeriği cihazdan çıkmaz.
abstract interface class HatirlaticiServisi {
  /// Bu platformda zamanlanmış bildirim desteklenir mi (web'de desteklenmez).
  bool get destekleniyor;

  /// Bildirim iznini ister; verildiyse true.
  Future<bool> izinIste();

  /// [zaman] anına (cihazın yerel saati) tek seferlik bildirim kurar; aynı kimlik varsa üzerine yazar.
  Future<void> planla({required int id, required String baslik, required String govde, required DateTime zaman});

  Future<void> iptal(int id);
}

/// Android ve iOS'ta `flutter_local_notifications` ile çalışır; diğer platformlarda hiçbir şey yapmaz.
class YerelHatirlaticiServisi implements HatirlaticiServisi {
  YerelHatirlaticiServisi();

  final _eklenti = FlutterLocalNotificationsPlugin();
  Future<void>? _hazirlik;

  static const _kanal = AndroidNotificationDetails(
    'hatirlaticilar',
    'Hatırlatıcılar',
    channelDescription: 'Kademe ilerlemesi gibi tarihli hatırlatmalar',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  @override
  bool get destekleniyor =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _hazirla() => _hazirlik ??= () async {
    tzveri.initializeTimeZones();
    // Türkiye tüm yıl UTC+3 (yaz saati uygulaması yok).
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    await _eklenti.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();

  /// Bildirim hatası uygulamayı bozmamalı: hata yutulur, işlem başarısız sayılır.
  Future<T> _guvenli<T>(Future<T> Function() islem, T yedek) async {
    try {
      return await islem();
    } catch (e) {
      debugPrint('Hatırlatıcı işlemi başarısız: $e');
      return yedek;
    }
  }

  @override
  Future<bool> izinIste() => _guvenli(() async {
    if (!destekleniyor) return false;
    await _hazirla();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _eklenti
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _eklenti
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }, false);

  @override
  Future<void> planla({required int id, required String baslik, required String govde, required DateTime zaman}) =>
      _guvenli(() async {
        if (!destekleniyor) return;
        await _hazirla();
        final an = tz.TZDateTime(tz.local, zaman.year, zaman.month, zaman.day, zaman.hour, zaman.minute);
        if (!an.isAfter(tz.TZDateTime.now(tz.local))) return;
        await _eklenti.zonedSchedule(
          id: id,
          title: baslik,
          body: govde,
          scheduledDate: an,
          notificationDetails: const NotificationDetails(android: _kanal, iOS: DarwinNotificationDetails()),
          // Tam zamanlı alarm izni istememek için: bildirim birkaç dakika kayabilir.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }, null);

  @override
  Future<void> iptal(int id) => _guvenli(() async {
    if (!destekleniyor) return;
    await _hazirla();
    await _eklenti.cancel(id: id);
  }, null);
}

/// Testler için: planlananları bellekte tutar.
class SahteHatirlaticiServisi implements HatirlaticiServisi {
  SahteHatirlaticiServisi({this.izinVerilir = true, this.destekleniyor = true});

  final bool izinVerilir;
  @override
  final bool destekleniyor;
  int izinIstegi = 0;
  final Map<int, ({String baslik, String govde, DateTime zaman})> planlananlar = {};

  @override
  Future<bool> izinIste() async {
    izinIstegi++;
    return izinVerilir;
  }

  @override
  Future<void> planla({required int id, required String baslik, required String govde, required DateTime zaman}) async {
    planlananlar[id] = (baslik: baslik, govde: govde, zaman: zaman);
  }

  @override
  Future<void> iptal(int id) async => planlananlar.remove(id);
}
