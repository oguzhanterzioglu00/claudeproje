import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/core/depolama.dart';
import 'package:pusula/features/profil/data/fotograf_deposu.dart';
import 'package:pusula/features/profil/data/profil_deposu.dart';
import 'package:pusula/features/profil/data/profil_kaydi.dart';
import 'package:pusula/features/profil/domain/profil.dart';
import 'package:pusula/features/profil/presentation/ilk_kurulum_sayfasi.dart';

import 'yardimci/sahte_fotograf.dart';
import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  Future<ProfilDeposu> ac(
    WidgetTester tester, {
    Size boyut = const Size(390, 844),
    FotografDeposu? fotograf,
    FotografKaynagi? kaynak,
    String ilkAd = '',
  }) async {
    tester.view.physicalSize = boyut;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = ProfilDeposu(BellekProfilKaydi());
    await depo.yukle();
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      home: IlkKurulumSayfasi(
        depo: depo,
        fotograf: fotograf ?? FotografDeposu(BellekDepolama()),
        fotografKaynagi: kaynak ?? SahteFotografKaynagi(sonuc: ornekPng),
        ilkAd: ilkAd,
      ),
    ));
    await tester.pumpAndSettle();
    return depo;
  }

  bool dugmeAktif(WidgetTester tester, String etiket) {
    final dugme = find.ancestor(of: find.text(etiket), matching: find.byType(InkWell)).first;
    return tester.widget<InkWell>(dugme).onTap != null;
  }

  Future<void> devam(WidgetTester tester) async {
    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();
  }

  testWidgets('memur akışı 4 adımdır; ad ve statü olmadan Devam pasif', (tester) async {
    final depo = await ac(tester);
    expect(find.text('Seni tanıyalım'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget, reason: 'statü seçilmeden memur dışı varsayılır');
    expect(find.bySemanticsLabel('Geri'), findsNothing, reason: 'ilk adımda geri yok');
    expect(dugmeAktif(tester, 'Devam'), isFalse);

    await tester.enterText(find.byType(TextField).first, 'Ayşe Yılmaz');
    await tester.pump();
    expect(dugmeAktif(tester, 'Devam'), isFalse, reason: 'statü seçilmedi');

    await tester.tap(find.text('657 sayılı Kanun memuru'));
    await tester.pump();
    expect(find.text('1 / 4'), findsOneWidget);
    expect(dugmeAktif(tester, 'Devam'), isTrue);
    await devam(tester);

    expect(find.text('Profil fotoğrafın'), findsOneWidget);
    await devam(tester);

    expect(find.text('Görev bilgilerin'), findsOneWidget);
    expect(find.text('Hizmet sınıfı'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Kurum:')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'SAGLIK');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sağlık Bakanlığı').last);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Çalıştığın il:')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'izmir');
    await tester.pumpAndSettle();
    await tester.tap(find.text('İzmir').last);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Hizmet sınıfı:')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sağlık Hizmetleri').last);
    await tester.pumpAndSettle();
    await devam(tester);

    expect(find.text('Becayiş ve dilekçe'), findsOneWidget);
    expect(find.text('Tamamla'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.enterText(find.byType(TextField).last, 'yanlis');
    await tester.pump();
    expect(find.text('Geçerli bir e-posta adresi gir'), findsOneWidget);
    expect(dugmeAktif(tester, 'Tamamla'), isFalse);

    await tester.enterText(find.byType(TextField).last, 'a@saglik.gov.tr');
    await tester.pump();
    await tester.tap(find.text('Tamamla'));
    await tester.pumpAndSettle();

    final p = depo.profil!;
    expect((p.ad, p.statu, p.kurumAdi, p.il, p.sinif),
        ('Ayşe Yılmaz', Statu.memur657, 'Sağlık Bakanlığı', 'İzmir', 'Sağlık Hizmetleri'));
    expect((p.sicilNo, p.kurumsalEposta), ('123456', 'a@saglik.gov.tr'));
  });

  testWidgets('hesaptan gelen ad önceden yazılır', (tester) async {
    await ac(tester, ilkAd: 'Can Öz');
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, 'Can Öz');
  });

  testWidgets('memur dışı akış 3 adımdır; sınıf ve sicil sorulmaz, son adımda Tamamla', (tester) async {
    final depo = await ac(tester);
    await tester.enterText(find.byType(TextField).first, 'Can');
    await tester.tap(find.text('İşçi'));
    await tester.pump();
    expect(find.text('1 / 3'), findsOneWidget);
    await devam(tester);
    await devam(tester);
    expect(find.text('Görev bilgilerin'), findsOneWidget);
    expect(find.text('Hizmet sınıfı'), findsNothing);
    expect(find.text('Tamamla'), findsOneWidget);

    await tester.tap(find.text('Tamamla'));
    await tester.pumpAndSettle();
    expect(depo.profil!.statu, Statu.isci);
    expect(depo.profil!.sinif, isEmpty);
  });

  testWidgets('fotoğraf adımı: galeriden seç, önizleme, kaldır; kamera ve galeri çağrılır', (tester) async {
    final foto = FotografDeposu(BellekDepolama());
    final kaynak = SahteFotografKaynagi(sonuc: ornekPng);
    await ac(tester, fotograf: foto, kaynak: kaynak);
    await tester.enterText(find.byType(TextField).first, 'Ayşe Yılmaz');
    await tester.tap(find.text('İşçi'));
    await tester.pump();
    await devam(tester);

    expect(find.text('Profil fotoğrafın'), findsOneWidget);
    expect(find.text('AY'), findsOneWidget, reason: 'fotoğraf yokken baş harfler');
    expect(find.text('Fotoğrafı kaldır'), findsNothing);

    await tester.tap(find.text('Galeriden seç'));
    await tester.pumpAndSettle();
    expect(kaynak.galeriCagrisi, 1);
    expect(foto.foto, isNotNull);
    expect(find.text('AY'), findsNothing);
    expect(find.text('Fotoğrafı kaldır'), findsOneWidget);

    await tester.tap(find.text('Fotoğraf çek'));
    await tester.pumpAndSettle();
    expect(kaynak.kameraCagrisi, 1);

    await tester.tap(find.text('Fotoğrafı kaldır'));
    await tester.pumpAndSettle();
    expect(foto.foto, isNull);
    expect(find.text('AY'), findsOneWidget);
  });

  testWidgets('fotoğraf alınamazsa açıklayıcı hata gösterilir, akış bozulmaz', (tester) async {
    final kaynak = SahteFotografKaynagi(hata: const FotografHatasi('Kameraya erişilemedi. Ayarlardan kamera iznini kontrol et.'));
    await ac(tester, kaynak: kaynak);
    await tester.enterText(find.byType(TextField).first, 'Can');
    await tester.tap(find.text('İşçi'));
    await tester.pump();
    await devam(tester);
    await tester.tap(find.text('Fotoğraf çek'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kameraya erişilemedi'), findsOneWidget);
    expect(dugmeAktif(tester, 'Devam'), isTrue);
  });

  testWidgets('vazgeçilen seçim (null) hiçbir şeyi değiştirmez', (tester) async {
    final foto = FotografDeposu(BellekDepolama());
    await ac(tester, fotograf: foto, kaynak: SahteFotografKaynagi());
    await tester.enterText(find.byType(TextField).first, 'Can');
    await tester.tap(find.text('İşçi'));
    await tester.pump();
    await devam(tester);
    await tester.tap(find.text('Galeriden seç'));
    await tester.pumpAndSettle();
    expect(foto.foto, isNull);
  });

  testWidgets('geri düğmesi bir önceki adıma döner, girdi korunur', (tester) async {
    await ac(tester);
    await tester.enterText(find.byType(TextField).first, 'Can');
    await tester.tap(find.text('İşçi'));
    await tester.pump();
    await devam(tester);
    await devam(tester);
    expect(find.text('Görev bilgilerin'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Geri'));
    await tester.pumpAndSettle();
    expect(find.text('Profil fotoğrafın'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Geri'));
    await tester.pumpAndSettle();
    expect(find.text('Seni tanıyalım'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, 'Can', reason: 'girdi korunur');
    expect(find.bySemanticsLabel('Geri'), findsNothing);
  });

  testWidgets('Şimdilik atla fotoğraf ve görev adımlarını geçer; son adımda sicil/e-posta kaydetmeden bitirir',
      (tester) async {
    final depo = await ac(tester);
    await tester.enterText(find.byType(TextField).first, 'Ayşe');
    await tester.tap(find.text('657 sayılı Kanun memuru'));
    await tester.pump();
    await devam(tester);

    await tester.tap(find.text('Şimdilik atla')); // fotoğraf
    await tester.pumpAndSettle();
    expect(find.text('Görev bilgilerin'), findsOneWidget);
    await tester.tap(find.text('Şimdilik atla')); // görev
    await tester.pumpAndSettle();
    expect(find.text('Becayiş ve dilekçe'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '999');
    await tester.tap(find.text('Şimdilik atla'));
    await tester.pumpAndSettle();
    expect(depo.profil!.ad, 'Ayşe');
    expect(depo.profil!.sicilNo, isEmpty);
    expect(depo.profil!.eksikBecayisAlanlari, isNotEmpty);
  });
}
