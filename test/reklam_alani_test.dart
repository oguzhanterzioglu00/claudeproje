import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/reklam/reklam_alani.dart';

void main() {
  testWidgets('boş reklam alanı WhatsApp başvuru bağlantısını açar', (
    tester,
  ) async {
    Uri? acilan;
    await tester.pumpWidget(
      MaterialApp(
        theme: pusulaTema(),
        home: Scaffold(
          body: ReklamAlani(
            baglantiAcici: (adres) async {
              acilan = adres;
              return true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Buraya reklam verebilirsiniz'), findsOneWidget);
    await tester.tap(find.text('Buraya reklam verebilirsiniz'));
    await tester.pump();
    expect(acilan?.host, 'wa.me');
    expect(acilan?.path, '/905529316903');
    expect(
      acilan?.queryParameters['text'],
      contains('reklam vermek istiyorum'),
    );
  });
}
