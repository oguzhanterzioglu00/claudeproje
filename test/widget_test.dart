import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/main.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  testWidgets('uygulama açılır ve Becayiş panelini gösterir', (tester) async {
    await tester.pumpWidget(const PusulaUygulamasi());
    await tester.pumpAndSettle();
    expect(find.text('Becayiş'), findsOneWidget);
    expect(find.text('Hemşire'), findsOneWidget);
  });
}
