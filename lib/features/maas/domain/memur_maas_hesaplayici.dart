import 'gosterge_tablosu.dart';
import 'maas_parametreleri.dart';

/// Kullanıcının bordrosundan bildiği girdiler.
class MaasGirdisi {
  const MaasGirdisi({
    required this.derece,
    required this.kademe,
    this.hizmetYili = 0,
    this.ekGosterge = 0,
    this.yanOdemePuani = 0,
    this.ozelHizmetTazminatiOrani = 0,
    this.digerBrut = 0,
  });

  final int derece;
  final int kademe;

  /// Kıdem aylığına esas hizmet yılı.
  final int hizmetYili;

  /// Unvana bağlı ek gösterge rakamı (bordroda yazar).
  final int ekGosterge;

  /// Unvana bağlı yan ödeme puanı.
  final int yanOdemePuani;

  /// 0-1 arası oran (ör. %50 için 0.5).
  final double ozelHizmetTazminatiOrani;

  /// Yukarıdakilere girmeyen brüt ödemeler (ek ödeme vb.), TL. SGK matrahına
  /// dahil edilmez; gelir ve damga vergisine dahil edilir.
  final double digerBrut;

  MaasGirdisi kopya({
    int? derece,
    int? kademe,
    int? hizmetYili,
    int? ekGosterge,
    int? yanOdemePuani,
    double? ozelHizmetTazminatiOrani,
    double? digerBrut,
  }) =>
      MaasGirdisi(
        derece: derece ?? this.derece,
        kademe: kademe ?? this.kademe,
        hizmetYili: hizmetYili ?? this.hizmetYili,
        ekGosterge: ekGosterge ?? this.ekGosterge,
        yanOdemePuani: yanOdemePuani ?? this.yanOdemePuani,
        ozelHizmetTazminatiOrani: ozelHizmetTazminatiOrani ?? this.ozelHizmetTazminatiOrani,
        digerBrut: digerBrut ?? this.digerBrut,
      );

  Map<String, Object?> toJson() => {
        'derece': derece,
        'kademe': kademe,
        'hizmetYili': hizmetYili,
        'ekGosterge': ekGosterge,
        'yanOdemePuani': yanOdemePuani,
        'ozelHizmetTazminatiOrani': ozelHizmetTazminatiOrani,
        'digerBrut': digerBrut,
      };

