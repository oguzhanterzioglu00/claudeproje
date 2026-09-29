import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/features/profil/data/profil_kaydi.dart';
import 'package:pusula/features/profil/domain/profil.dart';
import 'package:pusula/main.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  testWidgets('profil yoksa ilk kurulum açılır', (tester) async {
    await tester.pumpWidget(PusulaUygulamasi(profilKaydi: BellekProfilKaydi()));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Kamu Pusulası'), findsOneWidget);
    expect(find.text('Atla'), findsOneWidget);
  });

  testWidgets('profil varsa ana sayfa açılır', (tester) async {
    await tester.pumpWidget(PusulaUygulamasi(
      profilKaydi: BellekProfilKaydi(const Profil(ad: 'Ayşe', statu: Statu.memur657)),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Kamu Pusulası'), findsOneWidget);
    expect(find.text('Atla'), findsNothing);
  });
}
