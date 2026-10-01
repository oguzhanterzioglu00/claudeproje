import 'package:flutter/material.dart';

import 'bilesenler.dart';
import 'hareket.dart';
import 'tema.dart';

/// Boş ve hata durumlarında gösterilen illüstrasyonun türü. Her biri aynı `viewBox`taki üç katmandır:
/// `assets/gorsel/bos/<ad>_zemin|orta|on.svg`.
enum BosGorselTuru {
  arama('arama', 'Büyüteç ve belge çizimi'),
  baglanti('baglanti', 'Bulut ve kesik bağlantı çizimi'),
  kayit('kayit', 'Yer imi çizimi'),
  haber('haber', 'Gazete çizimi'),
  alarm('alarm', 'Çalan zil çizimi');

  const BosGorselTuru(this._ad, this.aciklama);

  final String _ad;
  final String aciklama;

  List<GorselKatmani> get katmanlar => [
    GorselKatmani('assets/gorsel/bos/${_ad}_zemin.svg', nefes: 0.04, hiz: 1, derinlik: 0.3),
    GorselKatmani('assets/gorsel/bos/${_ad}_orta.svg', suzulme: 3.5, hiz: 2, faz: 0.2, derinlik: 0.7),
    GorselKatmani('assets/gorsel/bos/${_ad}_on.svg', suzulme: 6, donme: 0.04, hiz: 3, faz: 0.55, derinlik: 1.2),
  ];
}

/// Çizimli boş/hata kartı: illüstrasyon, başlık, açıklama ve isteğe bağlı eylem düğmesi.
class BosDurum extends StatelessWidget {
  const BosDurum({
    super.key,
    required this.gorsel,
    required this.baslik,
    required this.alt,
    this.dugme,
    this.onDugme,
    this.gorselYuksekligi = 132,
  });

  final BosGorselTuru gorsel;
  final String baslik;
  final String alt;
  final String? dugme;
  final VoidCallback? onDugme;

  /// Çizimin yüksekliği; dar alanlarda (alt sayfa) küçültülür.
  final double gorselYuksekligi;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
    decoration: BoxDecoration(
      color: PusulaRenk.beyaz,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: PusulaRenk.lacivert, width: 1.5),
    ),
    child: Column(
      children: [
        SizedBox(
          height: gorselYuksekligi,
          child: HareketliGorsel(katmanlar: gorsel.katmanlar, anlamEtiketi: gorsel.aciklama),
        ),
        const SizedBox(height: 6),
        Text(baslik, textAlign: TextAlign.center, style: PusulaYazi.metin(16, agirlik: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          alt,
          textAlign: TextAlign.center,
          style: PusulaYazi.metin(13, renk: PusulaRenk.soluk, agirlik: FontWeight.w500),
        ),
        if (dugme != null) ...[
          const SizedBox(height: 16),
          BirincilDugme(metin: dugme!, onPressed: onDugme, yukseklik: 48),
        ],
      ],
    ),
  );
}
