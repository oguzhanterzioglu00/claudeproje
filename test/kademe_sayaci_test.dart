import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/features/ana_sayfa/ana_sayfa_verisi.dart';
import 'package:pusula/features/maas/domain/gosterge_tablosu.dart';
import 'package:pusula/features/maas/domain/memur_maas_hesaplayici.dart';
import 'package:pusula/features/profil/domain/profil.dart';

void main() {
  final bugun = DateTime(2026, 9, 29);

  group('kademeSayaci (657 md. 64: kademede en az bir yıl)', () {
    test('tam bir yıl dolduysa 0 gün ve oran 1', () {
      final (kalan, oran) = AnaSayfaVerisi.kademeSayaci(DateTime(2025, 9, 29), bugun);
      expect((kalan, oran), (0, 1.0));
    });

    test('30 gün kala', () {
      final (kalan, oran) = AnaSayfaVerisi.kademeSayaci(DateTime(2025, 10, 29), bugun);
      expect(kalan, 30);
      expect(oran, closeTo(335 / 365, 0.002));
    });

    test('süre geçmişse kalan negatif, oran 1 ile sınırlı; gelecekteki tarihte oran 0', () {
      final gecmis = AnaSayfaVerisi.kademeSayaci(DateTime(2024, 1, 1), bugun);
      expect(gecmis.$1, lessThan(0));
      expect(gecmis.$2, 1.0);
      final gelecek = AnaSayfaVerisi.kademeSayaci(DateTime(2026, 12, 1), bugun);
      expect(gelecek.$2, 0.0);
      expect(gelecek.$1, greaterThan(365));
    });

    test('saat bilgisi sonucu etkilemez', () {
      final a = AnaSayfaVerisi.kademeSayaci(DateTime(2025, 10, 29, 23, 59), DateTime(2026, 9, 29, 0, 1));
      expect(a.$1, 30);
    });
  });

  group('yol haritasında kademe sayacı', () {
    const maas = MaasGirdisi(derece: 8, kademe: 3, hizmetYili: 10);
    final tarih = DateTime(2025, 12, 1);

    AnaSayfaVerisi veri(Profil p) => AnaSayfaVerisi.profilden(p, bugun: bugun, becayisAlt: 'x');

    test('memur, kademe tarihi girilmiş ve ilerleyebileceği kademe var → ikinci satır', () {
      final v = veri(Profil(ad: 'A', statu: Statu.memur657, maas: maas, kademeTarihi: tarih));
      expect(v.yolHaritasi.map((o) => o.baslik), ['Sonraki maaş dönemi', 'En erken kademe ilerlemesi']);
      final k = v.yolHaritasi.last;
      expect(k.deger, '63 gün');
      expect(k.oran, closeTo(302 / 365, 0.002));
    });

    test('süre dolmuşsa "Şimdi" yazar', () {
      final v = veri(Profil(ad: 'A', statu: Statu.memur657, maas: maas, kademeTarihi: DateTime(2025, 1, 1)));
      expect(v.yolHaritasi.last.deger, 'Şimdi');
    });

    test('son kademedeki memurda sayaç yok; kademe tarihi yoksa ya da memur değilse de yok', () {
      final son = MaasGirdisi(derece: 8, kademe: GostergeTablosu.kademeSayisi(8), hizmetYili: 10);
      expect(veri(Profil(ad: 'A', statu: Statu.memur657, maas: son, kademeTarihi: tarih)).yolHaritasi, hasLength(1));
      expect(veri(const Profil(ad: 'A', statu: Statu.memur657, maas: maas)).yolHaritasi, hasLength(1));
      expect(veri(Profil(ad: 'A', statu: Statu.isci, kademeTarihi: tarih)).yolHaritasi, isEmpty);
    });

    test('bordro girdisi olmasa da tarih varsa sayaç gösterilir', () {
      final v = veri(Profil(ad: 'A', statu: Statu.memur657, kademeTarihi: tarih));
      expect(v.yolHaritasi.map((o) => o.baslik), contains('En erken kademe ilerlemesi'));
    });
  });
}
