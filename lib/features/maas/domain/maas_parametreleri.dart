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
    this.isciSgkPayi = 0.14,
    this.issizlikPayi = 0.01,
    this.sgkTavanKati = 9,
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

  /// 5510 sayılı Kanun'a göre 4/1-(a) kapsamındaki (işçi, 4/B sözleşmeli) sigortalının payı: sosyal sigorta %9 +
  /// genel sağlık sigortası %5 (md. 81) ve işsizlik sigortası %1 (4447 sayılı Kanun md. 49).
  final double isciSgkPayi;
  final double issizlikPayi;

  /// Prime esas kazancın üst sınırı, günlük alt sınırın (asgari ücretin) katı (5510 md. 82: 9 katı).
  final double sgkTavanKati;

  /// (üst sınır, oran) çiftleri; sonuncunun sınırı sonsuzdur.
  final List<(double, double)> gelirVergisiDilimleri;

  /// Asgari ücret istisnası hesabı için brüt asgari ücret ve işçi kesintisi (SGK+işsizlik).
  final double asgariUcretBrut;
  final double asgariUcretSgkKesintisi;
  final double asgariUcretDamgaIstisnasi;

  /// Kümülatif matrah için toplam gelir vergisi (kademeli tarife).
  double gelirVergisiTarifesi(double matrah) {
    var vergi = 0.0;
    var alt = 0.0;
    for (final (ust, oran) in gelirVergisiDilimleri) {
      if (matrah > alt) vergi += ((matrah < ust ? matrah : ust) - alt) * oran;
      alt = ust;
    }
    return vergi;
  }

  /// Aylık, taban aylık ve yan ödeme katsayıları [oran] kadar (ör. 0.20 = %20) artırılmış senaryo
  /// parametreleri. Vergi dilimleri ve asgari ücret değişmez (gerçekte yılbaşında yeniden belirlenir).
  MaasParametreleri zamliKatsayilarla(double oran) => MaasParametreleri(
    donem: '$donem, %${(oran * 100).toStringAsFixed(oran * 100 % 1 == 0 ? 0 : 1)} zam senaryosu',
    kaynak: kaynak,
    aylikKatsayi: aylikKatsayi * (1 + oran),
    tabanAylikKatsayi: tabanAylikKatsayi * (1 + oran),
    yanOdemeKatsayi: yanOdemeKatsayi * (1 + oran),
    tabanGosterge: tabanGosterge,
    yillikKidemGostergesi: yillikKidemGostergesi,
    enFazlaKidemYili: enFazlaKidemYili,
    emeklilikPayi: emeklilikPayi,
    gssPayi: gssPayi,
    damgaOrani: damgaOrani,
    isciSgkPayi: isciSgkPayi,
    issizlikPayi: issizlikPayi,
    sgkTavanKati: sgkTavanKati,
    gelirVergisiDilimleri: gelirVergisiDilimleri,
    asgariUcretBrut: asgariUcretBrut,
    asgariUcretSgkKesintisi: asgariUcretSgkKesintisi,
    asgariUcretDamgaIstisnasi: asgariUcretDamgaIstisnasi,
  );

  /// Temmuz–Aralık 2026 dönemi.
  ///
  /// Katsayılar: Hazine ve Maliye Bakanlığı mali haklar genelgesi (3 Temmuz 2026),
  /// R.G. 5 Temmuz 2026, S. 32999; iki ayrı kaynakta aynı çıktı.
  /// Gelir vergisi dilimleri (ücret gelirleri): GİB "Gelir Vergisi Tarifesi 2026" (332 Seri No.lu
  /// Tebliğ) ile birebir doğrulandı. Asgari ücret (brüt 33.030 TL; damga istisnası = 33.030 × 0,00759
  /// = 250,70 TL/ay) 2026 yılı için geçerlidir ve birden çok kaynakta aynıdır; Ocak 2027'de yeniden belirlenir.
  static const temmuzAralik2026 = MaasParametreleri(
    donem: 'Temmuz–Aralık 2026',
    kaynak: 'Hazine ve Maliye Bakanlığı genelgesi (3 Temmuz 2026), R.G. 5 Temmuz 2026 / 32999',
    aylikKatsayi: 1.575512,
    tabanAylikKatsayi: 25.794915,
    yanOdemeKatsayi: 0.499649,
    gelirVergisiDilimleri: [(190000, 0.15), (400000, 0.20), (1500000, 0.27), (5300000, 0.35), (double.infinity, 0.40)],
    asgariUcretBrut: 33030,
    asgariUcretDamgaIstisnasi: 250.70,
  );
}
