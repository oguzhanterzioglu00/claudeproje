import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../core/depolama.dart';
import '../domain/hesap.dart';
import 'kimlik_servisi.dart';

/// ÖRNEK hesap servisi: hesaplar yalnızca bu cihazda tutulur, sunucuya hiçbir
/// şey gitmez. Şifreler tuzlu PBKDF2-HMAC-SHA256 özetiyle saklanır (düz metin değil).
/// Google/Apple girişi gerçek değildir; örnek bir hesap oluşturur. Arka uç
/// bağlanınca [KimlikServisi]'nin gerçek uygulamasıyla değiştirilir.
class YerelKimlikServisi implements KimlikServisi {
  YerelKimlikServisi({AnahtarDeger? depolama, this.tur = 20000, Random? rastgele})
      : _depo = depolama ?? const YerelDepolama(),
        _rastgele = rastgele ?? Random.secure();

  final AnahtarDeger _depo;
  final Random _rastgele;

  /// PBKDF2 tur sayısı (testlerde küçültülebilir).
  final int tur;

  @override
  bool get gercek => false;

  @override
  Stream<KimlikOlayi> get olaylar => const Stream.empty();

  @override
  Future<void> kurtarmaSifresiBelirle(String yeniSifre) async =>
      throw const KimlikHatasi('Bu örnek sürümde şifre sıfırlama bağlantısı yok.');

  static const _hesaplarAnahtari = 'hesaplar_v1';
  static const _oturumAnahtari = 'oturum_v1';

  // --- saklama -------------------------------------------------------------

  Future<Map<String, Map<String, Object?>>> _hesaplariOku() async {
    final metin = await _depo.oku(_hesaplarAnahtari);
    if (metin == null) return {};
    try {
      final j = jsonDecode(metin);
      if (j is Map) {
        return {
          for (final e in j.entries)
            if (e.key is String && e.value is Map) e.key as String: Map<String, Object?>.from(e.value as Map),
        };
      }
    } catch (_) {
      // bozuk kayıt
    }
    return {};
  }

  Future<void> _hesaplariYaz(Map<String, Map<String, Object?>> h) => _depo.yaz(_hesaplarAnahtari, jsonEncode(h));

  Future<void> _oturumAc(Hesap h) => _depo.yaz(_oturumAnahtari, jsonEncode(h.toJson()));

  static String _anahtar(String eposta) => eposta.trim().toLowerCase();

  // --- şifre özeti ---------------------------------------------------------

  Uint8List _tuz() => Uint8List.fromList(List.generate(16, (_) => _rastgele.nextInt(256)));

