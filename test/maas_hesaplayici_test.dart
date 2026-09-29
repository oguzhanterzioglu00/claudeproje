import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/features/maas/domain/gosterge_tablosu.dart';
import 'package:pusula/features/maas/domain/maas_parametreleri.dart';
import 'package:pusula/features/maas/domain/memur_maas_hesaplayici.dart';

/// Beklenen değerler, motordan bağımsız bir Python betiğiyle aynı formüller
/// (docs/maas-spec.md) uygulanarak elde edildi.
void main() {
  const h = MemurMaasHesaplayici();

  Matcher yakin(double x) => closeTo(x, 0.01);

  group('gösterge tablosu (657 md. 154, I sayılı cetvel)', () {
    test('kademe sayıları: 1. derece 4, 2. derece 6, 3. derece 8, diğerleri 9', () {
      expect(GostergeTablosu.kademeSayisi(1), 4);
      expect(GostergeTablosu.kademeSayisi(2), 6);
      expect(GostergeTablosu.kademeSayisi(3), 8);
      for (var d = 4; d <= 15; d++) {
        expect(GostergeTablosu.kademeSayisi(d), 9, reason: '$d. derece');
      }
    });

    test('bilinen değerler', () {
      expect(GostergeTablosu.gosterge(1, 1), 1320);
      expect(GostergeTablosu.gosterge(1, 4), 1500);
      expect(GostergeTablosu.gosterge(8, 3), 690);
      expect(GostergeTablosu.gosterge(15, 9), 540);
      expect(GostergeTablosu.gosterge(15, 1), 500);
    });

    test('her satırda gösterge kademe arttıkça azalmaz; derece arttıkça (kademe 1) azalır', () {
      for (var d = 1; d <= 15; d++) {
        for (var k = 2; k <= GostergeTablosu.kademeSayisi(d); k++) {
          expect(GostergeTablosu.gosterge(d, k) >= GostergeTablosu.gosterge(d, k - 1), isTrue);
        }
      }
      for (var d = 2; d <= 15; d++) {
        expect(GostergeTablosu.gosterge(d, 1) < GostergeTablosu.gosterge(d - 1, 1), isTrue);
      }
    });

    test('geçersiz derece/kademe hata verir; sınırlama en yakın kademeyi döndürür', () {
      expect(() => GostergeTablosu.gosterge(0, 1), throwsArgumentError);
      expect(() => GostergeTablosu.gosterge(16, 1), throwsArgumentError);
      expect(() => GostergeTablosu.gosterge(1, 5), throwsArgumentError);
      expect(GostergeTablosu.kademeSinirla(1, 9), 4);
      expect(GostergeTablosu.kademeSinirla(3, 0), 1);
      expect(GostergeTablosu.kademeSinirla(8, 5), 5);
    });
  });

  group('maaş hesabı (Temmuz–Aralık 2026 katsayıları)', () {
    test('yalnızca derece/kademe/kıdem: taban aylık baskın, Ocak ayında vergi çıkmaz', () {
      final s = h.hesapla(const MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10), ay: 1);
      expect(s.gostergeAyligi, yakin(1087.1033));
      expect(s.tabanAylik, yakin(25794.915));
      expect(s.kidemAyligi, yakin(393.878));
      expect(s.brut, yakin(27275.8963));
      expect(s.emeklilikPayi, yakin(2454.8307));
      expect(s.gss, yakin(1363.7948));
      expect(s.gelirVergisi, 0, reason: 'asgari ücret istisnası vergiyi sıfırlar');
      expect(s.damgaVergisi, 0);
      expect(s.net, yakin(23457.2708));
    });

    test('ek gösterge, yan ödeme ve tazminatla: Temmuz', () {
      final s = h.hesapla(
        const MaasGirdisi(
          derece: 5, kademe: 4, hizmetYili: 15,
          ekGosterge: 2200, yanOdemePuani: 1000, ozelHizmetTazminatiOrani: 0.5,
        ),
        ay: 7,
      );
      expect(s.ekGostergeAyligi, yakin(3466.1264));
      expect(s.yanOdeme, yakin(499.649));
      expect(s.ozelHizmetTazminati, yakin(2453.8599));
      expect(s.brut, yakin(34246.9608));
      expect(s.gelirVergisi, yakin(723.4186));
      expect(s.damgaVergisi, yakin(9.2344));
      expect(s.net, yakin(28789.6841));
    });

    test('aynı girdi Aralık ayında: kümülatif vergi ve istisna değişir', () {
      final s = h.hesapla(
        const MaasGirdisi(
          derece: 5, kademe: 4, hizmetYili: 15,
          ekGosterge: 2200, yanOdemePuani: 1000, ozelHizmetTazminatiOrani: 0.5,
        ),
        ay: 12,
      );
      expect(s.gelirVergisi, yakin(289.3674));
      expect(s.net, yakin(29223.7353));
    });

    test('kıdem yılı 25 ile sınırlanır', () {
      final a = h.hesapla(const MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 25));
      final b = h.hesapla(const MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 40));
      expect(b.kidemAyligi, a.kidemAyligi);
    });

    test('diğer brüt ödemeler SGK matrahına girmez ama brüt ve vergiye girer', () {
      final ilk = h.hesapla(const MaasGirdisi(derece: 8, kademe: 3), ay: 7);
      final ek = h.hesapla(const MaasGirdisi(derece: 8, kademe: 3, digerBrut: 5000), ay: 7);
      expect(ek.brut - ilk.brut, yakin(5000));
      expect(ek.emeklilikPayi, yakin(ilk.emeklilikPayi));
      expect(ek.gelirVergisi > ilk.gelirVergisi, isTrue);
    });

    test('net her zaman brütten küçük, kesinti toplamı bileşenlerin toplamına eşit', () {
      final s = h.hesapla(
        const MaasGirdisi(derece: 3, kademe: 8, hizmetYili: 20, ekGosterge: 5000, ozelHizmetTazminatiOrani: 0.9),
        ay: 9,
      );
      expect(s.net < s.brut, isTrue);
      expect(s.kesintiToplami, yakin(s.emeklilikPayi + s.gss + s.gelirVergisi + s.damgaVergisi));
    });

    test('geçersiz ay hata verir', () {
      expect(() => h.hesapla(const MaasGirdisi(derece: 8, kademe: 3), ay: 0), throwsArgumentError);
      expect(() => h.hesapla(const MaasGirdisi(derece: 8, kademe: 3), ay: 13), throwsArgumentError);
    });

    test('parametreler değişince sonuç değişir (motor sabit kodlanmamış)', () {
      const eski = MaasParametreleri(
        donem: 'test',
        kaynak: 'test',
        aylikKatsayi: 1.0,
        tabanAylikKatsayi: 20.0,
        yanOdemeKatsayi: 0.4,
        gelirVergisiDilimleri: [(double.infinity, 0.15)],
        asgariUcretBrut: 30000,
        asgariUcretDamgaIstisnasi: 200,
      );
      final s = const MemurMaasHesaplayici(eski).hesapla(const MaasGirdisi(derece: 15, kademe: 1));
      expect(s.tabanAylik, yakin(20000));
      expect(s.gostergeAyligi, yakin(500));
    });
  });
}
