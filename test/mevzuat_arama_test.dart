import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/metin.dart';
import 'package:pusula/features/asistan/asistan_sayfasi.dart';
import 'package:pusula/features/asistan/bilgi_bankasi.dart';
import 'package:pusula/features/asistan/mevzuat_arama.dart';
import 'package:pusula/features/asistan/mevzuat_arama_sayfasi.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  group('MevzuatArama', () {
    test('boş ve çok kısa sorguda sonuç yok', () {
      expect(MevzuatArama.ara(''), isEmpty);
      expect(MevzuatArama.ara('a'), isEmpty);
      expect(MevzuatArama.ara('   '), isEmpty);
    });

    test('Türkçe harf farkı yok sayılır', () {
      final a = MevzuatArama.ara('yıllık izin');
      final b = MevzuatArama.ara('YILLIK IZIN');
      final c = MevzuatArama.ara('yillik izin');
      expect(a, isNotEmpty);
      expect(b.length, a.length);
      expect(c.length, a.length);
    });

    test('kanun metninde geçmeyen ama konu adında olan sözcük (becayiş) bulunur', () {
      final s = MevzuatArama.ara('becayiş');
      expect(s.any((r) => r.kaynak.baslik.contains('md. 73')), isTrue);
    });

    test('tüm sözcükler aynı maddede geçmeli', () {
      final tek = MevzuatArama.ara('becayiş');
      final iki = MevzuatArama.ara('becayiş kademe ilerlemesi disiplin');
      expect(tek, isNotEmpty);
      expect(iki, isEmpty);
    });

    test('olmayan sözcükte sonuç yok', () {
      expect(MevzuatArama.ara('xyzqwerty'), isEmpty);
    });

    test('sonuçlar puana göre sıralanır; başlığında sözcükler geçen maddeler öne çıkar', () {
      final s = MevzuatArama.ara('yıllık izin');
      expect(s.take(5).map((r) => r.kaynak.baslik), anyElement(contains('md. 102')));
      final ilk = aramaAnahtari(s.first.kaynak.baslik);
      expect(ilk, allOf(contains('yillik'), contains('izin')));
      for (var i = 1; i < s.length; i++) {
        expect(s[i - 1].puan, greaterThanOrEqualTo(s[i].puan));
      }
    });

    test('parça eşleşmeyi içerir ve vurgu aralıkları parça içinde kalır', () {
      final s = MevzuatArama.ara('aylıksız');
      expect(s, isNotEmpty);
      for (final r in s) {
        for (final (b, e) in r.vurgular) {
          expect(b, inInclusiveRange(0, r.parca.length));
          expect(e, inInclusiveRange(b, r.parca.length));
        }
        if (r.vurgular.isNotEmpty) {
          final (b, e) = r.vurgular.first;
          expect(r.parca.substring(b, e).toLowerCase().replaceAll('ı', 'i').replaceAll('İ', 'i'), contains('aylik'));
        }
      }
    });

    test('kitle süzgeci: işçi için memur kanunu maddeleri gelmez', () {
      final isci = MevzuatArama.ara('izin', kitle: Kitle.isci);
      expect(isci, isNotEmpty);
      expect(isci.every((r) => r.konu.kitle == Kitle.isci || r.konu.kitle == Kitle.herkes), isTrue);
      final hepsi = MevzuatArama.ara('izin');
      expect(hepsi.length, greaterThanOrEqualTo(isci.length));
    });

    test('en fazla ${MevzuatArama.enFazla} sonuç', () {
      expect(MevzuatArama.ara('ve').length, lessThanOrEqualTo(MevzuatArama.enFazla));
    });

    test('kapsam dışı konular aranmaz', () {
      final kapsamDisi = BilgiBankasi.konular.where((k) => k.kapsamDisi).map((k) => k.id).toSet();
      for (final r in MevzuatArama.ara('izin')) {
        expect(kapsamDisi.contains(r.konu.id), isFalse);
      }
    });
  });

  group('Mevzuat arama ekranı', () {
    setUp(() {
      final b = TestWidgetsFlutterBinding.ensureInitialized();
      b.platformDispatcher.views.first.physicalSize = const Size(900, 2400);
      b.platformDispatcher.views.first.devicePixelRatio = 1;
    });
    tearDown(() {
      final b = TestWidgetsFlutterBinding.ensureInitialized();
      b.platformDispatcher.views.first.resetPhysicalSize();
      b.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('başlangıçta öneriler görünür; öneriye dokununca arama yapılır', (t) async {
      await t.pumpWidget(const MaterialApp(home: MevzuatAramaSayfasi()));
      await t.pumpAndSettle();
      expect(find.text('Sık aranan'), findsOneWidget);
      await t.tap(find.text('kademe'));
      await t.pumpAndSettle();
      expect(find.textContaining('madde bulundu'), findsOneWidget);
      expect(find.text('Sık aranan'), findsNothing);
    });

    testWidgets('sonuç bulunamazsa boş durum çizimi gösterilir', (t) async {
      await t.pumpWidget(const MaterialApp(home: MevzuatAramaSayfasi()));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'zzzzqqq');
      await t.pumpAndSettle();
      expect(find.text('Sonuç bulunamadı'), findsOneWidget);
    });

    testWidgets('sonuca dokununca alıntı açılır ve kopyalanır', (t) async {
      String? pano;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
        if (c.method == 'Clipboard.setData') pano = (c.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      await t.pumpWidget(const MaterialApp(home: MevzuatAramaSayfasi(baslangicSorgu: 'becayiş')));
      await t.pumpAndSettle();
      await t.tap(find.textContaining('md. 73').first);
      await t.pumpAndSettle();
      expect(find.text('Alıntıyı kopyala'), findsOneWidget);
      await t.tap(find.text('Alıntıyı kopyala'));
      await t.pumpAndSettle();
      expect(pano, contains('md. 73'));
      expect(pano, contains('Aynı Kurumun'));
    });

    testWidgets('sorgu temizlenince öneriler geri gelir', (t) async {
      await t.pumpWidget(const MaterialApp(home: MevzuatAramaSayfasi(baslangicSorgu: 'izin')));
      await t.pumpAndSettle();
      expect(find.text('Sık aranan'), findsNothing);
      await t.tap(find.byTooltip('Temizle'));
      await t.pumpAndSettle();
      expect(find.text('Sık aranan'), findsOneWidget);
    });

    testWidgets('asistan ekranındaki arama düğmesi aramayı açar', (t) async {
      await t.pumpWidget(const MaterialApp(home: Scaffold(body: AsistanSayfasi(kitle: Kitle.memur))));
      await t.pumpAndSettle();
      await t.tap(find.bySemanticsLabel('Mevzuatta ara'));
      await t.pumpAndSettle();
      expect(find.text('Mevzuat ara'), findsOneWidget);
    });
  });
}
