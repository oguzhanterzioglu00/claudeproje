import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/telefon_cercevesi.dart';

void main() {
  Future<Size> boyutu(WidgetTester tester, Size ekran, {bool etkin = true}) async {
    tester.view.physicalSize = ekran;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Size? gorulen;
    await tester.pumpWidget(MaterialApp(
      home: TelefonCercevesi(
        etkin: etkin,
        child: Builder(builder: (c) {
          gorulen = MediaQuery.sizeOf(c);
          return const SizedBox.expand(key: Key('icerik'));
        }),
      ),
    ));
    return gorulen!;
  }

  testWidgets('geniş ekranda içerik telefon boyutuna sınırlanır ve öyle ölçülür', (tester) async {
    final s = await boyutu(tester, const Size(1400, 1000));
    expect(s, const Size(430, 900));
    expect(tester.getSize(find.byKey(const Key('icerik'))), const Size(430, 900));
  });

  testWidgets('kısa ekranda yükseklik ekrana uyar', (tester) async {
    final s = await boyutu(tester, const Size(1400, 700));
    expect(s.height, 668);
  });

  testWidgets('dar ekranda (telefon) hiçbir şey değişmez', (tester) async {
    final s = await boyutu(tester, const Size(390, 844));
    expect(s, const Size(390, 844));
  });

  testWidgets('etkin değilken (yerel derleme) geniş ekranda da değişmez', (tester) async {
    final s = await boyutu(tester, const Size(1400, 1000), etkin: false);
    expect(s, const Size(1400, 1000));
  });
}
