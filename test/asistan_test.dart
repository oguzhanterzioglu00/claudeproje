import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/asistan/asistan_servisi.dart';
import 'package:pusula/features/asistan/asistan_sayfasi.dart';
import 'package:pusula/features/asistan/bilgi_bankasi.dart';

import 'yardimci/yazilar.dart';

class _Hatali implements MevzuatAsistani {
  @override
  Future<AsistanCevabi> sor(String soru, {Kitle? kitle}) async => throw Exception('ağ yok');
}

class _Sayac implements MevzuatAsistani {
  int cagri = 0;

  @override
  Future<AsistanCevabi> sor(String soru, {Kitle? kitle}) async {
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
    await tester.pumpWidget(
      MaterialApp(
        theme: pusulaTema(),
        home: Scaffold(body: AsistanSayfasi(asistan: asistan)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('açılışta uyarı, kapsam ve dürüst karşılama metni görünür', (tester) async {
    await ac(tester, const YerelMevzuatAsistani(sure: Duration(milliseconds: 20)));
    expect(find.text('Hakkım ne?'), findsOneWidget);
    expect(find.textContaining('Hukuki tavsiye değildir'), findsOneWidget);
    expect(find.textContaining('tahmin yürütmem'), findsOneWidget);
    expect(find.textContaining('657 sayılı Devlet Memurları Kanunu'), findsOneWidget);
  });

  testWidgets('Becayiş sorusu gerçek kanun metniyle ve kaynak maddesiyle yanıtlanır', (tester) async {
    await ac(tester, const YerelMevzuatAsistani(sure: Duration(milliseconds: 50)));
    await tester.tap(find.text('Becayiş'));
    await tester.pump();
    expect(find.text('Becayiş şartları nedir?'), findsOneWidget);
    expect(find.text('Mevzuat taranıyor…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Mevzuat taranıyor…'), findsNothing);
    expect(find.textContaining('657 sayılı Devlet Memurları Kanunu, md. 73'), findsOneWidget);
    expect(find.textContaining('atamaya yetkili amirlerince uygun bulunmasına bağlıdır'), findsOneWidget);
    expect(find.textContaining('Kaynak: mevzuat.gov.tr birleştirilmiş metin'), findsOneWidget);
    expect(find.text('ÖRNEK CEVAP'), findsNothing);
  });

  testWidgets('hızlı soru düğmeleri her konuyu kaynak maddesiyle yanıtlar', (tester) async {
    await ac(tester, const YerelMevzuatAsistani(sure: Duration(milliseconds: 10)));
    final kaydirici = find.descendant(of: find.byType(ListView).at(1), matching: find.byType(Scrollable));
    for (final k in BilgiBankasi.konular.where((k) => !k.kapsamDisi)) {
      await tester.scrollUntilVisible(find.text(k.etiket), 120, scrollable: kaydirici);
      await tester.tap(find.text(k.etiket));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();
      expect(find.textContaining(k.kaynaklar.first.baslik), findsWidgets, reason: k.etiket);
    }
  });

  testWidgets('emeklilik: 5510 sayılı Kanun maddesiyle ve 2008 öncesi uyarısıyla yanıtlanır', (tester) async {
    await ac(tester, const YerelMevzuatAsistani(sure: Duration(milliseconds: 10)));
    await tester.enterText(find.byType(TextField), 'Emeklilik için ne kadar süre gerekir?');
    await tester.tap(find.bySemanticsLabel('Gönder'));
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pumpAndSettle();
    expect(find.textContaining('5510 sayılı Kanun, md. 28'), findsWidgets);
    expect(find.textContaining('2008 öncesinde'), findsOneWidget);
    expect(find.textContaining('5510 sayılı Kanun birleştirilmiş metni'), findsOneWidget);
  });

  testWidgets('bilinmeyen soruda tahmin yok; önerilen sorulara dokunarak devam edilir', (tester) async {
    await ac(tester, const YerelMevzuatAsistani(sure: Duration(milliseconds: 10)));
    await tester.enterText(find.byType(TextField), 'Bugün hava nasıl olacak?');
    await tester.tap(find.bySemanticsLabel('Gönder'));
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pumpAndSettle();
    expect(find.textContaining('dayanaklı bir cevap bulamadım'), findsOneWidget);
    expect(find.text('Yıllık izin kaç gün?'), findsOneWidget);

    await tester.ensureVisible(find.text('Yıllık izin kaç gün?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yıllık izin kaç gün?'));
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pumpAndSettle();
    expect(find.textContaining('657 sayılı Devlet Memurları Kanunu, md. 102'), findsOneWidget);
    expect(find.textContaining('yirmi gün'), findsOneWidget, reason: 'kanun alıntısı');
  });

  testWidgets('belirsiz "izin" sorusu netleştirme önerir', (tester) async {
    await ac(tester, const YerelMevzuatAsistani(sure: Duration(milliseconds: 10)));
    await tester.enterText(find.byType(TextField), 'izin');
    await tester.tap(find.bySemanticsLabel('Gönder'));
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pumpAndSettle();
    expect(find.textContaining('birkaç konuya girebilir'), findsOneWidget);
    expect(find.text('Mazeret izni kaç gün?'), findsOneWidget);
    expect(find.text('Yıllık izin kaç gün?'), findsOneWidget);
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
    await tester.tap(find.text('Becayiş'));
    await tester.pumpAndSettle();
    expect(find.textContaining('cevap üretemedim'), findsOneWidget);
  });

  group('çalışan grubuna göre asistan', () {
    Future<void> acK(WidgetTester tester, Kitle? kitle) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: pusulaTema(),
          home: Scaffold(
            body: AsistanSayfasi(
              asistan: const YerelMevzuatAsistani(sure: Duration(milliseconds: 10)),
              kitle: kitle,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder hizliSorular() => find.descendant(of: find.byType(ListView).at(1), matching: find.byType(Scrollable));

    Future<void> sonaKaydir(WidgetTester tester) async {
      await tester.drag(hizliSorular(), const Offset(-5000, 0));
      await tester.pumpAndSettle();
    }

    Future<void> basaKaydir(WidgetTester tester) async {
      await tester.drag(hizliSorular(), const Offset(5000, 0));
      await tester.pumpAndSettle();
    }

    Future<void> sor(WidgetTester tester, String metin) async {
      await tester.enterText(find.byType(TextField), metin);
      await tester.tap(find.bySemanticsLabel('Gönder'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'işçi: karşılama İş Kanunu\'nu anar, hızlı sorular işçi konuları; yıllık izin 4857 maddesiyle yanıtlanır',
      (tester) async {
        await acK(tester, Kitle.isci);
        expect(find.textContaining('4857 sayılı İş Kanunu'), findsOneWidget);
        expect(find.textContaining('tahmin yürütmem'), findsOneWidget);
        expect(find.text('İşçi yıllık izin'), findsOneWidget);
        await sonaKaydir(tester);
        expect(find.text('Kıdem tazminatı'), findsOneWidget);
        await basaKaydir(tester);
        expect(find.text('Becayiş'), findsNothing);

        await sor(tester, 'Yıllık izin kaç gün?');
        expect(find.textContaining('4857 sayılı İş Kanunu, md. 53'), findsWidgets);
        expect(find.textContaining('26 gün'), findsWidgets);
        expect(find.textContaining('Kaynak: mevzuat.gov.tr 4857 sayılı İş Kanunu'), findsOneWidget);
      },
    );

    testWidgets('memur: memur konuları; işçi konuları hızlı sorularda görünmez', (tester) async {
      await acK(tester, Kitle.memur);
      expect(find.text('Becayiş'), findsOneWidget);
      await sonaKaydir(tester);
      expect(find.text('Emeklilik'), findsOneWidget);
      expect(find.text('Kıdem tazminatı'), findsNothing);
      expect(find.textContaining('657 sayılı Devlet Memurları Kanunu'), findsOneWidget);
    });

    testWidgets('grup bilinmiyorsa (ör. sözleşmeli) her iki grubun konuları ve "işçi" ipucu görünür', (tester) async {
      await acK(tester, null);
      expect(find.textContaining('sorunda "işçi" yaz'), findsOneWidget);
      expect(find.text('Becayiş'), findsOneWidget);
      await sonaKaydir(tester);
      expect(find.text('Kıdem tazminatı'), findsOneWidget);
    });
  });
}
