import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/hareket.dart';
import 'package:pusula/features/haberler/haber_kapagi.dart';
import 'package:pusula/features/haberler/haber_modeli.dart';

Haber _haber(String id, HaberTuru tur, {String kaynak = 'Kurum'}) =>
    Haber(id: id, baslik: 'Başlık', tur: tur, kaynakAdi: kaynak, yayinTarihi: DateTime(2026, 9, 30));

Widget _sar(Widget c, {bool azalt = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: azalt),
    child: Scaffold(body: Center(child: SizedBox(width: 300, height: 225, child: c))),
  ),
);

void main() {
  tearDown(() => PusulaHareket.susHareketi = false);

  group('HaberGorselTuru', () {
    test('tür eşlemesi ve günlük Resmî Gazete sayısı', () {
      expect(HaberGorselTuru.sec(_haber('1', HaberTuru.maas)), HaberGorselTuru.maas);
      expect(HaberGorselTuru.sec(_haber('2', HaberTuru.mevzuat)), HaberGorselTuru.mevzuat);
      expect(HaberGorselTuru.sec(_haber('3', HaberTuru.duyuru)), HaberGorselTuru.duyuru);
      expect(HaberGorselTuru.sec(_haber('4', HaberTuru.atama)), HaberGorselTuru.atama);
      expect(
        HaberGorselTuru.sec(_haber('rg-20260930', HaberTuru.mevzuat, kaynak: 'Resmî Gazete')),
        HaberGorselTuru.gazete,
      );
      // Madde haberinin kimliği sayı + sıra içerir; günlük sayı sayılmaz.
      expect(
        HaberGorselTuru.sec(_haber('rg-20260930-1-123', HaberTuru.mevzuat, kaynak: 'Resmî Gazete')),
        HaberGorselTuru.mevzuat,
      );
    });

    test('her türün üç katmanı da uygulama paketinde var', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final t in HaberGorselTuru.values) {
        for (final yol in [t.zemin, t.orta, t.on]) {
          final veri = await rootBundle.loadString(yol);
          expect(veri, contains('viewBox="0 0 240 180"'), reason: '$yol aynı viewBox\'ı kullanmalı');
        }
      }
    });
  });

  group('HareketliGorsel', () {
    final katmanlar = HaberGorselTuru.maas.katmanlar;

    testWidgets('üç SVG katmanını çizer', (t) async {
      await t.pumpWidget(_sar(HareketliGorsel(katmanlar: katmanlar)));
      expect(find.byType(SvgPicture), findsNWidgets(3));
    });

    testWidgets('süs hareketi açıkken katmanlar zamanla yer değiştirir', (t) async {
      PusulaHareket.susHareketi = true;
      await t.pumpWidget(_sar(HareketliGorsel(katmanlar: katmanlar)));
      await t.pump(const Duration(milliseconds: 1500)); // giriş bitsin
      final once = t.getTopLeft(find.byType(SvgPicture).at(2));
      await t.pump(const Duration(milliseconds: 700));
      final sonra = t.getTopLeft(find.byType(SvgPicture).at(2));
      expect(sonra, isNot(once), reason: 'ön katman süzülmeli');
    });

    testWidgets('hareketi azalt açıkken hiçbir animasyon çalışmaz', (t) async {
      PusulaHareket.susHareketi = true;
      await t.pumpWidget(_sar(HareketliGorsel(katmanlar: katmanlar), azalt: true));
      // Sürekli animasyon olsaydı pumpAndSettle zaman aşımına uğrardı.
      await t.pumpAndSettle();
      final once = t.getTopLeft(find.byType(SvgPicture).at(2));
      await t.pump(const Duration(seconds: 3));
      expect(t.getTopLeft(find.byType(SvgPicture).at(2)), once);
    });

    testWidgets('hareketli: false durağan çizer', (t) async {
      PusulaHareket.susHareketi = true;
      await t.pumpWidget(_sar(HareketliGorsel(katmanlar: katmanlar, hareketli: false)));
      await t.pumpAndSettle();
      expect(find.byType(SvgPicture), findsNWidgets(3));
    });

    testWidgets('kaydırma değeri katmanları derinliğine göre yana kaydırır', (t) async {
      final kay = ValueNotifier<double>(0);
      await t.pumpWidget(_sar(HareketliGorsel(katmanlar: katmanlar, kaydirma: kay)));
      await t.pumpAndSettle();
      final onceArka = t.getTopLeft(find.byType(SvgPicture).at(0)).dx;
      final onceOn = t.getTopLeft(find.byType(SvgPicture).at(2)).dx;
      kay.value = 1;
      await t.pump();
      final arka = t.getTopLeft(find.byType(SvgPicture).at(0)).dx - onceArka;
      final on = t.getTopLeft(find.byType(SvgPicture).at(2)).dx - onceOn;
      expect(on.abs(), greaterThan(arka.abs()), reason: 'ön katman arka katmandan çok kaymalı');
    });

    testWidgets('anlam etiketi verilirse ekran okuyucuya açıklanır', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_sar(HareketliGorsel(katmanlar: katmanlar, anlamEtiketi: 'Maaş çizimi')));
      expect(find.bySemanticsLabel('Maaş çizimi'), findsOneWidget);
      h.dispose();
    });
  });

  group('Basilabilir', () {
    testWidgets('basılınca küçülür, bırakılınca eski boyuna döner', (t) async {
      await t.pumpWidget(_sar(Basilabilir(child: Container(color: Colors.red))));
      double genislik() => t.getSize(find.byType(Container).last).width;
      final normal = t.getRect(find.byType(Basilabilir)).width;
      expect(normal, 300);

      final dokunus = await t.startGesture(t.getCenter(find.byType(Basilabilir)));
      await t.pump(const Duration(milliseconds: 200));
      final tr = t.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(tr.scale, lessThan(1));
      expect(genislik(), greaterThan(0));

      await dokunus.up();
      await t.pumpAndSettle();
      expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    });

    testWidgets('aktif: false iken sarmalamaz', (t) async {
      await t.pumpWidget(_sar(const Basilabilir(aktif: false, child: SizedBox())));
      expect(find.byType(AnimatedScale), findsNothing);
    });
  });
}
