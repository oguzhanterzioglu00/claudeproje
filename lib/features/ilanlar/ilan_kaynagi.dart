import 'ilan_modeli.dart';

/// İlan akışı. Gerçek sürümde arka uç, resmî kaynaklardan derlenen ilanları
/// sunar (bkz. docs/asistan-ve-haber-spec.md).
abstract interface class IlanKaynagi {
  Future<List<KamuIlani>> getir();
}

/// Arka uç bağlanana kadar örnek ilanlar. Tüm içerik uydurmadır.
class OrnekIlanKaynagi implements IlanKaynagi {
  const OrnekIlanKaynagi({this.sure = const Duration(milliseconds: 400), this.bugun});

  final Duration sure;

  /// Tarihler bu güne göre üretilir; boşsa bugün.
  final DateTime? bugun;

  @override
  Future<List<KamuIlani>> getir() async {
    await Future<void>.delayed(sure);
    final t = bugun ?? DateTime.now();
    final g = DateTime(t.year, t.month, t.day);
    DateTime gun(int fark) => g.add(Duration(days: fark));

    return [
      KamuIlani(
        id: 'o1',
        baslik: 'Hemşire alımı',
        kurum: 'Sağlık Bakanlığı',
        konum: '81 il',
        tur: IlanTuru.memur,
        yayinTarihi: gun(-8),
        sonBasvuru: gun(12),
        kaynakAdi: 'Kurumun resmî duyurusu (örnek)',
        kaynakGuncelleme: gun(-1),
        ozet: 'Örnek ilan metni. Gerçek ilanlarda başvuru şartları ve tarihler kaynaktan derlenir.',
        uyum: 92,
      ),
      KamuIlani(
        id: 'o2',
        baslik: 'Zabıta memuru alımı',
        kurum: 'Belediye',
        konum: 'İl merkezi',
        tur: IlanTuru.memur,
        yayinTarihi: gun(-15),
        sonBasvuru: gun(5),
        kaynakAdi: 'Kurumun resmî duyurusu (örnek)',
        kaynakGuncelleme: gun(-2),
        uyum: 78,
      ),
      KamuIlani(
        id: 'o3',
        baslik: 'Sürekli işçi alımı',
        kurum: 'Kamu kurumu',
        konum: 'Ülke geneli',
        tur: IlanTuru.isci,
        yayinTarihi: gun(-5),
        sonBasvuru: gun(20),
        kaynakAdi: 'İŞKUR (örnek)',
        kaynakGuncelleme: gun(-1),
        uyum: 64,
      ),
      KamuIlani(
        id: 'o4',
        baslik: 'Sözleşmeli bilişim personeli',
        kurum: 'Bakanlık',
        konum: 'Ankara',
        tur: IlanTuru.sozlesmeli,
        yayinTarihi: gun(-3),
        sonBasvuru: gun(9),
        kaynakAdi: 'Kurumun resmî duyurusu (örnek)',
        kaynakGuncelleme: gun(-3),
      ),
      KamuIlani(
        id: 'o5',
        baslik: 'Öğretmen ataması duyurusu',
        kurum: 'Milli Eğitim Bakanlığı',
        konum: 'Ülke geneli',
        tur: IlanTuru.memur,
        yayinTarihi: gun(-20),
        sonBasvuru: gun(2),
        kaynakAdi: 'Kurumun resmî duyurusu (örnek)',
        kaynakGuncelleme: gun(-4),
        uyum: 55,
      ),
      // Süresi dolmuş: listede görünmemeli.
      KamuIlani(
        id: 'o6',
        baslik: 'Geçmiş dönem ilanı',
        kurum: 'Kurum',
        konum: 'Ankara',
        tur: IlanTuru.diger,
        yayinTarihi: gun(-40),
        sonBasvuru: gun(-3),
        kaynakAdi: 'Kurumun resmî duyurusu (örnek)',
        kaynakGuncelleme: gun(-30),
      ),
    ];
  }
}
