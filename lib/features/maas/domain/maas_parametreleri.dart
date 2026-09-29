/// Maaş hesabında kullanılan, dönemsel olarak değişen katsayılar ve oranlar.
/// Değerler dönem başında güncellenir; hesap motoru bunları sabit kodlamaz.
class MaasParametreleri {
  const MaasParametreleri({
    required this.donem,
    required this.kaynak,
    required this.aylikKatsayi,
    required this.tabanAylikKatsayi,
    required this.yanOdemeKatsayi,
    this.tabanGosterge = 1000,
    this.yillikKidemGostergesi = 25,
    this.enFazlaKidemYili = 25,
    this.emeklilikPayi = 0.09,
    this.gssPayi = 0.05,
    this.damgaOrani = 0.00759,
    required this.gelirVergisiDilimleri,
    required this.asgariUcretBrut,
    this.asgariUcretSgkKesintisi = 0.15,
    required this.asgariUcretDamgaIstisnasi,
  });

  /// Görünen dönem adı, ör. "Temmuz–Aralık 2026".
  final String donem;

  /// Değerlerin kaynağı (kullanıcıya gösterilir).
  final String kaynak;

  final double aylikKatsayi;
  final double tabanAylikKatsayi;
  final double yanOdemeKatsayi;

  /// Taban aylık göstergesi (taban aylık = gösterge × taban aylık katsayısı).
  final int tabanGosterge;

  /// Kıdem aylığı için hizmet yılı başına gösterge.
  final int yillikKidemGostergesi;
  final int enFazlaKidemYili;

  /// Memur payı: 5510 sosyal sigorta primi %9 ve genel sağlık sigortası %5.
  /// Emekli Sandığı kapsamındaki eski memurlarda oranlar farklı olabilir.
  final double emeklilikPayi;
  final double gssPayi;
  final double damgaOrani;

  /// (üst sınır, oran) çiftleri; sonuncunun sınırı sonsuzdur.
  final List<(double, double)> gelirVergisiDilimleri;

  /// Asgari ücret istisnası hesabı için brüt asgari ücret ve işçi kesintisi (SGK+işsizlik).
  final double asgariUcretBrut;
  final double asgariUcretSgkKesintisi;
  final double asgariUcretDamgaIstisnasi;

  /// Temmuz–Aralık 2026 dönemi.
  ///
  /// Katsayılar: Hazine ve Maliye Bakanlığı mali haklar genelgesi (3 Temmuz 2026),
  /// R.G. 5 Temmuz 2026, S. 32999; iki ayrı kaynakta aynı çıktı.
  /// Gelir vergisi dilimleri (ücretliler) ve asgari ücret (brüt 33.030 TL, damga
  /// istisnası 250,70 TL/ay) ikincil kaynaklardan alındı; yayın öncesi GİB ve
  /// Resmî Gazete ile teyit edilmeli.
  static const temmuzAralik2026 = MaasParametreleri(
    donem: 'Temmuz–Aralık 2026',
    kaynak: 'Hazine ve Maliye Bakanlığı genelgesi (3 Temmuz 2026), R.G. 5 Temmuz 2026 / 32999',
    aylikKatsayi: 1.575512,
    tabanAylikKatsayi: 25.794915,
    yanOdemeKatsayi: 0.499649,
    gelirVergisiDilimleri: [
      (190000, 0.15),
      (400000, 0.20),
      (1500000, 0.27),
      (5300000, 0.35),
      (double.infinity, 0.40),
    ],
    asgariUcretBrut: 33030,
    asgariUcretDamgaIstisnasi: 250.70,
  );
}
