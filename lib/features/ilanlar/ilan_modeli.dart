/// Kamu ilanının türü; filtre ve simge buna göre seçilir.
enum IlanTuru {
  memur('KPSS'),
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
    required this.sonBasvuru,
    required this.kaynakAdi,
    required this.kaynakGuncelleme,
    this.ozet = '',
    this.uyum,
    this.baglanti,
  });

  final String id;
  final String baslik;
  final String kurum;
  final String konum;
  final IlanTuru tur;
  final DateTime yayinTarihi;
  final DateTime sonBasvuru;

  /// Ör. "Kurumun resmî duyurusu", "ÖSYM", "İŞKUR".
  final String kaynakAdi;
  final DateTime kaynakGuncelleme;
  final String ozet;

  /// Kullanıcının profiline uyum (0-100); profil yoksa null.
  final int? uyum;

  /// İlanın kaynağındaki adres; yoksa "Kaynağı aç" düğmesi pasif kalır.
  final Uri? baglanti;

  /// [bugun] itibarıyla kalan tam gün; süresi dolduysa negatif.
  int kalanGun(DateTime bugun) {
    final b = DateTime(bugun.year, bugun.month, bugun.day);
    final s = DateTime(sonBasvuru.year, sonBasvuru.month, sonBasvuru.day);
    return s.difference(b).inDays;
  }

  bool acikMi(DateTime bugun) => kalanGun(bugun) >= 0;

  /// Başvuru süresinin ne kadarının geçtiği (0-1); çubuk bunu gösterir.
  double gecenOran(DateTime bugun) {
    final toplam = sonBasvuru.difference(yayinTarihi).inHours;
    if (toplam <= 0) return 1;
    return (bugun.difference(yayinTarihi).inHours / toplam).clamp(0.0, 1.0);
  }
}
