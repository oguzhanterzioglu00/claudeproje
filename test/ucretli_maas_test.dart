import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/features/maas/domain/maas_parametreleri.dart';
import 'package:pusula/features/maas/domain/ucretli_maas_hesaplayici.dart';

void main() {
  const h = UcretliMaasHesaplayici();
  const p = MaasParametreleri.temmuzAralik2026;

  group('gelir vergisi tarifesi (GİB 2026, ücret gelirleri)', () {
    test('dilim sınırlarındaki toplam vergi resmî tarifeyle aynı', () {
      expect(p.gelirVergisiTarifesi(190000), closeTo(28500, 0.001));
      expect(p.gelirVergisiTarifesi(400000), closeTo(70500, 0.001));
      expect(p.gelirVergisiTarifesi(1500000), closeTo(367500, 0.001));
      expect(p.gelirVergisiTarifesi(5300000), closeTo(1697500, 0.001));
      expect(p.gelirVergisiTarifesi(6300000), closeTo(1697500 + 1000000 * 0.40, 0.001));
    });
  });

  group('UcretliMaasHesaplayici', () {
    test('asgari ücret: brüt 33.030 → net 28.075,50; her ayda aynı (vergi ve damga istisnada)', () {
      for (var ay = 1; ay <= 12; ay++) {
        final s = h.hesapla(33030, ay: ay);
        expect(s.sgkPayi, closeTo(4624.20, 0.001), reason: 'ay $ay');
        expect(s.issizlik, closeTo(330.30, 0.001));
        expect(s.gelirVergisi, closeTo(0, 0.01));
        expect(s.damgaVergisi, closeTo(0, 0.01));
        expect(s.net, closeTo(28075.50, 0.01), reason: 'ay $ay');
      }
    });

    test('50.000 brüt, ocak: elle hesaplanan değerlerle aynı', () {
      final s = h.hesapla(50000);
      expect(s.sgkPayi, closeTo(7000, 0.001));
      expect(s.issizlik, closeTo(500, 0.001));
      // (50.000 − 7.500) × %15 − asgari ücret gelir vergisi istisnası (28.075,50 × %15)
      expect(s.gelirVergisi, closeTo(42500 * 0.15 - 28075.5 * 0.15, 0.001));
      expect(s.damgaVergisi, closeTo(50000 * 0.00759 - 250.70, 0.001));
      expect(s.net, closeTo(50000 - 7000 - 500 - s.gelirVergisi - s.damgaVergisi, 0.001));
      expect(s.net, closeTo(40207.53, 0.01));
    });

    test('kümülatif vergi: yıl ilerledikçe dilim yükselir, aralıkta net ocaktakinden düşüktür', () {
      final ocak = h.hesapla(80000, ay: 1);
      final aralik = h.hesapla(80000, ay: 12);
      expect(aralik.gelirVergisi, greaterThan(ocak.gelirVergisi));
      expect(aralik.net, lessThan(ocak.net));
    });

    test('SGK üst sınırı: tavanın üstündeki kazançtan prim kesilmez', () {
      final s = h.hesapla(400000);
      expect(s.sgkMatrahi, closeTo(297270, 0.001));
      expect(s.sgkPayi, closeTo(297270 * 0.14, 0.001));
      expect(s.issizlik, closeTo(297270 * 0.01, 0.001));
    });

    test('brüt sıfır ya da negatifse her kalem sıfır; geçersiz ay hata verir', () {
      for (final b in [0.0, -5.0]) {
        final s = h.hesapla(b);
        expect([s.brut, s.sgkPayi, s.gelirVergisi, s.damgaVergisi, s.net], everyElement(0));
      }
      expect(() => h.hesapla(1000, ay: 13), throwsArgumentError);
    });

    test('kesinti toplamı brüt − net', () {
      final s = h.hesapla(60000, ay: 6);
      expect(s.kesintiToplami, closeTo(s.sgkPayi + s.issizlik + s.gelirVergisi + s.damgaVergisi, 0.001));
    });
  });
}
