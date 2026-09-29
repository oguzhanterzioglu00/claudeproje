import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/haberler/gundem_bolumu.dart';
import 'package:pusula/features/haberler/haber_kaynagi.dart';
import 'package:pusula/features/haberler/haber_modeli.dart';
import 'package:pusula/features/haberler/haberler_sayfasi.dart';

import 'yardimci/yazilar.dart';

final _bugun = DateTime(2026, 9, 29);

class _Hatali implements HaberKaynagi {
  int cagri = 0;

  @override
  Future<List<Haber>> getir() async {
    cagri++;
    if (cagri == 1) throw Exception('ağ yok');
    return const OrnekHaberKaynagi(sure: Duration.zero).getir();
  }
}

class _Bos implements HaberKaynagi {
  @override
  Future<List<Haber>> getir() async => const [];
}

void main() {
  setUpAll(pusulaYazilariniYukle);

  Haber haber(int gunOnce) => Haber(
        id: 'x',
        baslik: 'B',
        tur: HaberTuru.duyuru,
        kaynakAdi: 'K',
        yayinTarihi: DateTime(2026, 9, 29).subtract(Duration(days: gunOnce)),
      );

  test('zaman etiketi', () {
    expect(haber(0).zamanEtiketi(_bugun), 'Bugün');
    expect(haber(-2).zamanEtiketi(_bugun), 'Bugün', reason: 'ileri tarih');
    expect(haber(1).zamanEtiketi(_bugun), 'Dün');
    expect(haber(3).zamanEtiketi(_bugun), '3 gün önce');
    expect(haber(14).zamanEtiketi(_bugun), '2 hafta önce');
    expect(haber(65).zamanEtiketi(_bugun), '2 ay önce');
    expect(haber(400).zamanEtiketi(_bugun), '1 yıl önce');
  });

  Future<void> sayfaAc(WidgetTester tester, HaberKaynagi kaynak, {ValueChanged<Haber>? kaynagiAc}) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      home: HaberlerSayfasi(kaynak: kaynak, bugun: _bugun, kaynagiAc: kaynagiAc),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  group('Haberler sayfası', () {
    testWidgets('haberler kaynak ve zamanla listelenir; süzgeç türe göre daraltır', (tester) async {
      await sayfaAc(tester, const OrnekHaberKaynagi(sure: Duration(milliseconds: 10)));
      expect(find.text('Gündem'), findsOneWidget);
      expect(find.textContaining('Memur maaş katsayıları güncellendi'), findsOneWidget);
      expect(find.textContaining('Hazine ve Maliye Bakanlığı (örnek) · Bugün'), findsOneWidget);
      expect(find.text('Resmî kaynak'), findsWidgets);

      await tester.tap(find.text('Mevzuat'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Memur maaş katsayıları'), findsNothing);
      expect(find.textContaining('Resmî Gazete\'de yeni kanun'), findsOneWidget);

      await tester.tap(find.text('Tümü'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Memur maaş katsayıları'), findsOneWidget);
    });

    testWidgets('ayrıntıda otomatik özet etiketi ve uyarı görünür; Kaynağı aç çağrılır', (tester) async {
      Haber? acilan;
      await sayfaAc(
        tester,
        const OrnekHaberKaynagi(sure: Duration(milliseconds: 10)),
        kaynagiAc: (h) => acilan = h,
      );
      await tester.tap(find.textContaining('Resmî Gazete\'de yeni kanun'));
      await tester.pumpAndSettle();
      expect(find.text('Otomatik özet'), findsOneWidget);
      expect(find.textContaining('hata içerebilir'), findsOneWidget);
      await tester.tap(find.text('Kaynağı aç'));
      await tester.pumpAndSettle();
      expect(acilan?.id, 'h2');
    });

    testWidgets('otomatik olmayan haberde otomatik özet etiketi çıkmaz; kaynakAc yoksa düğme pasif', (tester) async {
      await sayfaAc(tester, const OrnekHaberKaynagi(sure: Duration(milliseconds: 10)));
      await tester.tap(find.textContaining('Memur maaş katsayıları'));
      await tester.pumpAndSettle();
      expect(find.text('Otomatik özet'), findsNothing);
      final dugme = find.ancestor(of: find.text('Kaynağı aç'), matching: find.byType(InkWell)).first;
      expect(tester.widget<InkWell>(dugme).onTap, isNull);
    });

    testWidgets('hata durumunda Tekrar dene çalışır', (tester) async {
      final kaynak = _Hatali();
      await sayfaAc(tester, kaynak);
      expect(find.text('Haberler yüklenemedi'), findsOneWidget);
      await tester.tap(find.text('Tekrar dene'));
      await tester.pumpAndSettle();
      expect(find.text('Haberler yüklenemedi'), findsNothing);
      expect(find.textContaining('Memur maaş katsayıları'), findsOneWidget);
      expect(kaynak.cagri, 2);
    });

    testWidgets('boş akışta "Haber bulunamadı" görünür', (tester) async {
      await sayfaAc(tester, _Bos());
      expect(find.text('Haber bulunamadı'), findsOneWidget);
    });
  });

  group('Gündem bölümü', () {
    Future<void> bolumAc(WidgetTester tester, HaberKaynagi kaynak, {int adet = 3}) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: pusulaTema(),
        home: Scaffold(
          body: ListView(children: [GundemBolumu(kaynak: kaynak, bugun: _bugun, adet: adet)]),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
    }

    testWidgets('en yeni üç haber görünür, Tümü tam listeyi açar', (tester) async {
      await bolumAc(tester, const OrnekHaberKaynagi(sure: Duration(milliseconds: 10)));
      expect(find.text('Gündem'), findsOneWidget);
      expect(find.textContaining('Memur maaş katsayıları'), findsOneWidget);
      expect(find.textContaining('Kurumlar arası naklen'), findsOneWidget);
      expect(find.textContaining('Kurum içi yönetmelik'), findsNothing, reason: 'yalnızca 3 haber');

      await tester.tap(find.text('Tümü'));
      await tester.pumpAndSettle();
      expect(find.byType(HaberlerSayfasi), findsOneWidget);
      expect(find.textContaining('Kurum içi yönetmelik'), findsOneWidget);
    });

    testWidgets('hata veya boş akışta bölüm sessizce gizlenir', (tester) async {
      await bolumAc(tester, _Hatali());
      expect(find.text('Gündem'), findsNothing);
      await bolumAc(tester, _Bos());
      expect(find.text('Gündem'), findsNothing);
    });
  });
}
