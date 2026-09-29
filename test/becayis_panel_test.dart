import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/becayis/data/ornek_veri.dart';
import 'package:pusula/features/becayis/domain/eslesme.dart';
import 'package:pusula/features/becayis/presentation/becayis_panel_sayfasi.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  test('örnek veri: farklı kurumdaki ilan eşleşmez, 2 ikili + 1 zincir çıkar', () {
    final e = BecayisOrnekVeri.eslesmeler();
    expect(e.where((x) => x.tip == EslesmeTipi.ikili), hasLength(2));
    expect(e.where((x) => x.tip == EslesmeTipi.zincir), hasLength(1));
    expect(e.any((x) => x.icerir('yilmaz')), isFalse);
  });

  testWidgets('panel ilanı, sayıları ve en yeni eşleşmeyi gösterir', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Eslesme? acilan;
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      home: Scaffold(
        body: BecayisPanelSayfasi(
          benim: BecayisOrnekVeri.benimIlanim,
          eslesmeler: BecayisOrnekVeri.eslesmeler(),
          eslesmeAc: (e) => acilan = e,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Becayiş'), findsOneWidget);
    expect(find.text('Hemşire'), findsOneWidget);
    expect(find.text('Ankara'), findsWidgets);
    expect(find.text('Mavi tik · kurumsal e-posta doğrulandı'), findsOneWidget);
    expect(find.text('Hedef il'), findsOneWidget);
    expect(find.text('M. Demir · Hemşire'), findsOneWidget);

    await tester.tap(find.text('M. Demir · Hemşire'));
    expect(acilan, isNotNull);
    expect(acilan!.icerir('demir'), isTrue);
  });
}
