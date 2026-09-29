import 'package:flutter/material.dart';

/// Tasarımdaki "rise" girişi: aşağıdan hafifçe yükselerek belirir.
/// Sistem "hareketi azalt" ayarı açıksa animasyonsuz gösterir.
class Yukselen extends StatefulWidget {
  const Yukselen({
    super.key,
    required this.child,
    this.gecikme = Duration.zero,
  });

  final Widget child;
  final Duration gecikme;

  @override
  State<Yukselen> createState() => _YukselenState();
}

class _YukselenState extends State<Yukselen>
    with SingleTickerProviderStateMixin {
  static const _sure = Duration(milliseconds: 650);
  late final AnimationController _kontrol;
  late final Animation<double> _egri;

  @override
  void initState() {
    super.initState();
    final toplam = _sure + widget.gecikme;
    _kontrol = AnimationController(vsync: this, duration: toplam);
    _egri = CurvedAnimation(
      parent: _kontrol,
      curve: Interval(
        widget.gecikme.inMilliseconds / toplam.inMilliseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
    _kontrol.forward();
  }

  @override
  void dispose() {
    _kontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _egri,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _egri.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - _egri.value)),
          child: child,
        ),
      ),
    );
  }
}
