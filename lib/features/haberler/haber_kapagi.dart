import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/tema.dart';
import '../../core/ucgenler.dart';
import 'haber_modeli.dart';

/// Haberin tür simgesi ve rengi; liste kartları ve slaytlar ortak kullanır.
abstract final class HaberGorunumu {
  static IconData ikon(HaberTuru t) => switch (t) {
    HaberTuru.mevzuat => LucideIcons.scale,
    HaberTuru.maas => LucideIcons.banknote,
    HaberTuru.duyuru => LucideIcons.megaphone,
    HaberTuru.atama => LucideIcons.userCheck,
  };

  static Color renk(HaberTuru t) => switch (t) {
    HaberTuru.mevzuat => PusulaRenk.mor,
    HaberTuru.maas => PusulaRenk.amber,
    HaberTuru.duyuru => PusulaRenk.mavi,
    HaberTuru.atama => PusulaRenk.turkuaz,
  };

  static Color ikonRengi(HaberTuru t) => switch (t) {
    HaberTuru.mevzuat || HaberTuru.duyuru => PusulaRenk.beyaz,
    HaberTuru.maas || HaberTuru.atama => PusulaRenk.lacivert,
  };

  /// Kapak çiziminin koyu degrade renkleri (üzerine beyaz yazı okunur).
  static (Color, Color) degrade(HaberTuru t) => switch (t) {
    HaberTuru.mevzuat => (PusulaRenk.mor, PusulaRenk.lacivert),
    HaberTuru.maas => (PusulaRenk.mavi, PusulaRenk.lacivert),
    HaberTuru.duyuru => (PusulaRenk.lacivert, PusulaRenk.mavi),
    HaberTuru.atama => (const Color(0xFF0E7C93), PusulaRenk.lacivert),
  };
}

/// Haberin kapak görseli: [Haber.gorsel] varsa ağdan yüklenir; yoksa, yüklenirken
/// ya da hata olursa türe göre çizilmiş kapak gösterilir (uygulama görselsiz de güzel görünür).
class HaberKapagi extends StatelessWidget {
  const HaberKapagi({super.key, required this.haber});

  final Haber haber;

  @override
  Widget build(BuildContext context) {
    final cizim = _CizimKapak(tur: haber.tur);
    final adres = haber.gorsel;
    if (adres == null) return cizim;
    return Stack(
      fit: StackFit.expand,
      children: [
        cizim,
        Image.network(
          adres.toString(),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          excludeFromSemantics: true,
          errorBuilder: (context, hata, iz) => const SizedBox.shrink(),
          frameBuilder: (context, child, kare, senkron) => AnimatedOpacity(
            opacity: kare == null ? 0 : 1,
            duration: const Duration(milliseconds: 400),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _CizimKapak extends StatelessWidget {
  const _CizimKapak({required this.tur});

  final HaberTuru tur;

  @override
  Widget build(BuildContext context) {
    final (a, b) = HaberGorunumu.degrade(tur);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b]),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            right: -40,
            top: -30,
            child: Opacity(
              opacity: 0.12,
              child: PusulaUcgenler(boyut: 210, orta: PusulaRenk.beyaz),
            ),
          ),
          Positioned(
            right: 22,
            top: 22,
            child: Icon(HaberGorunumu.ikon(tur), size: 64, color: PusulaRenk.beyaz.withValues(alpha: 0.28)),
          ),
        ],
      ),
    );
  }
}
