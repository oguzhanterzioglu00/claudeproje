import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Kamu Pusulası logosu: dört renkli halka, yön gülü ve kuzeydoğuyu gösteren ibre.
/// Tam (yazılı) logo görseli için `assets/marka/logo_tam.png`; bu çizim yazısız simge ve animasyon içindir.
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

  // Halka renkleri (logodaki dört yay).
  static const _kehribar = Color(0xFFFBB040);
  static const _turuncu = Color(0xFFF7941D);
  static const _gok = Color(0xFF19C1EA);
  static const _mavi = Color(0xFF2D6BD8);
  static const _mor = Color(0xFF6A3BD8);
  static const _pembe = Color(0xFFC060E6);

  static double _rad(double derece) => derece * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    canvas.scale(k);

    if (arkaplan) _zemin(canvas);

    canvas.translate(50, 50);
    canvas.scale(icerikOlcegi);

    _halka(canvas);
    _yildiz(canvas);
    _ibre(canvas);
    _pim(canvas);
  }

  void _zemin(Canvas canvas) {
    const kutu = Rect.fromLTWH(0, 0, 100, 100);
    final r = koseOrani * 100;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(kutu, Radius.circular(r)));
    canvas.drawRect(
      kutu,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4FC0), Color(0xFF0F2266), Color(0xFF0A1442)],
          stops: [0, 0.45, 1],
        ).createShader(kutu),
    );
    // Logodaki geometrik şekiller: solda mor üçgen, sağ üstte camgöbeği, sağda kehribar.
    canvas.drawPath(
      Path()..addPolygon(const [Offset(0, 16), Offset(32, 50), Offset(0, 84)], true),
      Paint()..color = const Color(0xFF7B3FE0).withValues(alpha: 0.55),
    );
    canvas.drawPath(
      Path()..addPolygon(const [Offset(80, 0), Offset(100, 0), Offset(100, 40), Offset(74, 26)], true),
      Paint()..color = _gok.withValues(alpha: 0.75),
    );
    canvas.drawPath(
      Path()..addPolygon(const [Offset(84, 44), Offset(100, 38), Offset(100, 74), Offset(76, 58)], true),
      Paint()..color = _kehribar.withValues(alpha: 0.7),
    );
    canvas.restore();
  }

  /// Dört renkli, aralarında boşluk olan halka.
  void _halka(Canvas canvas) {
    const yaricap = 34.0;
    const kalinlik = 7.6;
    final kutu = Rect.fromCircle(center: Offset.zero, radius: yaricap);

    void yay(double baslangic, double bitis, Color a, Color b) {
      final s = _rad(baslangic);
      final e = _rad(bitis);
      canvas.drawArc(
        kutu,
        s,
        e - s,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kalinlik
          ..strokeCap = StrokeCap.butt
          ..shader = SweepGradient(startAngle: s, endAngle: e, colors: [a, b]).createShader(kutu),
      );
    }

    yay(-176.5, -90.5, _turuncu, _kehribar); // sol üst
    yay(-83.5, 5.5, _gok, _mavi); // sağ üst
    yay(12.5, 91.5, _mavi, _mor); // sağ alt
    yay(98.5, 177.5, _mor, _pembe); // sol alt
  }

  /// Dört uçlu yıldız (yön gülü): her kanat iki tonlu.
  void _yildiz(Canvas canvas) {
    const uc = 27.0;
    const ic = 5.3;
    final acik = Paint()..color = const Color(0xFFFFFFFF);
    final koyu = Paint()..color = const Color(0xFFC3CCEE);
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 2);
      canvas.drawPath(Path()..addPolygon(const [Offset(0, -uc), Offset(-ic, -ic), Offset.zero], true), acik);
      canvas.drawPath(Path()..addPolygon(const [Offset(0, -uc), Offset(ic, -ic), Offset.zero], true), koyu);
      canvas.restore();
    }
  }

  /// İbre: kuzey yarısı sarı-turuncu, güney yarısı beyaz.
  void _ibre(Canvas canvas) {
    canvas.save();
    canvas.rotate(ibreAcisi);
    const boy = 31.5;
    const yan = 8.0;
    void yari(double yon, Color sol, Color sag) {
      canvas.drawPath(
          Path()..addPolygon([Offset(0, yon * boy), const Offset(-yan, 0), Offset.zero], true), Paint()..color = sol);
      canvas.drawPath(
          Path()..addPolygon([Offset(0, yon * boy), const Offset(yan, 0), Offset.zero], true), Paint()..color = sag);
    }

    yari(-1, const Color(0xFFFFD25C), _turuncu);
    yari(1, const Color(0xFFFFFFFF), const Color(0xFFC3CCEE));
    canvas.restore();
  }

  void _pim(Canvas canvas) {
    canvas.drawCircle(Offset.zero, 5.2, Paint()..color = const Color(0xFF2450B0));
    canvas.drawCircle(Offset.zero, 3.5, Paint()..color = const Color(0xFF0C1E5F));
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
