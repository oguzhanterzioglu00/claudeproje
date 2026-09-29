import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pusula/features/maas/domain/memur_maas_hesaplayici.dart';
import 'package:pusula/features/profil/data/profil_deposu.dart';
import 'package:pusula/features/profil/data/profil_kaydi.dart';
import 'package:pusula/features/profil/domain/profil.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tam = Profil(
  ad: 'Ayşe Yılmaz',
  statu: Statu.memur657,
  adayMemur: false,
  kurumAdi: 'Sağlık Bakanlığı',
  sinif: 'Sağlık Hizmetleri',
  unvan: 'Hemşire',
  il: 'İzmir',
  sicilNo: '123456',
  kurumsalEposta: 'ayse@ornek.gov.tr',
  maas: MaasGirdisi(
    derece: 8, kademe: 3, hizmetYili: 10,
    ekGosterge: 2200, yanOdemePuani: 1000, ozelHizmetTazminatiOrani: 0.5, digerBrut: 1500,
  ),
);

class _Bozuk implements ProfilKaydi {
  @override
  Future<Profil?> yukle() async => throw Exception('disk hatası');

  @override
  Future<void> kaydet(Profil profil) async {}

  @override
  Future<void> sil() async {}
}

void main() {
  group('Profil modeli', () {
    test('JSON gidiş-dönüş aynı profili verir', () {
      final j = jsonDecode(jsonEncode(_tam.toJson())) as Map<String, Object?>;
      expect(Profil.fromJson(j), _tam);
    });

    test('bozuk veya eksik kayıt güvenli varsayılanlara döner', () {
      final p = Profil.fromJson({'statu': 'yok-böyle-bir-statu', 'ad': 5, 'maas': 'saçma'});
      expect(p.statu, Statu.diger);
      expect(p.ad, '');
      expect(p.maas, isNull);
      expect(Profil.fromJson(const {}).statu, Statu.diger);
    });

    test('maaş girdisi bozuk sayılarla motoru düşürmez: derece/kademe sınırlanır', () {
      final g = MaasGirdisi.fromJson({'derece': 99, 'kademe': 50, 'hizmetYili': -3, 'ozelHizmetTazminatiOrani': 999});
      expect(g.derece, 15);
      expect(g.kademe, 9);
      expect(g.hizmetYili, 0);
      expect(g.ozelHizmetTazminatiOrani, 10);
      expect(() => const MemurMaasHesaplayici().hesapla(g), returnsNormally);
    });

    test('becayiş için eksik alanlar', () {
      expect(_tam.eksikBecayisAlanlari, isEmpty);
      expect(
        const Profil(ad: 'A', statu: Statu.memur657).eksikBecayisAlanlari,
        ['Kurum', 'Hizmet sınıfı', 'Unvan', 'Çalıştığın il'],
      );
      expect(_tam.kopya(unvan: ' ').eksikBecayisAlanlari, ['Unvan']);
    });

    test('becayiş kapalı nedenleri', () {
      expect(_tam.becayisKapaliNedeni, isNull);
      expect(_tam.kopya(adayMemur: true).becayisKapaliNedeni, contains('asaleti'));
      expect(_tam.kopya(statu: Statu.sozlesmeli).becayisKapaliNedeni, contains('4/B sözleşmeli personel'));
      expect(_tam.kopya(statu: Statu.isci).becayisYapabilir, isFalse);
    });

    test('kurum kimliği Türkçe harfleri sadeleştirir', () {
      expect(kurumKimligiUret('Sağlık Bakanlığı'), 'saglik-bakanligi');
      expect(kurumKimligiUret('İçişleri Bakanlığı'), 'icisleri-bakanligi');
      expect(kurumKimligiUret('Çevre, Şehircilik ve İklim Değişikliği Bakanlığı'),
          'cevre-sehircilik-ve-iklim-degisikligi-bakanligi');
      expect(kurumKimligiUret('  Belediye  '), 'belediye');
      expect(kurumKimligiUret(''), '');
      // Aynı kurumun farklı yazımları aynı kimliğe düşmeli:
      expect(kurumKimligiUret('SAĞLIK BAKANLIĞI'), kurumKimligiUret('Sağlık Bakanlığı'));
    });

    test('seçenek listeleri: 81 il, tekrarsız; sınıflar sıralı', () {
      expect(ProfilSecenekleri.iller, hasLength(81));
      expect(ProfilSecenekleri.iller.toSet(), hasLength(81));
      expect(ProfilSecenekleri.siniflar, hasLength(9));
    });
  });

  group('ProfilDeposu', () {
    test('yükler, kaydeder, siler ve dinleyicileri bilgilendirir', () async {
      final kayit = BellekProfilKaydi();
      final depo = ProfilDeposu(kayit);
      var bildirim = 0;
      depo.addListener(() => bildirim++);

      expect(depo.yuklendi, isFalse);
      await depo.yukle();
      expect(depo.yuklendi, isTrue);
      expect(depo.profil, isNull);

      await depo.kaydet(_tam);
      expect(depo.profil, _tam);
      expect(await kayit.yukle(), _tam);

      await depo.sil();
      expect(depo.profil, isNull);
      expect(await kayit.yukle(), isNull);
      expect(bildirim, greaterThanOrEqualTo(3));
    });

    test('kayıt okunamazsa çökmez, profil boş sayılır', () async {
      final depo = ProfilDeposu(_Bozuk());
      await depo.yukle();
      expect(depo.yuklendi, isTrue);
      expect(depo.profil, isNull);
    });
  });

  group('YerelProfilKaydi (shared_preferences)', () {
    const kayit = YerelProfilKaydi();

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('kaydeder ve geri okur', () async {
      expect(await kayit.yukle(), isNull);
      await kayit.kaydet(_tam);
      expect(await kayit.yukle(), _tam);
    });

    test('sil kaydı kaldırır', () async {
      await kayit.kaydet(_tam);
      await kayit.sil();
      expect(await kayit.yukle(), isNull);
    });

    test('bozuk JSON çökertmez, null döner', () async {
      SharedPreferences.setMockInitialValues({const YerelProfilKaydi().anahtar: '{bu json değil'});
      expect(await kayit.yukle(), isNull);
      SharedPreferences.setMockInitialValues({const YerelProfilKaydi().anahtar: '[1,2,3]'});
      expect(await kayit.yukle(), isNull);
    });
  });

  group('kademe tarihi', () {
    const taban = Profil(ad: 'A', statu: Statu.memur657);

    test('JSON gidiş-dönüş; kopya ile temizlenir', () {
      final p = taban.kopya(kademeTarihi: DateTime(2025, 3, 4));
      expect(p.toJson()['kademeTarihi'], '2025-03-04');
      expect(Profil.fromJson(p.toJson()).kademeTarihi, DateTime(2025, 3, 4));
      expect(p.kopya(ad: 'B').kademeTarihi, DateTime(2025, 3, 4), reason: 'başka alan değişince korunur');
      expect(p.kopya(kademeTarihiniTemizle: true).kademeTarihi, isNull);
      expect(p == p.kopya(), isTrue);
      expect(p == taban, isFalse);
    });

    test('bozuk ve olanaksız tarihler null olur, hata fırlatmaz', () {
      for (final v in [null, 5, '', 'dün', '2025-13-01', '2025-02-31', '25-01-01', '1900-01-01', '2999-01-01', ['2025-01-01']]) {
        expect(Profil.fromJson({'ad': 'A', 'statu': 'memur657', 'kademeTarihi': v}).kademeTarihi, isNull, reason: '$v');
      }
    });
  });
}
