import '../../maas/domain/maas_parametreleri.dart';
import '../../maas/domain/memur_maas_hesaplayici.dart';

/// "Zam gelirse maaşım ne olur?" senaryosu: aylık, taban aylık ve yan ödeme katsayıları
/// aynı oranda artırılır (memur maaş zammı katsayılara uygulanır). Gerçek zam oranı
/// toplu sözleşme/kanunla belirlenir; bu yalnızca kullanıcının girdiği oranla yapılan bir tahmindir.
class ZamSonucu {
  const ZamSonucu({required this.oran, required this.eski, required this.yeni});

  final double oran;
  final MaasSonucu eski;
  final MaasSonucu yeni;

  double get netFark => yeni.net - eski.net;
  double get brutFark => yeni.brut - eski.brut;

  /// Netteki yüzde artış (zam oranından düşük olabilir: vergi ve kesintiler orantısız artar).
  double get netYuzde => eski.net <= 0 ? 0 : netFark / eski.net;
}

abstract final class ZamSenaryosu {
  /// [ay] verilen aydaki (kümülatif vergi için) her iki maaşı da hesaplar; varsayılan Ocak,
  /// yani yılın ilk ayı (yeni yıl zamlarının ilk ödemesi).
  static ZamSonucu hesapla(
    MaasGirdisi girdi, {
    required double oran,
    int ay = 1,
    MaasParametreleri temel = MaasParametreleri.temmuzAralik2026,
  }) {
    final o = oran < 0 ? 0.0 : oran;
    return ZamSonucu(
      oran: o,
      eski: MemurMaasHesaplayici(temel).hesapla(girdi, ay: ay),
      yeni: MemurMaasHesaplayici(temel.zamliKatsayilarla(o)).hesapla(girdi, ay: ay),
    );
  }
}
