import 'package:flutter/material.dart';

import 'core/tema.dart';
import 'features/becayis/data/becayis_deposu.dart';
import 'features/becayis/data/ornek_veri.dart';
import 'features/becayis/domain/statu.dart';
import 'features/kabuk/pusula_kabugu.dart';

void main() => runApp(const PusulaUygulamasi());

class PusulaUygulamasi extends StatefulWidget {
  const PusulaUygulamasi({super.key});

  @override
  State<PusulaUygulamasi> createState() => _PusulaUygulamasiState();
}

class _PusulaUygulamasiState extends State<PusulaUygulamasi> {
  // Profil ve veriler arka uç bağlanana kadar örnektir.
  static const _profil = Profil(ad: 'Ayşe Yılmaz', statu: Statu.memur657);
  final BecayisDeposu _depo = BecayisOrnekVeri.depo();

  @override
  void dispose() {
    _depo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Kamu Pusulası',
        debugShowCheckedModeBanner: false,
        theme: pusulaTema(),
        home: PusulaKabugu(profil: _profil, becayisDeposu: _depo),
      );
}
