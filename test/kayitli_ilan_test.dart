import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/depolama.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/ilanlar/ilan_kaynagi.dart';
import 'package:pusula/features/ilanlar/ilan_modeli.dart';
import 'package:pusula/features/ilanlar/ilanlar_bolumu.dart';
import 'package:pusula/features/ilanlar/ilanlar_sayfasi.dart';
import 'package:pusula/features/ilanlar/kayitli_ilanlar.dart';

import 'yardimci/yazilar.dart';

final _bugun = DateTime(2026, 9, 29);

class _Kaynak implements IlanKaynagi {
  List<KamuIlani> liste = [];
  bool hata = false;

  @override
  Future<List<KamuIlani>> getir() async {
    if (hata) throw Exception('ağ yok');
    return liste;
  }
}

KamuIlani _ilan(
  String id, {
  IlanTuru tur = IlanTuru.memur,
  String kurum = 'X KURUMU',
  DateTime? son,
  DateTime? yayin,
  Uri? baglanti,
}) => KamuIlani(
  id: id,
  baslik: 'Alım ilanı $id',
  kurum: kurum,
  konum: '',
  tur: tur,
  yayinTarihi: yayin ?? DateTime(2026, 9, 20),
  sonBasvuru: son,
  kaynakAdi: 'Kariyer Kapısı (kariyerkapisi.gov.tr) — Kamu İşe Alım İlanları',
  kaynakGuncelleme: DateTime(2026, 9, 29),
  baglanti: baglanti,
  kategori: 'B Grubu Memur',
);