  /// PBKDF2-HMAC-SHA256, 32 baytlık çıktı (tek blok).
  static List<int> _pbkdf2(String sifre, List<int> tuz, int tur) {
    final hmac = Hmac(sha256, utf8.encode(sifre));
    var u = hmac.convert([...tuz, 0, 0, 0, 1]).bytes;
    final sonuc = List<int>.of(u);
    for (var i = 1; i < tur; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < sonuc.length; j++) {
        sonuc[j] ^= u[j];
      }
    }
    return sonuc;
  }

  Map<String, Object?> _ozet(String sifre) {
    final tuz = _tuz();
    return {'tuz': base64.encode(tuz), 'tur': tur, 'ozet': base64.encode(_pbkdf2(sifre, tuz, tur))};
  }

  static bool _dogru(String sifre, Map<String, Object?> kayit) {
    final tuz = kayit['tuz'];
    final ozet = kayit['ozet'];
    final tur = kayit['tur'];
    if (tuz is! String || ozet is! String || tur is! int) return false;
    final hesaplanan = base64.encode(_pbkdf2(sifre, base64.decode(tuz), tur));
    // Sabit zamanlı karşılaştırma.
    if (hesaplanan.length != ozet.length) return false;
    var fark = 0;
    for (var i = 0; i < ozet.length; i++) {
      fark |= hesaplanan.codeUnitAt(i) ^ ozet.codeUnitAt(i);
    }
    return fark == 0;
  }

  // --- arayüz --------------------------------------------------------------

  @override
  Future<Hesap?> mevcut() async {
    final metin = await _depo.oku(_oturumAnahtari);
    if (metin == null) return null;
    try {
      return Hesap.fromJson(jsonDecode(metin));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Hesap> kayitOl({required String eposta, required String sifre}) async {
    if (!HesapKurali.epostaGecerli(eposta)) throw const KimlikHatasi('Geçerli bir e-posta adresi gir');
    final hata = HesapKurali.sifreHatasi(sifre);
    if (hata != null) throw KimlikHatasi(hata);
    final hesaplar = await _hesaplariOku();
    final k = _anahtar(eposta);
    if (hesaplar.containsKey(k)) throw const KimlikHatasi('Bu e-posta ile zaten bir hesap var. Giriş yapmayı dene.');
    final id = 'u-${base64Url.encode(_tuz()).replaceAll('=', '')}';
    hesaplar[k] = {'id': id, ..._ozet(sifre)};
    await _hesaplariYaz(hesaplar);
    final h = Hesap(id: id, saglayici: GirisSaglayici.eposta, eposta: eposta.trim());
    await _oturumAc(h);
    return h;
  }

  @override
  Future<Hesap> girisYap({required String eposta, required String sifre}) async {
    final hesaplar = await _hesaplariOku();
    final kayit = hesaplar[_anahtar(eposta)];
    // Hesap yok ile şifre yanlış aynı mesajı verir (hesap var/yok sızdırılmaz).
    if (kayit == null || !_dogru(sifre, kayit)) throw const KimlikHatasi('E-posta veya şifre hatalı');
    final h = Hesap(id: kayit['id']! as String, saglayici: GirisSaglayici.eposta, eposta: eposta.trim());
    await _oturumAc(h);
    return h;
  }

  @override
  Future<Hesap> saglayiciIleGiris(GirisSaglayici saglayici) async {
    if (saglayici == GirisSaglayici.eposta) throw ArgumentError('e-posta bir hızlı giriş sağlayıcısı değildir');
    final h = Hesap(id: 'ornek-${saglayici.name}', saglayici: saglayici);
    await _oturumAc(h);
    return h;
  }

  @override
  Future<void> sifreDegistir({required String eskiSifre, required String yeniSifre}) async {
    final h = await mevcut();
    if (h == null || !h.sifreliHesap) throw const KimlikHatasi('Şifre yalnızca e-posta hesaplarında değiştirilir');
    final hesaplar = await _hesaplariOku();
    final k = _anahtar(h.eposta);
    final kayit = hesaplar[k];
    if (kayit == null || !_dogru(eskiSifre, kayit)) throw const KimlikHatasi('Mevcut şifren hatalı');
    final hata = HesapKurali.sifreHatasi(yeniSifre);
    if (hata != null) throw KimlikHatasi(hata);
    if (eskiSifre == yeniSifre) throw const KimlikHatasi('Yeni şifre eskisinden farklı olmalı');
    hesaplar[k] = {'id': kayit['id'], ..._ozet(yeniSifre)};
    await _hesaplariYaz(hesaplar);
  }

  @override
  Future<void> sifreSifirlamaIste(String eposta) async {
    if (!HesapKurali.epostaGecerli(eposta)) throw const KimlikHatasi('Geçerli bir e-posta adresi gir');
    // Örnek sürümde e-posta gönderilmez; gerçek servis burada bağlantı yollar.
  }

  @override
  Future<void> cikisYap() => _depo.sil(_oturumAnahtari);

  @override
  Future<void> hesabiSil() async {
    final h = await mevcut();
    if (h != null && h.sifreliHesap) {
      final hesaplar = await _hesaplariOku()
        ..remove(_anahtar(h.eposta));
      await _hesaplariYaz(hesaplar);
    }
    await _depo.sil(_oturumAnahtari);
  }
}
