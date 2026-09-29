import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/haberler/haber_kaynagi.dart';
import 'package:pusula/features/kabuk/pusula_kabugu.dart';
import 'package:pusula/features/profil/data/profil_deposu.dart';
import 'package:pusula/features/profil/data/profil_kaydi.dart';
import 'package:pusula/features/profil/domain/profil.dart';

import 'yardimci/yazilar.dart';

/// Ekran okuyucu kullanıcıları düğmeleri semantik "dokun" eylemiyle çalıştırır;
/// `excludeSemantics` kullanan özel düğmelerin bu eylemi taşıdığını doğrular.
void main() {
  setUpAll(pusulaYazilariniYukle);

  testWidgets('özel düğmeler ekran okuyucu için dokunma eylemi taşır', (tester) async {
    final tutamak = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final depo = ProfilDeposu(BellekProfilKaydi(const Profil(ad: 'Ayşe', statu: Statu.memur657)));
    await depo.yukle();
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      home: PusulaKabugu(
        profilDeposu: depo,
        bugun: DateTime(2026, 9, 29),
        haberKaynagi: OrnekHaberKaynagi(sure: const Duration(milliseconds: 10), bugun: DateTime(2026, 9, 29)),
      ),
    ));
    await tester.pumpAndSettle();

    for (final etiket in ['Maaş', 'Profilim', 'Gündem, tüm haberler']) {
      final veri = tester.getSemantics(find.bySemanticsLabel(etiket)).getSemanticsData();
      expect(veri.hasAction(SemanticsAction.tap), isTrue, reason: etiket);
    }
    tutamak.dispose();
  });
}
