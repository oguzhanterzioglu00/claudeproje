import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/haberler/gundem_bolumu.dart';
import 'package:pusula/features/haberler/haber_kaynagi.dart';
import 'package:pusula/features/haberler/haber_modeli.dart';
import 'package:pusula/features/haberler/haber_slaytlari.dart';
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

    testWidgets('otomatik olmayan haberde otomatik özet etiketi çıkmaz; bağlantısı olmayan haberde düğme pasif',
        (tester) async {
      await sayfaAc(tester, const OrnekHaberKaynagi(sure: Duration(milliseconds: 10)));
      await tester.tap(find.textContaining('Kurum içi yönetmelik')); // h4: bağlantı yok
      await tester.pumpAndSettle();
      expect(find.text('Otomatik özet'), findsNothing);
      final dugme = find.ancestor(of: find.text('Kaynağı aç'), matching: find.byType(InkWell)).first;
      expect(tester.widget<InkWell>(dugme).onTap, isNull);
    });

    testWidgets('bağlantısı olan haberde Kaynağı aç düğmesi etkindir', (tester) async {
      await sayfaAc(tester, const OrnekHaberKaynagi(sure: Duration(milliseconds: 10)));
      await tester.tap(find.textContaining('Memur maaş katsayıları')); // h1: bağlantı var
      await tester.pumpAndSettle();
      final dugme = find.ancestor(of: find.text('Kaynağı aç'), matching: find.byType(InkWell)).first;
      expect(tester.widget<InkWell>(dugme).onTap, isNotNull);
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

  group('Gündem bölümü (görselli slaytlar)', () {
    Future<void> bolumAc(
      WidgetTester tester,
      HaberKaynagi kaynak, {
      Set<HaberTuru>? turler,
      String baslik = 'Gündem',
    }) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: pusulaTema(),
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              GundemBolumu(
                key: UniqueKey(), // her açılışta yeni durum (kaynak Future'ı bir kez alınır)
                kaynak: kaynak,
                bugun: _bugun,
                turler: turler,
                baslik: baslik,
                otomatik: false,
              ),
            ],
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
    }

    testWidgets('ilk haber slayt olarak görünür; kaydırınca sonraki gelir; sayfa noktaları güncellenir',
        (tester) async {
      final tutamak = tester.ensureSemantics();
      await bolumAc(tester, const OrnekHaberKaynagi(sure: Duration(milliseconds: 10)));
      expect(find.text('Gündem'), findsOneWidget);
      expect(find.textContaining('Memur maaş katsayıları'), findsOneWidget);
      expect(find.text('Maaş ve özlük'), findsOneWidget, reason: 'tür etiketi slayt üzerinde');
      expect(find.bySemanticsLabel('Haber 1 / 5'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('Resmî Gazete\'de yeni kanun'), findsWidgets);
      expect(find.bySemanticsLabel('Haber 2 / 5'), findsOneWidget);
      tutamak.dispose();
    });

    testWidgets('slayta dokununca haber ayrıntısı açılır; Tümü tam listeyi açar', (tester) async {
      await bolumAc(tester, const OrnekHaberKaynagi(sure: Duration(milliseconds: 10)));
      await tester.tap(find.textContaining('Memur maaş katsayıları'));
      await tester.pumpAndSettle();
      expect(find.text('Kaynağı aç'), findsOneWidget);
      await tester.tapAt(const Offset(195, 60)); // alt sayfayı kapat
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tümü'));
      await tester.pumpAndSettle();
      expect(find.byType(HaberlerSayfasi), findsOneWidget);
      expect(find.textContaining('Kurum içi yönetmelik'), findsOneWidget);
    });

    testWidgets('tür süzgeci ve başlık: yalnızca maaş ve mevzuat haberleri', (tester) async {
      final tutamak = tester.ensureSemantics();
      await bolumAc(
        tester,
        const OrnekHaberKaynagi(sure: Duration(milliseconds: 10)),
        turler: const {HaberTuru.maas, HaberTuru.mevzuat},
        baslik: 'Maaş ve mevzuat haberleri',
      );
      expect(find.text('Maaş ve mevzuat haberleri'), findsOneWidget);
      expect(find.bySemanticsLabel('Haber 1 / 3'), findsOneWidget, reason: 'h1, h2 ve h5');
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kurumlar arası naklen'), findsNothing);
      expect(find.textContaining('Kamu personeli için yeni düzenleme'), findsWidgets);
      tutamak.dispose();
    });

    testWidgets('hiç uygun haber yoksa (ya da hata) bölüm gizlenir', (tester) async {
      await bolumAc(tester, const OrnekHaberKaynagi(sure: Duration(milliseconds: 10)), turler: const <HaberTuru>{});
      expect(find.text('Gündem'), findsNothing);
      await bolumAc(tester, _Hatali());
      expect(find.text('Gündem'), findsNothing);
      await bolumAc(tester, _Bos());
      expect(find.text('Gündem'), findsNothing);
    });

    testWidgets('görsel adresi yüklenemezse çizilmiş kapak ve yazılar kalır, hata çıkmaz', (tester) async {
      await bolumAc(tester, _GorselliKaynak());
      expect(find.textContaining('Görselli haber'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('HaberSlaytlari kendiliğinden ilerleme', () {
    final haberler = [
      for (var i = 0; i < 3; i++)
        Haber(id: 'x$i', baslik: 'Haber $i', tur: HaberTuru.duyuru, kaynakAdi: 'K', yayinTarihi: _bugun),
    ];

    Future<void> ac(
      WidgetTester tester, {
      bool otomatik = true,
      bool hareketsiz = false,
      Widget Function(Widget)? sar,
    }) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Widget slayt = Scaffold(
        body: HaberSlaytlari(
          haberler: haberler,
          bugun: _bugun,
          onAc: (_) {},
          otomatik: otomatik,
          aralik: const Duration(seconds: 1),
        ),
      );
      if (sar != null) slayt = sar(slayt);
      await tester.pumpWidget(MaterialApp(
        theme: pusulaTema(),
        builder: (c, w) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: hareketsiz), child: w!),
        home: slayt,
      ));
      await tester.pump();
    }

    Future<void> saniye(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 700));
    }

    double sayfa(WidgetTester tester) => tester.widget<PageView>(find.byType(PageView)).controller?.page ?? 0;

    testWidgets('aralık dolunca bir sonraki slayta geçer ve sondan başa döner', (tester) async {
      await ac(tester);
      expect(sayfa(tester), 0);
      await saniye(tester);
      expect(sayfa(tester).round(), 1);
      await saniye(tester);
      expect(sayfa(tester).round(), 2);
      await saniye(tester);
      expect(sayfa(tester).round(), 0, reason: 'döngü');
    });

    testWidgets('kapalıyken ilerlemez', (tester) async {
      await ac(tester, otomatik: false);
      await saniye(tester);
      await saniye(tester);
      expect(sayfa(tester), 0);
    });

    testWidgets('hareketi azalt açıkken ilerlemez', (tester) async {
      await ac(tester, hareketsiz: true);
      await saniye(tester);
      await saniye(tester);
      expect(sayfa(tester), 0);
    });

    testWidgets('kullanıcı sürüklerken durur, bırakınca yeniden başlar', (tester) async {
      await ac(tester);
      final hareket = await tester.startGesture(const Offset(200, 100));
      await hareket.moveBy(const Offset(-20, 0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(sayfa(tester), lessThan(0.5), reason: 'parmak üzerindeyken kendiliğinden ilerlemez');
      await hareket.up();
      await tester.pumpAndSettle();
      final onceki = sayfa(tester).round();
      await saniye(tester);
      expect(sayfa(tester).round(), (onceki + 1) % 3);
    });

    testWidgets('sekme görünmezken (TickerMode kapalı) ilerlemez', (tester) async {
      await ac(tester, sar: (w) => TickerMode(enabled: false, child: w));
      await saniye(tester);
      await saniye(tester);
      expect(sayfa(tester), 0);
    });
  });
}

class _GorselliKaynak implements HaberKaynagi {
  @override
  Future<List<Haber>> getir() async => [
    Haber(
      id: 'g1',
      baslik: 'Görselli haber',
      tur: HaberTuru.duyuru,
      kaynakAdi: 'K',
      yayinTarihi: DateTime(2026, 9, 29),
      gorsel: Uri.parse('https://gorsel.ornek.invalid/kapak.jpg'),
    ),
  ];
}
