import 'package:flutter_test/flutter_test.dart';
import 'package:kadro/main.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(kadroYazilariniYukle);

  testWidgets('uygulama açılır', (tester) async {
    await tester.pumpWidget(const KadroUygulamasi());
    expect(find.text('Kadro'), findsOneWidget);
  });
}
