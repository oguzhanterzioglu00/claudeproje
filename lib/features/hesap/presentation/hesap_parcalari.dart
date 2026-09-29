import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/tema.dart';

/// Şifre yazılırken kuralların karşılanıp karşılanmadığını gösterir.
class SifreKurallari extends StatelessWidget {
  const SifreKurallari({super.key, required this.sifre});

  final String sifre;

  @override
  Widget build(BuildContext context) {
    final kurallar = <(String, bool)>[
      ('En az 8 karakter', sifre.length >= 8),
      ('Harf', sifre.contains(RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]'))),
      ('Rakam', sifre.contains(RegExp(r'\d'))),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final k in kurallar)
          Semantics(
            container: true,
            label: '${k.$1}${k.$2 ? ', sağlandı' : ''}',
            excludeSemantics: true,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: k.$2 ? PusulaRenk.yesilZemin : PusulaRenk.cizgi,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(k.$2 ? LucideIcons.check : LucideIcons.circle,
                      size: 13, color: k.$2 ? PusulaRenk.yesilYazi : PusulaRenk.soluk),
                  const SizedBox(width: 5),
                  Text(k.$1,
                      style: PusulaYazi.metin(12,
                          renk: k.$2 ? PusulaRenk.yesilYazi : PusulaRenk.soluk, agirlik: FontWeight.w700)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class HataKutusu extends StatelessWidget {
  const HataKutusu({super.key, required this.mesaj});

  final String mesaj;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFCE8E4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.circleAlert, size: 18, color: PusulaRenk.kirmizi),
              const SizedBox(width: 8),
              Expanded(
                child:
                    Text(mesaj, style: PusulaYazi.metin(13, renk: const Color(0xFF8A2A1B), agirlik: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
}
