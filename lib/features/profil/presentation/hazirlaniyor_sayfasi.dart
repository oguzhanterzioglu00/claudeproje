import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/logo.dart';
import '../../../core/tema.dart';
import '../../../core/ucgenler.dart';
import '../../../core/yukselen.dart';

/// Kurulum bittikten sonra kısa, animasyonlu "hazırlanıyor" akışı: pusula ibresi
/// yerine oturur, adımlar sırayla işaretlenir; sonra [onBitti] çağrılır.
class HazirlaniyorSayfasi extends StatefulWidget {
  const HazirlaniyorSayfasi({super.key, required this.onBitti, this.ad = '', this.memur = false});

  final VoidCallback onBitti;
  final String ad;

  /// 657 memuru ise maaş ve becayiş adımları gösterilir; değilse yalnızca geçerli olanlar.
  final bool memur;

  @override
  State<HazirlaniyorSayfasi> createState() => _HazirlaniyorSayfasiState();
}

class _HazirlaniyorSayfasiState extends State<HazirlaniyorSayfasi> {
  List<(IconData, String)> get _adimlar => [
        (LucideIcons.userRoundCheck, 'Profilin kaydedildi'),
        if (widget.memur)
          (LucideIcons.calculator, 'Maaş hesabın hazır')
        else
          (LucideIcons.sparkles, 'Hakkım ne? asistanı hazır'),
        if (widget.memur)
          (LucideIcons.arrowRightLeft, 'Becayiş ve ilanlar ayarlandı')
        else
          (LucideIcons.briefcase, 'İlanlar ayarlandı'),
        (LucideIcons.newspaper, 'Gündem yükleniyor'),
      ];

  Timer? _sayac;
  bool _basladi = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_basladi) return;
    _basladi = true;
    final hareketsiz = MediaQuery.disableAnimationsOf(context);
    _sayac = Timer(hareketsiz ? const Duration(milliseconds: 400) : const Duration(milliseconds: 3200), widget.onBitti);
  }

  @override
  void dispose() {
    _sayac?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad.trim().split(RegExp(r'\s+')).first;
    final adimlar = _adimlar;
    return Scaffold(
      backgroundColor: PusulaRenk.lacivert,
      body: Stack(
        children: [
          const Positioned(
            left: -100,
            bottom: -60,
            child: Opacity(opacity: 0.07, child: PusulaUcgenler(boyut: 340, orta: PusulaRenk.mavi)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AnimasyonluPusulaLogo(boyut: 150, arkaplan: false, sure: Duration(milliseconds: 2200)),
                  const SizedBox(height: 28),
                  Yukselen(
                    gecikme: const Duration(milliseconds: 200),
                    child: Text(
                      ad.isEmpty ? 'Hazırlıyoruz' : 'Hazırlıyoruz, $ad',
                      textAlign: TextAlign.center,
                      style: PusulaYazi.baslik(28, renk: PusulaRenk.beyaz, aralik: -1.2),
                    ),
                  ),
                  const SizedBox(height: 28),
                  for (var i = 0; i < adimlar.length; i++) ...[
                    Yukselen(
                      gecikme: Duration(milliseconds: 500 + i * 550),
                      child: _AdimSatiri(ikon: adimlar[i].$1, metin: adimlar[i].$2),
                    ),
                    if (i < adimlar.length - 1) const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdimSatiri extends StatelessWidget {
  const _AdimSatiri({required this.ikon, required this.metin});

  final IconData ikon;
  final String metin;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: PusulaRenk.beyaz.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PusulaRenk.beyaz.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Icon(ikon, size: 20, color: PusulaRenk.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Text(metin, style: PusulaYazi.metin(15, renk: PusulaRenk.beyaz, agirlik: FontWeight.w600)),
            ),
            const Icon(LucideIcons.circleCheck, size: 20, color: PusulaRenk.turkuaz),
          ],
        ),
      );
}
