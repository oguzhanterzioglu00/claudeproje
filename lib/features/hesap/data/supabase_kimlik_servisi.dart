import 'dart:async';

import '../domain/hesap.dart';
import 'kimlik_servisi.dart';

/// Arka uç istemcisinden gelen, sağlayıcıdan bağımsız kullanıcı bilgisi.
class IstemciKullanicisi {
  const IstemciKullanicisi({required this.id, this.eposta = '', this.ad = '', this.saglayici = 'email'});

  final String id;
  final String eposta;
  final String ad;

  /// "email" ya da "google".
  final String saglayici;
}

enum IstemciOlayTuru { girisYapti, cikisYapti, sifreKurtarma }

class IstemciOlayi {
  const IstemciOlayi(this.tur, [this.kullanici]);

  final IstemciOlayTuru tur;
  final IstemciKullanicisi? kullanici;
}

/// Arka uçtan dönen hata. [kod] arka ucun hata kodudur (ör. `invalid_credentials`); ağ hatalarında null.
class IstemciHatasi implements Exception {
  const IstemciHatasi({this.kod, this.mesaj = '', this.ag = false});

  final String? kod;
  final String mesaj;

  /// Bağlantı kurulamadı (internet yok, sunucuya ulaşılamadı).
  final bool ag;

  @override
  String toString() => 'IstemciHatasi($kod, $mesaj, ag: $ag)';
}

/// Arka uç istemcisinin (Supabase Auth) ihtiyaç duyulan kısmı. Gerçek uygulama [SupabaseKimlikIstemcisi],
/// testler sahte bir uygulama kullanır; böylece ağ olmadan akış mantığı sınanır.
abstract interface class KimlikIstemcisi {
  IstemciKullanicisi? get kullanici;
  Stream<IstemciOlayi> get olaylar;

  /// Hesap açar. E-posta doğrulaması gerekiyorsa oturum açılmaz ve null döner.
  Future<IstemciKullanicisi?> kayitOl(String eposta, String sifre, {required String yonlendirme});

  Future<IstemciKullanicisi> girisYap(String eposta, String sifre);

  /// Tarayıcıda sağlayıcı girişini başlatır; tarayıcı açılabildiyse true. Oturum, uygulamaya geri dönüşte
  /// [olaylar] üzerinden gelir.
  Future<bool> saglayiciBaslat(String saglayici, {required String yonlendirme});

  /// Cihazın yerel Google girişi (Android'de altta açılan hesap seçici; tarayıcıya gidilmez, uygulama adı
  /// "Kamu Pusulası" görünür). Bu platformda desteklenmiyorsa null döner; o zaman tarayıcı girişi kullanılır.
  /// [sunucuIstemciKimligi] Google Cloud'daki **Web** istemcisinin kimliğidir.
  Future<IstemciKullanicisi?> googleYerelGiris(String sunucuIstemciKimligi);

  Future<void> sifreSifirlamaIste(String eposta, {required String yonlendirme});
  Future<void> sifreGuncelle(String yeniSifre);
  Future<void> cikis();

  /// Sunucudaki hesabı ve ona bağlı tüm veriyi siler (sunucuda `hesabi_sil` işlevi).
  Future<void> hesabiSil();
}

/// [KimlikServisi]'nin Supabase uygulaması: e-posta/şifre ve Google ile giriş, şifre sıfırlama, hesap silme.
class SupabaseKimlikServisi implements KimlikServisi {
  SupabaseKimlikServisi(
    this._istemci, {
    this.yonlendirme = geriDonusAdresi,
    this.girisZamanAsimi = const Duration(minutes: 3),
    this.geriDonusBeklemesi = const Duration(seconds: 6),
    this.googleSunucuIstemcisi = '',
  });

  /// Android'de tarayıcıdan uygulamaya dönüş adresi (AndroidManifest'teki intent-filter ile aynı olmalı).
  static const geriDonusAdresi = 'tr.com.ayasyazilim.pusula://giris-geri-donus';

  final KimlikIstemcisi _istemci;
  final String yonlendirme;
  final Duration girisZamanAsimi;

  /// Google Cloud Web istemci kimliği. Doluysa Google girişi önce cihazın yerel hesap seçicisiyle denenir.
  final String googleSunucuIstemcisi;

  /// Kullanıcı tarayıcıdan uygulamaya döndükten sonra oturumun gelmesi için beklenen süre; gelmezse giriş
  /// iptal edilmiş sayılır.
  final Duration geriDonusBeklemesi;

  Completer<Hesap>? _bekleyenGiris;
  Timer? _geriDonusSayaci;

  @override
  bool get gercek => true;

  @override
  Stream<KimlikOlayi> get olaylar => _istemci.olaylar.map((o) {
    final h = o.kullanici == null ? null : _hesap(o.kullanici!);
    switch (o.tur) {
      case IstemciOlayTuru.girisYapti:
        return KimlikOlayi(KimlikOlayTuru.oturumAcildi, h);
      case IstemciOlayTuru.cikisYapti:
        return const KimlikOlayi(KimlikOlayTuru.oturumKapandi);
      case IstemciOlayTuru.sifreKurtarma:
        return KimlikOlayi(KimlikOlayTuru.sifreKurtarma, h);
    }
  });

  static Hesap _hesap(IstemciKullanicisi k) => Hesap(
    id: k.id,
    saglayici: k.saglayici == 'google' ? GirisSaglayici.google : GirisSaglayici.eposta,
    eposta: k.eposta,
    ad: k.ad,
  );

  @override
  Future<Hesap?> mevcut() async {
    final k = _istemci.kullanici;
    return k == null ? null : _hesap(k);
  }

