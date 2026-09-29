import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/becayis/data/ornek_veri.dart';
import 'package:pusula/features/becayis/domain/eslesme.dart';
import 'package:pusula/features/becayis/presentation/becayis_ilanlar_sayfasi.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  Future<void> ac(WidgetTester tester, {ValueChanged<Eslesme>? eslesmeAc}) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      home: BecayisIlanlarSayfasi(
        depo: BecayisOrnekVeri.depo(),
        eslesmeAc: eslesmeAc,
        ilanVer: () {},
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Yatay kaydırmalı il düğmelerinde [il] görünene dek kaydırıp dokunur.
  Future<void> ileDokun(WidgetTester tester, String il) async {
    final kaydirici = find.descendant(
      of: find.byType(ListView).at(1),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(find.text(il), 100, scrollable: kaydirici);
    await tester.tap(find.text(il));
    await tester.pumpAndSettle();
  }

  testWidgets('tüm ilanlar listelenir, kendi ilanın listede yok', (tester) async {
    await ac(tester);
    expect(find.text('6 açık ilan'), findsOneWidget);
    expect(find.text('Hemşire'), findsNWidgets(3));
    expect(find.text('Öğretmen'), findsOneWidget);
  });

  testWidgets('ile göre süzer: hem mevcut hem hedef il sayılır', (tester) async {
    await ac(tester);
    await ileDokun(tester, 'Antalya');
    expect(find.text('2 açık ilan'), findsOneWidget);
    expect(find.text('Memur'), findsOneWidget);
    expect(find.text('Uzman'), findsOneWidget);
    expect(find.text('Hemşire'), findsNothing);
  });

  testWidgets('ilan olmayan ilde boş durum gösterilir', (tester) async {
    await ac(tester);
    await ileDokun(tester, 'Eskişehir');
    expect(find.text('Bu ilde ilan yok'), findsOneWidget);
    expect(find.text('0 açık ilan'), findsOneWidget);
  });

  testWidgets('yalnızca eşleşen ilanlarda uyum bağlantısı çıkar ve eşleşmeyi açar', (tester) async {
    Eslesme? acilan;
    await ac(tester, eslesmeAc: (e) => acilan = e);
    // Farklı kurum/sınıftaki üç ilanda uyum yok; aynı gruptaki iki ikili eşleşmede var.
    expect(find.textContaining('uyum'), findsNWidgets(2));
    await tester.tap(find.textContaining('uyum').first);
    expect(acilan, isNotNull);
    expect(acilan!.tip, EslesmeTipi.ikili);
  });
}
