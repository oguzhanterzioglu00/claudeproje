import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/features/hesap/data/kimlik_servisi.dart';
import 'package:pusula/features/hesap/data/oturum_deposu.dart';
import 'package:pusula/features/hesap/data/supabase_kimlik_servisi.dart';
import 'package:pusula/features/hesap/domain/hesap.dart';
import 'package:pusula/features/hesap/presentation/giris_sayfasi.dart';
import 'package:pusula/features/hesap/presentation/yeni_sifre_sayfasi.dart';

import 'yardimci/yazilar.dart';

/// Ağ olmadan akışı sınamak için sahte Supabase istemcisi.
class _Sahte implements KimlikIstemcisi {
  IstemciKullanicisi? mevcut;
  final _olaylar = StreamController<IstemciOlayi>.broadcast();

  IstemciHatasi? hata;
  bool dogrulamaGerek = false;
  bool tarayiciAcilir = true;
  final cagrilar = <String>[];
  String? sonSifre;
  String? sonYonlendirme;

  @override
  IstemciKullanicisi? get kullanici => mevcut;

  @override
  Stream<IstemciOlayi> get olaylar => _olaylar.stream;

  void olayGonder(IstemciOlayi o) => _olaylar.add(o);

  @override
  Future<IstemciKullanicisi?> kayitOl(String eposta, String sifre, {required String yonlendirme}) async {
    cagrilar.add('kayit:$eposta');
    sonYonlendirme = yonlendirme;
    if (hata != null) throw hata!;
    if (dogrulamaGerek) return null;
    return mevcut = IstemciKullanicisi(id: 'u1', eposta: eposta);
  }

  @override
  Future<IstemciKullanicisi> girisYap(String eposta, String sifre) async {
    cagrilar.add('giris:$eposta');
    sonSifre = sifre;
    if (hata != null) throw hata!;
    return mevcut = IstemciKullanicisi(id: 'u1', eposta: eposta);
  }

  @override
  Future<bool> saglayiciBaslat(String saglayici, {required String yonlendirme}) async {
    cagrilar.add('oauth:$saglayici');
    sonYonlendirme = yonlendirme;
    if (hata != null) throw hata!;
    return tarayiciAcilir;
  }

  /// Yerel Google girişi: null = desteklenmiyor; kullanıcı = başarılı; [yerelHata] doluysa fırlatılır.
  IstemciKullanicisi? yerelKullanici;
  IstemciHatasi? yerelHata;
  String? yerelIstemciKimligi;

  @override
  Future<IstemciKullanicisi?> googleYerelGiris(String sunucuIstemciKimligi) async {
    cagrilar.add('yerel:$sunucuIstemciKimligi');
    yerelIstemciKimligi = sunucuIstemciKimligi;
    if (yerelHata != null) throw yerelHata!;
    return yerelKullanici;
  }

  IstemciKullanicisi? appleKullanici;
  IstemciHatasi? appleHata;

  @override
  Future<IstemciKullanicisi?> appleYerelGiris() async {
    cagrilar.add('apple');
    if (appleHata != null) throw appleHata!;
    return appleKullanici;
  }

  @override
  Future<void> sifreSifirlamaIste(String eposta, {required String yonlendirme}) async {
    cagrilar.add('sifirla:$eposta');
    if (hata != null) throw hata!;
  }

  @override
  Future<void> sifreGuncelle(String yeniSifre) async {
    cagrilar.add('guncelle:$yeniSifre');
    if (hata != null) throw hata!;
  }

  @override
  Future<void> cikis() async {
    cagrilar.add('cikis');
    mevcut = null;
  }

  @override
  Future<void> hesabiSil() async {
    cagrilar.add('sil');
    if (hata != null) throw hata!;
  }
}

