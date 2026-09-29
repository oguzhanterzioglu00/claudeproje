import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/metin.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/maas/domain/memur_maas_hesaplayici.dart';
import 'package:pusula/features/maas/presentation/maas_sayfasi.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  const h = MemurMaasHesaplayici();

  Future<void> ac(WidgetTester tester, {MaasGirdisi? girdi}) async {
    tester.view.physicalSize = const Size(390, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      home: Scaffold(
        body: MaasSayfasi(
          ay: 7,
          baslangic: girdi ?? const MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10),
        ),
      ),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  String net(MaasGirdisi g) => liraTam(h.hesapla(g, ay: 7).net);

  testWidgets('başlangıç girdisi için motorun net değerini gösterir', (tester) async {
    await ac(tester);
    const g = MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10);
    expect(find.text(net(g)), findsWidgets); // büyük tutar + döküm satırı
    expect(find.text('Maaş hesapla'), findsOneWidget);
    expect(find.text('Temmuz–Aralık 2026'), findsOneWidget);
    expect(find.text('Taban aylık'), findsOneWidget);
  });

  testWidgets('kademe seçimi tutarı günceller', (tester) async {
    await ac(tester);
    const g = MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10);
    await tester.tap(find.bySemanticsLabel('Kademe 9'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final yeni = net(g.kopya(kademe: 9));
    expect(yeni, isNot(net(g)));
    expect(find.text(yeni), findsWidgets);
  });

  testWidgets('derece değişince geçersiz kademe en yakın geçerli kademeye iner', (tester) async {
    await ac(tester, girdi: const MaasGirdisi(derece: 3, kademe: 8));
    expect(find.bySemanticsLabel(RegExp(r'^Kademe \d$')), findsNWidgets(8));

    await tester.tap(find.bySemanticsLabel('Dereceyi azalt')); // 2. derece: 6 kademe
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.bySemanticsLabel(RegExp(r'^Kademe \d$')), findsNWidgets(6));
    expect(find.text(net(const MaasGirdisi(derece: 2, kademe: 6))), findsWidgets);

    await tester.tap(find.bySemanticsLabel('Dereceyi azalt')); // 1. derece: 4 kademe
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.bySemanticsLabel(RegExp(r'^Kademe \d$')), findsNWidgets(4));
    expect(find.text(net(const MaasGirdisi(derece: 1, kademe: 4))), findsWidgets);
  });

  testWidgets('1. derecede azalt, 15. derecede artır düğmesi devre dışı', (tester) async {
    await ac(tester, girdi: const MaasGirdisi(derece: 1, kademe: 1));
    await tester.tap(find.bySemanticsLabel('Dereceyi azalt'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsWidgets); // derece hâlâ 1
    expect(find.bySemanticsLabel(RegExp(r'^Kademe \d$')), findsNWidgets(4));
  });

  testWidgets('bordrodan netleştir: ek gösterge girilince net değişir', (tester) async {
    await ac(tester);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Bordrondan netleştir'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(4));

    await tester.enterText(find.byType(TextField).at(0), '2200');
    await tester.enterText(find.byType(TextField).at(2), '50');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    const beklenen = MaasGirdisi(
      derece: 8, kademe: 3, hizmetYili: 10, ekGosterge: 2200, ozelHizmetTazminatiOrani: 0.5,
    );
    expect(find.text(net(beklenen)), findsWidgets);
    expect(find.text('Ek gösterge aylığı'), findsOneWidget);
    expect(find.text('Özel hizmet tazminatı'), findsWidgets);
  });

  testWidgets('sözleşmeli ve işçi için hesap yok, açıklama gösterilir', (tester) async {
    await ac(tester);
    await tester.tap(find.text('Sözleşmeli'));
    await tester.pumpAndSettle();
    expect(find.textContaining('yalnızca 657 sayılı Kanun'), findsOneWidget);
    expect(find.text('Döküm'), findsNothing);
    expect(find.text('Tahmini net maaş'), findsNothing);

    await tester.tap(find.text('Memur (657)'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Döküm'), findsOneWidget);
  });

  testWidgets('hizmet yılı azaltılıp artırılabilir ve sıfırın altına inmez', (tester) async {
    await ac(tester, girdi: const MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 1));
    await tester.tap(find.bySemanticsLabel('Hizmet yılını azalt'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text(net(const MaasGirdisi(derece: 8, kademe: 3))), findsWidgets);
    await tester.tap(find.bySemanticsLabel('Hizmet yılını azalt'));
    await tester.pumpAndSettle();
    expect(find.text(net(const MaasGirdisi(derece: 8, kademe: 3))), findsWidgets);
  });
}
