import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/profil/data/profil_deposu.dart';
import 'package:pusula/features/profil/data/profil_kaydi.dart';
import 'package:pusula/features/profil/domain/profil.dart';
import 'package:pusula/features/profil/presentation/ilk_kurulum_sayfasi.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  Future<ProfilDeposu> ac(WidgetTester tester, {Size boyut = const Size(390, 844)}) async {
    tester.view.physicalSize = boyut;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = ProfilDeposu(BellekProfilKaydi());
    await depo.yukle();
    await tester.pumpWidget(MaterialApp(theme: pusulaTema(), home: IlkKurulumSayfasi(depo: depo)));
    await tester.pumpAndSettle();
    return depo;
  }

  bool dugmeAktif(WidgetTester tester, String etiket) {
    final dugme = find.ancestor(of: find.text(etiket), matching: find.byType(InkWell)).first;
    return tester.widget<InkWell>(dugme).onTap != null;
  }

  Future<void> karsilamadanGec(WidgetTester tester) async {
    await tester.tap(find.text('Başlayalım'));
    await tester.pumpAndSettle();
  }

  testWidgets('karşılama markayı, dört özelliği ve gizlilik güvencesini gösterir', (tester) async {
    await ac(tester);
    expect(find.text('Kamu Pusulası'), findsOneWidget);
    for (final t in ['Maaşını hesapla', 'Hakkım ne?', 'Becayiş', 'İlanlar ve gündem']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('Bilgilerin yalnızca bu cihazda saklanır'), findsOneWidget);
    expect(find.text('Başlayalım'), findsOneWidget);
  });

  testWidgets('küçük ekranda karşılama taşmaz ve düğme erişilebilir kalır', (tester) async {
    await ac(tester, boyut: const Size(320, 568));
    expect(tester.takeException(), isNull);
    expect(find.text('Başlayalım'), findsOneWidget);
  });

  testWidgets('memur akışı 3 adımdır; ad ve statü olmadan Devam pasif', (tester) async {
    final depo = await ac(tester);
    await karsilamadanGec(tester);
    expect(find.text('Seni tanıyalım'), findsOneWidget);
    expect(find.text('1 / 3'), findsNothing, reason: 'statü seçilmeden memur adımı sayısı bilinmez → 2');
    expect(find.text('1 / 2'), findsOneWidget);
    expect(dugmeAktif(tester, 'Devam'), isFalse);

    await tester.enterText(find.byType(TextField).first, 'Ayşe Yılmaz');
    await tester.pump();
    expect(dugmeAktif(tester, 'Devam'), isFalse, reason: 'statü seçilmedi');

    await tester.tap(find.text('657 sayılı Kanun memuru'));
    await tester.pump();
    expect(find.text('1 / 3'), findsOneWidget);
    expect(dugmeAktif(tester, 'Devam'), isTrue);

    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();
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
    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();

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
    expect((p.ad, p.statu, p.kurumAdi, p.il, p.sinif), ('Ayşe Yılmaz', Statu.memur657, 'Sağlık Bakanlığı', 'İzmir', 'Sağlık Hizmetleri'));
    expect((p.sicilNo, p.kurumsalEposta), ('123456', 'a@saglik.gov.tr'));
  });

  testWidgets('memur dışı akış 2 adımdır; sınıf ve sicil sorulmaz, son adımda Tamamla', (tester) async {
    final depo = await ac(tester);
    await karsilamadanGec(tester);
    await tester.enterText(find.byType(TextField).first, 'Can');
    await tester.tap(find.text('İşçi'));
    await tester.pump();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();
    expect(find.text('Hizmet sınıfı'), findsNothing);
    expect(find.text('Tamamla'), findsOneWidget);

    await tester.tap(find.text('Tamamla'));
    await tester.pumpAndSettle();
    expect(depo.profil!.statu, Statu.isci);
    expect(depo.profil!.sinif, isEmpty);
  });

  testWidgets('geri düğmesi ve sistem geri tuşu bir önceki adıma döner; ilk adımdan karşılamaya', (tester) async {
    await ac(tester);
    await karsilamadanGec(tester);
    await tester.enterText(find.byType(TextField).first, 'Can');
    await tester.tap(find.text('İşçi'));
    await tester.pump();
    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();
    expect(find.text('Görev bilgilerin'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Geri'));
    await tester.pumpAndSettle();
    expect(find.text('Seni tanıyalım'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, 'Can', reason: 'girdi korunur');

    await tester.tap(find.bySemanticsLabel('Geri'));
    await tester.pumpAndSettle();
    expect(find.text('Başlayalım'), findsOneWidget);
  });

  testWidgets('Şimdilik atla görev adımını geçer; sicil/e-posta adımında bilgi kaydetmeden bitirir', (tester) async {
    final depo = await ac(tester);
    await karsilamadanGec(tester);
    await tester.enterText(find.byType(TextField).first, 'Ayşe');
    await tester.tap(find.text('657 sayılı Kanun memuru'));
    await tester.pump();
    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Şimdilik atla'));
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