void main() {
  setUpAll(pusulaYazilariniYukle);

  late _Sahte istemci;
  late SupabaseKimlikServisi servis;

  setUp(() {
    istemci = _Sahte();
    servis = SupabaseKimlikServisi(
      istemci,
      girisZamanAsimi: const Duration(seconds: 5),
      geriDonusBeklemesi: const Duration(milliseconds: 50),
    );
  });

  group('SupabaseKimlikServisi', () {
    test('gerçek bir servistir', () => expect(servis.gercek, isTrue));

    test('kayıt: hesap döner, doğru yönlendirme adresi gönderilir', () async {
      final h = await servis.kayitOl(eposta: ' ayse@ornek.com ', sifre: 'Deneme123');
      expect(h.eposta, 'ayse@ornek.com', reason: 'baştaki/sondaki boşluk atılır');
      expect(h.saglayici, GirisSaglayici.eposta);
      // E-posta bağlantıları uygulama-içi adrese değil, herkese açık köprü sayfasına iner.
      expect(istemci.sonYonlendirme, SupabaseKimlikServisi.epostaDonusAdresi);
      expect(istemci.sonYonlendirme, 'https://oguzhanterzioglu00.github.io/claudeproje/auth-donus.html');
    });

    test('e-posta doğrulaması gerekiyorsa bilgi mesajı fırlatılır (hata değil)', () async {
      istemci.dogrulamaGerek = true;
      await expectLater(
        servis.kayitOl(eposta: 'a@b.com', sifre: 'Deneme123'),
        throwsA(isA<EpostaDogrulamaBekleniyor>().having((e) => e.bilgi, 'bilgi', isTrue)),
      );
    });

    test('giriş', () async {
      final h = await servis.girisYap(eposta: 'a@b.com', sifre: 'Deneme123');
      expect(h.id, 'u1');
      expect(await servis.mevcut(), isNotNull);
    });

    test('mevcut: oturum yoksa null', () async {
      expect(await servis.mevcut(), isNull);
    });

    test('hata kodları Türkçe mesaja çevrilir', () async {
      final eslesmeler = {
        'invalid_credentials': 'E-posta ya da şifre hatalı',
        'email_not_confirmed': 'doğrulaman',
        'user_already_exists': 'zaten bir hesap var',
        'email_exists': 'zaten bir hesap var',
        'weak_password': 'yeterince güçlü değil',
        'over_email_send_rate_limit': 'Çok fazla deneme',
        'over_request_rate_limit': 'Çok fazla deneme',
        'signup_disabled': 'kapalı',
        'bilinmeyen_kod': 'tamamlanamadı',
      };
      for (final e in eslesmeler.entries) {
        istemci.hata = IstemciHatasi(kod: e.key);
        await expectLater(
          servis.girisYap(eposta: 'a@b.com', sifre: 'x'),
          throwsA(isA<KimlikHatasi>().having((k) => k.mesaj, 'mesaj', contains(e.value))),
          reason: e.key,
        );
      }
    });

    test('ağ hatası bağlantı mesajı verir', () async {
      istemci.hata = const IstemciHatasi(ag: true);
      await expectLater(
        servis.girisYap(eposta: 'a@b.com', sifre: 'x'),
        throwsA(isA<KimlikHatasi>().having((k) => k.mesaj, 'mesaj', contains('Sunucuya ulaşılamadı'))),
      );
    });

    test('şifre değiştirme: eski şifre doğrulanır, sonra yenisi yazılır', () async {
      istemci.mevcut = const IstemciKullanicisi(id: 'u1', eposta: 'a@b.com');
      await servis.sifreDegistir(eskiSifre: 'Eski1234', yeniSifre: 'Yeni12345');
      expect(istemci.sonSifre, 'Eski1234');
      expect(istemci.cagrilar, containsAllInOrder(['giris:a@b.com', 'guncelle:Yeni12345']));
    });

    test('şifre değiştirme: eski şifre yanlışsa yenisi yazılmaz', () async {
      istemci.mevcut = const IstemciKullanicisi(id: 'u1', eposta: 'a@b.com');
      istemci.hata = const IstemciHatasi(kod: 'invalid_credentials');
      await expectLater(
        servis.sifreDegistir(eskiSifre: 'yanlis', yeniSifre: 'Yeni12345'),
        throwsA(isA<KimlikHatasi>().having((k) => k.mesaj, 'mesaj', 'Mevcut şifren yanlış')),
      );
      expect(istemci.cagrilar.any((c) => c.startsWith('guncelle')), isFalse);
    });

    test('şifre değiştirme: oturum yoksa açıklama verir', () async {
      await expectLater(
        servis.sifreDegistir(eskiSifre: 'a', yeniSifre: 'b'),
        throwsA(isA<KimlikHatasi>().having((k) => k.mesaj, 'mesaj', contains('Oturum bulunamadı'))),
      );
    });

    test('şifre sıfırlama isteği ve kurtarma şifresi', () async {
      await servis.sifreSifirlamaIste(' a@b.com ');
      await servis.kurtarmaSifresiBelirle('Yeni12345');
      expect(istemci.cagrilar, ['sifirla:a@b.com', 'guncelle:Yeni12345']);
    });

    test('hesap silme önce sunucudaki hesabı siler, sonra oturumu kapatır', () async {
      await servis.hesabiSil();
      expect(istemci.cagrilar, ['sil', 'cikis']);
    });

    test('hesap silme başarısızsa oturum kapatılmaz', () async {
      istemci.hata = const IstemciHatasi(kod: 'x');
      await expectLater(servis.hesabiSil(), throwsA(isA<KimlikHatasi>()));
      expect(istemci.cagrilar, ['sil']);
    });

    test('Apple: iOS dışında (istemci null döner) açıklayıcı mesaj verir', () async {
      await expectLater(
        servis.saglayiciIleGiris(GirisSaglayici.apple),
        throwsA(isA<KimlikHatasi>().having((k) => k.mesaj, 'mesaj', contains('iPhone ve iPad'))),
      );
    });

    test('Apple: yerel giriş hesabı Apple sağlayıcısıyla döner (tarayıcıya gidilmez)', () async {
      istemci.appleKullanici = const IstemciKullanicisi(id: 'a1', eposta: 'x@privaterelay.appleid.com', ad: 'Ayşe Yılmaz', saglayici: 'apple');
      final h = await servis.saglayiciIleGiris(GirisSaglayici.apple);
      expect(h.id, 'a1');
      expect(h.saglayici, GirisSaglayici.apple);
      expect(h.ad, 'Ayşe Yılmaz');
      expect(istemci.cagrilar, ['apple']);
    });

    test('Apple: vazgeçme ve hata mesajları', () async {
      istemci.appleHata = const IstemciHatasi(kod: 'iptal');
      await expectLater(
        servis.saglayiciIleGiris(GirisSaglayici.apple),
        throwsA(isA<KimlikHatasi>().having((k) => k.mesaj, 'mesaj', 'Giriş iptal edildi.')),
      );
      istemci.appleHata = const IstemciHatasi(kod: 'apple_hatasi');
      await expectLater(
        servis.saglayiciIleGiris(GirisSaglayici.apple),
        throwsA(isA<KimlikHatasi>().having((k) => k.mesaj, 'mesaj', contains('Apple ile giriş yapılamadı'))),
      );
    });

    test('Google: tarayıcı açılır, uygulamaya dönüşte gelen oturum hesabı döner', () async {
      final sonuc = servis.saglayiciIleGiris(GirisSaglayici.google);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(istemci.cagrilar, contains('oauth:google'));
      istemci.olayGonder(
        const IstemciOlayi(
          IstemciOlayTuru.girisYapti,
          IstemciKullanicisi(id: 'g1', eposta: 'g@gmail.com', ad: 'Ayşe', saglayici: 'google'),
        ),
      );
      final h = await sonuc;
      expect(h.saglayici, GirisSaglayici.google);
      expect(h.eposta, 'g@gmail.com');
      expect(h.ad, 'Ayşe');
    });

    test('Google yerel giriş: istemci kimliği verilmişse önce yerel hesap seçici denenir, tarayıcı açılmaz', () async {
      istemci.yerelKullanici = const IstemciKullanicisi(id: 'y1', eposta: 'y@gmail.com', ad: 'Yerel', saglayici: 'google');
      final s = SupabaseKimlikServisi(istemci, googleSunucuIstemcisi: 'web-kimlik.apps.googleusercontent.com');
      final h = await s.saglayiciIleGiris(GirisSaglayici.google);
      expect(h.id, 'y1');
      expect(h.saglayici, GirisSaglayici.google);
      expect(istemci.yerelIstemciKimligi, 'web-kimlik.apps.googleusercontent.com');
      expect(istemci.cagrilar.any((c) => c.startsWith('oauth')), isFalse);
    });

    test('Google yerel giriş desteklenmiyorsa (null) tarayıcı girişine düşer', () async {
      final s = SupabaseKimlikServisi(
        istemci,
        googleSunucuIstemcisi: 'web-kimlik',
        girisZamanAsimi: const Duration(seconds: 5),
      );
      final sonuc = s.saglayiciIleGiris(GirisSaglayici.google);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(istemci.cagrilar, containsAllInOrder(['yerel:web-kimlik', 'oauth:google']));
      istemci.olayGonder(const IstemciOlayi(IstemciOlayTuru.girisYapti, IstemciKullanicisi(id: 'b1', saglayici: 'google')));
      expect((await sonuc).id, 'b1');
    });

    test('Google yerel giriş: kullanıcı vazgeçerse "iptal edildi" ve tarayıcıya geçilmez', () async {
      istemci.yerelHata = const IstemciHatasi(kod: 'iptal');
      final s = SupabaseKimlikServisi(istemci, googleSunucuIstemcisi: 'web-kimlik');
      await expectLater(
        s.saglayiciIleGiris(GirisSaglayici.google),
        throwsA(isA<KimlikHatasi>().having((k) => k.mesaj, 'mesaj', 'Giriş iptal edildi.')),
      );
      expect(istemci.cagrilar.any((c) => c.startsWith('oauth')), isFalse);
    });

    test('Google yerel giriş hatası anlaşılır mesaj verir', () async {
      istemci.yerelHata = const IstemciHatasi(kod: 'google_hatasi');
      final s = SupabaseKimlikServisi(istemci, googleSunucuIstemcisi: 'web-kimlik');
      await expectLater(
        s.saglayiciIleGiris(GirisSaglayici.google),
        throwsA(isA<KimlikHatasi>().having((k) => k.mesaj, 'mesaj', contains('Google ile giriş yapılamadı'))),
      );
    });

    test('Google: istemci kimliği boşsa yerel giriş hiç denenmez', () async {
      final sonuc = servis.saglayiciIleGiris(GirisSaglayici.google);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(istemci.cagrilar.any((c) => c.startsWith('yerel')), isFalse);
      istemci.olayGonder(const IstemciOlayi(IstemciOlayTuru.girisYapti, IstemciKullanicisi(id: 'g1', saglayici: 'google')));
      await sonuc;
    });

    test('Google: tarayıcı açılamazsa hata verir', () async {
      istemci.tarayiciAcilir = false;
      await expectLater(
        servis.saglayiciIleGiris(GirisSaglayici.google),
        throwsA(isA<KimlikHatasi>().having((k) => k.mesaj, 'mesaj', contains('açılamadı'))),
      );
    });

    test('Google: kullanıcı vazgeçip uygulamaya dönerse giriş iptal edilir (düğme takılı kalmaz)', () async {
      final sonuc = servis.saglayiciIleGiris(GirisSaglayici.google);
      final bekle = expectLater(sonuc, throwsA(isA<KimlikHatasi>()));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      servis.uygulamaOnePlanaGeldi(); // oturum gelmedi
      await bekle;
    });

    test('Google: dönüşte oturum kısa sürede gelirse iptal edilmez', () async {
      final sonuc = servis.saglayiciIleGiris(GirisSaglayici.google);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      servis.uygulamaOnePlanaGeldi();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      istemci.olayGonder(const IstemciOlayi(IstemciOlayTuru.girisYapti, IstemciKullanicisi(id: 'g1', saglayici: 'google')));
      expect((await sonuc).id, 'g1');
    });

    test('olay akışı: giriş, çıkış ve şifre kurtarma dönüştürülür', () async {
      final gelenler = <KimlikOlayi>[];
      final abone = servis.olaylar.listen(gelenler.add);
      istemci.olayGonder(const IstemciOlayi(IstemciOlayTuru.girisYapti, IstemciKullanicisi(id: 'a')));
      istemci.olayGonder(const IstemciOlayi(IstemciOlayTuru.sifreKurtarma, IstemciKullanicisi(id: 'a')));
      istemci.olayGonder(const IstemciOlayi(IstemciOlayTuru.cikisYapti));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await abone.cancel();
      expect(gelenler.map((o) => o.tur), [
        KimlikOlayTuru.oturumAcildi,
        KimlikOlayTuru.sifreKurtarma,
        KimlikOlayTuru.oturumKapandi,
      ]);
    });
  });

  group('OturumDeposu + arka plan olayları', () {
    test('tarayıcıdan dönen Google oturumu (uygulama yeniden açılsa bile) hesabı kurar', () async {
      final depo = OturumDeposu(servis);
      await depo.yukle();
      expect(depo.hesap, isNull);
      istemci.olayGonder(const IstemciOlayi(IstemciOlayTuru.girisYapti, IstemciKullanicisi(id: 'g1', eposta: 'g@x.com', saglayici: 'google')));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(depo.hesap?.id, 'g1');
      expect(depo.gercek, isTrue);
      istemci.olayGonder(const IstemciOlayi(IstemciOlayTuru.cikisYapti));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(depo.hesap, isNull);
      depo.dispose();
    });

    test('şifre kurtarma olayı yeni şifre bekler; belirlenince normal oturuma döner', () async {
      final depo = OturumDeposu(servis);
      await depo.yukle();
      istemci.olayGonder(const IstemciOlayi(IstemciOlayTuru.sifreKurtarma, IstemciKullanicisi(id: 'u9', eposta: 'a@b.com')));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(depo.sifreKurtarmaBekliyor, isTrue);
      await depo.yeniSifreBelirle('Yeni12345');
      expect(depo.sifreKurtarmaBekliyor, isFalse);
      expect(depo.hesap?.id, 'u9');
      expect(istemci.cagrilar, contains('guncelle:Yeni12345'));
      depo.dispose();
    });

    test('şifre kurtarmadan vazgeçmek oturumu kapatır', () async {
      final depo = OturumDeposu(servis);
      await depo.yukle();
      istemci.olayGonder(const IstemciOlayi(IstemciOlayTuru.sifreKurtarma, IstemciKullanicisi(id: 'u9')));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await depo.kurtarmadanVazgec();
      expect(depo.sifreKurtarmaBekliyor, isFalse);
      expect(depo.hesap, isNull);
      depo.dispose();
    });
  });

  group('Arayüz', () {
    setUp(() {
      final b = TestWidgetsFlutterBinding.ensureInitialized();
      b.platformDispatcher.views.first.physicalSize = const Size(900, 2200);
      b.platformDispatcher.views.first.devicePixelRatio = 1;
    });
    tearDown(() {
      final b = TestWidgetsFlutterBinding.ensureInitialized();
      b.platformDispatcher.views.first.resetPhysicalSize();
      b.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('gerçek serviste ÖRNEK rozeti ve örnek metni yok; Google düğmesi var', (t) async {
      final depo = OturumDeposu(servis);
      await depo.yukle();
      await t.pumpWidget(MaterialApp(home: GirisSayfasi(oturum: depo, sosyalGiris: true, appleGoster: false)));
      await t.pumpAndSettle();
      expect(find.text('ÖRNEK'), findsNothing);
      expect(find.text('Google ile devam et'), findsOneWidget);
      expect(find.text('Apple ile devam et'), findsNothing);
      expect(find.textContaining('güvenli sunucuda'), findsOneWidget);
      expect(find.textContaining('Bu sürümde hesabın'), findsNothing);
      depo.dispose();
    });

    testWidgets('iOS: Apple düğmesi görünür ve yerel Apple girişini başlatır', (t) async {
      istemci.appleKullanici = const IstemciKullanicisi(id: 'a1', eposta: 'a@x.com', saglayici: 'apple');
      final depo = OturumDeposu(servis);
      await depo.yukle();
      await t.pumpWidget(MaterialApp(home: GirisSayfasi(oturum: depo, sosyalGiris: true, appleGoster: true)));
      await t.pumpAndSettle();
      expect(find.text('Apple ile devam et'), findsOneWidget);
      await t.tap(find.text('Apple ile devam et'));
      await t.pumpAndSettle();
      expect(istemci.cagrilar, contains('apple'));
      expect(depo.hesap?.saglayici, GirisSaglayici.apple);
      depo.dispose();
    });

    testWidgets('Google düğmesi örnek onay sayfası açmadan doğrudan girişi başlatır', (t) async {
      final depo = OturumDeposu(servis);
      await depo.yukle();
      await t.pumpWidget(MaterialApp(home: GirisSayfasi(oturum: depo, sosyalGiris: true, appleGoster: false)));
      await t.pumpAndSettle();
      await t.tap(find.text('Google ile devam et'));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Örnek hesapla devam et'), findsNothing);
      expect(istemci.cagrilar, contains('oauth:google'));
      istemci.olayGonder(const IstemciOlayi(IstemciOlayTuru.girisYapti, IstemciKullanicisi(id: 'g1', saglayici: 'google')));
      await t.pumpAndSettle();
      expect(depo.hesap?.id, 'g1');
      expect(depo.mesgul, isFalse);
      depo.dispose();
    });

    testWidgets('e-posta doğrulaması bekleniyorsa yeşil bilgi kutusu görünür', (t) async {
      istemci.dogrulamaGerek = true;
      final depo = OturumDeposu(servis);
      await depo.yukle();
      await t.pumpWidget(MaterialApp(home: GirisSayfasi(oturum: depo)));
      await t.pumpAndSettle();
      await t.tap(find.text('Hesap oluştur').first);
      await t.pumpAndSettle();
      final alanlar = find.byType(TextField);
      await t.enterText(alanlar.at(0), 'yeni@ornek.com');
      await t.enterText(alanlar.at(1), 'Deneme1234');
      await t.pump();
      await t.tap(find.widgetWithText(ElevatedButton, 'Hesap oluştur').evaluate().isEmpty
          ? find.text('Hesap oluştur').last
          : find.widgetWithText(ElevatedButton, 'Hesap oluştur'));
      await t.pumpAndSettle();
      expect(find.textContaining('Doğrulama bağlantısını yeni@ornek.com adresine gönderdik'), findsOneWidget);
      depo.dispose();
    });

    testWidgets('yeni şifre sayfası: kısa şifrede düğme pasif, uygun şifrede kaydeder', (t) async {
      istemci.mevcut = const IstemciKullanicisi(id: 'u9', eposta: 'a@b.com');
      final depo = OturumDeposu(servis);
      await depo.yukle();
      istemci.olayGonder(const IstemciOlayi(IstemciOlayTuru.sifreKurtarma, IstemciKullanicisi(id: 'u9', eposta: 'a@b.com')));
      await t.pump(const Duration(milliseconds: 10));
      await t.pumpWidget(MaterialApp(home: YeniSifreSayfasi(oturum: depo)));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'kisa');
      await t.pump();
      expect(find.text('Şifre en az 8 karakter olmalı'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'Yeni12345');
      await t.pump();
      await t.tap(find.text('Şifreyi kaydet'));
      await t.pumpAndSettle();
      expect(istemci.cagrilar, contains('guncelle:Yeni12345'));
      expect(depo.sifreKurtarmaBekliyor, isFalse);
      depo.dispose();
    });
  });
}
