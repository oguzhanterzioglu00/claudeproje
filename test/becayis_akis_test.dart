import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/metin.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/becayis/data/becayis_deposu.dart';
import 'package:pusula/features/becayis/data/ornek_veri.dart';
import 'package:pusula/features/becayis/data/servisler.dart';
import 'package:pusula/features/becayis/domain/eslesme.dart';
import 'package:pusula/features/becayis/domain/statu.dart';
import 'package:pusula/features/becayis/presentation/becayis_eslesme_sayfasi.dart';
import 'package:pusula/features/becayis/presentation/becayis_sekmesi.dart';

import 'yardimci/yazilar.dart';

const _memur = Profil(ad: 'Ayşe Yılmaz', statu: Statu.memur657);

void main() {
  setUpAll(pusulaYazilariniYukle);

  Future<void> uygula(WidgetTester tester, Widget ev) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: pusulaTema(), home: ev));
    await tester.pumpAndSettle();
  }

  BecayisDeposu depo({OdemeServisi odeme = const SahteOdemeServisi(sure: Duration(milliseconds: 50))}) =>
      BecayisDeposu(
        benim: BecayisOrnekVeri.benimIlanim,
        digerleri: BecayisOrnekVeri.digerIlanlar,
        kisiler: BecayisOrnekVeri.kisiler,
        epostam: 'ayse.yilmaz@ornek.gov.tr',
        odeme: odeme,
      );

  group('uçtan uca akış', () {
    testWidgets('panel → eşleşme → ilgileniyorum → ödeme → iletişim açılır → dilekçe', (tester) async {
      await uygula(tester, BecayisSekmesi(profil: _memur, depo: depo()));

      await tester.tap(find.text('M. Demir · Hemşire'));
      await tester.pumpAndSettle();
      expect(find.text('Eşleşme'), findsOneWidget);
      expect(find.text('Kilitli'), findsOneWidget);
      expect(find.text('05•• ••• •• ••'), findsOneWidget);

      // İlgilenmeden ödeme düğmesi yok.
      expect(find.textContaining('İletişimi aç ·'), findsNothing);
      await tester.tap(find.text('İlgileniyorum'));
      await tester.pumpAndSettle();
      expect(find.text('İletişimi aç · ₺249,99'), findsOneWidget);

      await tester.tap(find.text('İletişimi aç · ₺249,99'));
      await tester.pumpAndSettle();
      expect(find.text('Onayla ve öde'), findsOneWidget);
      expect(find.textContaining('kart bilgisi uygulamada tutulmaz'), findsOneWidget);

      await tester.tap(find.text('Onayla ve öde'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Açık'), findsOneWidget);
      expect(find.text('Mehmet Demir'), findsOneWidget);
      expect(find.text('0555 000 00 01'), findsOneWidget);
      expect(find.text('Onayla ve öde'), findsNothing);

      await tester.tap(find.text('Dilekçeni hazırla'));
      await tester.pumpAndSettle();
      expect(find.text('Dilekçe'), findsOneWidget);
      expect(find.text('SAĞLIK BAKANLIĞI MAKAMINA'), findsOneWidget);
      expect(find.textContaining('Mehmet Demir', findRichText: true), findsOneWidget);
      expect(find.textContaining('657 sayılı Devlet Memurları Kanunu', findRichText: true), findsOneWidget);

      await tester.tap(find.text('PDF indir'));
      await tester.pump();
      expect(find.text('İndirildi'), findsOneWidget);
    });

    testWidgets('ödeme başarısız olursa iletişim kilitli kalır ve hata gösterilir', (tester) async {
      final d = depo(odeme: const SahteOdemeServisi(sure: Duration(milliseconds: 10), basarili: false));
      final e = d.eslesmeler.firstWhere((x) => x.tip == EslesmeTipi.ikili);
      d.ilgileniyorum(e);
      await uygula(tester, BecayisEslesmeSayfasi(depo: d, ilkEslesme: e));

      await tester.tap(find.text('İletişimi aç · ₺249,99'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Onayla ve öde'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Ödeme tamamlanamadı. Tekrar dene.'), findsOneWidget);
      expect(d.iletisimAcik, isFalse);
      expect(find.text('Kilitli'), findsOneWidget);
    });

    testWidgets("ikili ile 3'lü zincir arasında geçiş; zincirde md. 73 uyarısı çıkar", (tester) async {
      final d = depo();
      final e = d.eslesmeler.firstWhere((x) => x.tip == EslesmeTipi.ikili);
      await uygula(tester, BecayisEslesmeSayfasi(depo: d, ilkEslesme: e));

      expect(find.textContaining('md. 73'), findsNothing);
      await tester.tap(find.text("3'lü zincir"));
      await tester.pumpAndSettle();
      expect(find.textContaining('md. 73'), findsOneWidget);
      expect(find.text('Zincir kapanıyor: herkes istediği ile ulaşıyor'), findsOneWidget);
      expect(find.text('S. Kaya'), findsWidgets);
      expect(find.text('F. Arslan'), findsWidgets);
    });
  });

  group('kurallar', () {
    test('ödeme, iki taraf da onaylamadan yapılamaz', () async {
      final d = depo();
      final e = d.eslesmeler.first;
      expect(d.hazir(e), isFalse);
      expect(await d.odemeYap(e), isFalse);
      expect(d.iletisimAcik, isFalse);
      expect(d.kisi('demir'), isNull, reason: 'yetki yokken kişi bilgisi verilmez');

      d.ilgileniyorum(e);
      expect(await d.odemeYap(e), isTrue);
      expect(d.kisi('demir')?.tamAd, 'Mehmet Demir');
    });

    testWidgets('657 memuru olmayanlarda Becayiş kapalı sayfası çıkar', (tester) async {
      await uygula(
        tester,
        BecayisSekmesi(profil: const Profil(ad: 'A', statu: Statu.sozlesmeli), depo: depo()),
      );
      expect(find.text('Becayiş sende kapalı'), findsOneWidget);
      expect(find.textContaining('4/B sözleşmeli personel'), findsOneWidget);
      expect(find.text('Hemşire'), findsNothing);
    });

    testWidgets('aday memurda kapalı, nedeni asalet', (tester) async {
      await uygula(
        tester,
        BecayisSekmesi(
          profil: const Profil(ad: 'A', statu: Statu.memur657, adayMemur: true),
          depo: depo(),
        ),
      );
      expect(find.text('Becayiş sende kapalı'), findsOneWidget);
      expect(find.textContaining('asaleti'), findsOneWidget);
    });

    test('Türkçe büyük harf ve lira biçimi', () {
      expect(buyukHarf('Milli Eğitim Bakanlığı'), 'MİLLİ EĞİTİM BAKANLIĞI');
      expect(buyukHarf('Sağlık Bakanlığı'), 'SAĞLIK BAKANLIĞI');
      expect(lira(249.99), '₺249,99');
      expect(lira(250), '₺250,00');
    });

    test('kurumsal e-posta yalnızca .gov.tr ve .edu.tr kabul eder', () {
      expect(SahteDogrulamaServisi.kurumsalMi('a@saglik.gov.tr'), isTrue);
      expect(SahteDogrulamaServisi.kurumsalMi('a@uni.edu.tr'), isTrue);
      expect(SahteDogrulamaServisi.kurumsalMi('a@gmail.com'), isFalse);
      expect(SahteDogrulamaServisi.kurumsalMi('gov.tr'), isFalse);
    });
  });
}
