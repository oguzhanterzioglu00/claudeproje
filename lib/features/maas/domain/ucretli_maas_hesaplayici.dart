import 'maas_parametreleri.dart';

class UcretliSonucu {
  const UcretliSonucu({
    required this.brut,
    required this.sgkMatrahi,
    required this.sgkPayi,
    required this.issizlik,
    required this.gelirVergisi,
    required this.damgaVergisi,
    required this.net,
  });

  final double brut;

  /// Prime esas kazanç: brüt, asgari ücret (alt) ve tavan (üst) sınırlarına çekilmiş hali.
  final double sgkMatrahi;
  final double sgkPayi;
  final double issizlik;
  final double gelirVergisi;
  final double damgaVergisi;
  final double net;

  double get kesintiToplami => brut - net;
}

/// 4/B sözleşmeli personel ve işçi gibi 5510 sayılı Kanun md. 4/1-(a) kapsamındaki ücretlinin
/// brüt aylık ücretinden tahmini net hesabı.
///
/// Kesintiler (hepsi kaynaklı, bkz. [MaasParametreleri]): SGK işçi payı %14 (sosyal sigorta %9 + genel sağlık
/// %5) ve işsizlik sigortası %1 (prime esas kazanç üzerinden, tavana kadar), damga vergisi binde 7,59
/// (asgari ücrete isabet eden kısım istisna), kümülatif gelir vergisi (asgari ücret istisnası düşülerek).
///
/// Varsayımlar (sonuç bu yüzden "tahmini"dir):
/// - Aylık brüt tutar yıl boyunca sabit kabul edilir; zam, ikramiye, fazla mesai kümülatif vergiyi etkiler.
/// - Sendika aidatı, nafaka, icra kesintisi, özel sağlık sigortası, engelli indirimi gibi kişisel kalemler yoktur.
class UcretliMaasHesaplayici {
  const UcretliMaasHesaplayici([this.parametreler = MaasParametreleri.temmuzAralik2026]);

  final MaasParametreleri parametreler;

  /// [ay] 1-12: kümülatif gelir vergisi bu aya göre hesaplanır.
  UcretliSonucu hesapla(double brut, {int ay = 1}) {
    if (ay < 1 || ay > 12) throw ArgumentError.value(ay, 'ay', '1-12 olmalı');
    final p = parametreler;
    final b = brut < 0 ? 0.0 : brut;

    final taban = p.asgariUcretBrut;
    final tavan = p.asgariUcretBrut * p.sgkTavanKati;
    final sgkMatrahi = b == 0 ? 0.0 : b.clamp(taban, tavan).toDouble();
    // Alt sınırın altındaki kazançta fark işverenin yükümlülüğüdür (5510 md. 82); işçi payı brüt üzerinden alınır.
    final payMatrahi = b > tavan ? tavan : b;
    final sgk = payMatrahi * p.isciSgkPayi;
    final issizlik = payMatrahi * p.issizlikPayi;

    final gelirMatrahi = b - sgk - issizlik;
    final vergi = p.gelirVergisiTarifesi(ay * gelirMatrahi) - p.gelirVergisiTarifesi((ay - 1) * gelirMatrahi);
    final asgariMatrah = p.asgariUcretBrut * (1 - p.asgariUcretSgkKesintisi);
    final istisna = p.gelirVergisiTarifesi(ay * asgariMatrah) - p.gelirVergisiTarifesi((ay - 1) * asgariMatrah);
    final gelirVergisi = _sifirdanKucukseSifir(vergi - istisna);
    final damga = _sifirdanKucukseSifir(b * p.damgaOrani - p.asgariUcretDamgaIstisnasi);

    return UcretliSonucu(
      brut: b,
      sgkMatrahi: sgkMatrahi,
      sgkPayi: sgk,
      issizlik: issizlik,
      gelirVergisi: gelirVergisi,
      damgaVergisi: damga,
      net: b - sgk - issizlik - gelirVergisi - damga,
    );
  }

  static double _sifirdanKucukseSifir(double x) => x < 0 ? 0 : x;
}
