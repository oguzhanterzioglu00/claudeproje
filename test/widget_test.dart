import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/depolama.dart';
import 'package:pusula/features/hesap/data/yerel_kimlik_servisi.dart';
import 'package:pusula/features/profil/data/profil_kaydi.dart';
import 'package:pusula/features/profil/domain/profil.dart';
import 'package:pusula/main.dart';

import 'yardimci/sahte_fotograf.dart';
import 'yardimci/yazilar.dart';

const _sifre = 'sifre1234';

void main() {
  setUpAll(pusulaYazilariniYukle);

  /// Uygulamayı bellek içi depolamayla açar; [hesapVar] ise önceden kayıtlı oturum vardır.
  Future<({BellekDepolama depo, Map<String, BellekProfilKaydi> profiller})> ac(
    WidgetTester tester, {
    bool tanitimGoruldu = false,
    bool hesapVar = false,
    Profil? profil,
    bool apple = true,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final depo = BellekDepolama({if (tanitimGoruldu) 'tanitim_goruldu_v1': '1'});
    final kimlik = YerelKimlikServisi(depolama: depo, tur: 8);
    final profiller = <String, BellekProfilKaydi>{};
    if (hesapVar) {
      final h = await kimlik.kayitOl(eposta: 'ayse@kurum.gov.tr', sifre: _sifre);
      if (profil != null) profiller[h.id] = BellekProfilKaydi(profil);
    }
    await tester.pumpWidget(PusulaUygulamasi(
      kimlik: kimlik,
      depolama: depo,
      profilKaydiUret: (id) => profiller.putIfAbsent(id, BellekProfilKaydi.new),
      fotografKaynagi: SahteFotografKaynagi(sonuc: ornekPng),
      appleGoster: apple,
    ));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    return (depo: depo, profiller: profiller);
  }

  testWidgets('ilk açılışta tanıtım gelir; bitince giriş ekranı, sonra bir daha tanıtım çıkmaz', (tester) async {
    final s = await ac(tester);
    expect(find.text('Atla'), findsOneWidget);
    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();
    expect(find.text('Giriş yap'), findsWidgets);
    expect(await s.depo.oku('tanitim_goruldu_v1'), '1');
  });

  testWidgets('tanıtım görüldüyse doğrudan giriş ekranı açılır', (tester) async {
    await ac(tester, tanitimGoruldu: true);
    expect(find.text('Hesap oluştur'), findsOneWidget);
    expect(find.text('Google ile devam et'), findsOneWidget);
    expect(find.text('Apple ile devam et'), findsOneWidget);
  });

  testWidgets('hesap var ve profil yoksa profil kurulumu açılır', (tester) async {
    await ac(tester, tanitimGoruldu: true, hesapVar: true);
    expect(find.text('Seni tanıyalım'), findsOneWidget);
  });

  testWidgets('hesap ve profil varsa doğrudan ana sayfa açılır (kurulum ve hazırlanıyor atlanır)', (tester) async {
    await ac(
      tester,
      tanitimGoruldu: true,
      hesapVar: true,
      profil: const Profil(ad: 'Ayşe', statu: Statu.memur657),
    );
    expect(find.text('Kamu Pusulası'), findsOneWidget);
    expect(find.text('Seni tanıyalım'), findsNothing);
    expect(find.textContaining('Hazırlıyoruz'), findsNothing);
  });

  testWidgets('uçtan uca: kayıt → kurulum → hazırlanıyor animasyonu → ana sayfa', (tester) async {
    await ac(tester, tanitimGoruldu: true);

    // Hesap oluştur.
    await tester.tap(find.text('Hesap oluştur'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'yeni@kurum.gov.tr');
    await tester.enterText(find.byType(TextField).last, _sifre);
    await tester.pump();
    await tester.tap(find.widgetWithText(InkWell, 'Hesap oluştur').last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Seni tanıyalım'), findsOneWidget);

    // Kurulum: memur olmayan kısa yol.
    await tester.enterText(find.byType(TextField).first, 'Ayşe Yılmaz');
    await tester.tap(find.text('İşçi'));
    await tester.pump();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Tamamla'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Hazırlanıyor akışı.
    expect(find.text('Hazırlıyoruz, Ayşe'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Hazırlıyoruz, Ayşe'), findsNothing);
    expect(find.text('Kamu Pusulası'), findsOneWidget);
  });

  testWidgets('Apple düğmesi kapatılabilir', (tester) async {
    await ac(tester, tanitimGoruldu: true, apple: false);
    expect(find.text('Google ile devam et'), findsOneWidget);
    expect(find.text('Apple ile devam et'), findsNothing);
  });
}
