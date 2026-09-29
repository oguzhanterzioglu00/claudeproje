import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/profil/data/profil_deposu.dart';
import 'package:pusula/features/profil/data/profil_kaydi.dart';
import 'package:pusula/features/profil/domain/profil.dart';
import 'package:pusula/features/profil/presentation/profil_sayfasi.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  Future<ProfilDeposu> ac(WidgetTester tester, {Profil? mevcut, bool ilk = true, VoidCallback? onBitti}) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = ProfilDeposu(BellekProfilKaydi(mevcut));
    await depo.yukle();
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      home: ProfilSayfasi(depo: depo, ilkKurulum: ilk, onBitti: onBitti ?? () {}),
    ));
    await tester.pumpAndSettle();
    return depo;
  }

  bool baslaAktif(WidgetTester tester, String etiket) {
    final dugme = find.ancestor(of: find.text(etiket), matching: find.byType(InkWell)).first;
    return tester.widget<InkWell>(dugme).onTap != null;
  }

  testWidgets('ilk kurulumda ad ve statü olmadan Başla pasif; ikisi gelince kaydeder', (tester) async {
    var bitti = 0;
    final depo = await ac(tester, onBitti: () => bitti++);
    expect(find.text('Hoş geldin'), findsOneWidget);
    expect(baslaAktif(tester, 'Başla'), isFalse);

    await tester.enterText(find.byType(TextField).first, 'Ayşe Yılmaz');
    await tester.pump();
    expect(baslaAktif(tester, 'Başla'), isFalse, reason: 'statü seçilmedi');

    await tester.tap(find.text('İşçi'));
    await tester.pump();
    expect(baslaAktif(tester, 'Başla'), isTrue);

    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    expect(depo.profil!.ad, 'Ayşe Yılmaz');
    expect(depo.profil!.statu, Statu.isci);
    expect(bitti, 1);
  });

  testWidgets('memur seçilince sınıf, sicil ve e-posta alanları açılır; diğer statülerde gizlenir', (tester) async {
    await ac(tester);
    expect(find.text('Görev bilgilerin'), findsNothing);

    await tester.tap(find.text('657 sayılı Kanun memuru'));
    await tester.pump();
    expect(find.text('Görev bilgilerin'), findsOneWidget);
    expect(find.text('Hizmet sınıfı'), findsOneWidget);
    expect(find.text('Sicil no'), findsOneWidget);
    expect(find.text('Kurumsal e-posta'), findsOneWidget);
    expect(find.textContaining('aday memurum'), findsOneWidget);

    await tester.tap(find.text('4/B sözleşmeli personel'));
    await tester.pump();
    expect(find.text('Görev bilgilerin'), findsOneWidget);
    expect(find.text('Hizmet sınıfı'), findsNothing);
    expect(find.text('Sicil no'), findsNothing);
    expect(find.textContaining('aday memurum'), findsNothing);
  });

  testWidgets('kurum ve il aranarak seçilir; listede olmayan kurum elle yazılabilir', (tester) async {
    final depo = await ac(tester);
    await tester.enterText(find.byType(TextField).first, 'Ayşe');
    await tester.tap(find.text('657 sayılı Kanun memuru'));
    await tester.pump();

    // Kurum: arama Türkçe harf farkını önemsemez.
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Kurum:')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'SAGLIK');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sağlık Bakanlığı').last);
    await tester.pumpAndSettle();

    // İl:
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Çalıştığın il:')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'izmir');
    await tester.pumpAndSettle();
    await tester.tap(find.text('İzmir').last);
    await tester.pumpAndSettle();

    // Sınıf:
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Hizmet sınıfı:')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sağlık Hizmetleri').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    final p = depo.profil!;
    expect((p.kurumAdi, p.il, p.sinif), ('Sağlık Bakanlığı', 'İzmir', 'Sağlık Hizmetleri'));
    expect(p.kurumKimligi, 'saglik-bakanligi');
  });

  testWidgets('serbest kurum yazımı "Kullan" seçeneğiyle kabul edilir', (tester) async {
    final depo = await ac(tester);
    await tester.enterText(find.byType(TextField).first, 'Ayşe');
    await tester.tap(find.text('İşçi'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Kurum:')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Özel Belediye Şirketi');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kullan: "Özel Belediye Şirketi"'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    expect(depo.profil!.kurumAdi, 'Özel Belediye Şirketi');
  });

  testWidgets('geçersiz e-posta hata gösterir ve kaydı engeller', (tester) async {
    await ac(tester);
    await tester.enterText(find.byType(TextField).first, 'Ayşe');
    await tester.tap(find.text('657 sayılı Kanun memuru'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'yanlis-adres');
    await tester.pump();
    expect(find.text('Geçerli bir e-posta adresi gir'), findsOneWidget);
    expect(baslaAktif(tester, 'Başla'), isFalse);

    await tester.enterText(find.byType(TextField).last, 'a@kurum.gov.tr');
    await tester.pump();
    expect(find.text('Geçerli bir e-posta adresi gir'), findsNothing);
    expect(baslaAktif(tester, 'Başla'), isTrue);
  });

  testWidgets('aday memur seçimi kaydedilir; memur dışı statüye geçince sınıf ve sicil temizlenir', (tester) async {
    final depo = await ac(
      tester,
      ilk: false,
      mevcut: const Profil(
        ad: 'Ayşe', statu: Statu.memur657, sinif: 'Sağlık Hizmetleri', sicilNo: '999', maas: null,
      ),
    );
    expect(find.text('Profilim'), findsOneWidget);
    expect(find.text('Kaydet'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(depo.profil!.adayMemur, isTrue);
    expect(depo.profil!.sicilNo, '999');

    // Yeniden aç ve statüyü değiştir.
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      home: ProfilSayfasi(depo: depo, onBitti: () {}),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İşçi'));
    await tester.pump();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(depo.profil!.statu, Statu.isci);
    expect(depo.profil!.adayMemur, isFalse);
    expect(depo.profil!.sinif, isEmpty);
    expect(depo.profil!.sicilNo, isEmpty);
  });

  testWidgets('kaydedilmiş maaş girdisi profil düzenlenirken korunur', (tester) async {
    final depo = await ac(
      tester,
      ilk: false,
      mevcut: const Profil(ad: 'A', statu: Statu.memur657, maas: null),
    );
    await tester.enterText(find.byType(TextField).first, 'B');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(depo.profil!.ad, 'B');
  });

  testWidgets('profil silme onay ister; onaylanınca cihazdan silinir', (tester) async {
    final depo = await ac(
      tester,
      ilk: false,
      mevcut: const Profil(ad: 'Ayşe', statu: Statu.diger),
    );
    await tester.ensureVisible(find.text('Profilimi sil'));
    await tester.tap(find.text('Profilimi sil'));
    await tester.pumpAndSettle();
    expect(find.text('Profil silinsin mi?'), findsOneWidget);

    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(depo.profil, isNotNull);

    await tester.tap(find.text('Profilimi sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(depo.profil, isNull);
  });
}
