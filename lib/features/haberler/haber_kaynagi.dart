import '../../core/akis.dart';
import 'haber_modeli.dart';

/// Haber akışı. Gerçek sürümde arka uç, resmî kaynaklardan (Resmî Gazete,
/// kurum duyuruları, bakanlık genelgeleri) derlenen içeriği sunar; en yeni
/// haber başta olmalıdır.
abstract interface class HaberKaynagi {
  Future<List<Haber>> getir();
}

/// Arka uç bağlanana kadar örnek haberler. Tüm içerik uydurmadır; gerçek bir
/// gelişmeyi yansıtmaz ve bu yüzden ekranda "ÖRNEK" rozeti görünür.
class OrnekHaberKaynagi implements HaberKaynagi {
  const OrnekHaberKaynagi({this.sure = const Duration(milliseconds: 400), this.bugun});

  final Duration sure;

  /// Tarihler bu güne göre üretilir; boşsa bugün.
  final DateTime? bugun;

  @override
  Future<List<Haber>> getir() async {
    await Future<void>.delayed(sure);
    final t = bugun ?? DateTime.now();
    final g = DateTime(t.year, t.month, t.day);
    DateTime gun(int fark) => g.subtract(Duration(days: fark));

    return [
      Haber(
        id: 'h1',
        baslik: 'Örnek: Memur maaş katsayıları güncellendi',
        tur: HaberTuru.maas,
        kaynakAdi: 'Hazine ve Maliye Bakanlığı (örnek)',
        yayinTarihi: gun(0),
        ozet:
            'Örnek içerik. Gerçek sürümde katsayı duyuruları kaynaktan derlenir; '
            'maaş hesabı bu akıştan değil, doğrulanmış parametre güncellemesinden beslenir.',
        resmiKaynak: true,
        baglanti: Uri.parse('https://www.hmb.gov.tr'),
      ),
      Haber(
        id: 'h2',
        baslik: 'Örnek: Resmî Gazete\'de yeni kanun hükmü yayımlandı',
        tur: HaberTuru.mevzuat,
        kaynakAdi: 'Resmî Gazete (örnek)',
        yayinTarihi: gun(1),
        ozet: 'Örnek içerik. Mevzuat değişiklikleri kaynak maddesiyle birlikte gösterilir.',
        resmiKaynak: true,
        otomatikOzet: true,
        baglanti: Uri.parse('https://www.resmigazete.gov.tr'),
      ),
      Haber(
        id: 'h3',
        baslik: 'Örnek: Kurumlar arası naklen atama duyurusu',
        tur: HaberTuru.atama,
        kaynakAdi: 'Kurumun resmî duyurusu (örnek)',
        yayinTarihi: gun(3),
        ozet: 'Örnek içerik. Başvuru şartları ve tarihler için kaynağı kontrol et.',
        resmiKaynak: true,
      ),
      Haber(
        id: 'h4',
        baslik: 'Örnek: Kurum içi yönetmelik değişikliği',
        tur: HaberTuru.duyuru,
        kaynakAdi: 'Kurumun resmî duyurusu (örnek)',
        yayinTarihi: gun(6),
        resmiKaynak: true,
      ),
      Haber(
        id: 'h5',
        baslik: 'Örnek: Kamu personeli için yeni düzenleme değerlendirmesi',
        tur: HaberTuru.mevzuat,
        kaynakAdi: 'Haber sitesi (örnek)',
        yayinTarihi: gun(10),
        ozet: 'Resmî olmayan kaynak: yalnızca başlık ve bağlantı verilir.',
      ),
    ];
  }
}

/// Gerçek haber akışı: `haberler.json` (Resmî Gazete günlük fihristi ve kamu personelini ilgilendiren
/// maddeler, bkz. `tool/feed_uret.py`). Haber ajansı içeriği kullanılmaz.
class AkisHaberKaynagi implements HaberKaynagi {
  AkisHaberKaynagi([AkisIstemcisi? istemci]) : _istemci = istemci ?? AkisIstemcisi();

  final AkisIstemcisi _istemci;

  @override
  Future<List<Haber>> getir() async => haberleriCoz(await _istemci.oku('haberler.json'));

  static List<Haber> haberleriCoz(Map<String, Object?> json) {
    final sonuc = <Haber>[];
    for (final o in json.liste('haberler')) {
      final id = o.metin('id');
      final baslik = o.metin('baslik');
      final yayin = o.duvarTarihi('yayin');
      if (id.isEmpty || baslik.isEmpty || yayin == null) continue;
      sonuc.add(
        Haber(
          id: id,
          baslik: baslik,
          tur: switch (o.metin('tur')) {
            'maas' => HaberTuru.maas,
            'atama' => HaberTuru.atama,
            'duyuru' => HaberTuru.duyuru,
            _ => HaberTuru.mevzuat,
          },
          kaynakAdi: o.metin('kaynak').isEmpty ? 'Resmî Gazete' : o.metin('kaynak'),
          yayinTarihi: yayin,
          ozet: o.metin('ozet'),
          resmiKaynak: o['resmi'] == true,
          baglanti: o.adres('baglanti'),
        ),
      );
    }
    // En yeni gün başta; aynı gün içinde madde haberleri günlük sayı özetinden ("rg-YYYYMMDD") önce gelir.
    sonuc.sort((a, b) {
      final gun = DateTime(
        b.yayinTarihi.year,
        b.yayinTarihi.month,
        b.yayinTarihi.day,
      ).compareTo(DateTime(a.yayinTarihi.year, a.yayinTarihi.month, a.yayinTarihi.day));
      if (gun != 0) return gun;
      final ozetA = RegExp(r'^rg-\d{8}$').hasMatch(a.id) ? 1 : 0;
      final ozetB = RegExp(r'^rg-\d{8}$').hasMatch(b.id) ? 1 : 0;
      return ozetA.compareTo(ozetB);
    });
    return sonuc;
  }
}
