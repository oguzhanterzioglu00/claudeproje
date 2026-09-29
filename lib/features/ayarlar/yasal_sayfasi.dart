import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/bilesenler.dart';
import '../../core/tema.dart';
import '../../core/yukselen.dart';
import 'yasal_metinler.dart';

/// Yasal metin (aydınlatma metni, kullanım koşulları) okuma sayfası. [taslak] doğruysa belirgin uyarı gösterir.
class YasalSayfasi extends StatelessWidget {
  const YasalSayfasi({super.key, required this.metin, this.taslak = false});

  final YasalMetin metin;

  /// Yer tutucu içeren bir metin gösteriliyorsa true verilir.
  final bool taslak;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
        children: [
          Yukselen(
            child: GeriBaslik(ustYazi: 'Gizlilik ve yasal', baslik: _kisaBaslik, sag: const SizedBox.shrink()),
          ),
          const SizedBox(height: 16),
          if (taslak) ...[
            Semantics(
              container: true,
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFFF1D6), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.triangleAlert, size: 20, color: PusulaRenk.lacivert),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(YasalMetinler.taslakUyarisi, style: PusulaYazi.metin(13, agirlik: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(metin.baslik, style: PusulaYazi.baslik(22, aralik: -0.9)),
          const SizedBox(height: 4),
          Text(
            metin.guncelleme,
            style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w600),
          ),
          for (var i = 0; i < metin.bolumler.length; i++) ...[
            const SizedBox(height: 20),
            Text(
              '${i + 1}. ${metin.bolumler[i].baslik}',
              style: PusulaYazi.baslik(16, aralik: -0.4, agirlik: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(metin.bolumler[i].metin, style: PusulaYazi.metin(14, agirlik: FontWeight.w500).copyWith(height: 1.5)),
          ],
        ],
      ),
    ),
  );

  String get _kisaBaslik => metin.baslik.split(' (').first;
}
