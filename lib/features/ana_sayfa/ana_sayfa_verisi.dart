import 'package:flutter/material.dart';

import '../../core/tema.dart';

/// Yol haritasındaki bir satır (sonraki zam, kademe atlama, emeklilik).
class YolHaritasiOgesi {
  const YolHaritasiOgesi({
    required this.baslik,
    required this.deger,
    required this.oran,
    required this.renk,
    required this.ikonRengi,
  });

  final String baslik;

  /// Sağda görünen değer ("94 gün", "9 ay", "12 yıl").
  final String deger;

  /// İlerleme çubuğu doluluğu, 0-1.
  final double oran;
  final Color renk;
  final Color ikonRengi;
}

/// Ana sayfanın gösterdiği özet. Gerçek sürümde maaş motoru ve profil
/// bilgisinden hesaplanır; şimdilik örnek veridir.
class AnaSayfaVerisi {
  const AnaSayfaVerisi({
    required this.netMaas,
    required this.zamFarki,
    required this.egri,
    required this.yolHaritasi,
    required this.yeniEslesme,
    this.bildirimVar = true,
    this.ornek = true,
  });

  final int netMaas;
  final int zamFarki;

  /// Maaş grafiği için 0-1 arası (1 = en yüksek) noktalar; en az iki.
  final List<double> egri;
  final List<YolHaritasiOgesi> yolHaritasi;
  final int yeniEslesme;
  final bool bildirimVar;

  /// Veri örnekse ekranda "ÖRNEK HESAP" rozeti görünür.
  final bool ornek;

  static const ornekVeri = AnaSayfaVerisi(
    netMaas: 41250,
    zamFarki: 3450,
    egri: [0.24, 0.34, 0.28, 0.52, 0.44, 0.78, 1.0],
    yeniEslesme: 1,
    yolHaritasi: [
      YolHaritasiOgesi(
        baslik: 'Sonraki zam',
        deger: '94 gün',
        oran: 0.48,
        renk: PusulaRenk.amber,
        ikonRengi: PusulaRenk.lacivert,
      ),
      YolHaritasiOgesi(
        baslik: 'Kademe atlama',
        deger: '9 ay',
        oran: 0.70,
        renk: PusulaRenk.mor,
        ikonRengi: PusulaRenk.beyaz,
      ),
      YolHaritasiOgesi(
        baslik: 'Emeklilik',
        deger: '12 yıl',
        oran: 0.22,
        renk: PusulaRenk.turkuaz,
        ikonRengi: PusulaRenk.lacivert,
      ),
    ],
  );
}
