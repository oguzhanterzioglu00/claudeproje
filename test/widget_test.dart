import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kadro/main.dart';

void main() {
  setUpAll(() {
    // Testlerde ağdan yazı tipi çekilmez.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('uygulama açılır', (tester) async {
    await tester.pumpWidget(const KadroUygulamasi());
    expect(find.text('Kadro'), findsOneWidget);
  });
}
