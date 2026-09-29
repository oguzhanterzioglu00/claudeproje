import '../../core/akis.dart';
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
        baglanti: Uri.parse('https://www.saglik.gov.tr'),
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
        baglanti: Uri.parse('https://www.iskur.gov.tr'),
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
        baglanti: Uri.parse('https://www.meb.gov.tr'),
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

/// Gerçek ilan akışı: `ilanlar.json` (Kariyer Kapısı resmî RSS'inden derlenir, bkz. `tool/feed_uret.py`).
/// Yüklenemezse hata fırlatır; ekran "yüklenemedi / tekrar dene" durumunu gösterir. Örnek veriye düşülmez.
class AkisIlanKaynagi implements IlanKaynagi {
  AkisIlanKaynagi([AkisIstemcisi? istemci]) : _istemci = istemci ?? AkisIstemcisi();

  final AkisIstemcisi _istemci;

  @override
  Future<List<KamuIlani>> getir() async => ilanlariCoz(await _istemci.oku('ilanlar.json'));

  /// `ilanlar.json` içeriğini ilan listesine çevirir; kimliği, başlığı ya da tarihi bozuk kayıtlar atlanır.
  static List<KamuIlani> ilanlariCoz(Map<String, Object?> json) {
    final guncelleme = json.duvarTarihi('guncelleme') ?? DateTime.now();
    final kaynak = json.metin('kaynak').isEmpty ? 'Kariyer Kapısı' : json.metin('kaynak');
    final sonuc = <KamuIlani>[];
    for (final o in json.liste('ilanlar')) {
      final id = o.metin('id');
      final baslik = o.metin('baslik');
      final yayin = o.duvarTarihi('yayin');
      if (id.isEmpty || baslik.isEmpty || yayin == null) continue;
      final kurum = o.metin('kurum');
      sonuc.add(
        KamuIlani(
          id: id,
          baslik: kurum.isNotEmpty && baslik.startsWith('$kurum - ') ? baslik.substring(kurum.length + 3) : baslik,
          kurum: kurum,
          konum: '',
          tur: switch (o.metin('tur')) {
            'memur' => IlanTuru.memur,
            'isci' => IlanTuru.isci,
            'sozlesmeli' => IlanTuru.sozlesmeli,
            _ => IlanTuru.diger,
          },
          yayinTarihi: yayin,
          sonBasvuru: o.duvarTarihi('sonBasvuru'),
          kaynakAdi: kaynak,
          kaynakGuncelleme: guncelleme,
          baglanti: o.adres('baglanti'),
          kategori: o.metin('kategori'),
        ),
      );
    }
    sonuc.sort((a, b) => b.yayinTarihi.compareTo(a.yayinTarihi));
    return sonuc;
  }
}
