import 'package:flutter/material.dart';

import 'tema.dart';

/// Ayas Software logosundaki beş üçgen (100x100 birimlik alanda).
/// [orta] logonun ortadaki (mavi) üçgeninin rengi; koyu zeminde lacivert verilir.
class KadroUcgenler extends StatelessWidget {
  const KadroUcgenler({super.key, required this.boyut, this.orta = KadroRenk.mavi});

  final double boyut;
  final Color orta;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: boyut,
        child: CustomPaint(painter: _UcgenRessami(orta)),
      );
}

class _UcgenRessami extends CustomPainter {
  _UcgenRessami(this.orta);

  final Color orta;

  static const _sekiller = <List<Offset>>[
    [Offset(8, 6), Offset(42, 6), Offset(24, 40)],
    [Offset(50, 0), Offset(68, 0), Offset(46, 52), Offset(32, 52)],
    [Offset(60, 14), Offset(92, 14), Offset(70, 72), Offset(36, 72)],
    [Offset(78, 48), Offset(98, 92), Offset(72, 92)],
    [Offset(2, 58), Offset(28, 58), Offset(44, 92), Offset(4, 92)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final renkler = [
      KadroRenk.turkuaz,
      KadroRenk.amber,
      orta,
      KadroRenk.eflatun,
      KadroRenk.mor,
    ];
    final olcek = size.width / 100;
    for (var i = 0; i < _sekiller.length; i++) {
      final yol = Path()..addPolygon(
          _sekiller[i].map((p) => p * olcek).toList(),
          true,
        );
      canvas.drawPath(yol, Paint()..color = renkler[i]);
    }
  }

  @override
  bool shouldRepaint(_UcgenRessami eski) => eski.orta != orta;
}
