import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pusula/core/depolama.dart';
import 'package:pusula/core/tema.dart';
import 'package:pusula/features/hesap/data/oturum_deposu.dart';
import 'package:pusula/features/hesap/data/yerel_kimlik_servisi.dart';
import 'package:pusula/features/hesap/domain/hesap.dart';
import 'package:pusula/features/hesap/presentation/giris_sayfasi.dart';

import 'yardimci/yazilar.dart';

void main() {
  setUpAll(pusulaYazilariniYukle);

  Future<OturumDeposu> ac(WidgetTester tester, {bool apple = true, Size boyut = const Size(390, 844)}) async {
    tester.view.physicalSize = boyut;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final oturum = OturumDeposu(YerelKimlikServisi(depolama: BellekDepolama(), tur: 8));
    await oturum.yukle();
    await tester.pumpWidget(MaterialApp(theme: pusulaTema(), home: GirisSayfasi(oturum: oturum, appleGoster: apple)));
    await tester.pumpAndSettle();
    return oturum;
  }

  /// Aynı yazı hem sekmede hem düğmede geçebilir; düğme ağaçta sonra gelir.
  bool aktif(WidgetTester tester, String etiket) {
    final dugme = find.ancestor(of: find.text(etiket).last, matching: find.byType(InkWell)).first;
    return tester.widget<InkWell>(dugme).onTap != null;
  }

  Future<void> yaz(WidgetTester tester, String eposta, String sifre) async {
    await tester.enterText(find.byType(TextField).first, eposta);
    await tester.enterText(find.byType(TextField).last, sifre);
    await tester.pump();
  }

  Future<void> kayitModu(WidgetTester tester) async {
    await tester.tap(find.text('Hesap oluştur').first);
    await tester.pumpAndSettle();
  }

  testWidgets('giriş modunda düğme, geçerli e-posta ve dolu şifre olmadan pasif', (tester) async {
    await ac(tester);
    expect(aktif(tester, 'Giriş yap'), isFalse);
    await yaz(tester, 'yanlis', 'sifre1234');
    expect(aktif(tester, 'Giriş yap'), isFalse);
    await yaz(tester, 'a@b.co', '');
    expect(aktif(tester, 'Giriş yap'), isFalse);
    await yaz(tester, 'a@b.co', 'x');
    expect(aktif(tester, 'Giriş yap'), isTrue);
    expect(find.text('Şifremi unuttum'), findsOneWidget);
  });

  testWidgets('kayıt modunda şifre kuralları canlı işaretlenir ve kurallar sağlanınca düğme açılır', (tester) async {
    final tutamak = tester.ensureSemantics();
    await ac(tester);
    await kayitModu(tester);
    expect(find.text('Şifremi unuttum'), findsNothing);
    expect(find.bySemanticsLabel('En az 8 karakter'), findsOneWidget);

    await yaz(tester, 'a@b.co', 'abc');
    expect(find.bySemanticsLabel('Harf, sağlandı'), findsOneWidget);
    expect(find.bySemanticsLabel('Rakam'), findsOneWidget);
    expect(aktif(tester, 'Hesap oluştur'), isFalse);

    await yaz(tester, 'a@b.co', 'abcdefg1');
    expect(find.bySemanticsLabel('Rakam, sağlandı'), findsOneWidget);
    expect(find.bySemanticsLabel('En az 8 karakter, sağlandı'), findsOneWidget);
    expect(aktif(tester, 'Hesap oluştur'), isTrue);
    tutamak.dispose();
  });

  testWidgets('kayıt olunca oturum açılır; aynı e-posta ile tekrar kayıt hata gösterir', (tester) async {
    final oturum = await ac(tester);
    await kayitModu(tester);
    await yaz(tester, 'a@b.co', 'sifre1234');
    await tester.tap(find.widgetWithText(InkWell, 'Hesap oluştur').last);
    await tester.pumpAndSettle();
    expect(oturum.hesap?.eposta, 'a@b.co');

    await oturum.cikisYap();
    await tester.pumpAndSettle();
    await kayitModu(tester);
    await yaz(tester, 'A@B.co', 'sifre1234');
    await tester.tap(find.widgetWithText(InkWell, 'Hesap oluştur').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('zaten bir hesap var'), findsOneWidget);
    expect(oturum.hesap, isNull);
  });

  testWidgets('yanlış şifre "E-posta veya şifre hatalı" der; mod değişince hata temizlenir', (tester) async {
    final oturum = await ac(tester);
    await oturum.kayitOl('a@b.co', 'sifre1234');
    await oturum.cikisYap();
    await tester.pumpAndSettle();

    await yaz(tester, 'a@b.co', 'yanlis1234');
    await tester.tap(find.widgetWithText(InkWell, 'Giriş yap').last);
    await tester.pumpAndSettle();
    expect(find.text('E-posta veya şifre hatalı'), findsOneWidget);

    await kayitModu(tester);
    expect(find.text('E-posta veya şifre hatalı'), findsNothing);
  });

  testWidgets('doğru şifreyle giriş yapılır', (tester) async {
    final oturum = await ac(tester);
    await oturum.kayitOl('a@b.co', 'sifre1234');
    await oturum.cikisYap();
    await tester.pumpAndSettle();
    await yaz(tester, 'a@b.co', 'sifre1234');
    await tester.tap(find.widgetWithText(InkWell, 'Giriş yap').last);
    await tester.pumpAndSettle();
    expect(oturum.hesap?.eposta, 'a@b.co');
  });

  testWidgets('şifre göster/gizle düğmesi alanı açar', (tester) async {
    await ac(tester);
    EditableText alan() => tester.widget<EditableText>(find.byType(EditableText).last);
    expect(alan().obscureText, isTrue);
    await tester.tap(find.bySemanticsLabel('Şifreyi göster'));
    await tester.pump();
    expect(alan().obscureText, isFalse);
    expect(find.bySemanticsLabel('Şifreyi gizle'), findsOneWidget);
  });

  testWidgets('Google ile devam et örnek olduğunu açıklar; onaylanmadan giriş yapılmaz', (tester) async {
    final oturum = await ac(tester);
    await tester.tap(find.text('Google ile devam et'));
    await tester.pumpAndSettle();
    expect(find.textContaining('gerçek Google girişi henüz bağlı değil'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(oturum.hesap, isNull);

    await tester.tap(find.text('Google ile devam et'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Örnek hesapla devam et'));
    await tester.pumpAndSettle();
    expect(oturum.hesap?.saglayici, GirisSaglayici.google);
  });

  testWidgets('Apple ile devam et ve Apple düğmesini gizleme', (tester) async {
    final oturum = await ac(tester);
    await tester.tap(find.text('Apple ile devam et'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Örnek hesapla devam et'));
    await tester.pumpAndSettle();
    expect(oturum.hesap?.saglayici, GirisSaglayici.apple);
  });

  testWidgets('şifremi unuttum: geçersiz e-posta düğmeyi kapatır; geçerliyse bilgilendirir', (tester) async {
    await ac(tester);
    await tester.tap(find.text('Şifremi unuttum'));
    await tester.pumpAndSettle();
    expect(find.text('Şifreni sıfırla'), findsOneWidget);
    expect(aktif(tester, 'Bağlantı gönder'), isFalse);

    await tester.enterText(find.byType(TextField).last, 'a@b.co');
    await tester.pump();
    expect(aktif(tester, 'Bağlantı gönder'), isTrue);
    await tester.tap(find.text('Bağlantı gönder'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bu e-posta ile kayıtlı bir hesap varsa'), findsOneWidget);
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(find.text('Şifreni sıfırla'), findsNothing);
  });

  testWidgets('küçük ekranda giriş ekranı taşmaz', (tester) async {
    await ac(tester, boyut: const Size(320, 568));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Hesap oluştur').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Google ile devam et'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Apple ile devam et'), findsOneWidget);
  });

  testWidgets('Kullanım Koşulları ve Aydınlatma Metni bağlantıları taslak metni açar', (tester) async {
    await ac(tester);
    await tester.scrollUntilVisible(find.text('Kullanım Koşulları'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Kullanım Koşulları'));
    await tester.pumpAndSettle();
    expect(find.textContaining('TASLAK'), findsOneWidget);
    expect(find.textContaining('1. Hizmetin tanımı'), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aydınlatma Metni'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1. Veri sorumlusu'), findsOneWidget);
  });
}
