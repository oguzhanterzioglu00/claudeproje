import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/ilanlar/ilan_kaynagi.dart';
import 'package:pusula/features/ilanlar/ilan_modeli.dart';
import 'package:pusula/features/ilanlar/ilanlar_sayfasi.dart';

import 'yardimci/yazilar.dart';

final _bugun = DateTime(2026, 9, 29);

class _Hatali implements IlanKaynagi {
  int cagri = 0;

  @override
  Future<List<KamuIlani>> getir() async {
    cagri++;
    if (cagri == 1) throw Exception('ağ yok');
    return const OrnekIlanKaynagi(sure: Duration.zero).getir();
  }
}

void main() {
  setUpAll(pusulaYazilariniYukle);

  Future<void> ac(WidgetTester tester, {IlanKaynagi? kaynak, ValueChanged<KamuIlani>? kaynagiAc}) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      home: Scaffold(
        body: IlanlarSayfasi(
          kaynak: kaynak ?? OrnekIlanKaynagi(sure: const Duration(milliseconds: 10), bugun: _bugun),
          bugun: _bugun,
          kaynagiAc: kaynagiAc,
        ),
      ),
    ));
    await tester.pump(); // yükleniyor
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  group('model', () {
    final ilan = KamuIlani(
      id: 'x', baslik: 'b', kurum: 'k', konum: 'l', tur: IlanTuru.memur,
      yayinTarihi: DateTime(2026, 9, 19), sonBasvuru: DateTime(2026, 10, 9),
      kaynakAdi: 'k', kaynakGuncelleme: DateTime(2026, 9, 28),
    );

    test('kalan gün ve açıklık', () {
      expect(ilan.kalanGun(DateTime(2026, 9, 29)), 10);
      expect(ilan.kalanGun(DateTime(2026, 10, 9, 15)), 0);
      expect(ilan.acikMi(DateTime(2026, 10, 9, 15)), isTrue);
      expect(ilan.acikMi(DateTime(2026, 10, 10)), isFalse);
    });

    test('geçen oran 0-1 arasında kalır', () {
      expect(ilan.gecenOran(DateTime(2026, 9, 19)), 0);
      expect(ilan.gecenOran(DateTime(2026, 9, 29)), closeTo(0.5, 0.001));
      expect(ilan.gecenOran(DateTime(2027, 1, 1)), 1);
      expect(ilan.gecenOran(DateTime(2020, 1, 1)), 0);
    });
  });

  group('ekran', () {
    testWidgets('yüklenirken bekleme, sonra süresi dolmayan ilanlar listelenir', (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: pusulaTema(),
        home: Scaffold(
          body: IlanlarSayfasi(
            kaynak: OrnekIlanKaynagi(sure: const Duration(milliseconds: 100), bugun: _bugun),
            bugun: _bugun,
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('İlanlar yükleniyor'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.text('5 açık ilan'), findsOneWidget);
      expect(find.text('Hemşire alımı'), findsOneWidget);
      expect(find.text('Geçmiş dönem ilanı'), findsNothing, reason: 'süresi dolan ilan gösterilmez');
    });

    testWidgets('aramada Türkçe büyük/küçük harf farkı önemsenmez', (tester) async {
      await ac(tester);
      await tester.enterText(find.byType(TextField), 'ÖĞRETMEN');
      await tester.pumpAndSettle();
      expect(find.text('Öğretmen ataması duyurusu'), findsOneWidget);
      expect(find.text('Hemşire alımı'), findsNothing);

      await tester.enterText(find.byType(TextField), 'ıııyyy');
      await tester.pumpAndSettle();
      expect(find.text('Uygun ilan bulunamadı'), findsOneWidget);
    });

    testWidgets('süzgeçler: Sana uygun uyum ≥ 70; İşçi alımı yalnızca işçi', (tester) async {
      await ac(tester);
      await tester.tap(find.text('Sana uygun'));
      await tester.pumpAndSettle();
      expect(find.text('Hemşire alımı'), findsOneWidget);
      expect(find.text('Zabıta memuru alımı'), findsOneWidget);
      expect(find.text('Sürekli işçi alımı'), findsNothing); // uyum 64
      expect(find.text('Öğretmen ataması duyurusu'), findsNothing); // uyum 55

            await tester.drag(find.text('Tümü'), const Offset(-400, 0)); // süzgeç şeridini kaydır
      await tester.pumpAndSettle();
      await tester.tap(find.text('İşçi alımı'));
      await tester.pumpAndSettle();
      expect(find.text('Sürekli işçi alımı'), findsOneWidget);
      expect(find.text('Hemşire alımı'), findsNothing);
    });

    testWidgets('kaydet düğmesi durumu değiştirir', (tester) async {
      await ac(tester);
      expect(find.bySemanticsLabel('Kaydet'), findsWidgets);
      await tester.tap(find.bySemanticsLabel('Kaydet').first);
      await tester.pump();
      expect(find.bySemanticsLabel('Kaydı kaldır'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Kaydı kaldır'));
      await tester.pump();
      expect(find.bySemanticsLabel('Kaydı kaldır'), findsNothing);
    });

    testWidgets('kalan gün, acil ilan ve uyum etiketi gösterilir', (tester) async {
      await ac(tester);
      expect(find.text('12 gün'), findsOneWidget); // hemşire
      expect(find.text('2 gün'), findsOneWidget); // öğretmen
      expect(find.text('%92 uyum'), findsOneWidget);
    });

    testWidgets('kart ayrıntı açar; kaynak ve son güncelleme gösterilir, kaynağı aç çağrılır', (tester) async {
      KamuIlani? acilan;
      await ac(tester, kaynagiAc: (i) => acilan = i);
      await tester.tap(find.text('Hemşire alımı'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kaynak: Kurumun resmî duyurusu (örnek)'), findsOneWidget);
      expect(find.textContaining('Son güncelleme: 28.09.2026'), findsOneWidget);
      expect(find.textContaining('kaynaktan doğrula'), findsOneWidget);
      expect(find.textContaining('12 gün kaldı'), findsOneWidget);

      await tester.tap(find.text('Kaynağı aç'));
      expect(acilan?.id, 'o1');
    });

    testWidgets('yükleme hatasında tekrar dene çalışır', (tester) async {
      await ac(tester, kaynak: _Hatali());
      expect(find.text('İlanlar yüklenemedi'), findsOneWidget);
      await tester.tap(find.text('Tekrar dene'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('İlanlar yüklenemedi'), findsNothing);
      expect(find.text('Hemşire alımı'), findsOneWidget);
    });
  });
}