  /// Bozuk kayıtta (yanlış tipler, aşırı değerler) geçersiz derece/kademe motoru
  /// düşürmesin diye değerler güvenli aralığa çekilir; asla hata fırlatmaz.
  factory MaasGirdisi.fromJson(Map<String, Object?> j) {
    int tam(String k, int varsayilan) => j[k] is num ? (j[k]! as num).toInt() : varsayilan;
    double ondalik(String k) => j[k] is num ? (j[k]! as num).toDouble() : 0.0;

    final derece = tam('derece', 1).clamp(1, GostergeTablosu.enUstDerece);
    return MaasGirdisi(
      derece: derece,
      kademe: GostergeTablosu.kademeSinirla(derece, tam('kademe', 1)),
      hizmetYili: tam('hizmetYili', 0).clamp(0, 60),
      ekGosterge: tam('ekGosterge', 0).clamp(0, 100000),
      yanOdemePuani: tam('yanOdemePuani', 0).clamp(0, 100000),
      ozelHizmetTazminatiOrani: ondalik('ozelHizmetTazminatiOrani').clamp(0.0, 10.0),
      digerBrut: ondalik('digerBrut').clamp(0.0, 10000000.0),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MaasGirdisi &&
      other.derece == derece &&
      other.kademe == kademe &&
      other.hizmetYili == hizmetYili &&
      other.ekGosterge == ekGosterge &&
      other.yanOdemePuani == yanOdemePuani &&
      other.ozelHizmetTazminatiOrani == ozelHizmetTazminatiOrani &&
      other.digerBrut == digerBrut;

  @override
  int get hashCode =>
      Object.hash(derece, kademe, hizmetYili, ekGosterge, yanOdemePuani, ozelHizmetTazminatiOrani, digerBrut);
}

class MaasSonucu {
  const MaasSonucu({
    required this.gostergeAyligi,
    required this.ekGostergeAyligi,
    required this.tabanAylik,
    required this.kidemAyligi,
    required this.yanOdeme,
    required this.ozelHizmetTazminati,
    required this.digerBrut,
    required this.brut,
    required this.emeklilikPayi,
    required this.gss,
    required this.gelirVergisi,
    required this.damgaVergisi,
    required this.net,
  });

  final double gostergeAyligi;
  final double ekGostergeAyligi;
  final double tabanAylik;
  final double kidemAyligi;
  final double yanOdeme;
  final double ozelHizmetTazminati;
  final double digerBrut;
  final double brut;
  final double emeklilikPayi;
  final double gss;
  final double gelirVergisi;
  final double damgaVergisi;
  final double net;

  double get kesintiToplami => brut - net;
}

/// 657 sayılı Kanun'a tabi memur maaşının tahmini brüt/net hesabı.
///
/// Brüt kalemleri kanundaki formüllere göredir (gösterge, ek gösterge, taban
/// aylık, kıdem aylığı, yan ödeme, özel hizmet tazminatı). Net için memur payı
/// SGK/GSS kesintileri, damga vergisi ve kümülatif gelir vergisi (asgari ücret
/// istisnası düşülerek) uygulanır.
///
/// Varsayımlar (sonuç bu yüzden "tahmini"dir):
/// - Aylık tutar yıl boyunca sabit kabul edilir; dönem içinde zam veya statü
///   değişimi kümülatif vergiyi etkiler.
/// - Özel hizmet tazminatı matrahı (gösterge + ek gösterge) × aylık katsayıdır.
/// - Yan ödeme ve [MaasGirdisi.digerBrut] SGK matrahına girmez.
/// - Aile/çocuk yardımı, ek ödeme, fazla mesai gibi kişisel kalemler dahil değildir
///   (isteğe bağlı olarak [MaasGirdisi.digerBrut] ile eklenir).
class MemurMaasHesaplayici {
  const MemurMaasHesaplayici([this.parametreler = MaasParametreleri.temmuzAralik2026]);

  final MaasParametreleri parametreler;

  /// [ay] 1-12: kümülatif gelir vergisi bu aya göre hesaplanır.
  MaasSonucu hesapla(MaasGirdisi g, {int ay = 1}) {
    if (ay < 1 || ay > 12) throw ArgumentError.value(ay, 'ay', '1-12 olmalı');
    final p = parametreler;
    final gosterge = GostergeTablosu.gosterge(g.derece, g.kademe);

    final gostergeAyligi = gosterge * p.aylikKatsayi;
    final ekGostergeAyligi = g.ekGosterge * p.aylikKatsayi;
    final tabanAylik = p.tabanGosterge * p.tabanAylikKatsayi;
    final yil = g.hizmetYili.clamp(0, p.enFazlaKidemYili);
    final kidemAyligi = yil * p.yillikKidemGostergesi * p.aylikKatsayi;
    final yanOdeme = g.yanOdemePuani * p.yanOdemeKatsayi;
    final tazminat = g.ozelHizmetTazminatiOrani * (gosterge + g.ekGosterge) * p.aylikKatsayi;

    final sgkMatrahi = gostergeAyligi + ekGostergeAyligi + tabanAylik + kidemAyligi + tazminat;
    final brut = sgkMatrahi + yanOdeme + g.digerBrut;

    final emeklilik = sgkMatrahi * p.emeklilikPayi;
    final gss = sgkMatrahi * p.gssPayi;
    final gelirMatrahi = brut - emeklilik - gss;

    final vergi = _tarife(ay * gelirMatrahi) - _tarife((ay - 1) * gelirMatrahi);
    final asgariMatrah = p.asgariUcretBrut * (1 - p.asgariUcretSgkKesintisi);
    final istisna = _tarife(ay * asgariMatrah) - _tarife((ay - 1) * asgariMatrah);
    final gelirVergisi = _sifirdanKucukseSifir(vergi - istisna);
    final damga = _sifirdanKucukseSifir(brut * p.damgaOrani - p.asgariUcretDamgaIstisnasi);

    return MaasSonucu(
      gostergeAyligi: gostergeAyligi,
      ekGostergeAyligi: ekGostergeAyligi,
      tabanAylik: tabanAylik,
      kidemAyligi: kidemAyligi,
      yanOdeme: yanOdeme,
      ozelHizmetTazminati: tazminat,
      digerBrut: g.digerBrut,
      brut: brut,
      emeklilikPayi: emeklilik,
      gss: gss,
      gelirVergisi: gelirVergisi,
      damgaVergisi: damga,
      net: brut - emeklilik - gss - gelirVergisi - damga,
    );
  }

  /// Kümülatif matrah için toplam gelir vergisi (kademeli tarife).
  double _tarife(double matrah) {
    var vergi = 0.0;
    var alt = 0.0;
    for (final (ust, oran) in parametreler.gelirVergisiDilimleri) {
      if (matrah > alt) vergi += ((matrah < ust ? matrah : ust) - alt) * oran;
      alt = ust;
    }
    return vergi;
  }

  static double _sifirdanKucukseSifir(double x) => x < 0 ? 0 : x;
}
