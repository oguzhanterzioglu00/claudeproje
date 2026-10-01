import 'package:flutter/material.dart';

import 'hareket.dart';
import 'tema.dart';

/// Yüklenirken liste kartlarının yerini tutan iskelet: gri bloklar üzerinden soldan sağa parıltı
/// geçer. Dönen halka yerine içeriğin şeklini önceden gösterir; sayfa "boş" görünmez.
class IskeletListe extends StatefulWidget {
  const IskeletListe({super.key, this.adet = 3, this.kartYuksekligi = 104});

  final int adet;
  final double kartYuksekligi;

  @override
  State<IskeletListe> createState() => _IskeletListeState();
}

class _IskeletListeState extends State<IskeletListe> with SingleTickerProviderStateMixin {
  AnimationController? _kontrol;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final canli = !PusulaHareket.azalt(context) && PusulaHareket.susHareketi;
    if (canli && _kontrol == null) {
      _kontrol = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    } else if (!canli) {
      _kontrol?.dispose();
      _kontrol = null;
    }
  }

  @override
  void dispose() {
    _kontrol?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Yükleniyor',
    container: true,
    excludeSemantics: true,
    child: _Parilti(
      animasyon: _kontrol,
      child: Column(
        children: [
          for (var i = 0; i < widget.adet; i++) ...[
            _IskeletKart(yukseklik: widget.kartYuksekligi),
            if (i < widget.adet - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    ),
  );
}

class _Parilti extends InheritedWidget {
  const _Parilti({required this.animasyon, required super.child});

  final Animation<double>? animasyon;

  static Animation<double>? al(BuildContext c) => c.dependOnInheritedWidgetOfExactType<_Parilti>()?.animasyon;

  @override
  bool updateShouldNotify(_Parilti eski) => eski.animasyon != animasyon;
}

class _IskeletKart extends StatelessWidget {
  const _IskeletKart({required this.yukseklik});

  final double yukseklik;

  @override
  Widget build(BuildContext context) => Container(
    height: yukseklik,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: PusulaRenk.beyaz,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: PusulaRenk.cizgi, width: 1.5),
    ),
    child: const Row(
      children: [
        IskeletBlok(genislik: 56, yukseklik: 56, yaricap: 18),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IskeletBlok(yukseklik: 14),
              SizedBox(height: 8),
              IskeletBlok(genislik: 150, yukseklik: 12),
              SizedBox(height: 8),
              IskeletBlok(genislik: 90, yukseklik: 10),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Parıltılı gri blok; [IskeletListe] altında soldan sağa parlar, dışında düz gri durur.
class IskeletBlok extends StatelessWidget {
  const IskeletBlok({super.key, this.genislik, this.yukseklik = 12, this.yaricap = 8});

  final double? genislik;
  final double yukseklik;
  final double yaricap;

  @override
  Widget build(BuildContext context) {
    final anim = _Parilti.al(context);
    Widget blok(double v) => Container(
      width: genislik,
      height: yukseklik,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(yaricap),
        gradient: LinearGradient(
          begin: Alignment(-2 + 4 * v, 0),
          end: Alignment(-1 + 4 * v, 0),
          colors: const [PusulaRenk.cizgi, Color(0xFFF6F5FB), PusulaRenk.cizgi],
          stops: const [0.2, 0.5, 0.8],
        ),
      ),
    );
    if (anim == null) return blok(0.5);
    return AnimatedBuilder(animation: anim, builder: (context, _) => blok(anim.value));
  }
}
