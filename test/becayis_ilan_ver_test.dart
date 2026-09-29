import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/becayis/data/becayis_deposu.dart';
import 'package:pusula/features/becayis/data/ornek_veri.dart';
import 'package:pusula/features/becayis/presentation/becayis_ilan_ver_sayfasi.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  Future<BecayisDeposu> ac(WidgetTester tester, {bool maviTik = true}) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = BecayisDeposu(
      benim: BecayisOrnekVeri.benimIlanim.copyWith(maviTik: maviTik),
      digerleri: BecayisOrnekVeri.digerIlanlar,
      kisiler: BecayisOrnekVeri.kisiler,
      epostam: 'ayse.yilmaz@ornek.gov.tr',
    );
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      home: BecayisIlanVerSayfasi(depo: depo),
    ));
    await tester.pumpAndSettle();
    return depo;
  }

  testWidgets('profilden gelen bilgiler kilitli alanlarda gösterilir', (tester) async {
    await ac(tester);
    expect(find.text('Hemşire'), findsOneWidget);
    expect(find.text('Sağlık Bakanlığı'), findsOneWidget);
    expect(find.text('Sağlık Hizmetleri'), findsOneWidget);
    expect(find.text('İzmir'), findsOneWidget);
    expect(find.text('3 seçili'), findsOneWidget);
  });

  testWidgets('il seçimi sayacı günceller; hiç il yoksa yayınlanamaz', (tester) async {
    await ac(tester);
    await tester.tap(find.text('İstanbul'));
    await tester.pump();
    expect(find.text('4 seçili'), findsOneWidget);

    for (final il in ['Ankara', 'Eskişehir', 'Bursa', 'İstanbul']) {
      await tester.tap(find.text(il));
      await tester.pump();
    }
    expect(find.text('0 seçili'), findsOneWidget);
    await tester.tap(find.text('İlanı yayınla · Ücretsiz'));
    await tester.pumpAndSettle();
    expect(find.text('İlanın yayında'), findsNothing);
  });

  testWidgets('yayınlayınca seçim sırası tercih sırası olarak kaydedilir', (tester) async {
    final depo = await ac(tester);
    await tester.tap(find.text('Ankara')); // kaldır
    await tester.pump();
    await tester.tap(find.text('Ankara')); // sona ekle
    await tester.pump();
    await tester.tap(find.text('Konya'));
    await tester.pump();
    await tester.tap(find.text('İlanı yayınla · Ücretsiz'));
    await tester.pumpAndSettle();

    expect(find.text('İlanın yayında'), findsOneWidget);
    expect(depo.benim.hedefIller, ['Eskişehir', 'Bursa', 'Ankara', 'Konya']);
    expect(find.textContaining('4 ilde'), findsOneWidget);
  });

  testWidgets('mavi tik doğrulama: yanlış uzunlukta kod kabul edilmez, 6 hane doğrular', (tester) async {
    final depo = await ac(tester, maviTik: false);
    expect(find.text('Doğrula'), findsOneWidget);
    expect(find.text('Doğrulandı'), findsNothing);

    await tester.tap(find.text('Doğrula'));
    await tester.pumpAndSettle();
    expect(find.text('E-postanı doğrula'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();
    await tester.tap(find.text('Onayla'));
    await tester.pumpAndSettle();
    expect(depo.benim.maviTik, isFalse);
    expect(find.text('E-postanı doğrula'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Onayla'));
    await tester.pumpAndSettle();
    expect(depo.benim.maviTik, isTrue);
    expect(find.text('Doğrulandı'), findsOneWidget);
    expect(find.text('E-postanı doğrula'), findsNothing);
  });
}
