import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/bos_durum.dart';
import 'package:pusula/core/hareket.dart';
import 'package:pusula/core/iskelet.dart';

Widget _sar(Widget c, {bool azalt = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: azalt),
    child: Scaffold(body: SingleChildScrollView(child: c)),
  ),
);

void main() {
  tearDown(() => PusulaHareket.susHareketi = false);

  group('BosDurum', () {
    testWidgets('illüstrasyon, başlık ve açıklamayı gösterir', (t) async {
      await t.pumpWidget(_sar(const BosDurum(gorsel: BosGorselTuru.arama, baslik: 'Sonuç yok', alt: 'Aramayı değiştir')));
      expect(find.text('Sonuç yok'), findsOneWidget);
      expect(find.text('Aramayı değiştir'), findsOneWidget);
      expect(find.byType(SvgPicture), findsNWidgets(3));
    });

    testWidgets('düğme verilirse çalışır', (t) async {
      var sayac = 0;
      await t.pumpWidget(_sar(BosDurum(
        gorsel: BosGorselTuru.baglanti,
        baslik: 'Yüklenemedi',
        alt: 'Bağlantını kontrol et',
        dugme: 'Tekrar dene',
        onDugme: () => sayac++,
      )));
      await t.tap(find.text('Tekrar dene'));
      expect(sayac, 1);
    });

    test('her türün üç katmanı pakette var', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final t in BosGorselTuru.values) {
        for (final k in t.katmanlar) {
          final veri = await rootBundle.loadString(k.varlik);
          expect(veri, contains('viewBox="0 0 240 180"'), reason: k.varlik);
        }
      }
    });
  });

  group('IskeletListe', () {
    testWidgets('verilen sayıda kart çizer ve ekran okuyucuya "Yükleniyor" der', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_sar(const IskeletListe(adet: 4)));
      expect(find.byType(IskeletBlok), findsNWidgets(4 * 4));
      expect(find.bySemanticsLabel('Yükleniyor'), findsOneWidget);
      h.dispose();
    });

    testWidgets('parıltı açıkken sürekli çalışır, hareketi azalt açıkken durur', (t) async {
      PusulaHareket.susHareketi = true;
      await t.pumpWidget(_sar(const IskeletListe()));
      await t.pump(const Duration(milliseconds: 300));
      expect(t.hasRunningAnimations, isTrue, reason: 'parıltı dönmeli');

      await t.pumpWidget(_sar(const IskeletListe(), azalt: true));
      await t.pumpAndSettle(); // hareketi azalt: animasyon kalmamalı, yoksa zaman aşımı olur
    });
  });
}
