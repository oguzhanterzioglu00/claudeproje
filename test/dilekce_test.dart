import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/features/araclar/presentation/araclar_bolumu.dart';
import 'package:pusula/features/dilekce/dilekce_sablonlari.dart';
import 'package:pusula/features/dilekce/dilekce_sayfasi.dart';
import 'package:pusula/features/profil/domain/profil.dart';

import 'yardimci/yazilar.dart';

const _profil = Profil(
  ad: 'Ayşe Yılmaz',
  statu: Statu.memur657,
  kurumAdi: 'Milli Eğitim Müdürlüğü',
  unvan: 'Memur',
  sicilNo: '123456',
);

final _bugun = DateTime(2026, 9, 29);

DilekceGirdisi _girdi({
  Profil? profil = _profil,
  Map<String, String> metinler = const {},
  Map<String, DateTime> tarihler = const {},
  Map<String, int> sayilar = const {},
}) => DilekceGirdisi(profil: profil, tarih: _bugun, metinler: metinler, tarihler: tarihler, sayilar: sayilar);

void main() {
  setUpAll(pusulaYazilariniYukle);

  group('DilekceTuru.uret', () {
    test('yıllık izin: profil bilgileri, tarih ve gün yazıyla dolar', () {
      final s = DilekceTuru.yillikIzin.uret(
        _girdi(tarihler: {'baslangic': DateTime(2026, 10, 12)}, sayilar: {'gun': 7}, metinler: {'adres': 'Ankara'}),
      );
      expect(s.tamam, isTrue);
      expect(s.metin, contains('MİLLİ EĞİTİM MÜDÜRLÜĞÜ'), reason: 'Türkçe büyük harf');
      expect(s.metin, contains('Tarih: 29.09.2026'));
      expect(s.metin, contains('Konu: Yıllık izin talebi hakkında.'));
      expect(s.metin, contains('Milli Eğitim Müdürlüğü bünyesinde Memur olarak görev yapmaktayım.'));
      expect(s.metin, contains('102 ve 103. maddeleri'));
      expect(s.metin, contains('12.10.2026 tarihinden itibaren 7 (yedi) gün yıllık izin'));
      expect(s.metin, contains('ulaşılabileceğim adres: Ankara'));
      expect(s.metin, contains('Sicil No: 123456'));
      expect(s.metin, endsWith('İmza:'));
    });

    test('eksik alan ve profil bilgisi [..] ile işaretlenir ve listelenir', () {
      final s = DilekceTuru.mazeretIzni.uret(_girdi(profil: const Profil(ad: '', statu: Statu.memur657)));
      expect(s.tamam, isFalse);
      expect(s.metin, contains('[Kurum adı]'));
      expect(s.metin, contains('[Ad Soyad]'));
      expect(s.metin, contains('[gg.aa.yyyy]'));
      expect(s.eksikProfil, containsAll(['ad soyad', 'kurum adı', 'unvan']));
      expect(s.eksikAlanlar, containsAll(['İzne başlama tarihi', 'İzin süresi (gün)', 'Mazeretin']));
    });

    test('isteğe bağlı alanlar eksik sayılmaz', () {
      final s = DilekceTuru.yillikIzin.uret(_girdi(tarihler: {'baslangic': DateTime(2026, 10, 1)}, sayilar: {'gun': 5}));
      expect(s.eksikAlanlar, isEmpty);
      expect(s.metin, isNot(contains('adres')));
    });

    test('sayı sınırı dışındaki değer eksik sayılır', () {
      final s = DilekceTuru.yillikIzin.uret(_girdi(tarihler: {'baslangic': DateTime(2026, 10, 1)}, sayilar: {'gun': 400}));
      expect(s.eksikAlanlar, contains('İzin süresi (gün)'));
    });

    test('evlilik ve ölüm izni: seçime göre metin değişir, süre kanundaki 7 gündür', () {
      final evlilik = DilekceTuru.evlilikOlum.uret(
        _girdi(metinler: {'olay': 'Kendi evlenmem'}, tarihler: {'baslangic': DateTime(2026, 11, 2)}),
      );
      expect(evlilik.tamam, isTrue);
      expect(evlilik.metin, contains('evlenmem nedeniyle'));
      expect(evlilik.metin, contains('104. maddesinin (B) bendi'));
      expect(evlilik.metin, contains('7 (yedi) gün'));

      final vefat = DilekceTuru.evlilikOlum.uret(
        _girdi(
          metinler: {'olay': 'Yakınımın vefatı', 'yakinlik': 'babam'},
          tarihler: {'baslangic': DateTime(2026, 11, 2)},
        ),
      );
      expect(vefat.tamam, isTrue);
      expect(vefat.metin, contains('babam vefatı nedeniyle'));

      final eksik = DilekceTuru.evlilikOlum.uret(
        _girdi(metinler: {'olay': 'Yakınımın vefatı'}, tarihler: {'baslangic': DateTime(2026, 11, 2)}),
      );
      expect(eksik.eksikAlanlar, contains('Vefat eden yakının'));
    });

    test('hastalık raporu, aylıksız izin, atama, nakil ve eş durumu doğru maddeye atıf yapar', () {
      String metin(DilekceTuru t, {Map<String, String> m = const {}, Map<String, DateTime> d = const {}, Map<String, int> s = const {}}) =>
          t.uret(_girdi(metinler: m, tarihler: d, sayilar: s)).metin;

      expect(
        metin(DilekceTuru.hastalik, m: {'saglikKurumu': 'Şehir Hastanesi'}, d: {'raporTarihi': DateTime(2026, 9, 1)}, s: {'gun': 3}),
        allOf(contains('105. maddesi'), contains('Şehir Hastanesi'), contains('3 (üç) gün istirahat')),
      );
      expect(
        metin(DilekceTuru.aylikSizIzin, d: {'baslangic': DateTime(2027, 1, 4)}, s: {'ay': 6}),
        allOf(contains('108. maddesinin (E) bendi'), contains('6 ay süreyle'), contains('5 hizmet yılımı')),
      );
      expect(metin(DilekceTuru.kurumIciAtama, m: {'hedefYer': 'İzmir'}), allOf(contains('76. maddesi'), contains('İzmir')));
      expect(
        metin(DilekceTuru.kurumlarArasiNakil, m: {'hedefKurum': 'Sağlık Bakanlığı'}),
        allOf(contains('74. maddesi'), contains('Sağlık Bakanlığı'), contains('muvafakatiyle')),
      );
      expect(
        metin(DilekceTuru.esDurumu, m: {'esKurum': 'Adalet Bakanlığı', 'hedefYer': 'Konya'}),
        allOf(contains('72. maddesi'), contains('Adalet Bakanlığı'), contains('Konya')),
      );
    });

    test('sayiYazi', () {
      expect(DilekceTuru.sayiYazi(7), 'yedi');
      expect(DilekceTuru.sayiYazi(10), 'on');
      expect(DilekceTuru.sayiYazi(21), 'yirmibir');
      expect(DilekceTuru.sayiYazi(100), '100');
    });

    test('her türün atıf yaptığı madde kartta ve metinde tutarlı', () {
      for (final t in DilekceTuru.values) {
        final numara = RegExp(r'\d+').firstMatch(t.madde)!.group(0)!;
        final doldurulmus = t.uret(
          _girdi(
            metinler: {
              'olay': 'Kendi evlenmem',
              'mazeret': 'x',
              'saglikKurumu': 'x',
              'hedefYer': 'x',
              'hedefKurum': 'x',
              'esKurum': 'x',
            },
            tarihler: {'baslangic': DateTime(2026, 10, 1), 'raporTarihi': DateTime(2026, 10, 1)},
            sayilar: {'gun': 3, 'ay': 3},
          ),
        );
        expect(doldurulmus.metin, contains(RegExp('Kanunu\'nun[^.]*$numara')), reason: t.baslik);
      }
    });
  });

  group('Dilekçe ekranları', () {
    setUp(() {
      final b = TestWidgetsFlutterBinding.ensureInitialized();
      b.platformDispatcher.views.first.physicalSize = const Size(900, 2600);
      b.platformDispatcher.views.first.devicePixelRatio = 1;
    });
    tearDown(() {
      final b = TestWidgetsFlutterBinding.ensureInitialized();
      b.platformDispatcher.views.first.resetPhysicalSize();
      b.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('liste sekiz türü gösterir ve forma götürür', (t) async {
      await t.pumpWidget(const MaterialApp(home: DilekceSayfasi(profil: _profil)));
      await t.pumpAndSettle();
      for (final tur in DilekceTuru.values) {
        expect(find.text(tur.baslik), findsOneWidget);
      }
      await t.tap(find.text('Yıllık izin'));
      await t.pumpAndSettle();
      expect(find.text('Önizleme'), findsOneWidget);
      expect(find.text('Metni kopyala'), findsOneWidget);
    });

    testWidgets('form: tarih, gün seçildikçe önizleme dolar ve kopyalama panoya yazar', (t) async {
      String? pano;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
        if (c.method == 'Clipboard.setData') pano = (c.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      await t.pumpWidget(
        MaterialApp(
          home: DilekceFormu(
            tur: DilekceTuru.yillikIzin,
            profil: _profil,
            bugun: _bugun,
            tarihSec: (context, baslangic, ilk, son) async => DateTime(2026, 10, 12),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.textContaining('Doldurulacak: İzne başlama tarihi, İzin süresi (gün)'), findsOneWidget);

      await t.tap(find.text('Tarih seç'));
      await t.pumpAndSettle();
      expect(find.text('12.10.2026'), findsOneWidget);

      await t.tap(find.bySemanticsLabel('İzin süresi (gün) artır'));
      await t.pumpAndSettle();
      expect(find.textContaining('Doldurulacak'), findsNothing);

      await t.tap(find.text('Metni kopyala'));
      await t.pumpAndSettle();
      expect(pano, contains('12.10.2026 tarihinden itibaren 1 (bir) gün yıllık izin'));
      expect(find.textContaining('Dilekçe panoya kopyalandı'), findsOneWidget);
    });

    testWidgets('profil eksikse uyarı çıkar', (t) async {
      await t.pumpWidget(
        MaterialApp(home: DilekceFormu(tur: DilekceTuru.kurumIciAtama, profil: null, bugun: _bugun)),
      );
      await t.pumpAndSettle();
      expect(find.textContaining('Profilinde eksik: ad soyad, kurum adı, unvan'), findsOneWidget);
    });

    testWidgets('evlilik/ölüm formunda yakınlık alanı yalnızca vefat seçilince görünür', (t) async {
      await t.pumpWidget(MaterialApp(home: DilekceFormu(tur: DilekceTuru.evlilikOlum, profil: _profil, bugun: _bugun)));
      await t.pumpAndSettle();
      expect(find.text('Vefat eden yakının'), findsNothing);
      await t.tap(find.text('Yakınımın vefatı'));
      await t.pumpAndSettle();
      expect(find.text('Vefat eden yakının'), findsOneWidget);
    });

    testWidgets('Araçlar bölümü dilekçe kartını yalnızca açma işlevi verilince gösterir', (t) async {
      await t.pumpWidget(const MaterialApp(home: Scaffold(body: AraclarBolumu())));
      await t.pumpAndSettle();
      expect(find.text('Dilekçe hazırla'), findsNothing);

      var acildi = false;
      await t.pumpWidget(MaterialApp(home: Scaffold(body: AraclarBolumu(dilekceAc: () => acildi = true))));
      await t.pumpAndSettle();
      await t.tap(find.text('Dilekçe hazırla'));
      expect(acildi, isTrue);
    });
  });
}
