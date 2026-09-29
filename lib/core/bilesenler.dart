import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'tema.dart';

/// Beyaz zeminli, lacivert çerçeveli kart (tasarımdaki ortak kart).
class PusulaKart extends StatelessWidget {
  const PusulaKart({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 26,
    this.onTap,
    this.renk = PusulaRenk.beyaz,
    this.cerceve = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color renk;
  final bool cerceve;

  @override
  Widget build(BuildContext context) {
    final sekil = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: cerceve
          ? const BorderSide(color: PusulaRenk.lacivert, width: 1.5)
          : BorderSide.none,
    );
    return Material(
      color: renk,
      shape: sekil,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Küçük yuvarlak etiket.
class Hap extends StatelessWidget {
  const Hap(
    this.metin, {
    super.key,
    this.zemin = PusulaRenk.lacivert,
    this.yazi = PusulaRenk.amber,
    this.ikon,
    this.boyut = 12,
  });

  final String metin;
  final Color zemin;
  final Color yazi;
  final IconData? ikon;
  final double boyut;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(ikon == null ? 10 : 8, 5, 10, 5),
        decoration: BoxDecoration(color: zemin, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ikon != null) ...[
              Icon(ikon, size: 14, color: yazi),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                metin,
                overflow: TextOverflow.ellipsis,
                style: PusulaYazi.metin(boyut, renk: yazi, agirlik: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

/// "ÖRNEK" rozeti: gerçek veri bağlanana kadar ekranlarda görünür.
class OrnekRozeti extends StatelessWidget {
  const OrnekRozeti({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: PusulaRenk.lacivert,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text('ÖRNEK', style: PusulaYazi.metin(11, renk: PusulaRenk.amber, agirlik: FontWeight.w700)),
      );
}

/// Geri düğmeli ekran başlığı.
class GeriBaslik extends StatelessWidget {
  const GeriBaslik({
    super.key,
    required this.ustYazi,
    required this.baslik,
    this.sag = const OrnekRozeti(),
  });

  final String ustYazi;
  final String baslik;
  final Widget sag;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Semantics(
            button: true,
            label: 'Geri',
            excludeSemantics: true,
            child: Material(
              color: PusulaRenk.beyaz,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: PusulaRenk.lacivert, width: 1.5),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.maybePop(context),
                child: const SizedBox.square(
                  dimension: 44,
                  child: Icon(LucideIcons.arrowLeft, size: 22, color: PusulaRenk.lacivert),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ustYazi,
                    overflow: TextOverflow.ellipsis,
                    style: PusulaYazi.metin(12, renk: PusulaRenk.soluk, agirlik: FontWeight.w700)),
                Text(baslik, style: PusulaYazi.baslik(24, aralik: -1)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          sag,
        ],
      );
}

/// Ana eylem düğmesi (amber) veya koyu ikincil (lacivert).
class BirincilDugme extends StatelessWidget {
  const BirincilDugme({
    super.key,
    required this.metin,
    required this.onPressed,
    this.ikon,
    this.zemin = PusulaRenk.amber,
    this.yazi = PusulaRenk.lacivert,
    this.yukseklik = 54,
    this.yukleniyor = false,
    this.yukleniyorMetni = '',
  });

  final String metin;
  final VoidCallback? onPressed;
  final IconData? ikon;
  final Color zemin;
  final Color yazi;
  final double yukseklik;
  final bool yukleniyor;
  final String yukleniyorMetni;

  @override
  Widget build(BuildContext context) {
    final pasif = onPressed == null || yukleniyor;
    final bg = onPressed == null && !yukleniyor ? const Color(0xFFC9CCD6) : zemin;
    final fg = onPressed == null && !yukleniyor ? PusulaRenk.soluk : yazi;
    return SizedBox(
      height: yukseklik,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(yukseklik / 2.6),
        child: InkWell(
          borderRadius: BorderRadius.circular(yukseklik / 2.6),
          onTap: pasif ? null : onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (yukleniyor)
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
                  )
                else if (ikon != null)
                  Icon(ikon, size: 20, color: fg),
                if (yukleniyor || ikon != null) const SizedBox(width: 8),
                Text(
                  yukleniyor ? yukleniyorMetni : metin,
                  style: PusulaYazi.metin(15, renk: fg, agirlik: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tasarımdaki alt sayfa (bottom sheet).
abstract final class AltSayfa {
  static Future<T?> goster<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool kapatilabilir = true,
  }) =>
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        isDismissible: kapatilabilir,
        enableDrag: kapatilabilir,
        backgroundColor: PusulaRenk.beyaz,
        barrierColor: const Color(0x99182350),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        builder: (c) => Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 26 + MediaQuery.viewInsetsOf(c).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: PusulaRenk.cizgi,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              builder(c),
            ],
          ),
        ),
      );
}

/// Yüzde skoru gösteren halka. Değer değişince eski değerden yenisine akar.
class SkorHalkasi extends StatelessWidget {
  const SkorHalkasi({
    super.key,
    required this.skor,
    this.boyut = 56,
    this.kalinlik = 5,
    this.yaziBoyutu = 15,
    this.iz = PusulaRenk.cizgi,
    this.yaziRengi = PusulaRenk.lacivert,
    this.yuzdeIsareti = false,
  });

  final int skor;
  final double boyut;
  final double kalinlik;
  final double yaziBoyutu;
  final Color iz;
  final Color yaziRengi;
  final bool yuzdeIsareti;

  @override
  Widget build(BuildContext context) {
    final hareketsiz = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Uyum skoru yüzde $skor',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: boyut,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: hareketsiz ? skor / 100 : 0, end: skor / 100),
          duration: hareketsiz ? Duration.zero : const Duration(milliseconds: 1400),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: v,
                  strokeWidth: kalinlik,
                  strokeCap: StrokeCap.round,
                  backgroundColor: iz,
                  color: PusulaRenk.amber,
                ),
              ),
              Text.rich(
                TextSpan(
                  text: '${(v * 100).round()}',
                  style: PusulaYazi.baslik(yaziBoyutu, renk: yaziRengi, aralik: -0.5),
                  children: [
                    if (yuzdeIsareti)
                      TextSpan(text: '%', style: PusulaYazi.baslik(yaziBoyutu / 1.9, renk: yaziRengi, aralik: 0)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
