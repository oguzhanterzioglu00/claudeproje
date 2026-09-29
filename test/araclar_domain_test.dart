import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/features/araclar/domain/derece_tablosu.dart';
import 'package:pusula/features/araclar/domain/izin_hesaplayici.dart';
import 'package:pusula/features/araclar/domain/zam_senaryosu.dart';
import 'package:pusula/features/maas/domain/gosterge_tablosu.dart';
import 'package:pusula/features/maas/domain/maas_parametreleri.dart';
import 'package:pusula/features/maas/domain/memur_maas_hesaplayici.dart';

void main() {
  group('yıllık izin (657 md. 102-103)', () {
    test('süre: 1 yıldan az → yok; 1-10 yıl (10 dahil) → 20; 10 yıldan fazla → 30', () {
      expect(IzinHesaplayici.yillikHak(0), 0);
      expect(IzinHesaplayici.yillikHak(1), 20);
      expect(IzinHesaplayici.yillikHak(10), 20);
      expect(IzinHesaplayici.yillikHak(11), 30);
      expect(IzinHesaplayici.yillikHak(35), 30);
    });

    test('devreden gün geçen yılın hakkını aşamaz; negatif girdi 0 sayılır', () {
      // 11. yıl: bu yıl 30, ama geçen yıl (10. yıl) hakkı 20 → en çok 20 devredebilir.
      final s = IzinHesaplayici.hesapla(hizmetYili: 11, gecenYildanKalan: 30, buYilKullanilan: 5);
      expect((s.yillikHak, s.devreden, s.toplamHak, s.kalan), (30, 20, 50, 45));

      final n = IzinHesaplayici.hesapla(hizmetYili: 5, gecenYildanKalan: -3, buYilKullanilan: -1);
      expect((n.devreden, n.buYilKullanilan, n.kalan), (0, 0, 20));
    });

    test('ilk yıl ve ikinci yıl sınırları', () {
      final ilk = IzinHesaplayici.hesapla(hizmetYili: 0, gecenYildanKalan: 10, buYilKullanilan: 0);
      expect((ilk.yillikHak, ilk.devreden, ilk.hizmetYiliYetersiz), (0, 0, true));

      // 1. yıl: geçen yıl (0. yıl) hakkı yok → devreden 0.
      final bir = IzinHesaplayici.hesapla(hizmetYili: 1, gecenYildanKalan: 10, buYilKullanilan: 0);
      expect((bir.yillikHak, bir.devreden, bir.hizmetYiliYetersiz), (20, 0, false));

      final iki = IzinHesaplayici.hesapla(hizmetYili: 2, gecenYildanKalan: 7, buYilKullanilan: 0);
      expect(iki.devreden, 7);
    });

    test('fazla kullanılırsa kalan negatif', () {
      final s = IzinHesaplayici.hesapla(hizmetYili: 3, gecenYildanKalan: 0, buYilKullanilan: 25);
      expect(s.kalan, -5);
    });

    test('gidiş-dönüş ek süresi en çok 2+2 gün', () {
      expect(IzinSonucu.gidisDonusEnFazla, 4);
    });
  });

  group('zam senaryosu', () {
    const girdi = MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10, ekGosterge: 0, yanOdemePuani: 0);

    test('%0 zamda eski ve yeni maaş aynıdır', () {
      final s = ZamSenaryosu.hesapla(girdi, oran: 0);
      expect(s.yeni.net, closeTo(s.eski.net, 1e-9));
      expect(s.netFark, closeTo(0, 1e-9));
    });

    test('katsayı kalemlerinin hepsi zam oranı kadar artar: brüt %20 zamda 1,2 katı', () {
      final s = ZamSenaryosu.hesapla(girdi, oran: 0.20);
      expect(s.yeni.brut / s.eski.brut, closeTo(1.2, 1e-9));
      expect(s.yeni.gostergeAyligi / s.eski.gostergeAyligi, closeTo(1.2, 1e-9));
    });

    test('net artış zam oranından küçüktür (asgari ücret istisnası sabit) ama pozitiftir', () {
      final s = ZamSenaryosu.hesapla(girdi, oran: 0.20);
      expect(s.netFark, greaterThan(0));
      expect(s.netYuzde, lessThan(0.20));
      expect(s.netYuzde, greaterThan(0.15));
    });

    test('negatif oran 0 sayılır; sabit brüt ödeme (digerBrut) zamlanmaz', () {
      final s0 = ZamSenaryosu.hesapla(girdi, oran: -0.5);
      expect(s0.oran, 0);
      const ekli = MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10, digerBrut: 1000);
      final s = ZamSenaryosu.hesapla(ekli, oran: 0.10);
      expect(s.yeni.digerBrut, 1000);
    });

    test('senaryo parametresinin dönem adı zam oranını içerir; temel parametreler değişmez', () {
      final p = MaasParametreleri.temmuzAralik2026.zamliKatsayilarla(0.125);
      expect(p.donem, contains('%12.5'));
      expect(MaasParametreleri.temmuzAralik2026.aylikKatsayi, 1.575512);
      expect(p.aylikKatsayi, closeTo(1.575512 * 1.125, 1e-9));
      expect(p.asgariUcretBrut, MaasParametreleri.temmuzAralik2026.asgariUcretBrut);
      expect(MaasParametreleri.temmuzAralik2026.zamliKatsayilarla(0.2).donem, contains('%20 '));
    });
  });

  group('derece tablosu', () {
    test('her derecede kademe sayısı kadar satır; değerler maaş motoruyla tutarlı', () {
      for (var d = 1; d <= GostergeTablosu.enUstDerece; d++) {
        expect(DereceTablosu.satirlar(d), hasLength(GostergeTablosu.kademeSayisi(d)), reason: 'derece $d');
      }
      final satir = DereceTablosu.satirlar(8)[2]; // 8/3
      final m = const MemurMaasHesaplayici().hesapla(const MaasGirdisi(derece: 8, kademe: 3));
      expect(satir.gosterge, GostergeTablosu.gosterge(8, 3));
      expect(satir.gostergeAyligi, closeTo(m.gostergeAyligi, 1e-9));
      expect(satir.temelAylik, closeTo(m.gostergeAyligi + m.tabanAylik, 1e-9));
    });

    test('kademe arttıkça gösterge ve temel aylık azalmaz', () {
      for (var d = 1; d <= GostergeTablosu.enUstDerece; d++) {
        final s = DereceTablosu.satirlar(d);
        for (var i = 1; i < s.length; i++) {
          expect(s[i].temelAylik, greaterThanOrEqualTo(s[i - 1].temelAylik), reason: 'derece $d kademe ${i + 1}');
        }
      }
    });

    test('daha yüksek derece (küçük sayı) aynı kademede daha yüksek temel aylık verir', () {
      expect(DereceTablosu.satirlar(1).first.temelAylik, greaterThan(DereceTablosu.satirlar(15).first.temelAylik));
    });
  });
}
