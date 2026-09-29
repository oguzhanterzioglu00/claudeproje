import '../domain/eslesme.dart';
import '../domain/eslestirici.dart';
import '../domain/ilan.dart';
import '../domain/kisi_bilgisi.dart';
import 'becayis_deposu.dart';

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
    // Aşağıdakiler farklı kurum/sınıf: eşleşmemeli, yalnızca ilan listesinde görünür.
    Ilan(
      id: 'yilmaz',
      kullaniciId: 'u-yilmaz',
      kurumId: 'meb',
      kurumAdi: 'Milli Eğitim Bakanlığı',
      sinif: 'Eğitim ve Öğretim Hizmetleri',
      unvan: 'Öğretmen',
      mevcutIl: 'İstanbul',
      hedefIller: ['Ankara'],
      maviTik: true,
      gorunenAd: 'A. Yılmaz',
    ),
    Ilan(
      id: 'celik',
      kullaniciId: 'u-celik',
      kurumId: 'adalet-bakanligi',
      kurumAdi: 'Adalet Bakanlığı',
      sinif: 'Genel İdare Hizmetleri',
      unvan: 'Memur',
      mevcutIl: 'Bursa',
      hedefIller: ['Antalya'],
      maviTik: true,
      gorunenAd: 'E. Çelik',
    ),
    Ilan(
      id: 'sahin',
      kullaniciId: 'u-sahin',
      kurumId: 'universite',
      kurumAdi: 'Üniversite Rektörlüğü',
      sinif: 'Genel İdare Hizmetleri',
      unvan: 'Uzman',
      mevcutIl: 'Ordu',
      hedefIller: ['Antalya'],
      gorunenAd: 'H. Şahin',
    ),
  ];

  /// Ödeme sonrası açılan bilgiler (örnek/uydurma).
  static const kisiler = <String, KisiBilgisi>{
    'ben': KisiBilgisi(tamAd: 'Ayşe Yılmaz', sicilNo: '123456', telefon: '0555 000 00 00', eposta: 'ayse.yilmaz@ornek.gov.tr'),
    'demir': KisiBilgisi(tamAd: 'Mehmet Demir', sicilNo: '654321', telefon: '0555 000 00 01', eposta: 'm.demir@ornek.gov.tr'),
    'arslan': KisiBilgisi(tamAd: 'Fatma Arslan', sicilNo: '112233', telefon: '0555 000 00 02', eposta: 'f.arslan@ornek.gov.tr'),
    'kaya': KisiBilgisi(tamAd: 'Selim Kaya', sicilNo: '445566', telefon: '0555 000 00 03', eposta: 's.kaya@ornek.gov.tr'),
  };

  static List<Ilan> get tumIlanlar => [benimIlanim, ...digerIlanlar];

  static List<Eslesme> eslesmeler() =>
      const Eslestirici().bul(tumIlanlar, ilanId: benimIlanim.id);

  static BecayisDeposu depo() => BecayisDeposu(
        benim: benimIlanim,
        digerleri: digerIlanlar,
        kisiler: kisiler,
        epostam: 'ayse.yilmaz@ornek.gov.tr',
      );
}
