import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/tema.dart';
import '../../../core/yukselen.dart';

/// Ana sayfadaki "Araçlar" bölümü: izin hakkı, zam senaryosu ve derece tablosu kısayolları.
class AraclarBolumu extends StatelessWidget {
  const AraclarBolumu({super.key, this.izinAc, this.zamAc, this.tabloAc});

  final VoidCallback? izinAc;
  final VoidCallback? zamAc;
  final VoidCallback? tabloAc;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Yukselen(
          gecikme: const Duration(milliseconds: 450),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Araçlar', style: PusulaYazi.baslik(18, agirlik: FontWeight.w700, aralik: -0.4)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Arac(
                      ikon: LucideIcons.calendarCheck,
                      renk: PusulaRenk.turkuaz,
                      ikonRengi: PusulaRenk.lacivert,
                      baslik: 'İzin hakkı',
                      alt: 'Kalan gün',
                      onTap: izinAc,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Arac(
                      ikon: LucideIcons.trendingUp,
                      renk: PusulaRenk.eflatun,
                      ikonRengi: PusulaRenk.beyaz,
                      baslik: 'Zam senaryosu',
                      alt: 'Yeni maaş',
                      onTap: zamAc,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Arac(
                      ikon: LucideIcons.table,
                      renk: PusulaRenk.mavi,
                      ikonRengi: PusulaRenk.beyaz,
                      baslik: 'Derece tablosu',
                      alt: 'Gösterge',
                      onTap: tabloAc,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _Arac extends StatelessWidget {
  const _Arac({
    required this.ikon,
    required this.renk,
    required this.ikonRengi,
    required this.baslik,
    required this.alt,
    required this.onTap,
  });

  final IconData ikon;
  final Color renk;
  final Color ikonRengi;
  final String baslik;
  final String alt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        label: '$baslik, $alt',
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: PusulaRenk.beyaz,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(12)),
                    child: Icon(ikon, size: 20, color: ikonRengi),
                  ),
                  const SizedBox(height: 10),
                  Text(baslik, style: PusulaYazi.metin(13, agirlik: FontWeight.w700).copyWith(height: 1.15)),
                  const SizedBox(height: 2),
                  Text(alt, style: PusulaYazi.metin(11, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      );
}
