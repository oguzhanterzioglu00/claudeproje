/// Türkçe harfleri de doğru küçülten, karşılaştırma için normalleştirilmiş anahtar.
String normalize(String s) => s
    .trim()
    .replaceAll('İ', 'i')
    .replaceAll('I', 'ı')
    .toLowerCase();

/// Bir memurun becayiş ilanı.
///
/// Yasal ölçüt (657 sayılı Kanun md. 73): aynı kurum ve aynı sınıf.
/// [unvan] yasal şart değildir; eşleşme puanını etkiler, kurumlar farklı
/// unvanı uygun bulmayabilir.
class Ilan {
  const Ilan({
    required this.id,
    required this.kullaniciId,
    required this.kurumId,
    required this.sinif,
    required this.unvan,
    required this.mevcutIl,
    required this.hedefIller,
    this.zincirIzni = true,
    this.maviTik = false,
    this.kurumAdi = '',
    this.gorunenAd = '',
  });

  final String id;
  final String kullaniciId;
  final String kurumId;

  /// Hizmet sınıfı (ör. "Sağlık Hizmetleri", "Eğitim ve Öğretim Hizmetleri").
  final String sinif;
  final String unvan;
  final String mevcutIl;

  /// Tercih sırasına göre hedef iller (ilk eleman en çok istenen).
  final List<String> hedefIller;
  final bool zincirIzni;
  final bool maviTik;

  /// Ekranda gösterilecek kurum adı (ör. "Sağlık Bakanlığı"). Eşleşmeyi etkilemez.
  final String kurumAdi;

  /// Gizlilik gereği yalnızca baş harf + soyad (ör. "M. Demir"). Eşleşmeyi etkilemez.
  final String gorunenAd;

  /// Yasal olarak karşılaştırılabilir grup: aynı kurum + aynı sınıf.
  String get grup => '${normalize(kurumId)}|${normalize(sinif)}';

  /// Bu ilanın sahibi [il] iline gitmek istiyor mu?
  bool hedefliyor(String il) => hedefIller.any((h) => normalize(h) == normalize(il));

  /// [il] hedefleri arasında kaçıncı sırada; yoksa -1.
  int hedefSirasi(String il) =>
      hedefIller.indexWhere((h) => normalize(h) == normalize(il));
}
