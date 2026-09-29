import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Veri akışının (ilanlar, Resmî Gazete haberleri) okunduğu adres. `tool/feed_uret.py` ve
/// `.github/workflows/feed.yml` bu dosyaları her 15 dakikada `feed-data` dalına yayımlar.
abstract final class Yapilandirma {
  static final Uri akisTabani = Uri.parse(
    'https://raw.githubusercontent.com/oguzhanterzioglu00/claudeproje/feed-data/',
  );
}

/// Akış dosyası okunamadı (ağ yok, sunucu hatası ya da bozuk içerik).
class AkisHatasi implements Exception {
  const AkisHatasi(this.mesaj);

  final String mesaj;

  @override
  String toString() => 'AkisHatasi: $mesaj';
}

/// Akış JSON dosyalarını okur. Aynı dosya kısa süre içinde tekrar istenirse (ör. ana sayfa ve maaş
/// ekranındaki haber bölümleri) ağa gidilmez; başarısız istekler önbelleğe alınmaz.
class AkisIstemcisi {
  AkisIstemcisi({
    http.Client? istemci,
    Uri? taban,
    this.onbellek = const Duration(seconds: 60),
    DateTime Function()? simdi,
  }) : _istemci = istemci ?? http.Client(),
       taban = taban ?? Yapilandirma.akisTabani,
       _simdi = simdi ?? DateTime.now;

  final http.Client _istemci;
  final Uri taban;
  final Duration onbellek;
  final DateTime Function() _simdi;
  final Map<String, (DateTime, Map<String, Object?>)> _onbellek = {};

  Future<Map<String, Object?>> oku(String dosya, {bool yenile = false}) async {
    final kayit = _onbellek[dosya];
    if (!yenile && kayit != null && _simdi().difference(kayit.$1) < onbellek) return kayit.$2;
    try {
      final r = await _istemci.get(taban.resolve(dosya)).timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) throw AkisHatasi('$dosya: HTTP ${r.statusCode}');
      final govde = jsonDecode(utf8.decode(r.bodyBytes));
      if (govde is! Map<String, Object?>) throw AkisHatasi('$dosya: beklenmeyen biçim');
      _onbellek[dosya] = (_simdi(), govde);
      return govde;
    } on AkisHatasi {
      rethrow;
    } on TimeoutException {
      throw AkisHatasi('$dosya: zaman aşımı');
    } catch (e) {
      throw AkisHatasi('$dosya: $e');
    }
  }
}

/// JSON'dan güvenli okuma yardımcıları (bozuk kayıt uygulamayı düşürmez).
extension AkisAlani on Map<String, Object?> {
  String metin(String anahtar) => this[anahtar] is String ? this[anahtar]! as String : '';

  DateTime? tarih(String anahtar) {
    final v = this[anahtar];
    return v is String ? DateTime.tryParse(v) : null;
  }

  /// Kaynağın (Türkiye saatiyle yazılmış) tarihini saat dilimi çevirmeden, yazıldığı gibi okur: "2026-10-19T00:00:00+03:00"
  /// her cihazda 19 Ekim'dir. Saat dilimi eki olmayan ("2026-10-05") değerler de olduğu gibi çözülür.
  DateTime? duvarTarihi(String anahtar) {
    final v = this[anahtar];
    if (v is! String) return null;
    return DateTime.tryParse(v.length >= 19 ? v.substring(0, 19) : v);
  }

  Uri? adres(String anahtar) {
    final v = this[anahtar];
    if (v is! String) return null;
    final u = Uri.tryParse(v);
    return u != null && (u.scheme == 'https' || u.scheme == 'http') && u.host.isNotEmpty ? u : null;
  }

  List<Map<String, Object?>> liste(String anahtar) {
    final v = this[anahtar];
    return v is List
        ? [
            for (final e in v)
              if (e is Map<String, Object?>) e,
          ]
        : const [];
  }
}