void main() {
  setUpAll(pusulaYazilariniYukle);

  group('KamuIlani JSON', () {
    test('gidiş-dönüş aynı ilanı verir; uyum saklanmaz', () {
      final i = _ilan(
        'a',
        son: DateTime(2026, 10, 5),
        baglanti: Uri.parse('https://kariyerkapisi.gov.tr/IlanDetay?i=a'),
      );
      final geri = KamuIlani.fromJson(i.toJson())!;
      expect(geri.id, 'a');
      expect(geri.baslik, i.baslik);
      expect(geri.tur, IlanTuru.memur);
      expect(geri.sonBasvuru, DateTime(2026, 10, 5));
      expect(geri.baglanti.toString(), 'https://kariyerkapisi.gov.tr/IlanDetay?i=a');
      expect(geri.kategori, 'B Grubu Memur');
    });

    test('bozuk kayıt null döner; güvensiz bağlantı ve bilinmeyen tür güvenli varsayılana düşer', () {
      expect(KamuIlani.fromJson('x'), isNull);
      expect(KamuIlani.fromJson({'id': 'a'}), isNull);
      final g = KamuIlani.fromJson({
        'id': 'a',
        'baslik': 'b',
        'yayin': '2026-09-20T00:00:00',
        'tur': 'yok',
        'baglanti': 'javascript:1',
      })!;
      expect(g.tur, IlanTuru.diger);
      expect(g.baglanti, isNull);
      expect(g.sonBasvuru, isNull);
    });
  });

  group('KayitliIlanlar', () {
    test('ekler, kaldırır, en yenisi başta; yeniden yüklenince korunur; hesaplar ayrıdır', () async {
      final depo = BellekDepolama();
      final k = KayitliIlanlar(depo, hesapId: 'h1');
      await k.yukle();
      await k.degistir(_ilan('a'));
      await k.degistir(_ilan('b'));
      expect(k.liste.map((i) => i.id), ['b', 'a']);
      expect(k.icerir('a'), isTrue);

      final k2 = KayitliIlanlar(depo, hesapId: 'h1');
      await k2.yukle();
      expect(k2.liste.map((i) => i.id), ['b', 'a']);
      final baska = KayitliIlanlar(depo, hesapId: 'h2');
      await baska.yukle();
      expect(baska.liste, isEmpty);

      await k2.degistir(_ilan('a'));
      expect(k2.liste.map((i) => i.id), ['b']);
      await k2.temizle();
      expect(await depo.oku('kayitli_ilanlar_v1_h1'), isNull);
    });

    test('bozuk kayıt boş listeye döner; en fazla 100 ilan saklanır', () async {
      final bozuk = KayitliIlanlar(BellekDepolama({'kayitli_ilanlar_v1_h1': '[{"id":1},"x"'}), hesapId: 'h1');
      await bozuk.yukle();
      expect(bozuk.liste, isEmpty);
      final k = KayitliIlanlar(BellekDepolama(), hesapId: 'h1');
      await k.yukle();
      for (var i = 0; i < 105; i++) {
        await k.degistir(_ilan('i$i'));
      }
      expect(k.liste, hasLength(KayitliIlanlar.enFazla));
      expect(k.liste.first.id, 'i104');
    });
  });

  group('İlanlar ekranı: Kaydedilenler', () {
    Future<void> ac(WidgetTester tester, _Kaynak kaynak, KayitliIlanlar kayitlar) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: pusulaTema(),
          home: Scaffold(
            body: IlanlarSayfasi(kaynak: kaynak, bugun: _bugun, kayitlar: kayitlar),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    testWidgets('kaydet işareti ilanı kalıcı kaydeder; Kaydedilenler süzgeci onları gösterir', (tester) async {
      final kaynak = _Kaynak()..liste = [_ilan('a'), _ilan('b', kurum: 'Y KURUMU')];
      final depo = BellekDepolama();
      final kayitlar = KayitliIlanlar(depo, hesapId: 'h1');
      await kayitlar.yukle();
      await ac(tester, kaynak, kayitlar);

      await tester.tap(find.bySemanticsLabel('Kaydet').first);
      await tester.pumpAndSettle();
      expect(kayitlar.liste.map((i) => i.id), ['a']);
      expect(await depo.oku('kayitli_ilanlar_v1_h1'), isNotNull);
      expect(find.bySemanticsLabel('Kaydı kaldır'), findsOneWidget);

      await tester.tap(find.text('Kaydedilenler'));
      await tester.pumpAndSettle();
      expect(find.text('1 kayıtlı ilan'), findsOneWidget);
      expect(find.text('Alım ilanı a'), findsOneWidget);
      expect(find.text('Alım ilanı b'), findsNothing);
    });

    testWidgets('kayıtlı ilan akıştan kalksa, akış hata verse ve süresi dolsa da Kaydedilenler\'de görünür', (
      tester,
    ) async {
      final kayitlar = KayitliIlanlar(BellekDepolama(), hesapId: 'h1');
      await kayitlar.yukle();
      await kayitlar.degistir(_ilan('eski', son: DateTime(2026, 9, 1)));
      final kaynak = _Kaynak()..hata = true;
      await ac(tester, kaynak, kayitlar);
      expect(find.text('İlanlar yüklenemedi'), findsOneWidget);
      await tester.tap(find.text('Kaydedilenler'));
      await tester.pumpAndSettle();
      expect(find.text('İlanlar yüklenemedi'), findsNothing);
      expect(find.text('Alım ilanı eski'), findsOneWidget);
    });

    testWidgets('kayıtlı ilan yokken açıklayıcı boş durum; kaydı kaldırınca listeden çıkar', (tester) async {
      final kayitlar = KayitliIlanlar(BellekDepolama(), hesapId: 'h1');
      await kayitlar.yukle();
      await ac(tester, _Kaynak()..liste = [_ilan('a')], kayitlar);
      await tester.tap(find.text('Kaydedilenler'));
      await tester.pumpAndSettle();
      expect(find.text('Kayıtlı ilanın yok'), findsOneWidget);

      await kayitlar.degistir(_ilan('a'));
      await tester.pumpAndSettle();
      expect(find.text('Alım ilanı a'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Kaydı kaldır'));
      await tester.pumpAndSettle();
      expect(find.text('Kayıtlı ilanın yok'), findsOneWidget);
    });
  });

  group('Ana sayfa: Yeni ilanlar bölümü', () {
    Future<int> ac(WidgetTester tester, _Kaynak kaynak, Set<IlanTuru> turler) async {
      var acildi = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: pusulaTema(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: IlanlarBolumu(kaynak: kaynak, turler: turler, bugun: _bugun, tumunuAc: () => acildi++),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
      return acildi;
    }

    testWidgets('kullanıcının türlerindeki açık ilanlardan en fazla 3 tanesini gösterir; dokununca İlanlar açılır', (
      tester,
    ) async {
      var acildi = 0;
      final kaynak = _Kaynak()
        ..liste = [
          _ilan('m1'),
          _ilan('i1', tur: IlanTuru.isci),
          _ilan('eski', son: DateTime(2026, 9, 1)),
          _ilan('m2'),
          _ilan('s1', tur: IlanTuru.sozlesmeli, kurum: 'S KURUMU'),
          _ilan('m3'),
          _ilan('m4'),
        ];
      await tester.pumpWidget(
        MaterialApp(
          theme: pusulaTema(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: IlanlarBolumu(
                kaynak: kaynak,
                turler: const {IlanTuru.memur, IlanTuru.sozlesmeli},
                bugun: _bugun,
                tumunuAc: () => acildi++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Yeni ilanlar'), findsOneWidget);
      expect(find.text('Alım ilanı m1'), findsOneWidget);
      expect(find.text('Alım ilanı m2'), findsOneWidget);
      expect(find.text('Alım ilanı s1'), findsOneWidget);
      expect(find.text('Alım ilanı m3'), findsNothing, reason: 'en fazla 3');
      expect(find.text('Alım ilanı i1'), findsNothing, reason: 'işçi türü seçili değil');
      expect(find.text('Alım ilanı eski'), findsNothing, reason: 'süresi dolmuş');
      expect(find.textContaining('Kaynak: Kariyer Kapısı'), findsOneWidget);

      await tester.tap(find.text('Alım ilanı m1'));
      expect(acildi, 1);
      await tester.tap(find.text('Tümü'));
      expect(acildi, 2);
    });

    testWidgets('akış hata verirse ya da uygun ilan yoksa bölüm gizlenir', (tester) async {
      await ac(tester, _Kaynak()..hata = true, {IlanTuru.memur});
      expect(find.text('Yeni ilanlar'), findsNothing);
      await ac(tester, _Kaynak()..liste = [_ilan('i', tur: IlanTuru.isci)], {IlanTuru.memur});
      expect(find.text('Yeni ilanlar'), findsNothing);
    });

    testWidgets('başlamamış ilanda "Başvurular ... tarihinde başlar" yazar', (tester) async {
      await ac(tester, _Kaynak()..liste = [_ilan('g', yayin: DateTime(2026, 10, 19))], {IlanTuru.memur});
      expect(find.text('Başvurular 19.10.2026 tarihinde başlar'), findsOneWidget);
    });
  });
}
