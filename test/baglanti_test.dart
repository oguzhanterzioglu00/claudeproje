import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/core/baglanti.dart';
import 'package:pusula/core/tema.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  Future<BuildContext> ac(WidgetTester tester) async {
    late BuildContext baglam;
    await tester.pumpWidget(MaterialApp(
      theme: pusulaTema(),
      home: Scaffold(body: Builder(builder: (c) {
        baglam = c;
        return const SizedBox();
      })),
    ));
    return baglam;
  }

  testWidgets('https adresi açıcıya verilir, mesaj çıkmaz', (tester) async {
    final baglam = await ac(tester);
    final acilan = <Uri>[];
    await baglantiAc(baglam, Uri.parse('https://www.resmigazete.gov.tr'), acici: (u) async {
      acilan.add(u);
      return true;
    });
    await tester.pump();
    expect(acilan.single.host, 'www.resmigazete.gov.tr');
    expect(find.textContaining('Bağlantı açılamadı'), findsNothing);
  });

  testWidgets('https dışı adresler ve boş adres açılmaz, kullanıcıya bildirilir', (tester) async {
    final baglam = await ac(tester);
    var cagri = 0;
    Future<bool> acici(Uri u) async {
      cagri++;
      return true;
    }

    for (final adres in [Uri.parse('http://ornek.com'), Uri.parse('javascript:alert(1)'), Uri.parse('tel:112'), null]) {
      await baglantiAc(baglam, adres, acici: acici);
    }
    await tester.pump();
    expect(cagri, 0);
    expect(find.textContaining('Bağlantı açılamadı'), findsOneWidget);
  });

  testWidgets('açıcı başarısız olur ya da hata fırlatırsa mesaj gösterilir', (tester) async {
    final baglam = await ac(tester);
    await baglantiAc(baglam, Uri.parse('https://ornek.gov.tr'), acici: (_) async => false);
    await tester.pump();
    expect(find.textContaining('Bağlantı açılamadı'), findsOneWidget);

    ScaffoldMessenger.of(baglam).clearSnackBars();
    await tester.pump();
    await baglantiAc(baglam, Uri.parse('https://ornek.gov.tr'), acici: (_) async => throw Exception('yok'));
    await tester.pump();
    expect(find.textContaining('Bağlantı açılamadı'), findsOneWidget);
  });
}
