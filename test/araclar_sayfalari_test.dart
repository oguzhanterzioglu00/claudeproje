import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pusula/core/metin.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/araclar/domain/zam_senaryosu.dart';
import 'package:pusula/features/araclar/presentation/derece_tablosu_sayfasi.dart';
import 'package:pusula/features/araclar/presentation/izin_sayfasi.dart';
import 'package:pusula/features/araclar/presentation/zam_sayfasi.dart';
import 'package:pusula/features/asistan/asistan_servisi.dart';
import 'package:pusula/features/haberler/haber_kaynagi.dart';
import 'package:pusula/features/ilanlar/ilan_kaynagi.dart';
import 'package:pusula/features/kabuk/pusula_kabugu.dart';
import 'package:pusula/features/maas/domain/memur_maas_hesaplayici.dart';
import 'package:pusula/features/profil/data/profil_deposu.dart';
import 'package:pusula/features/profil/data/profil_kaydi.dart';
import 'package:pusula/features/profil/domain/profil.dart';

import 'yardimci/yazilar.dart';

Future<void> _ac(WidgetTester tester, Widget sayfa) async {
  tester.view.physicalSize = const Size(390, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: pusulaTema(), home: sayfa));
  await tester.pumpAndSettle();
}

/// Sonuç kartındaki büyük değer (aynı yazı satırlarda da geçebildiği için boyutla ayırt edilir).
Finder _buyuk(String metin) =>
    find.byWidgetPredicate((w) => w is Text && w.data == metin && (w.style?.fontSize ?? 0) >= 30);

