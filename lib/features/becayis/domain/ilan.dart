import '../../../core/metin.dart';

export '../../../core/metin.dart' show normalize;

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

  Ilan copyWith({List<String>? hedefIller, bool? zincirIzni, bool? maviTik}) =>
      Ilan(
        id: id,
        kullaniciId: kullaniciId,
        kurumId: kurumId,
        sinif: sinif,
        unvan: unvan,
        mevcutIl: mevcutIl,
        hedefIller: hedefIller ?? this.hedefIller,
        zincirIzni: zincirIzni ?? this.zincirIzni,
        maviTik: maviTik ?? this.maviTik,
        kurumAdi: kurumAdi,
        gorunenAd: gorunenAd,
      );

  Map<String, Object?> toJson() => {
    'user_id': kullaniciId,
    'kurum_id': kurumId,
    'kurum_adi': kurumAdi,
    'sinif': sinif,
    'unvan': unvan,
    'mevcut_il': mevcutIl,
    'hedef_iller': hedefIller,
    'zincir_izni': zincirIzni,
    'gorunen_ad': gorunenAd,
    'aktif': true,
  };

  factory Ilan.fromJson(Map<String, dynamic> j) => Ilan(
    id: (j['user_id'] ?? '').toString(),
    kullaniciId: (j['user_id'] ?? '').toString(),
    kurumId: (j['kurum_id'] ?? '').toString(),
    kurumAdi: (j['kurum_adi'] ?? '').toString(),
    sinif: (j['sinif'] ?? '').toString(),
    unvan: (j['unvan'] ?? '').toString(),
    mevcutIl: (j['mevcut_il'] ?? '').toString(),
    hedefIller: (j['hedef_iller'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList(growable: false),
    zincirIzni: j['zincir_izni'] == true,
    maviTik: j['mavi_tik'] == true,
    gorunenAd: (j['gorunen_ad'] ?? '').toString(),
  );

  /// Yasal olarak karşılaştırılabilir grup: aynı kurum + aynı sınıf.
  String get grup => '${normalize(kurumId)}|${normalize(sinif)}';

  /// Bu ilanın sahibi [il] iline gitmek istiyor mu?
  bool hedefliyor(String il) =>
      hedefIller.any((h) => normalize(h) == normalize(il));

  /// [il] hedefleri arasında kaçıncı sırada; yoksa -1.
  int hedefSirasi(String il) =>
      hedefIller.indexWhere((h) => normalize(h) == normalize(il));
}
