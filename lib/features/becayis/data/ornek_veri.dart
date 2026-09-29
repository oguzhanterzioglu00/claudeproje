import '../domain/eslesme.dart';
import '../domain/eslestirici.dart';
import '../domain/ilan.dart';

/// Tasarımdaki örnek senaryo. Arka uç bağlanana kadar ekranlar bunu kullanır;
/// eşleşmeler gerçek motordan hesaplanır.
class BecayisOrnekVeri {
  BecayisOrnekVeri._();

  static const benimIlanim = Ilan(
    id: 'ben',
    kullaniciId: 'u-ben',
    kurumId: 'saglik-bakanligi',
    kurumAdi: 'Sağlık Bakanlığı',
    sinif: 'Sağlık Hizmetleri',
    unvan: 'Hemşire',
    mevcutIl: 'İzmir',
    hedefIller: ['Ankara', 'Eskişehir', 'Bursa'],
    maviTik: true,
    gorunenAd: 'Sen',
  );

  static const digerIlanlar = [
    Ilan(
      id: 'demir',
      kullaniciId: 'u-demir',
      kurumId: 'saglik-bakanligi',
      kurumAdi: 'Sağlık Bakanlığı',
      sinif: 'Sağlık Hizmetleri',
      unvan: 'Hemşire',
      mevcutIl: 'Ankara',
      hedefIller: ['İzmir'],
      maviTik: true,
      gorunenAd: 'M. Demir',
    ),
    Ilan(
      id: 'kaya',
      kullaniciId: 'u-kaya',
      kurumId: 'saglik-bakanligi',
      kurumAdi: 'Sağlık Bakanlığı',
      sinif: 'Sağlık Hizmetleri',
      unvan: 'Hemşire',
      mevcutIl: 'Ankara',
      hedefIller: ['Bursa'],
      maviTik: true,
      gorunenAd: 'S. Kaya',
    ),
    Ilan(
      id: 'arslan',
      kullaniciId: 'u-arslan',
      kurumId: 'saglik-bakanligi',
      kurumAdi: 'Sağlık Bakanlığı',
      sinif: 'Sağlık Hizmetleri',
      unvan: 'Hemşire',
      mevcutIl: 'Bursa',
      hedefIller: ['İzmir'],
      gorunenAd: 'F. Arslan',
    ),
    // Farklı kurum: eşleşmemeli.
    Ilan(
      id: 'yilmaz',
      kullaniciId: 'u-yilmaz',
      kurumId: 'meb',
      kurumAdi: 'Milli Eğitim Bakanlığı',
      sinif: 'Eğitim ve Öğretim Hizmetleri',
      unvan: 'Öğretmen',
      mevcutIl: 'Ankara',
      hedefIller: ['İzmir'],
      maviTik: true,
      gorunenAd: 'A. Yılmaz',
    ),
  ];

  static List<Ilan> get tumIlanlar => [benimIlanim, ...digerIlanlar];

  static List<Eslesme> eslesmeler() =>
      const Eslestirici().bul(tumIlanlar, ilanId: benimIlanim.id);
}
