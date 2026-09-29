import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/metin.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/ana_sayfa/ana_sayfa.dart';
import 'package:pusula/features/ana_sayfa/ana_sayfa_verisi.dart';
import 'package:pusula/features/becayis/data/ornek_veri.dart';
import 'package:pusula/features/asistan/asistan_servisi.dart';
import 'package:pusula/features/ilanlar/ilan_kaynagi.dart';
import 'package:pusula/features/kabuk/pusula_kabugu.dart';
import 'package:pusula/features/maas/domain/memur_maas_hesaplayici.dart';
import 'package:pusula/features/profil/data/profil_deposu.dart';
import 'package:pusula/features/profil/data/profil_kaydi.dart';
import 'package:pusula/features/profil/domain/profil.dart';

import 'yardimci/yazilar.dart';

const _maas = MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10);

const _tamMemur = Profil(
  ad: 'Ayşe Yılmaz',
  statu: Statu.memur657,
  kurumAdi: 'Sağlık Bakanlığı',
  sinif: 'Sağlık Hizmetleri',
  unvan: 'Hemşire',
  il: 'İzmir',
  sicilNo: '123456',
  kurumsalEposta: 'ayse.yilmaz@ornek.gov.tr',
  maas: _maas,
);

void main() {
  setUpAll(pusulaYazilariniYukle);

  Future<void> boyutla(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('ana sayfa verisi', () {
    test('sonraki maaş dönemi: 29 Eylül → 1 Ocak, 94 gün', () {
      final (kalan, oran) = AnaSayfaVerisi.sonrakiDonem(DateTime(2026, 9, 29));
      expect(kalan, 94);
      expect(oran, closeTo(90 / 184, 0.001)); // 1 Temmuz'dan 90 gün geçti, dönem 184 gün
    });

    test('dönem sınırları: 30 Haziran → 1 gün; 1 Temmuz → 184 gün', () {
      expect(AnaSayfaVerisi.sonrakiDonem(DateTime(2026, 6, 30)).$1, 1);
      expect(AnaSayfaVerisi.sonrakiDonem(DateTime(2026, 7, 1)).$1, 184);
      expect(AnaSayfaVerisi.sonrakiDonem(DateTime(2026, 1, 1)).$2, 0);
    });

    test('memur ve maaş girdisi varsa net motordan gelir, uydurma zam yok', () {
      final bugun = DateTime(2026, 9, 29);
      final v = AnaSayfaVerisi.profilden(_tamMemur, bugun: bugun, becayisAlt: 'İlan ver');
      expect(v.netMaas, const MemurMaasHesaplayici().hesapla(_maas, ay: 9).net.round());
      expect(v.zamFarki, isNull);
      expect(v.egri, isNull);
      expect(v.ornek, isFalse);
      expect(v.yolHaritasi.single.deger, '94 gün');
    });

    test('maaş girdisi yoksa açıklama gösterilir, sayı üretilmez', () {
      final v = AnaSayfaVerisi.profilden(
        _tamMemur.kopya(maas: null).let((p) => Profil(ad: p.ad, statu: p.statu)),
        bugun: DateTime(2026, 9, 29),
        becayisAlt: 'x',
      );
      expect(v.netMaas, isNull);
      expect(v.maasMesaji, contains('derece, kademe'));
    });

    test('sözleşmeli için brüt ücret girilmemişse maaş yok ve yol haritası boş', () {
      final v = AnaSayfaVerisi.profilden(
        const Profil(ad: 'A', statu: Statu.sozlesmeli),
        bugun: DateTime(2026, 9, 29),
        becayisAlt: 'x',
      );
      expect(v.netMaas, isNull);
      expect(v.maasMesaji, contains('aylık brüt ücretini gir'));
      expect(v.yolHaritasi, isEmpty);
    });
  });

  group('ana sayfa ekranı', () {
    testWidgets('örnek veri: rozet, zam ve yol haritası görünür', (tester) async {
      await boyutla(tester);
      var asistan = 0, becayis = 0, profil = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: pusulaTema(),
          home: Scaffold(
            body: AnaSayfa(
              veri: AnaSayfaVerisi.ornekVeri,
              bugun: DateTime(2026, 9, 29),
              asistanaGit: () => asistan++,
              becayisiAc: () => becayis++,
              profilAc: () => profil++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Kamu Pusulası'), findsOneWidget);
      expect(find.text('Salı, 29 Eylül'), findsOneWidget);
      expect(find.text('₺41.250'), findsOneWidget);
      expect(find.text('+₺3.450 zam'), findsOneWidget);
      expect(find.text('ÖRNEK HESAP'), findsOneWidget);
      expect(find.text('Yol haritan'), findsOneWidget);
      expect(find.text('1 yeni eşleşme'), findsOneWidget);

      await tester.tap(find.text('Hakkım ne?'));
      await tester.tap(find.text('Becayiş'));
      await tester.tap(find.bySemanticsLabel('Profilim'));
      expect((asistan, becayis, profil), (1, 1, 1));
    });

    testWidgets('net maaş yoksa açıklama kartı; yol haritası boşsa bölüm gizlenir', (tester) async {
      await boyutla(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: pusulaTema(),
          home: const Scaffold(
            body: AnaSayfa(
              veri: AnaSayfaVerisi(maasMesaji: 'Maaşını görmek için derece, kademe ve hizmet yılını gir.'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.textContaining('derece, kademe ve hizmet yılını gir'), findsOneWidget);
      expect(find.text('Yol haritan'), findsNothing);
      expect(find.text('ÖRNEK HESAP'), findsNothing);
      expect(find.text('Eşleşme bul'), findsOneWidget);
    });
  });

  group('kabuk', () {
    Future<ProfilDeposu> ac(WidgetTester tester, Profil profil, {int sekme = 0, bool ornekBecayis = false}) async {
      await boyutla(tester);
      final depo = ProfilDeposu(BellekProfilKaydi(profil));
      await depo.yukle();
      await tester.pumpWidget(
        MaterialApp(
          theme: pusulaTema(),
          home: PusulaKabugu(
            profilDeposu: depo,
            bugun: DateTime(2026, 9, 29),
            haberOtomatik: false,
            baslangicSekmesi: sekme,
            asistan: const YerelMevzuatAsistani(sure: Duration(milliseconds: 10)),
            ilanKaynagi: OrnekIlanKaynagi(sure: const Duration(milliseconds: 10), bugun: DateTime(2026, 9, 29)),
            becayisDeposuUret: ornekBecayis ? (_) => BecayisOrnekVeri.depo() : BecayisOrnekVeri.depoProfilden,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));
      return depo;
    }

    testWidgets('ana sayfa profilden hesaplanan net maaşı gösterir', (tester) async {
      await ac(tester, _tamMemur);
      final net = const MemurMaasHesaplayici().hesapla(_maas, ay: 9).net;
      expect(find.text(liraTam(net.round())), findsOneWidget);
      expect(find.text('Sonraki maaş dönemi'), findsOneWidget);
      expect(find.text('94 gün'), findsOneWidget);
      expect(find.text('ÖRNEK HESAP'), findsNothing);
      expect(find.text('Ana sayfa'), findsOneWidget);
      expect(find.text('Maaş'), findsNothing);
    });

    testWidgets('alt çubuktan sekmeler arasında geçilir', (tester) async {
      await ac(tester, _tamMemur);
      await tester.tap(find.byKey(const ValueKey('sekme-1')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Maaş hesapla'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('sekme-2')));
      await tester.pumpAndSettle();
      expect(find.text('Hakkım ne?'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('sekme-4')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('İlanlar'), findsWidgets);
      expect(find.text('Hemşire alımı'), findsOneWidget);
    });

    testWidgets('ilanı olmayan memurda Becayiş sekmesi karşılama gösterir; kısayol "İlan ver" der', (tester) async {
      await ac(tester, _tamMemur);
      expect(find.text('İlan ver'), findsOneWidget); // ana sayfa kısayolu
      await tester.tap(find.text('İlan ver'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Henüz ilanın yok'), findsOneWidget);
      expect(find.textContaining('Hemşire · Sağlık Bakanlığı · İzmir'), findsOneWidget);
    });

    testWidgets('becayiş için profil eksikse Becayiş sekmesi profil ister', (tester) async {
      await ac(tester, _tamMemur.kopya(unvan: ''));
      expect(find.text('Profilini tamamla'), findsOneWidget); // ana sayfa kısayolu
      await tester.tap(find.byKey(const ValueKey('sekme-3')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('Profilinde eksik olanlar: Unvan'), findsOneWidget);
      expect(find.text('Profili düzenle'), findsOneWidget);
    });

    testWidgets('sözleşmelide Becayiş kapalı ve ana sayfa "Yalnızca memurlar" der', (tester) async {
      await ac(tester, const Profil(ad: 'A', statu: Statu.sozlesmeli));
      expect(find.text('Yalnızca memurlar'), findsOneWidget);
      expect(find.textContaining('Maaşını görmek için Maaş sekmesinden aylık brüt ücretini gir'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sekme-3')));
      await tester.pumpAndSettle();
      expect(find.text('Becayiş sende kapalı'), findsOneWidget);
    });

    testWidgets('yayındaki ilanı olan kullanıcıda ana sayfa eşleşme sayısını gösterir', (tester) async {
      await ac(tester, _tamMemur, ornekBecayis: true);
      expect(find.text('2 eşleşme'), findsOneWidget); // 2 ikili; zincir ayrı sayılır
    });

    testWidgets('maaş sekmesinden kaydedilen girdi profile yazılır ve ana sayfaya yansır', (tester) async {
      final depo = await ac(
        tester,
        _tamMemur
            .kopya(maas: null)
            .let(
              (p) => Profil(ad: p.ad, statu: p.statu, kurumAdi: p.kurumAdi, sinif: p.sinif, unvan: p.unvan, il: p.il),
            ),
      );
      expect(find.textContaining('derece, kademe ve hizmet yılını gir'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('sekme-1')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.scrollUntilVisible(find.text('Bilgilerimi profilime kaydet'), 300);
      await tester.tap(find.text('Bilgilerimi profilime kaydet'));
      await tester.pumpAndSettle();
      expect(depo.profil!.maas, const MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10));
      expect(find.text('Profilinde kayıtlı'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('sekme-0')));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.textContaining('derece, kademe ve hizmet yılını gir'), findsNothing);
      expect(find.text('Sonraki maaş dönemi'), findsOneWidget);
    });
  });

  group('metin yardımcıları', () {
    test('binlik ayırıcı', () {
      expect(binlik(999), '999');
      expect(binlik(41250), '41.250');
      expect(binlik(1000000), '1.000.000');
      expect(binlik(-1500), '-1.500');
      expect(binlik(41249.6), '41.250');
    });

    test('liraTam ve kısa tarih', () {
      expect(liraTam(3450), '₺3.450');
      expect(kisaTarih(DateTime(2026, 9, 29)), 'Salı, 29 Eylül');
      expect(kisaTarih(DateTime(2026, 1, 4)), 'Pazar, 4 Ocak');
    });
  });
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
