import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../ilanlar/ilan_alarmi.dart';
import '../ilanlar/ilan_modeli.dart';
import '../ilanlar/kayitli_ilanlar.dart';
import '../profil/data/profil_deposu.dart';
import '../profil/domain/profil.dart';

/// Yedeklenen veriler: profil, kayıtlı ilanlar ve ilan alarmları. Fotoğraf yedeğe girmez (büyük). Hesap şifresi
/// ve bildirim izinleri de girmez; yeni telefonda bildirimler yeniden açılır.
///
/// Kod biçimi: `KPYEDEK1.<base64url(json)>.<sha256'nın ilk 8 hanesi>`. Sağlama toplamı, kodun eksik
/// kopyalandığını ya da bozulduğunu yüklemeden önce yakalar.
@immutable
class YedekPaketi {
  const YedekPaketi({this.profil, this.kayitliIlanlar = const [], this.alarmlar = const [], required this.olusturma});

  static const onEk = 'KPYEDEK1';

  final Profil? profil;
  final List<KamuIlani> kayitliIlanlar;
  final List<IlanAlarmi> alarmlar;
  final DateTime olusturma;

  bool get bos => profil == null && kayitliIlanlar.isEmpty && alarmlar.isEmpty;

  /// Kullanıcıya gösterilen kısa özet: "profil, 3 kayıtlı ilan, 2 alarm".
  String get ozet => [
    if (profil != null) 'profil',
    if (kayitliIlanlar.isNotEmpty) '${kayitliIlanlar.length} kayıtlı ilan',
    if (alarmlar.isNotEmpty) '${alarmlar.length} alarm',
  ].join(', ');

  static String _saglama(String yuk) => sha256.convert(utf8.encode(yuk)).toString().substring(0, 8);

  String kodla() {
    final yuk = base64Url.encode(
      utf8.encode(
        jsonEncode({
          'v': 1,
          'olusturma': olusturma.toIso8601String(),
          'profil': profil?.toJson(),
          'kayitli': [for (final i in kayitliIlanlar) i.toJson()],
          'alarmlar': [for (final a in alarmlar) a.toJson()],
        }),
      ),
    );
    return '$onEk.$yuk.${_saglama(yuk)}';
  }

  /// Yapıştırılan metinden paketi çözer. Boşluk ve satır sonları yok sayılır (mesajlaşma uygulamaları kodu
  /// böler). Biçim, sağlama toplamı ya da içerik geçersizse null döner.
  static YedekPaketi? coz(String metin) {
    final temiz = metin.replaceAll(RegExp(r'\s+'), '');
    final parcalar = temiz.split('.');
    if (parcalar.length != 3 || parcalar[0] != onEk) return null;
    if (_saglama(parcalar[1]) != parcalar[2]) return null;
    try {
      final j = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parcalar[1]))));
      if (j is! Map<String, Object?> || j['v'] != 1) return null;
      final profil = j['profil'];
      final kayitli = j['kayitli'];
      final alarmlar = j['alarmlar'];
      return YedekPaketi(
        profil: profil is Map<String, Object?> ? Profil.fromJson(profil) : null,
        kayitliIlanlar: [
          if (kayitli is List)
            for (final e in kayitli)
              if (KamuIlani.fromJson(e) case final i?) i,
        ],
        alarmlar: [
          if (alarmlar is List)
            for (final e in alarmlar)
              if (IlanAlarmi.fromJson(e) case final a?) a,
        ],
        olusturma: DateTime.tryParse('${j['olusturma']}') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Yedeğin okunduğu ve geri yüklendiği cihaz içi depolar.
class YedekBaglami {
  const YedekBaglami({required this.profil, this.kayitliIlanlar, this.alarmlar});

  final ProfilDeposu profil;
  final KayitliIlanlar? kayitliIlanlar;
  final IlanAlarmlari? alarmlar;

  /// Şu anki cihaz verisinden yedek paketi oluşturur.
  YedekPaketi olustur({DateTime? simdi}) => YedekPaketi(
    profil: profil.profil,
    kayitliIlanlar: kayitliIlanlar?.liste ?? const [],
    alarmlar: alarmlar?.liste ?? const [],
    olusturma: simdi ?? DateTime.now(),
  );

  /// Paketi cihaza yükler. Profil, yedekteki ile değiştirilir; kayıtlı ilanlar ve alarmlar mevcutlara eklenir
  /// (aynı olanlar tekrarlanmaz). Yüklenen kayıt sayılarını döner.
  Future<({bool profil, int ilan, int alarm})> geriYukle(YedekPaketi p) async {
    var profilYuklendi = false;
    if (p.profil != null) {
      await profil.kaydet(p.profil!);
      profilYuklendi = true;
    }
    final ilan = await kayitliIlanlar?.birlestir(p.kayitliIlanlar) ?? 0;
    var alarm = 0;
    for (final a in p.alarmlar.reversed) {
      if (await alarmlar?.ekle(kelime: a.kelime, il: a.il, tur: a.tur) ?? false) alarm++;
    }
    return (profil: profilYuklendi, ilan: ilan, alarm: alarm);
  }
}
