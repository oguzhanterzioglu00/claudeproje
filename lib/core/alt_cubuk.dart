import 'package:flutter/material.dart';

import 'tema.dart';

/// Alt gezinme çubuğundaki bir sekme.
class AltSekme {
  const AltSekme({required this.etiket, required this.ikon});

  final String etiket;
  final IconData ikon;
}

/// Tasarımdaki yüzen lacivert alt çubuk: seçili sekme amber hap içinde etiketiyle,
/// diğerleri yalnızca ikonla görünür.
class PusulaAltCubuk extends StatelessWidget {
  const PusulaAltCubuk({
    super.key,
    required this.sekmeler,
    required this.secili,
    required this.onSec,
  });

  final List<AltSekme> sekmeler;
  final int secili;
  final ValueChanged<int> onSec;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: PusulaRenk.lacivert,
              borderRadius: BorderRadius.circular(34),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < sekmeler.length; i++)
                  _Oge(
                    key: ValueKey('sekme-$i'),
                    sekme: sekmeler[i],
                    secili: i == secili,
                    onTap: () => onSec(i),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _Oge extends StatelessWidget {
  const _Oge({super.key, required this.sekme, required this.secili, required this.onTap});

  final AltSekme sekme;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: secili,
        label: sekme.etiket,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 48,
            constraints: const BoxConstraints(minWidth: 48),
            padding: EdgeInsets.symmetric(horizontal: secili ? 16 : 0),
            decoration: BoxDecoration(
              color: secili ? PusulaRenk.amber : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(sekme.ikon, size: 24, color: secili ? PusulaRenk.lacivert : const Color(0xFFC9D0E0)),
                if (secili) ...[
                  const SizedBox(width: 8),
                  Text(sekme.etiket,
                      style: PusulaYazi.metin(13, renk: PusulaRenk.lacivert, agirlik: FontWeight.w700)),
                ],
              ],
            ),
          ),
        ),
      );
}
