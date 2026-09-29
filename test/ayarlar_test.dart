import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/ayarlar/ayarlar_sayfasi.dart';
import 'package:pusula/features/ayarlar/kisisel_veri_dokumu.dart';
import 'package:pusula/features/ayarlar/uygulama_bilgisi.dart';
import 'package:pusula/features/ayarlar/yasal_metinler.dart';
import 'package:pusula/features/hesap/domain/hesap.dart';
import 'package:pusula/features/profil/domain/profil.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  test('uygulama sürümü pubspec.yaml ile aynı', () {
    final satir = File('pubspec.yaml').readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    expect(satir, 'version: ${UygulamaBilgisi.surum}+${UygulamaBilgisi.derleme}');
  });

  group('yasal metin taslakları', () {
    test('taslaklar açıkça işaretli; doldurulacak yerler sayılır', () {
      expect(YasalMetinler.taslakUyarisi, contains('TASLAK'));
      expect(YasalMetinler.aydinlatma.doldurulacakYerSayisi, greaterThan(0));
      expect(YasalMetinler.kosullar.doldurulacakYerSayisi, greaterThan(0));
    });

    test('aydınlatma metni KVKK md. 10 unsurlarını kapsar', () {
      final basliklar = YasalMetinler.aydinlatma.bolumler.map((b) => b.baslik).join('|');
      for (final unsur in ['Veri sorumlusu', 'İşleme amaçları', 'aktarım', 'Hukuki sebep', 'Haklarınız']) {
        expect(basliklar, contains(unsur));
      }
    });

    test('metinler bugünkü gerçek veri akışını doğru anlatır: veriler cihazda, sunucuya gitmez', () {
      final metin = YasalMetinler.aydinlatma.bolumler.map((b) => b.metin).join(' ');
      expect(metin, contains('yalnızca cihazınızda saklanır'));
      expect(metin, contains('sunucuya gönderilmez'));
    });
  });

  group('KisiselVeriDokumu', () {
    const profil = Profil(ad: 'Ayşe', statu: Statu.memur657, kurumAdi: 'Sağlık Bakanlığı', sicilNo: '123');
    const hesap = Hesap(id: 'u-1', saglayici: GirisSaglayici.eposta, eposta: 'a@b.co');

    test('hesap ve profili içerir; kimlik/şifre alanı ve fotoğraf içeriği yok', () {
      final d = KisiselVeriDokumu.uret(hesap: hesap, profil: profil, fotografVar: true, zaman: DateTime(2026, 9, 29));
      expect(d, contains('"eposta": "a@b.co"'));
      expect(d, contains('"kurumAdi": "Sağlık Bakanlığı"'));
      expect(d, contains('"sicilNo": "123"'));
      expect(d, contains('var (dışa aktarılmadı)'));
      expect(d, isNot(contains('u-1')), reason: 'iç hesap kimliği dışa verilmez');
      expect(d, isNot(contains('ozet')));
      expect(d, contains('2026-09-29'));
    });

    test('hesap ya da profil yoksa ilgili bölüm yazılmaz', () {
      final d = KisiselVeriDokumu.uret();
      expect(d, isNot(contains('"hesap"')));
      expect(d, isNot(contains('"profil"')));
      expect(d, contains('"profilFotografi": "yok"'));
    });
  });

  group('Ayarlar sayfası', () {
    Future<void> ac(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: pusulaTema(),
        home: const AyarlarSayfasi(
          hesap: Hesap(id: 'u-1', saglayici: GirisSaglayici.eposta, eposta: 'a@b.co'),
          profil: Profil(ad: 'Ayşe', statu: Statu.diger),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('sürüm ve bölümler görünür', (tester) async {
      await ac(tester);
      expect(find.text('Ayarlar'), findsOneWidget);
      expect(find.text('Sürüm ${UygulamaBilgisi.surumMetni}'), findsOneWidget);
      for (final t in ['Aydınlatma Metni', 'Kullanım Koşulları', 'Verilerimi kopyala', 'Açık kaynak lisansları']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
    });

    testWidgets('yasal metin sayfası taslak uyarısını ve tüm bölümleri gösterir', (tester) async {
      await ac(tester);
      await tester.tap(find.text('Aydınlatma Metni'));
      await tester.pumpAndSettle();
      expect(find.textContaining('TASLAK'), findsOneWidget);
      expect(find.text('Aydınlatma Metni (KVKK md. 10)'), findsOneWidget);
      expect(find.textContaining('1. Veri sorumlusu'), findsOneWidget);
    });

    testWidgets('Verilerimi kopyala panoya döküm yazar ve bilgi verir', (tester) async {
      String? pano;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') pano = (call.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await ac(tester);
      await tester.tap(find.text('Verilerimi kopyala'));
      await tester.pumpAndSettle();
      expect(pano, isNotNull);
      expect(pano, contains('a@b.co'));
      expect(pano, contains('"ad": "Ayşe"'));
      expect(find.textContaining('panoya kopyalandı'), findsOneWidget);
    });
  });
}
