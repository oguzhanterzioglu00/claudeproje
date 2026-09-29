import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tema.dart';

/// Kamu Pusulası logosu: halka içinde, kuzeyi gösteren pusula ibresi.
/// Halka ve ibre Ayas Software renklerindedir (amber kuzey, turkuaz güney).
///
/// [arkaplan] true ise lacivert yuvarlatılmış kare çizilir (uygulama simgesi);
/// false ise yalnızca pusula çizilir (koyu bir zemin üstünde kullanmak için).
/// [icerikOlcegi] pusulanın küçültülmesi içindir (Android uyarlanabilir simge güvenli alanı).
class PusulaLogo extends StatelessWidget {
  const PusulaLogo({
    super.key,
    required this.boyut,
    this.arkaplan = true,
    this.koseOrani = 0.22,
    this.icerikOlcegi = 1,
  });

  final double boyut;
  final bool arkaplan;

  /// Köşe yarıçapının kenara oranı; 0 tam kare.
  final double koseOrani;
  final double icerikOlcegi;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Kamu Pusulası logosu',
        image: true,
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: boyut,
          child: CustomPaint(
              painter: PusulaLogoRessami(arkaplan: arkaplan, koseOrani: koseOrani, icerikOlcegi: icerikOlcegi)),
        ),
      );
}

class PusulaLogoRessami extends CustomPainter {
  const PusulaLogoRessami({
    this.arkaplan = true,
    this.koseOrani = 0.22,
    this.icerikOlcegi = 1,
    this.ibreAcisi = math.pi / 4,
  });

  final bool arkaplan;
  final double koseOrani;
  final double icerikOlcegi;

  /// İbrenin kuzeyden saat yönündeki açısı (radyan); varsayılan kuzeydoğu.
  final double ibreAcisi;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    canvas.scale(k);

    if (arkaplan) {
      final r = koseOrani * 100;
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 100, 100), Radius.circular(r)),
        Paint()..color = PusulaRenk.lacivert,
      );
    }

    canvas.translate(50, 50);
    canvas.scale(icerikOlcegi);

    final beyaz = Paint()..color = PusulaRenk.beyaz.withValues(alpha: 0.92);

    // Halka.
    canvas.drawCircle(
      Offset.zero,
      32,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2
        ..color = beyaz.color,
    );

    // Dört yön çentiği.
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 2);
      canvas.drawLine(
        const Offset(0, -38.5),
        const Offset(0, -45),
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4.2
          ..color = beyaz.color,
      );
      canvas.restore();
    }

    // İbre: kuzeydoğuyu gösteren elmas; kuzey yarısı amber, güney yarısı turkuaz.
    canvas.rotate(ibreAcisi);
    const uzunluk = 27.0;
    const yari = 9.6;
    final kuzey = Path()
      ..moveTo(0, -uzunluk)
      ..lineTo(yari, 0)
      ..lineTo(-yari, 0)
      ..close();
    final guney = Path()
      ..moveTo(0, uzunluk)
      ..lineTo(yari, 0)
      ..lineTo(-yari, 0)
      ..close();
    canvas.drawPath(guney, Paint()..color = PusulaRenk.turkuaz);
    canvas.drawPath(kuzey, Paint()..color = PusulaRenk.amber);

    // Merkez pimi.
    canvas.drawCircle(Offset.zero, 4.2, Paint()..color = PusulaRenk.lacivert);
    canvas.drawCircle(
      Offset.zero,
      4.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = beyaz.color,
    );
  }

  @override
  bool shouldRepaint(PusulaLogoRessami eski) =>
      eski.arkaplan != arkaplan ||
      eski.koseOrani != koseOrani ||
      eski.icerikOlcegi != icerikOlcegi ||
      eski.ibreAcisi != ibreAcisi;
}

/// Açılışta ibresi sallanıp kuzeydoğuda duran logo (tek seferlik, sonlu animasyon).
/// Sistem "hareketi azalt" ayarı açıksa doğrudan son konumda görünür.
class AnimasyonluPusulaLogo extends StatefulWidget {
  const AnimasyonluPusulaLogo({
    super.key,
    required this.boyut,
    this.arkaplan = true,
    this.koseOrani = 0.22,
    this.sure = const Duration(milliseconds: 1600),
  });

  final double boyut;
  final bool arkaplan;
  final double koseOrani;
  final Duration sure;

  @override
  State<AnimasyonluPusulaLogo> createState() => _AnimasyonluPusulaLogoState();
}

class _AnimasyonluPusulaLogoState extends State<AnimasyonluPusulaLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _kontrol = AnimationController(vsync: this, duration: widget.sure);
  late final Animation<double> _aci = Tween<double>(begin: -math.pi * 0.9, end: math.pi / 4)
      .animate(CurvedAnimation(parent: _kontrol, curve: Curves.elasticOut));
  bool _basladi = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_basladi) return;
    _basladi = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _kontrol.value = 1;
    } else {
      _kontrol.forward();
    }
  }

  @override
  void dispose() {
    _kontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Kamu Pusulası logosu',
        image: true,
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: widget.boyut,
          child: AnimatedBuilder(
            animation: _aci,
            builder: (context, _) => CustomPaint(
              painter: PusulaLogoRessami(
                arkaplan: widget.arkaplan,
                koseOrani: widget.koseOrani,
                ibreAcisi: _aci.value,
              ),
            ),
          ),
        ),
      );
}