  Future<T> _hataCevir<T>(Future<T> Function() islem) async {
    try {
      return await islem();
    } on IstemciHatasi catch (h) {
      throw KimlikHatasi(mesajiCevir(h));
    }
  }

  /// Arka uç hata kodlarını Türkçe, kullanıcıya gösterilebilir mesaja çevirir.
  static String mesajiCevir(IstemciHatasi h) {
    if (h.ag) return 'Sunucuya ulaşılamadı. Bağlantını kontrol edip tekrar dene.';
    return switch (h.kod) {
      'invalid_credentials' => 'E-posta ya da şifre hatalı',
      'email_not_confirmed' => 'E-postanı doğrulaman gerekiyor. Gelen kutundaki bağlantıya dokun.',
      'user_already_exists' || 'email_exists' => 'Bu e-posta ile zaten bir hesap var. Giriş yapmayı dene.',
      'weak_password' => 'Şifre yeterince güçlü değil. En az 8 karakter, harf ve rakam kullan.',
      'over_email_send_rate_limit' ||
      'over_request_rate_limit' => 'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.',
      'signup_disabled' => 'Yeni hesap açma şu an kapalı.',
      'same_password' => 'Yeni şifre eskisiyle aynı olamaz.',
      'iptal' => 'Giriş iptal edildi.',
      'google_hatasi' => 'Google ile giriş yapılamadı. Tekrar dene.',
      _ => 'İşlem tamamlanamadı. Tekrar dene.',
    };
  }

  @override
  Future<Hesap> kayitOl({required String eposta, required String sifre}) => _hataCevir(() async {
    final k = await _istemci.kayitOl(eposta.trim(), sifre, yonlendirme: yonlendirme);
    if (k == null) throw EpostaDogrulamaBekleniyor(eposta.trim());
    return _hesap(k);
  });

  @override
  Future<Hesap> girisYap({required String eposta, required String sifre}) =>
      _hataCevir(() async => _hesap(await _istemci.girisYap(eposta.trim(), sifre)));

  @override
  Future<Hesap> saglayiciIleGiris(GirisSaglayici saglayici) async {
    if (saglayici != GirisSaglayici.google) {
      throw KimlikHatasi('${saglayici.etiket} ile giriş şu an desteklenmiyor.');
    }
    // Önce yerel hesap seçici (Android): hızlı ve uygulama adıyla görünür. Desteklenmiyorsa tarayıcı girişine düşülür.
    if (googleSunucuIstemcisi.isNotEmpty) {
      final yerel = await _hataCevir(() => _istemci.googleYerelGiris(googleSunucuIstemcisi));
      if (yerel != null) return _hesap(yerel);
    }
    _bekleyenGiris?.completeError(const KimlikHatasi('Giriş iptal edildi.'));
    final bekleyen = _bekleyenGiris = Completer<Hesap>();
    final abonelik = _istemci.olaylar.listen((o) {
      if (o.tur == IstemciOlayTuru.girisYapti && o.kullanici != null && !bekleyen.isCompleted) {
        bekleyen.complete(_hesap(o.kullanici!));
      }
    });
    try {
      final acildi = await _hataCevir(() => _istemci.saglayiciBaslat('google', yonlendirme: yonlendirme));
      if (!acildi) throw const KimlikHatasi('Giriş sayfası açılamadı. Tekrar dene.');
      return await bekleyen.future.timeout(
        girisZamanAsimi,
        onTimeout: () => throw const KimlikHatasi('Giriş tamamlanmadı. Tekrar dene.'),
      );
    } finally {
      _geriDonusSayaci?.cancel();
      _geriDonusSayaci = null;
      unawaited(abonelik.cancel());
      if (identical(_bekleyenGiris, bekleyen)) _bekleyenGiris = null;
    }
  }

  /// Uygulama ön plana dönünce çağrılır. Tarayıcıdaki Google girişi bekleniyorsa ve oturum kısa sürede
  /// gelmezse (kullanıcı vazgeçti) giriş iptal edilmiş sayılır; böylece düğme sonsuza dek meşgul kalmaz.
  void uygulamaOnePlanaGeldi() {
    final bekleyen = _bekleyenGiris;
    if (bekleyen == null || bekleyen.isCompleted) return;
    _geriDonusSayaci?.cancel();
    _geriDonusSayaci = Timer(geriDonusBeklemesi, () {
      if (!bekleyen.isCompleted) bekleyen.completeError(const KimlikHatasi('Giriş tamamlanmadı. Tekrar dene.'));
    });
  }

  @override
  Future<void> sifreDegistir({required String eskiSifre, required String yeniSifre}) => _hataCevir(() async {
    final k = _istemci.kullanici;
    if (k == null || k.eposta.isEmpty) throw const KimlikHatasi('Oturum bulunamadı. Tekrar giriş yap.');
    try {
      await _istemci.girisYap(k.eposta, eskiSifre);
    } on IstemciHatasi catch (h) {
      if (h.kod == 'invalid_credentials') throw const KimlikHatasi('Mevcut şifren yanlış');
      rethrow;
    }
    await _istemci.sifreGuncelle(yeniSifre);
  });

  @override
  Future<void> sifreSifirlamaIste(String eposta) => _hataCevir(
    () => _istemci.sifreSifirlamaIste(eposta.trim(), yonlendirme: yonlendirme),
  );

  @override
  Future<void> kurtarmaSifresiBelirle(String yeniSifre) => _hataCevir(() => _istemci.sifreGuncelle(yeniSifre));

  @override
  Future<void> cikisYap() => _hataCevir(_istemci.cikis);

  @override
  Future<void> hesabiSil() => _hataCevir(() async {
    await _istemci.hesabiSil();
    await _istemci.cikis();
  });
}
