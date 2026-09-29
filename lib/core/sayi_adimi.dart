import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'bilesenler.dart';
import 'tema.dart';

/// Etiketli, büyük sayı gösteren ve −/+ düğmeleriyle değiştirilen alan.
class SayiAdimi extends StatelessWidget {
  const SayiAdimi({
    super.key,
    required this.etiket,
    required this.deger,
    required this.eksiEtiketi,
    required this.artiEtiketi,
    required this.onEksi,
    required this.onArti,
    this.alt,
  });

  final String etiket;
  final String? alt;
  final String deger;
  final String eksiEtiketi;
  final String artiEtiketi;
  final VoidCallback? onEksi;
  final VoidCallback? onArti;

  @override
  Widget build(BuildContext context) => PusulaKart(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiket, style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
                  Text(deger, style: PusulaYazi.baslik(28, aralik: -1)),
                  if (alt != null)
                    Text(alt!, style: PusulaYazi.metin(11, renk: PusulaRenk.soluk, agirlik: FontWeight.w500)),
                ],
              ),
            ),
            YuvarlakDugme(LucideIcons.minus, eksiEtiketi, onEksi),
            const SizedBox(width: 8),
            YuvarlakDugme(LucideIcons.plus, artiEtiketi, onArti),
          ],
        ),
      );
}

/// Yuvarlatılmış kare, amber ikon düğmesi.
class YuvarlakDugme extends StatelessWidget {
  const YuvarlakDugme(this.ikon, this.etiket, this.onTap, {super.key});

  final IconData ikon;
  final String etiket;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onTap != null,
        label: etiket,
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: onTap == null ? PusulaRenk.cizgi : PusulaRenk.amber,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 48,
              child: Icon(ikon, size: 22, color: onTap == null ? PusulaRenk.soluk : PusulaRenk.lacivert),
            ),
          ),
        ),
      );
}
