import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/metin.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/ana_sayfa/ana_sayfa.dart';
import 'package:pusula/features/ana_sayfa/ana_sayfa_verisi.dart';
import 'package:pusula/features/becayis/data/ornek_veri.dart';
import 'package:pusula/features/becayis/domain/statu.dart';
import 'package:pusula/features/kabuk/pusula_kabugu.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  Future<void> boyutla(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('ana sayfa', () {
    testWidgets('maaş, yol haritası ve kısayolları gösterir', (tester) async {
      await boyutla(tester);
      var asistan = 0, becayis = 0;
      await tester.pumpWidget(MaterialApp(
        theme: pusulaTema(),
        home: Scaffold(
          body: AnaSayfa(
            veri: AnaSayfaVerisi.ornekVeri,
            bugun: DateTime(2026, 9, 29),
            asistanaGit: () => asistan++,
            becayisiAc: () => becayis++,
          ),
        ),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Kamu Pusulası'), findsOneWidget);
      expect(find.text('Salı, 29 Eylül'), findsOneWidget);
      expect(find.text('₺41.250'), findsOneWidget);
      expect(find.text('+₺3.450 zam'), findsOneWidget);
      expect(find.text('ÖRNEK HESAP'), findsOneWidget);
      expect(find.text('Yol haritan'), findsOneWidget);
      expect(find.text('94 gün'), findsOneWidget);
      expect(find.text('9 ay'), findsOneWidget);
      expect(find.text('12 yıl'), findsOneWidget);
      expect(find.text('1 yeni eşleşme'), findsOneWidget);

      await tester.tap(find.text('Hakkım ne?'));
      await tester.tap(find.text('Becayiş'));
      expect((asistan, becayis), (1, 1));
    });

    testWidgets('örnek değilse rozet gösterilmez; eşleşme yoksa kısayol "Eşleşme bul" der', (tester) async {
      await boyutla(tester);
      await tester.pumpWidget(MaterialApp(
        theme: pusulaTema(),
        home: const Scaffold(
          body: AnaSayfa(
            veri: AnaSayfaVerisi(
              netMaas: 30000,
              zamFarki: 0,
              egri: [0.2, 0.9],
              yolHaritasi: [],
              yeniEslesme: 0,
              ornek: false,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('ÖRNEK HESAP'), findsNothing);
      expect(find.text('Eşleşme bul'), findsOneWidget);
      expect(find.text('₺30.000'), findsOneWidget);
    });
  });

  group('kabuk', () {
    Future<void> ac(WidgetTester tester, {int sekme = 0}) async {
      await boyutla(tester);
      await tester.pumpWidget(MaterialApp(
        theme: pusulaTema(),
        home: PusulaKabugu(
          profil: const Profil(ad: 'Ayşe', statu: Statu.memur657),
          becayisDeposu: BecayisOrnekVeri.depo(),
          bugun: DateTime(2026, 9, 29),
          baslangicSekmesi: sekme,
        ),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    testWidgets('ana sayfada açılır; yalnızca seçili sekmenin etiketi görünür', (tester) async {
      await ac(tester);
      expect(find.text('₺41.250'), findsOneWidget);
      expect(find.text('Ana sayfa'), findsOneWidget);
      expect(find.text('Maaş'), findsNothing);
    });

    testWidgets('alt çubuktan sekmeler arasında geçilir', (tester) async {
      await ac(tester);
      await tester.tap(find.byKey(const ValueKey('sekme-3')));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Hemşire'), findsOneWidget);
      expect(find.text('Becayiş'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('sekme-0')));
      await tester.pumpAndSettle();
      expect(find.text('₺41.250'), findsOneWidget);
      expect(find.text('Hemşire'), findsNothing);
    });

    testWidgets('ana sayfadaki Becayiş kısayolu Becayiş sekmesini açar', (tester) async {
      await ac(tester);
      await tester.tap(find.text('1 yeni eşleşme'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Hemşire'), findsOneWidget);
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
