import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/main.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  testWidgets('uygulama ana sayfada açılır', (tester) async {
    await tester.pumpWidget(const PusulaUygulamasi());
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Kamu Pusulası'), findsOneWidget);
    expect(find.text('Yol haritan'), findsOneWidget);
  });
}
