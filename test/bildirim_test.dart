import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/ana_sayfa/bildirimler.dart';
import 'package:pusula/features/asistan/asistan_servisi.dart';
import 'package:pusula/features/becayis/data/ornek_veri.dart';
import 'package:pusula/features/haberler/haber_kaynagi.dart';
import 'package:pusula/features/ilanlar/ilan_kaynagi.dart';
import 'package:pusula/features/kabuk/pusula_kabugu.dart';
import 'package:pusula/features/maas/domain/memur_maas_hesaplayici.dart';
import 'package:pusula/features/profil/data/profil_deposu.dart';
import 'package:pusula/features/profil/data/profil_kaydi.dart';
import 'package:pusula/features/profil/domain/profil.dart';

import 'yardimci/yazilar.dart';

const _tam = Profil(
  ad: 'Ayşe',
  statu: Statu.memur657,
  kurumAdi: 'Sağlık Bakanlığı',
  sinif: 'Sağlık Hizmetleri',
  unvan: 'Hemşire',
  il: 'İzmir',
  maas: MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10),
);

void main() {
  setUpAll(pusulaYazilariniYukle);

  group('bildirimleriUret', () {
    test('becayiş kapalıyken becayiş bildirimi üretilmez', () {
      final b = bildirimleriUret(_tam, becayisYayinda: false, ikiliEslesme: 0, becayisAcik: false);
      expect(b.where((x) => x.baslik.contains('Becayiş')), isEmpty);
    });

    List<String> basliklar(Profil p, {bool yayinda = false, int eslesme = 0}) =>
        bildirimleriUret(p, becayisYayinda: yayinda, ikiliEslesme: eslesme).map((b) => b.baslik).toList();

    test('eksik profil: tamamlama önerisi, eksik alanlar açıklamada', () {
      const p = Profil(ad: 'A', statu: Statu.memur657, maas: MaasGirdisi(derece: 8, kademe: 3));
      final b = bildirimleriUret(p, becayisYayinda: false, ikiliEslesme: 0).single;
      expect(b.baslik, 'Becayiş için profilini tamamla');
      expect(b.aciklama, contains('Kurum'));
      expect(b.hedef, BildirimHedefi.profil);
    });

    test('tam profil, ilan yok → ilan ver; ilan var ve eşleşme var → eşleşme bildirimi', () {
      expect(basliklar(_tam), ['Becayiş ilanı ver']);
      expect(basliklar(_tam, yayinda: true), isEmpty);
      expect(basliklar(_tam, yayinda: true, eslesme: 2), ['2 yeni becayiş eşleşmesi']);
    });

    test('maaş girdisi yoksa memura maaş hesaplama önerilir', () {
      const maassiz = Profil(
        ad: 'Ayşe',
        statu: Statu.memur657,
        kurumAdi: 'Sağlık Bakanlığı',
        sinif: 'Sağlık Hizmetleri',
        unvan: 'Hemşire',
        il: 'İzmir',
      );
      expect(basliklar(maassiz, yayinda: true), ['Maaşını hesapla']);
    });

    test('sözleşmeli ve işçiye brüt ücret girmesi önerilir; girince öneri kalkar', () {
      final ilk = bildirimleriUret(
        const Profil(ad: 'A', statu: Statu.sozlesmeli),
        becayisYayinda: false,
        ikiliEslesme: 0,
      );
      expect(ilk.single.baslik, 'Maaşını hesapla');
      expect(ilk.single.aciklama, contains('brüt ücretini'));
      expect(
        bildirimleriUret(
          const Profil(ad: 'A', statu: Statu.isci, brutUcret: 40000),
          becayisYayinda: false,
          ikiliEslesme: 0,
        ),
        isEmpty,
      );
    });

    test('memur olmayan ve aday memura becayiş bildirimi gitmez', () {
      expect(basliklar(const Profil(ad: 'A', statu: Statu.isci, brutUcret: 40000)), isEmpty);
      expect(basliklar(_tam.kopya(adayMemur: true), yayinda: true, eslesme: 3), isEmpty);
    });
  });

  Future<void> ac(WidgetTester tester, Profil profil, {int sekme = 0}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = ProfilDeposu(BellekProfilKaydi(profil));
    await depo.yukle();
    await tester.pumpWidget(
      MaterialApp(
        theme: pusulaTema(),
        home: PusulaKabugu(
          profilDeposu: depo,
          bugun: DateTime(2026, 9, 29),
          haberOtomatik: false,
          baslangicSekmesi: sekme,
          asistan: const YerelMevzuatAsistani(sure: Duration(milliseconds: 10)),
          ilanKaynagi: OrnekIlanKaynagi(sure: const Duration(milliseconds: 10), bugun: DateTime(2026, 9, 29)),
          haberKaynagi: OrnekHaberKaynagi(sure: const Duration(milliseconds: 10), bugun: DateTime(2026, 9, 29)),
          becayisDeposuUret: BecayisOrnekVeri.depoProfilden,
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  testWidgets('bildirim düğmesi listeyi açar; bildirime dokunmak ilgili yere götürür', (tester) async {
    await ac(tester, _tam);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Bildirimler')));
    await tester.pumpAndSettle();
    expect(find.text('Bildirimler'), findsWidgets);
    expect(find.text('Becayiş ilanı ver'), findsOneWidget);

    await tester.tap(find.text('Becayiş ilanı ver'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Becayiş'), findsWidgets);
    expect(find.text('İlan ver'), findsWidgets, reason: 'Becayiş sekmesi açıldı');
  });

  testWidgets('bildirim yoksa boş durum gösterilir', (tester) async {
    await ac(tester, const Profil(ad: 'Can', statu: Statu.isci, brutUcret: 40000));
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Bildirimler')));
    await tester.pumpAndSettle();
    expect(find.text('Yeni bildirim yok'), findsOneWidget);
  });

  testWidgets('Yol haritan → Detay maaş sekmesine götürür', (tester) async {
    await ac(tester, _tam);
    await tester.tap(find.bySemanticsLabel('Yol haritan, detay'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Maaş hesapla'), findsOneWidget);
  });
}
