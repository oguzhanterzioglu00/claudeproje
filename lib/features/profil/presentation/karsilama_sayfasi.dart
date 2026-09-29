import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/bilesenler.dart';
import '../../../core/tema.dart';
import '../../../core/ucgenler.dart';
import '../../../core/yukselen.dart';

/// İlk açılış karşılaması: marka, uygulamanın ne sunduğu ve gizlilik güvencesi.
class KarsilamaSayfasi extends StatelessWidget {
  const KarsilamaSayfasi({super.key, required this.onBasla});

  final VoidCallback onBasla;

  static const _ozellikler = <(IconData, Color, Color, String, String)>[
    (LucideIcons.calculator, PusulaRenk.amber, PusulaRenk.lacivert, 'Maaşını hesapla',
        'Güncel katsayılarla tahmini net maaş'),
    (LucideIcons.sparkles, PusulaRenk.mor, PusulaRenk.beyaz, 'Hakkım ne?',
        'Cevaplar mevzuat maddesiyle, kaynağıyla gelir'),
    (LucideIcons.arrowRightLeft, PusulaRenk.turkuaz, PusulaRenk.lacivert, 'Becayiş',
        'Karşılıklı yer değiştirme eşleşmeleri'),
    (LucideIcons.briefcase, PusulaRenk.eflatun, PusulaRenk.beyaz, 'İlanlar ve gündem',
        'Kamu ilanları ve gelişmeler tek yerde'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: PusulaRenk.lacivert,
        body: Stack(
          children: [
            // Köşeden taşan, silik logo deseni.
            const Positioned(
              right: -70,
              top: -40,
              child: Opacity(opacity: 0.10, child: PusulaUcgenler(boyut: 300, orta: PusulaRenk.mavi)),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, kisit) => SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: kisit.maxHeight - 48),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Yukselen(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: PusulaRenk.beyaz.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(color: PusulaRenk.beyaz.withValues(alpha: 0.18)),
                                  ),
                                  child: const PusulaUcgenler(boyut: 64, orta: PusulaRenk.mavi),
                                ),
                              ),
                              const SizedBox(height: 26),
                              Yukselen(
                                gecikme: const Duration(milliseconds: 100),
                                child: Text('Kamu Pusulası',
                                    style: PusulaYazi.baslik(38, renk: PusulaRenk.beyaz, aralik: -1.8)),
                              ),
                              const SizedBox(height: 10),
                              Yukselen(
                                gecikme: const Duration(milliseconds: 180),
                                child: Text(
                                  'Memur, sözleşmeli ve işçi — tüm kamu çalışanlarının cebindeki rehber.',
                                  style: PusulaYazi.metin(16, renk: const Color(0xFFC9D2EC), agirlik: FontWeight.w500)
                                      .copyWith(height: 1.45),
                                ),
                              ),
                              const SizedBox(height: 30),
                              for (var i = 0; i < _ozellikler.length; i++) ...[
                                Yukselen(
                                  gecikme: Duration(milliseconds: 260 + i * 80),
                                  child: _Ozellik(
                                    ikon: _ozellikler[i].$1,
                                    renk: _ozellikler[i].$2,
                                    ikonRengi: _ozellikler[i].$3,
                                    baslik: _ozellikler[i].$4,
                                    alt: _ozellikler[i].$5,
                                  ),
                                ),
                                if (i < _ozellikler.length - 1) const SizedBox(height: 14),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                    child: Column(
                      children: [
                        BirincilDugme(yukseklik: 58, metin: 'Başlayalım', ikon: LucideIcons.arrowRight, onPressed: onBasla),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.shield, size: 15, color: Color(0xFFC9D2EC)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Bilgilerin yalnızca bu cihazda saklanır',
                                style: PusulaYazi.metin(12, renk: const Color(0xFFC9D2EC), agirlik: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Ozellik extends StatelessWidget {
  const _Ozellik({
    required this.ikon,
    required this.renk,
    required this.ikonRengi,
    required this.baslik,
    required this.alt,
  });

  final IconData ikon;
  final Color renk;
  final Color ikonRengi;
  final String baslik;
  final String alt;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: '$baslik. $alt',
        excludeSemantics: true,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(15)),
              child: Icon(ikon, size: 23, color: ikonRengi),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik, style: PusulaYazi.metin(16, renk: PusulaRenk.beyaz, agirlik: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(alt,
                      style: PusulaYazi.metin(13, renk: const Color(0xFFC9D2EC), agirlik: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      );
}
