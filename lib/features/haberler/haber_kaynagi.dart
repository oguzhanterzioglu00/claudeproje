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
        ozet: 'Örnek içerik. Gerçek sürümde katsayı duyuruları kaynaktan derlenir; '
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