void main() {
  setUpAll(pusulaYazilariniYukle);

  group('İzin hakkı sayfası', () {
    testWidgets('varsayılan: 5 yıl → 20 gün; artırınca 10 yıldan sonra 30 gün', (tester) async {
      await _ac(tester, const IzinSayfasi(baslangicHizmetYili: 10));
      expect(_buyuk('20 gün'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Hizmet yılını artır'));
      await tester.pumpAndSettle();
      expect(_buyuk('30 gün'), findsOneWidget);
    });

    testWidgets('devreden ve kullanılan gün kalanı günceller; fazla kullanımda uyarı', (tester) async {
      await _ac(tester, const IzinSayfasi(baslangicHizmetYili: 5));
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.bySemanticsLabel('Geçen yıldan kalanı artır'));
      }
      await tester.pump();
      expect(_buyuk('26 gün'), findsOneWidget); // 20 + 6
      for (var i = 0; i < 30; i++) {
        await tester.tap(find.bySemanticsLabel('Kullanılanı artır'));
      }
      await tester.pumpAndSettle();
      expect(find.textContaining('fazla kullanmış görünüyorsun'), findsOneWidget);
    });

    testWidgets('devreden, geçen yıl hakkını aşamaz (10. yılda en çok 20)', (tester) async {
      await _ac(tester, const IzinSayfasi(baslangicHizmetYili: 11));
      for (var i = 0; i < 30; i++) {
        await tester.tap(find.bySemanticsLabel('Geçen yıldan kalanı artır'));
      }
      await tester.pumpAndSettle();
      expect(_buyuk('50 gün'), findsOneWidget, reason: '30 + en çok 20 devreden');
    });

    testWidgets('hizmet 1 yıldan azsa kanundaki süreler uygulanmaz denir', (tester) async {
      await _ac(tester, const IzinSayfasi(baslangicHizmetYili: 0));
      expect(find.textContaining('hizmeti 1 yıldan fazla olanlar için'), findsOneWidget);
    });

    testWidgets('kanun maddeleri ve teyit uyarısı görünür', (tester) async {
      await _ac(tester, const IzinSayfasi());
      await tester.scrollUntilVisible(find.textContaining('657 sayılı Kanun md. 102'), 200);
      expect(find.textContaining('Md. 103'), findsOneWidget);
      expect(find.textContaining('personel biriminden teyit et'), findsOneWidget);
    });
  });

  group('Zam senaryosu sayfası', () {
    const girdi = MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10);

    testWidgets('yeni net maaş ve fark gösterilir; hazır oran seçilince güncellenir', (tester) async {
      await _ac(tester, const ZamSayfasi(girdi: girdi));
      expect(find.text('%20'), findsWidgets);
      final s20 = _yeniNetMetni(girdi, 0.20);
      expect(find.text(s20), findsWidgets);

      await tester.tap(find.bySemanticsLabel('Yüzde 30 zam'));
      await tester.pumpAndSettle();
      expect(find.text(_yeniNetMetni(girdi, 0.30)), findsWidgets);
      expect(find.text(s20), findsNothing);
    });

    testWidgets('profilde bordro yoksa örnek derece uyarısı, varsa profil bilgisi notu', (tester) async {
      await _ac(tester, const ZamSayfasi(girdi: girdi));
      expect(find.textContaining('örnek bir derece ve kademeyle'), findsOneWidget);
      await _ac(tester, const ZamSayfasi(girdi: girdi, profildenMi: true));
      expect(find.textContaining('profilindeki derece/kademe'), findsOneWidget);
    });

    testWidgets('tahmin uyarısı görünür', (tester) async {
      await _ac(tester, const ZamSayfasi(girdi: girdi));
      await tester.scrollUntilVisible(find.textContaining('Bu bir tahmindir'), 200);
      expect(find.textContaining('toplu sözleşme'), findsOneWidget);
    });
  });

  group('Derece tablosu sayfası', () {
    testWidgets('seçili derecenin tüm kademeleri listelenir; senin kademen vurgulanır', (tester) async {
      final tutamak = tester.ensureSemantics();
      await _ac(tester, const DereceTablosuSayfasi(derece: 8, kademe: 3));
      expect(find.text('Temel aylık (brüt)'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Derece 8, kademe 3: .*senin kademen')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Derece 8, kademe [1-9]:')), findsWidgets);

      await tester.tap(find.bySemanticsLabel('Derece 1'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp(r'^Derece 1, kademe 1:')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'senin kademen')), findsNothing, reason: 'başka derece seçilince vurgu yok');
      tutamak.dispose();
    });

    testWidgets('kapsam notu ek kalemlerin dahil olmadığını söyler', (tester) async {
      await _ac(tester, const DereceTablosuSayfasi());
      await tester.scrollUntilVisible(find.textContaining('dahil değildir'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('Temmuz–Aralık 2026'), findsOneWidget);
    });
  });

  group('Ana sayfada Araçlar bölümü', () {
    Future<void> kabuk(WidgetTester tester, Profil p) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final depo = ProfilDeposu(BellekProfilKaydi(p));
      await depo.yukle();
      await tester.pumpWidget(MaterialApp(
        theme: pusulaTema(),
        home: PusulaKabugu(
          profilDeposu: depo,
          bugun: DateTime(2026, 9, 29),
          haberOtomatik: false,
          asistan: const YerelMevzuatAsistani(sure: Duration(milliseconds: 10)),
          ilanKaynagi: OrnekIlanKaynagi(sure: const Duration(milliseconds: 10), bugun: DateTime(2026, 9, 29)),
          haberKaynagi: OrnekHaberKaynagi(sure: const Duration(milliseconds: 10), bugun: DateTime(2026, 9, 29)),
        ),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    testWidgets('memur için üç araç görünür ve sayfalarını açar (profildeki bordro kullanılır)', (tester) async {
      await kabuk(tester, const Profil(ad: 'A', statu: Statu.memur657, maas: MaasGirdisi(derece: 6, kademe: 4, hizmetYili: 12)));
      expect(find.text('Araçlar'), findsOneWidget);

      await tester.tap(find.text('İzin hakkı'));
      await tester.pumpAndSettle();
      expect(_buyuk('30 gün'), findsOneWidget, reason: '12 yıl hizmet → 30 gün');
      await tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zam senaryosu'));
      await tester.pumpAndSettle();
      expect(find.textContaining('profilindeki derece/kademe'), findsOneWidget);
      await tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Derece tablosu'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp(r'Derece 6, kademe 4: .*senin kademen')), findsOneWidget);
    });

    testWidgets('memur olmayan statüde Araçlar bölümü görünmez', (tester) async {
      await kabuk(tester, const Profil(ad: 'A', statu: Statu.isci));
      expect(find.text('Araçlar'), findsNothing);
    });
  });
}

/// Zam sayfasının gösterdiği yeni net maaş metni (aynı motorla).
String _yeniNetMetni(MaasGirdisi g, double oran) => liraTam(ZamSenaryosu.hesapla(g, oran: oran).yeni.net.round());
