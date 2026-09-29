import 'package:flutter/material.dart';

/// Google "G" işaretinin sadeleştirilmiş çizimi (dört renkli halka ve çubuk).
/// Mağazaya gönderirken Google'ın resmî düğme varlıklarıyla değiştirilmelidir.
class GoogleGIkonu extends StatelessWidget {
  const GoogleGIkonu({super.key, this.boyut = 22});

  final double boyut;

  @override
  Widget build(BuildContext context) => SizedBox.square(dimension: boyut, child: CustomPaint(painter: _GRessami()));
}

class _GRessami extends CustomPainter {
  static const _mavi = Color(0xFF4285F4);
  static const _kirmizi = Color(0xFFEA4335);
  static const _sari = Color(0xFFFBBC05);
  static const _yesil = Color(0xFF34A853);

  static double _rad(double derece) => derece * 3.141592653589793 / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final kalinlik = size.width * 0.2;
    final r = size.width / 2 - kalinlik / 2;
    final merkez = Offset(size.width / 2, size.height / 2);
    final kutu = Rect.fromCircle(center: merkez, radius: r);
    Paint boya(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kalinlik
      ..color = c;

    canvas.drawArc(kutu, _rad(-45), _rad(-95), false, boya(_kirmizi));
    canvas.drawArc(kutu, _rad(-140), _rad(-80), false, boya(_sari));
    canvas.drawArc(kutu, _rad(140), _rad(-100), false, boya(_yesil));
    canvas.drawArc(kutu, _rad(40), _rad(-45), false, boya(_mavi));
    canvas.drawRect(
      Rect.fromLTWH(merkez.dx, merkez.dy - kalinlik / 2, r + kalinlik / 2, kalinlik),
      Paint()..color = _mavi,
    );
  }

  @override
  bool shouldRepaint(_GRessami eski) => false;
}
