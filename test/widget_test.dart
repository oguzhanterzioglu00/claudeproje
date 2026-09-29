import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/main.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  testWidgets('uygulama açılır', (tester) async {
    await tester.pumpWidget(const PusulaUygulamasi());
    expect(find.text('Kamu Pusulası'), findsOneWidget);
  });
}
