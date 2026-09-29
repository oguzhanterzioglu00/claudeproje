/// Kamu ilanının türü; filtre ve simge buna göre seçilir.
enum IlanTuru {
  memur('Memur alımı'),
  isci('İşçi alımı'),
  sozlesmeli('Sözleşmeli'),
  diger('Diğer');

  const IlanTuru(this.etiket);

  final String etiket;
}

/// Otomatik derlenen bir kamu ilanı. Her ilan kaynağını ve kaynağın son
/// güncellenme zamanını taşır; kullanıcı başvurmadan önce kaynağı doğrulayabilir.
class KamuIlani {
  const KamuIlani({
    required this.id,
    required this.baslik,
    required this.kurum,
    required this.konum,
    required this.tur,
    required this.yayinTarihi,
    this.sonBasvuru,
    required this.kaynakAdi,
    required this.kaynakGuncelleme,
    this.ozet = '',
    this.uyum,
    this.baglanti,
    this.kategori = '',
  });

  final String id;
  final String baslik;
  final String kurum;
  final String konum;
  final IlanTuru tur;
  final DateTime yayinTarihi;

  /// Son başvuru günü; kaynak bildirmediyse null (tarih ilan sayfasında yazar).
  final DateTime? sonBasvuru;

  /// Kaynağın kendi sınıflandırması, ör. "B Grubu Memur", "Sözleşmeli Personel İlanları".
  final String kategori;

  /// Ör. "Kurumun resmî duyurusu", "ÖSYM", "İŞKUR".
  final String kaynakAdi;
  final DateTime kaynakGuncelleme;
  final String ozet;

  /// Kullanıcının profiline uyum (0-100); profil yoksa null.
  final int? uyum;

  /// İlanın kaynağındaki adres; yoksa "Kaynağı aç" düğmesi pasif kalır.
  final Uri? baglanti;

  /// [bugun] itibarıyla kalan tam gün; süresi dolduysa negatif, son başvuru günü bilinmiyorsa null.
  int? kalanGun(DateTime bugun) {
    final son = sonBasvuru;
    if (son == null) return null;
    final b = DateTime(bugun.year, bugun.month, bugun.day);
    final s = DateTime(son.year, son.month, son.day);
    return s.difference(b).inDays;
  }

  /// Son başvuru günü bilinmeyen ilan kaynağında yayında olduğu sürece açık sayılır.
  bool acikMi(DateTime bugun) => (kalanGun(bugun) ?? 0) >= 0;

  /// Yayın/başlangıç tarihi [bugun]'den sonraysa başvurular henüz başlamamıştır.
  bool baslamadiMi(DateTime bugun) => DateTime(
    yayinTarihi.year,
    yayinTarihi.month,
    yayinTarihi.day,
  ).isAfter(DateTime(bugun.year, bugun.month, bugun.day));

  /// Başvuru süresinin ne kadarının geçtiği (0-1); çubuk bunu gösterir. Son gün bilinmiyorsa 0.
  double gecenOran(DateTime bugun) {
    final son = sonBasvuru;
    if (son == null) return 0;
    final toplam = son.difference(yayinTarihi).inHours;
    if (toplam <= 0) return 1;
    return (bugun.difference(yayinTarihi).inHours / toplam).clamp(0.0, 1.0);
  }
}
