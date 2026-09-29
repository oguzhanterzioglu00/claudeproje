import 'package:flutter/material.dart';

import '../../core/tema.dart';
import '../maas/domain/memur_maas_hesaplayici.dart';
import '../profil/domain/profil.dart';

/// Yol haritasındaki bir satır.
class YolHaritasiOgesi {
  const YolHaritasiOgesi({
    required this.baslik,
    required this.deger,
    required this.oran,
    required this.renk,
    required this.ikonRengi,
  });

  final String baslik;

  /// Sağda görünen değer ("94 gün").
  final String deger;

  /// İlerleme çubuğu doluluğu, 0-1.
  final double oran;
  final Color renk;
  final Color ikonRengi;
}

/// Ana sayfanın gösterdiği özet.
class AnaSayfaVerisi {
  const AnaSayfaVerisi({
    this.netMaas,
    this.zamFarki,
    this.egri,
    this.maasMesaji,
    this.yolHaritasi = const [],
    this.becayisAlt = 'Eşleşme bul',
    this.bildirimVar = false,
    this.ornek = false,
  });

  /// Tahmini net maaş; hesaplanamıyorsa null ([maasMesaji] gösterilir).
  final int? netMaas;

  /// Önceki döneme göre artış; bilinmiyorsa null (rozet gösterilmez).
  final int? zamFarki;

  /// Maaş grafiği için 0-1 arası noktalar; yoksa çizilmez.
  final List<double>? egri;

  /// [netMaas] null iken kartta gösterilen açıklama.
  final String? maasMesaji;

  final List<YolHaritasiOgesi> yolHaritasi;

  /// Becayiş kısayolunun alt yazısı (durumuna göre).
  final String becayisAlt;
  final bool bildirimVar;

  /// Veri örnekse ekranda "ÖRNEK HESAP" rozeti görünür.
  final bool ornek;

  /// Sonraki katsayı dönemine (memur maaşları her yıl 1 Ocak ve 1 Temmuz'da
  /// güncellenir) kalan gün ve dönemin ne kadarının geçtiği.
  static (int kalanGun, double oran) sonrakiDonem(DateTime bugun) {
    final gun = DateTime(bugun.year, bugun.month, bugun.day);
    final ikinciYari = bugun.month >= 7;
    final baslangic = DateTime(bugun.year, ikinciYari ? 7 : 1, 1);
    final bitis = ikinciYari ? DateTime(bugun.year + 1, 1, 1) : DateTime(bugun.year, 7, 1);
    final toplam = bitis.difference(baslangic).inDays;
    return (bitis.difference(gun).inDays, gun.difference(baslangic).inDays / toplam);
  }

  /// Profilden ana sayfa özeti üretir. Uydurma rakam üretmez: maaş için profilde
  /// bordro girdisi yoksa açıklayıcı bir mesaj gösterilir.
  factory AnaSayfaVerisi.profilden(
    Profil p, {
    required DateTime bugun,
    required String becayisAlt,
    bool bildirimVar = false,
    MemurMaasHesaplayici hesaplayici = const MemurMaasHesaplayici(),
  }) {
    int? net;
    String? mesaj;
    if (p.statu != Statu.memur657) {
      mesaj = 'Maaş hesabı şu an yalnızca 657 memurları için. ${p.statu.etiket} için yakında.';
    } else if (p.maas == null) {
      mesaj = 'Maaşını görmek için derece, kademe ve hizmet yılını gir.';
    } else {
      net = hesaplayici.hesapla(p.maas!, ay: bugun.month).net.round();
    }

    final donem = p.statu == Statu.memur657 ? sonrakiDonem(bugun) : null;
    return AnaSayfaVerisi(
      netMaas: net,
      maasMesaji: mesaj,
      becayisAlt: becayisAlt,
      bildirimVar: bildirimVar,
      yolHaritasi: [
        if (donem != null)
          YolHaritasiOgesi(
            baslik: 'Sonraki maaş dönemi',
            deger: '${donem.$1} gün',
            oran: donem.$2,
            renk: PusulaRenk.amber,
            ikonRengi: PusulaRenk.lacivert,
          ),
      ],
    );
  }

  /// Tasarım/demo için örnek özet.
  static const ornekVeri = AnaSayfaVerisi(
    netMaas: 41250,
    zamFarki: 3450,
    egri: [0.24, 0.34, 0.28, 0.52, 0.44, 0.78, 1.0],
    becayisAlt: '1 yeni eşleşme',
    bildirimVar: true,
    ornek: true,
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
