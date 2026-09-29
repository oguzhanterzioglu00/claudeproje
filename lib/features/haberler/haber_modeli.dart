/// Haberin türü; süzgeç ve simge buna göre seçilir.
enum HaberTuru {
  mevzuat('Mevzuat'),
  maas('Maaş ve özlük'),
  duyuru('Kurum duyurusu'),
  atama('Atama ve alım');

  const HaberTuru(this.etiket);

  final String etiket;
}

/// Kamu çalışanlarını ilgilendiren bir gelişme. Her haber kaynağını ve yayın
/// zamanını taşır; kaynağı bilinmeyen içerik gösterilmez.
///
/// Telif ve doğruluk gereği yalnızca başlık, kısa özet ve kaynağa bağlantı
/// tutulur; haber metni kopyalanmaz (bkz. docs/asistan-ve-haber-spec.md).
class Haber {
  const Haber({
    required this.id,
    required this.baslik,
    required this.tur,
    required this.kaynakAdi,
    required this.yayinTarihi,
    this.ozet = '',
    this.resmiKaynak = false,
    this.otomatikOzet = false,
    this.baglanti,
  });

  final String id;
  final String baslik;
  final HaberTuru tur;

  /// Ör. "Resmî Gazete", "Hazine ve Maliye Bakanlığı", "Kurumun duyurusu".
  final String kaynakAdi;
  final DateTime yayinTarihi;
  final String ozet;

  /// Kaynak bir kamu kurumu/Resmî Gazete ise true; kullanıcıya "Resmî kaynak" rozeti gösterilir.
  final bool resmiKaynak;

  /// [ozet] yapay zekâ ile üretildiyse true; ekranda "Otomatik özet" etiketi zorunludur.
  final bool otomatikOzet;

  /// Kaynağın adresi. Yoksa "Kaynağı aç" düğmesi pasif kalır.
  final Uri? baglanti;

  /// "Bugün", "Dün", "3 gün önce", "2 hafta önce", "4 ay önce"; ileri tarih "Bugün" sayılır.
  String zamanEtiketi(DateTime bugun) {
    final b = DateTime(bugun.year, bugun.month, bugun.day);
    final y = DateTime(yayinTarihi.year, yayinTarihi.month, yayinTarihi.day);
    final gun = b.difference(y).inDays;
    if (gun <= 0) return 'Bugün';
    if (gun == 1) return 'Dün';
    if (gun < 7) return '$gun gün önce';
    if (gun < 30) return '${gun ~/ 7} hafta önce';
    if (gun < 365) return '${gun ~/ 30} ay önce';
    return '${gun ~/ 365} yıl önce';
  }
}
