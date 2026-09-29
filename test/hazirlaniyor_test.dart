import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/profil/presentation/hazirlaniyor_sayfasi.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  Future<int Function()> ac(WidgetTester tester, {String ad = 'Ayşe Yılmaz', bool memur = false}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var bitti = 0;
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      home: HazirlaniyorSayfasi(ad: ad, memur: memur, onBitti: () => bitti++),
    ));
    await tester.pump();
    return () => bitti;
  }

  testWidgets('memur için maaş ve becayiş adımları, sonunda onBitti çağrılır', (tester) async {
    final bitti = await ac(tester, memur: true);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Hazırlıyoruz, Ayşe'), findsOneWidget);
    expect(find.text('Maaş hesabın hazır'), findsOneWidget);
    expect(find.text('Becayiş ve ilanlar ayarlandı'), findsOneWidget);
    expect(bitti(), 0);
    await tester.pump(const Duration(seconds: 1));
    expect(bitti(), 1);
  });

  testWidgets('memur olmayana geçerli olmayan maaş/becayiş vaadi gösterilmez', (tester) async {
    await ac(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Maaş hesabın hazır'), findsNothing);
    expect(find.textContaining('Becayiş'), findsNothing);
    expect(find.text('Hakkım ne? asistanı hazır'), findsOneWidget);
    expect(find.text('İlanlar ayarlandı'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('ad boşsa yalnızca "Hazırlıyoruz"; ekran kapanırsa sayaç iptal edilir', (tester) async {
    final bitti = await ac(tester, ad: '   ');
    expect(find.text('Hazırlıyoruz'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(seconds: 5));
    expect(bitti(), 0, reason: 'dispose sonrası çağrılmaz');
  });

  testWidgets('hareketi azalt açıkken kısa sürede biter', (tester) async {
    var bitti = 0;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      builder: (c, w) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: true), child: w!),
      home: HazirlaniyorSayfasi(onBitti: () => bitti++),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(bitti, 1);
  });
}
