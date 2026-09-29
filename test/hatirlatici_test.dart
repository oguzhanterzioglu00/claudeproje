import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/depolama.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/ayarlar/ayarlar_sayfasi.dart';
import 'package:pusula/features/hatirlatici/hatirlatici_deposu.dart';
import 'package:pusula/features/hatirlatici/hatirlatici_servisi.dart';
import 'package:pusula/features/maas/domain/gosterge_tablosu.dart';
import 'package:pusula/features/maas/domain/memur_maas_hesaplayici.dart';
import 'package:pusula/features/profil/domain/profil.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  final simdi = DateTime(2026, 9, 29, 10);
  final profil = Profil(
    ad: 'Ayşe',
    statu: Statu.memur657,
    maas: const MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10),
    kademeTarihi: DateTime(2025, 12, 1),
  );

  group('kademeHatirlatmalari', () {
    test('süre dolmadan bir hafta önce ve dolduğu gün 09:00', () {
      final l = kademeHatirlatmalari(DateTime(2025, 12, 1), simdi);
      expect(l.map((h) => h.zaman), [DateTime(2026, 11, 24, 9), DateTime(2026, 12, 1, 9)]);
      expect(l.first.baslik, contains('1 hafta'));
    });

    test('geçmişte kalan hatırlatmalar üretilmez', () {
      expect(kademeHatirlatmalari(DateTime(2025, 10, 1), simdi).map((h) => h.zaman), [DateTime(2026, 10, 1, 9)]);
      expect(kademeHatirlatmalari(DateTime(2024, 1, 1), simdi), isEmpty);
    });
  });

  group('HatirlaticiDeposu', () {
    HatirlaticiDeposu uret(SahteHatirlaticiServisi s, [AnahtarDeger? d]) =>
        HatirlaticiDeposu(s, d ?? BellekDepolama(), hesapId: 'h1', simdi: () => simdi);

    test('varsayılan kapalı; açılınca izin istenir, bildirimler kurulur, kapatılınca kalkar', () async {
      final s = SahteHatirlaticiServisi();
      final d = uret(s);
      await d.yukle();
      expect(d.kademeAcik, isFalse);
      await d.esitle(profil);
      expect(s.planlananlar, isEmpty);

      expect(await d.kademeAyarla(true, profil), isTrue);
      expect(s.izinIstegi, 1);
      expect(
        s.planlananlar.keys,
        unorderedEquals([HatirlaticiDeposu.kademeBirHaftaId, HatirlaticiDeposu.kademeGunuId]),
      );

      expect(await d.kademeAyarla(false, profil), isTrue);
      expect(s.planlananlar, isEmpty);
    });

    test('izin verilmezse açılmaz ve hiçbir şey kurulmaz', () async {
      final s = SahteHatirlaticiServisi(izinVerilir: false);
      final d = uret(s);
      await d.yukle();
      expect(await d.kademeAyarla(true, profil), isFalse);
      expect(d.kademeAcik, isFalse);
      expect(s.planlananlar, isEmpty);
    });

    test('tercih hesap bazında saklanır ve yeniden yüklenir', () async {
      final depo = BellekDepolama();
      final a = uret(SahteHatirlaticiServisi(), depo);
      await a.yukle();
      await a.kademeAyarla(true, profil);
      final b = uret(SahteHatirlaticiServisi(), depo);
      await b.yukle();
      expect(b.kademeAcik, isTrue);
      final baska = HatirlaticiDeposu(SahteHatirlaticiServisi(), depo, hesapId: 'h2');
      await baska.yukle();
      expect(baska.kademeAcik, isFalse);
    });

    test('profil değişince plan yenilenir; tarih kalkar, son kademe, memur olmayan: bildirim yok', () async {
      final s = SahteHatirlaticiServisi();
      final d = uret(s);
      await d.yukle();
      await d.kademeAyarla(true, profil);
      expect(s.planlananlar, hasLength(2));

      await d.esitle(profil.kopya(kademeTarihiniTemizle: true));
      expect(s.planlananlar, isEmpty);

      await d.esitle(profil);
      expect(s.planlananlar, hasLength(2));
      final son = MaasGirdisi(derece: 8, kademe: GostergeTablosu.kademeSayisi(8), hizmetYili: 10);
      await d.esitle(profil.kopya(maas: son));
      expect(s.planlananlar, isEmpty, reason: 'son kademede ilerleme yok');

      await d.esitle(profil.kopya(statu: Statu.isci));
      expect(s.planlananlar, isEmpty);
    });

    test('tercihiSil hem bildirimleri hem kaydı kaldırır', () async {
      final s = SahteHatirlaticiServisi();
      final depo = BellekDepolama();
      final d = uret(s, depo);
      await d.yukle();
      await d.kademeAyarla(true, profil);
      await d.tercihiSil();
      expect(s.planlananlar, isEmpty);
      expect(await depo.oku('hatirlatici_kademe_v1_h1'), isNull);
    });
  });

  group('Ayarlar: Hatırlatıcılar bölümü', () {
    Future<void> ac(WidgetTester tester, HatirlaticiDeposu? depo, {Profil? p}) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: pusulaTema(),
          home: AyarlarSayfasi(profil: p ?? profil, hatirlatici: depo),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('anahtar açılınca bildirimler kurulur', (tester) async {
      final s = SahteHatirlaticiServisi();
      final d = HatirlaticiDeposu(s, BellekDepolama(), hesapId: 'h1', simdi: () => simdi);
      await d.yukle();
      await ac(tester, d);
      expect(find.text('Hatırlatıcılar'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(d.kademeAcik, isTrue);
      expect(s.planlananlar, hasLength(2));
    });

    testWidgets('izin reddedilirse mesaj gösterilir, anahtar kapalı kalır', (tester) async {
      final s = SahteHatirlaticiServisi(izinVerilir: false);
      final d = HatirlaticiDeposu(s, BellekDepolama(), hesapId: 'h1', simdi: () => simdi);
      await d.yukle();
      await ac(tester, d);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bildirim izni verilmedi'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('kademe tarihi girilmemişse açıklama görünür', (tester) async {
      final d = HatirlaticiDeposu(SahteHatirlaticiServisi(), BellekDepolama(), hesapId: 'h1', simdi: () => simdi);
      await d.yukle();
      await ac(
        tester,
        d,
        p: const Profil(ad: 'A', statu: Statu.memur657),
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.textContaining('kademeye geliş tarihini girmelisin'), findsOneWidget);
    });

    testWidgets('servis desteklemiyorsa (web) ya da depo yoksa bölüm görünmez', (tester) async {
      final d = HatirlaticiDeposu(SahteHatirlaticiServisi(destekleniyor: false), BellekDepolama(), hesapId: 'h1');
      await ac(tester, d);
      expect(find.text('Hatırlatıcılar'), findsNothing);
      await ac(tester, null);
      expect(find.text('Hatırlatıcılar'), findsNothing);
    });
  });
}
