import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/tema.dart';
import '../../../core/ucgenler.dart';

/// Araç sayfalarındaki koyu sonuç kartı: üstte etiket, büyük değer, altında ayrıntı satırları.
class SonucKarti extends StatelessWidget {
  const SonucKarti({
    super.key,
    required this.etiket,
    required this.deger,
    this.altYazi,
    this.satirlar = const [],
    this.renk = PusulaRenk.lacivert,
    this.anlamsalEtiket,
  });

  final String etiket;
  final String deger;
  final String? altYazi;
  final List<(String, String)> satirlar;
  final Color renk;

  /// Ekran okuyucuya okunacak tam cümle (boşsa etiket ve değer birleştirilir).
  final String? anlamsalEtiket;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: anlamsalEtiket ?? '$etiket: $deger',
        excludeSemantics: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            color: renk,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Stack(
              children: [
                const Positioned(
                  right: -50,
                  top: -40,
                  child: Opacity(opacity: 0.16, child: PusulaUcgenler(boyut: 190, orta: PusulaRenk.beyaz)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(etiket, style: PusulaYazi.metin(13, renk: const Color(0xFFC9D2EC), agirlik: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(deger, style: PusulaYazi.baslik(38, renk: PusulaRenk.beyaz, aralik: -1.8)),
                    if (altYazi != null) ...[
                      const SizedBox(height: 4),
                      Text(altYazi!, style: PusulaYazi.metin(13, renk: PusulaRenk.amber, agirlik: FontWeight.w700)),
                    ],
                    if (satirlar.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      for (final (ad, d) in satirlar)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(ad,
                                  style: PusulaYazi.metin(13, renk: const Color(0xFFC9D2EC), agirlik: FontWeight.w600)),
                              Text(d, style: PusulaYazi.metin(14, renk: PusulaRenk.beyaz, agirlik: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

/// Sayfa altı açıklama/uyarı notu.
class NotSatiri extends StatelessWidget {
  const NotSatiri(this.metin, {super.key, this.ikon = LucideIcons.info});

  final String metin;
  final IconData ikon;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: Icon(ikon, size: 18, color: PusulaRenk.soluk)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              metin,
              style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w500).copyWith(height: 1.45),
            ),
          ),
        ],
      );
}
