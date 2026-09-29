import '../../maas/domain/gosterge_tablosu.dart';
import '../../maas/domain/maas_parametreleri.dart';

/// Bir derece-kademenin temel aylık bilgisi (kanunun 154. maddesindeki gösterge cetveli).
class DereceSatiri {
  const DereceSatiri(
      {required this.derece,
      required this.kademe,
      required this.gosterge,
      required this.gostergeAyligi,
      required this.temelAylik});

  final int derece;
  final int kademe;
  final int gosterge;

  /// Gösterge rakamı × aylık katsayı.
  final double gostergeAyligi;

  /// Gösterge aylığı + taban aylık (ek gösterge, kıdem, yan ödeme, tazminat hariç), brüt.
  final double temelAylik;
}

abstract final class DereceTablosu {
  static List<DereceSatiri> satirlar(int derece,
      {MaasParametreleri parametreler = MaasParametreleri.temmuzAralik2026}) {
    final taban = parametreler.tabanGosterge * parametreler.tabanAylikKatsayi;
    return [
      for (var k = 1; k <= GostergeTablosu.kademeSayisi(derece); k++)
        () {
          final g = GostergeTablosu.gosterge(derece, k);
          final ga = g * parametreler.aylikKatsayi;
          return DereceSatiri(derece: derece, kademe: k, gosterge: g, gostergeAyligi: ga, temelAylik: ga + taban);
        }(),
    ];
  }
}
