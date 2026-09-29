import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/avatar.dart';
import 'package:pusula/core/depolama.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/hesap/data/oturum_deposu.dart';
import 'package:pusula/features/hesap/data/yerel_kimlik_servisi.dart';
import 'package:pusula/features/hesap/domain/hesap.dart';
import 'package:pusula/features/profil/data/fotograf_deposu.dart';
import 'package:pusula/features/profil/data/profil_deposu.dart';
import 'package:pusula/features/profil/data/profil_kaydi.dart';
import 'package:pusula/features/profil/domain/profil.dart';
import 'package:pusula/features/profil/presentation/profil_sayfasi.dart';

import 'yardimci/sahte_fotograf.dart';
import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  test('baş harfler: Türkçe büyük harf ve tek/çok sözcük', () {
    expect(ProfilAvatar.basHarfler('Ayşe Yılmaz'), 'AY');
    expect(ProfilAvatar.basHarfler('  ışık  iğne  '), 'Iİ');
    expect(ProfilAvatar.basHarfler('Can'), 'C');
    expect(ProfilAvatar.basHarfler('Ali Veli Deli'), 'AD');
    expect(ProfilAvatar.basHarfler('   '), '');
  });

  group('fotoğraf deposu', () {
    test('kaydeder, yeniden yükler, kaldırır; büyük ve boş fotoğrafı reddeder', () async {
      final d = BellekDepolama();
      final f = FotografDeposu(d);
      await f.yukle();
      expect(f.foto, isNull);
      await f.ayarla(ornekPng);
      expect(f.foto, ornekPng);

      final yeni = FotografDeposu(d);
      await yeni.yukle();
      expect(yeni.foto, ornekPng);

      await expectLater(f.ayarla(Uint8List(0)), throwsA(isA<FotografHatasi>()));
      await expectLater(f.ayarla(Uint8List(FotografDeposu.enBuyukBoyut + 1)), throwsA(isA<FotografHatasi>()));
      expect(f.foto, ornekPng, reason: 'hatalı giriş mevcut fotoğrafı bozmaz');

      await f.kaldir();
      expect(f.foto, isNull);
      expect(await d.oku('profil_foto_v1'), isNull);
    });

    test('bozuk kayıt çökertmez; hesaplar birbirinin fotoğrafını görmez', () async {
      final d = BellekDepolama({'profil_foto_v1_a': '###bozuk###'});
      final a = FotografDeposu(d, anahtar: 'profil_foto_v1_a');
      await a.yukle();
      expect((a.foto, a.yuklendi), (null, true));

      final b = FotografDeposu(d, anahtar: 'profil_foto_v1_b');
      await b.yukle();
      await b.ayarla(ornekPng);
      await a.yukle();
      expect(a.foto, isNull);
    });
  });

  Future<({OturumDeposu oturum, ProfilDeposu profil, FotografDeposu foto})> ac(
    WidgetTester tester, {
    bool google = false,
    SahteFotografKaynagi? kaynak,
  }) async {
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final oturum = OturumDeposu(YerelKimlikServisi(depolama: BellekDepolama(), tur: 8));
    await oturum.yukle();
    if (google) {
      await oturum.saglayiciIleGiris(GirisSaglayici.google);
    } else {
      await oturum.kayitOl('ayse@kurum.gov.tr', 'sifre1234');
    }
    final profil = ProfilDeposu(BellekProfilKaydi(const Profil(ad: 'Ayşe Yılmaz', statu: Statu.diger)));
    await profil.yukle();
    final foto = FotografDeposu(BellekDepolama());
    await foto.yukle();
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      home: ProfilSayfasi(
        depo: profil,
        fotograf: foto,
        fotografKaynagi: kaynak ?? SahteFotografKaynagi(sonuc: ornekPng),
        oturum: oturum,
      ),
    ));
    await tester.pumpAndSettle();
    return (oturum: oturum, profil: profil, foto: foto);
  }

  testWidgets('hesap bölümü giriş yöntemini gösterir; fotoğraf satırı baş harfleri gösterir', (tester) async {
    await ac(tester);
    expect(find.text('Hesap ve güvenlik'), findsOneWidget);
    expect(find.text('ayse@kurum.gov.tr'), findsOneWidget);
    expect(find.text('Şifreyi değiştir'), findsOneWidget);
    expect(find.text('AY'), findsOneWidget);
    expect(find.text('Fotoğraf ekle'), findsOneWidget);
  });

  testWidgets('Google hesabında şifre değiştirme yoktur, açıklama görünür', (tester) async {
    await ac(tester, google: true);
    expect(find.text('Google ile giriş (örnek)'), findsOneWidget);
    expect(find.text('Şifreyi değiştir'), findsNothing);
    expect(find.textContaining('şifren orada yönetilir'), findsOneWidget);
  });

  testWidgets('şifre değiştirme: eşleşmeyen tekrar uyarı verir; yanlış mevcut şifre hata; doğru akış başarıyla biter',
      (tester) async {
    final s = await ac(tester);
    await tester.tap(find.text('Şifreyi değiştir'));
    await tester.pumpAndSettle();
    expect(find.text('Şifre değiştir'), findsOneWidget);

    bool guncelleAktif() {
      final d = find.ancestor(of: find.text('Şifreyi güncelle'), matching: find.byType(InkWell)).first;
      return tester.widget<InkWell>(d).onTap != null;
    }

    final alanlar = find.byType(TextField);
    await tester.enterText(alanlar.at(0), 'yanlis1234');
    await tester.enterText(alanlar.at(1), 'yeniSifre55');
    await tester.enterText(alanlar.at(2), 'baska12345');
    await tester.pump();
    expect(find.text('Şifreler eşleşmiyor'), findsOneWidget);
    expect(guncelleAktif(), isFalse);

    await tester.enterText(alanlar.at(2), 'yeniSifre55');
    await tester.pump();
    expect(guncelleAktif(), isTrue);
    await tester.tap(find.text('Şifreyi güncelle'));
    await tester.pumpAndSettle();
    expect(find.text('Mevcut şifren hatalı'), findsOneWidget);

    await tester.enterText(alanlar.at(0), 'sifre1234');
    await tester.pump();
    await tester.tap(find.text('Şifreyi güncelle'));
    await tester.pumpAndSettle();
    expect(find.text('Şifren güncellendi'), findsOneWidget);

    await s.oturum.cikisYap();
    await s.oturum.girisYap('ayse@kurum.gov.tr', 'yeniSifre55');
    expect(s.oturum.hesap, isNotNull);

    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(find.text('Şifre değiştir'), findsNothing);
  });

  testWidgets('zayıf yeni şifre güncelleme düğmesini açmaz', (tester) async {
    await ac(tester);
    await tester.tap(find.text('Şifreyi değiştir'));
    await tester.pumpAndSettle();
    final alanlar = find.byType(TextField);
    await tester.enterText(alanlar.at(0), 'sifre1234');
    await tester.enterText(alanlar.at(1), 'kisa');
    await tester.enterText(alanlar.at(2), 'kisa');
    await tester.pump();
    final d = find.ancestor(of: find.text('Şifreyi güncelle'), matching: find.byType(InkWell)).first;
    expect(tester.widget<InkWell>(d).onTap, isNull);
  });

  testWidgets('çıkış onay ister; onaylanınca oturum kapanır, veriler cihazda kalır', (tester) async {
    final s = await ac(tester);
    await tester.tap(find.text('Çıkış yap'));
    await tester.pumpAndSettle();
    expect(find.text('Çıkış yapılsın mı?'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(s.oturum.hesap, isNotNull);

    await tester.tap(find.text('Çıkış yap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çıkış yap').last);
    await tester.pumpAndSettle();
    expect(s.oturum.hesap, isNull);
    expect(s.profil.profil, isNotNull);
  });

  testWidgets('hesabı silme: hesap, profil ve fotoğraf silinir', (tester) async {
    final s = await ac(tester);
    await s.foto.ayarla(ornekPng);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hesabımı ve verilerimi sil'));
    await tester.pumpAndSettle();
    expect(find.text('Hesabın silinsin mi?'), findsOneWidget);
    await tester.tap(find.text('Hesabımı sil'));
    await tester.pumpAndSettle();
    expect((s.oturum.hesap, s.profil.profil, s.foto.foto), (null, null, null));
  });

  testWidgets('fotoğraf sayfası: profilden açılır, seçilen fotoğraf profilde görünür', (tester) async {
    final s = await ac(tester);
    await tester.tap(find.text('Fotoğraf ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Fotoğraf'), findsOneWidget);
    await tester.tap(find.text('Galeriden seç'));
    await tester.pumpAndSettle();
    expect(s.foto.foto, isNotNull);

    await tester.tap(find.text('Bitti'));
    await tester.pumpAndSettle();
    expect(find.text('Fotoğrafı değiştir'), findsOneWidget);
    expect(find.text('AY'), findsNothing);
  });

  testWidgets('Ayarlar ve yasal satırı ayarlar sayfasını açar (hesap ve profil aktarılır)', (tester) async {
    await ac(tester);
    await tester.ensureVisible(find.bySemanticsLabel('Ayarlar ve yasal'));
    await tester.tap(find.text('Ayarlar ve yasal'));
    await tester.pumpAndSettle();
    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.text('Verilerimi kopyala'), findsOneWidget);
  });
}
