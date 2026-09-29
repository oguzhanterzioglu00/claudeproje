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

  Future<ProfilDeposu> ac(WidgetTester tester, {Profil? mevcut, VoidCallback? onBitti}) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = ProfilDeposu(BellekProfilKaydi(mevcut));
    await depo.yukle();
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      home: ProfilSayfasi(depo: depo, onBitti: onBitti ?? () {}),
    ));
    await tester.pumpAndSettle();
    return depo;
  }

  testWidgets('kurum, il ve sınıf aranarak seçilir ve kaydedilir', (tester) async {
    final depo = await ac(tester, mevcut: const Profil(ad: 'Ayşe', statu: Statu.memur657));

    // Arama Türkçe harf farkını önemsemez.
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

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    final p = depo.profil!;
    expect((p.kurumAdi, p.il, p.sinif), ('Sağlık Bakanlığı', 'İzmir', 'Sağlık Hizmetleri'));
    expect(p.kurumKimligi, 'saglik-bakanligi');
  });

  testWidgets('geçersiz e-posta hata gösterir; kayıt düğmesi çalışmaz', (tester) async {
    final depo = await ac(tester, mevcut: const Profil(ad: 'Ayşe', statu: Statu.memur657));
    await tester.enterText(find.byType(TextField).last, 'yanlis-adres');
    await tester.pump();
    expect(find.text('Geçerli bir e-posta adresi gir'), findsOneWidget);
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(depo.profil!.kurumsalEposta, isEmpty);
  });

  testWidgets('aday memur seçimi kaydedilir; memur dışı statüye geçince sınıf ve sicil temizlenir', (tester) async {
    final depo = await ac(
      tester,
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
      mevcut: const Profil(ad: 'Ayşe', statu: Statu.diger),
    );
    await tester.ensureVisible(find.text('Profil bilgilerimi sil'));
    await tester.tap(find.text('Profil bilgilerimi sil'));
    await tester.pumpAndSettle();
    expect(find.text('Profil silinsin mi?'), findsOneWidget);

    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(depo.profil, isNotNull);

    await tester.tap(find.text('Profil bilgilerimi sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(depo.profil, isNull);
  });
}
