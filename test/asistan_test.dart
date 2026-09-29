import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/asistan/asistan_servisi.dart';
import 'package:pusula/features/asistan/asistan_sayfasi.dart';

import 'yardimci/yazilar.dart';

class _Hatali implements MevzuatAsistani {
  @override
  Future<AsistanCevabi> sor(String soru) async => throw Exception('ağ yok');
}

class _Sayac implements MevzuatAsistani {
  int cagri = 0;

  @override
  Future<AsistanCevabi> sor(String soru) async {
    cagri++;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const AsistanCevabi(metin: 'tamam', ornek: true);
  }
}

void main() {
  setUpAll(pusulaYazilariniYukle);

  Future<void> ac(WidgetTester tester, MevzuatAsistani asistan) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      home: Scaffold(body: AsistanSayfasi(asistan: asistan)),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('açılışta uyarı ve dürüst karşılama metni görünür', (tester) async {
    await ac(tester, const SahteAsistan(sure: Duration(milliseconds: 20)));
    expect(find.text('Hakkım ne?'), findsOneWidget);
    expect(find.textContaining('Hukuki tavsiye değildir'), findsOneWidget);
    expect(find.textContaining('örnek sürümdeyim'), findsOneWidget);
  });

  testWidgets('Becayiş sorusu gerçek kanun metniyle ve kaynak maddesiyle yanıtlanır', (tester) async {
    await ac(tester, const SahteAsistan(sure: Duration(milliseconds: 50)));
    await tester.tap(find.text('Becayiş'));
    await tester.pump();
    expect(find.text('Becayiş şartları nedir?'), findsOneWidget);
    expect(find.text('Mevzuat taranıyor…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Mevzuat taranıyor…'), findsNothing);
    expect(find.textContaining('657 sayılı Devlet Memurları Kanunu, md. 73'), findsOneWidget);
    expect(find.textContaining('atamaya yetkili amirlerince uygun bulunmasına bağlıdır'), findsOneWidget);
    expect(find.text('ÖRNEK CEVAP'), findsNothing);
  });

  testWidgets('doğrulanmamış konularda uydurma cevap yok, örnek cevap etiketi çıkar', (tester) async {
    await ac(tester, const SahteAsistan(sure: Duration(milliseconds: 20)));
    final kaydirici = find.descendant(of: find.byType(ListView).at(1), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(find.text('Mazeret izni'), 100, scrollable: kaydirici);
    await tester.drag(kaydirici, const Offset(-150, 0)); // düğme tam görünsün
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mazeret izni'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.text('ÖRNEK CEVAP'), findsOneWidget);
    expect(find.textContaining('mevzuattan cevap üretemiyorum'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Text && RegExp(r'\d+ gün').hasMatch(w.data ?? '')),
      findsNothing,
      reason: 'süre/gün sayısı uydurulmaz',
    );
  });

  testWidgets('yazılan soru gönderilir; boş soru gönderilmez', (tester) async {
    final a = _Sayac();
    await ac(tester, a);
    await tester.tap(find.bySemanticsLabel('Gönder'));
    await tester.pump();
    expect(a.cagri, 0);

    await tester.enterText(find.byType(TextField), 'Yıllık iznimi bölebilir miyim?');
    await tester.tap(find.bySemanticsLabel('Gönder'));
    await tester.pump();
    expect(find.text('Yıllık iznimi bölebilir miyim?'), findsOneWidget);
    expect(a.cagri, 1);
    expect(find.byType(TextField).evaluate().isNotEmpty, isTrue);
    final alan = tester.widget<TextField>(find.byType(TextField));
    expect(alan.controller!.text, isEmpty);

    // Cevap gelene kadar ikinci gönderim yok sayılır.
    await tester.enterText(find.byType(TextField), 'ikinci soru');
    await tester.tap(find.bySemanticsLabel('Gönder'));
    await tester.pump();
    expect(a.cagri, 1);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('tamam'), findsOneWidget);
  });

  testWidgets('servis hata verirse nazik bir mesaj gösterilir', (tester) async {
    await ac(tester, _Hatali());
    await tester.tap(find.text('Rapor'));
    await tester.pumpAndSettle();
    expect(find.textContaining('cevap üretemedim'), findsOneWidget);
  });
}
