import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/profil/presentation/karsilama_sayfasi.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  Future<void Function()> ac(WidgetTester tester, {Size boyut = const Size(390, 844)}) async {
    tester.view.physicalSize = boyut;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var bitti = 0;
    await tester.pumpWidget(MaterialApp(theme: pusulaTema(), home: KarsilamaSayfasi(onBasla: () => bitti++)));
    await tester.pumpAndSettle();
    return () => expect(bitti, 1);
  }

  testWidgets('tanıtım 5 sayfadır; Devam ile ilerler, son sayfada Başlayalım tanıtımı bitirir', (tester) async {
    final bittiMi = await ac(tester);
    expect(find.text('Kamu Pusulası'), findsOneWidget);
    expect(find.text('Atla'), findsOneWidget);
    expect(find.text('Bilgilerin yalnızca bu cihazda saklanır'), findsOneWidget);

    for (final baslik in ['Maaşın, net olarak', 'Hakkını kaynağıyla öğren', 'Becayişte eşleş']) {
      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      expect(find.text(baslik), findsOneWidget, reason: baslik);
      expect(find.text('Örnek görünüm'), findsOneWidget);
    }
    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();
    expect(find.text('İlanlar ve gündem tek yerde'), findsOneWidget);
    expect(find.text('Devam'), findsNothing);
    expect(find.byWidgetPredicate((w) => w is Visibility && !w.visible), findsOneWidget, reason: 'Atla son sayfada gizli');

    await tester.tap(find.text('Başlayalım'));
    await tester.pumpAndSettle();
    bittiMi();
  });

  testWidgets('kaydırma jesti sayfayı değiştirir; Atla tanıtımı bitirir', (tester) async {
    final bittiMi = await ac(tester);
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Maaşın, net olarak'), findsOneWidget);
    expect(find.bySemanticsLabel('Sayfa 2 / 5'), findsOneWidget);

    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();
    bittiMi();
  });

  testWidgets('küçük ekranda ve büyük yazı boyutunda tanıtım taşmaz, düğme erişilebilir kalır', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await ac(tester, boyut: const Size(320, 568));
    for (var i = 0; i < 4; i++) {
      expect(tester.takeException(), isNull, reason: 'sayfa $i');
      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    expect(find.text('Başlayalım'), findsOneWidget);
  });
}
